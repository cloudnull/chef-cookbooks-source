#
# Cookbook Name:: openstack-ha
#
# Recipe:: default
#
# Copyright 2012-2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require "ipaddr"

# Include default keepalived recipe
include_recipe "keepalived"

# Include default haproxy recipe, for loadbalancing
include_recipe "haproxy"

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup","keystone")
haproxy_platform_options = node["haproxy"]["platform"]

# set up floating ip/load balancer for the defined services
node["ha"]["available_services"].each do |s, v|

  role, ns, svc, svc_type, lb_mode, lb_algo, lb_opts, ssl_lb_opts =
    v["role"], v["namespace"], v["service"], v["service_type"], v["lb_mode"],
    v["lb_algorithm"], v["lb_options"], v["ssl_lb_options"]

  if rcb_safe_deref(node, "ha.swift-only") && node['ha']['swift-only']
    unless node.run_list.expand(node.chef_environment).roles.include?("ha-controller1")||
           node.run_list.expand(node.chef_environment).roles.include?("ha-controller2")
      next unless ["swift-proxy", "keystone-admin-api", "keystone-service-api"].include?("#{ns}-#{svc}")
    end
  end

  # See if a vip has been defined for this service, if yes create a vrrp and virtual server definition
  if listen_ip = rcb_safe_deref(node, "vips.#{ns}-#{svc}")
    ip = IPAddr.new listen_ip
    if ! ip.ipv4?()
      Chef::Application.fatal!("vips.#{ns}-#{svc} is not an IPv4 address.")
    end

    if not vrid = rcb_safe_deref(node, "vips_config_#{listen_ip}_vrid","_")
      Chef::Application.fatal! "You have not configured a VRID for the VIP.  Please set node[\"vips\"][\"config\"][\"#{listen_ip}\"][\"vrid\"]"
    end

    if not vip_network = rcb_safe_deref(node, "vips_config_#{listen_ip}_network","_")
      Chef::Application.fatal! "You have not configured a network for the VIP.  Please set node[\"vips\"][\"config\"][\"#{listen_ip}\"][\"network\"]"
    end

    # make sure we have some back ends
    if get_role_count(role) > 0

      # first configure the vrrp
      Chef::Log.info("Configuring vrrp for #{ns}-#{svc}")
      vrrp_name = "vi_#{listen_ip.gsub(/\./, '_')}"
      vrrp_interface = get_if_for_net(vip_network, node)
      mgmt_ip = get_ip_for_net(vip_network, node)
      src_ip = node["apipa"]
      router_id = vrid

      keepalived_chkscript "haproxy" do
        script "#{haproxy_platform_options["service_bin"]} #{haproxy_platform_options["haproxy_service"]} status"
        interval 5
        action :create
        not_if {File.exists?('/etc/keepalived/conf.d/script_haproxy.conf')}
      end

      # restart the keepalived service immediately so the new VIPs config gets
      # added and we can consume the API services
      keepalived_vrrp vrrp_name do
        interface vrrp_interface
        virtual_router_id router_id  # Needs to be a integer between 1..255
        track_script "haproxy"
        notify_master "/etc/keepalived/notify.sh haproxy #{vrrp_interface} #{listen_ip} #{src_ip} #{mgmt_ip}"
        notify_backup "/etc/keepalived/notify.sh del #{vrrp_interface} #{listen_ip} #{src_ip} #{mgmt_ip}"
        notify_fault "/etc/keepalived/notify.sh del #{vrrp_interface} #{listen_ip} #{src_ip} #{mgmt_ip}"
        notify_stop "/etc/keepalived/notify.sh del #{vrrp_interface} #{listen_ip} #{src_ip} #{mgmt_ip}"
        notifies :restart, "service[keepalived]", :immediately
      end

      # now configure the virtual server
      Chef::Log.info("Configuring virtual_server for #{ns}-#{svc}")

      if lb_opts.include?("activebackup")
        active_backup = true
        lb_opts = lb_opts.reject { |i| i == "activebackup" }
      else
        active_backup = false
      end
      Chef::Log.debug "active_backup is #{active_backup}"

      # Lookup listen_port from the environment, or fall back to the first searched node running the role
      listen_port = rcb_safe_deref(node, "#{ns}.services.#{svc}.port") ? node[ns]["services"][svc]["port"] : get_realserver_endpoints(role, ns, svc)[0]["port"]
      scheme = rcb_safe_deref(node, "#{ns}.services.#{svc}.port") ? node[ns]["services"][svc]["scheme"] : get_realserver_endpoints(role, ns, svc)[0]["scheme"]
      if scheme == "https"
        lb_opts = ssl_lb_opts
        lb_mode = "tcp"
      end
      # Generate array of host:port real servers
      rs_list = get_realserver_endpoints(role, ns, svc).each.inject([]) { |output,x| output << x["host"] + ":" + x["port"].to_s }
      rs_list.sort!
      Chef::Log.debug "realserver list is #{rs_list}"

      # if we're processing the keystone-internal-api and see that it's using
      # the same ip and port as the service-api then skip setting up a separate
      # internal-api virtual_server
      if "#{ns}-#{svc}" == "keystone-internal-api" && node["vips"]["keystone-service-api"] == node["vips"]["keystone-internal-api"] && node["keystone"]["services"]["service-api"]["port"] == node["keystone"]["services"]["internal-api"]["port"]
        next
     end

      haproxy_virtual_server "#{ns}-#{svc}" do
        lb_algo lb_algo
        mode lb_mode
        options lb_opts
        vs_listen_ip src_ip
        vs_listen_port listen_port.to_s
        real_servers rs_list
        active_backup active_backup
      end

    else
      Chef::Log.info("Skipping service #{ns}-#{svc} as there are currently no back ends")
    end

  elsif
    listen_ip = rcb_safe_deref(node, "external-vips.#{ns}-#{svc}")
    ip = IPAddr.new listen_ip
    if ! ip.ipv4?()
      Chef::Application.fatal!("vips.#{ns}-#{svc} is not an IPv4 address.")
    end
    Chef::Log.info("External vip found for #{ns}-#{svc}. Only updating keystone endpoint")
  else
    Chef::Log.info("Skipping: #{ns}-#{svc}")
  end

  endpoint_skip_list = node["ha"]["service_ignore_list"]
  #unless listen_ip.nil?
  if listen_ip and get_role_count(role) > 0
    # Need to update keystone endpoint
    case svc_type
    when "ec2"
      public_endpoint = get_access_endpoint(role, ns, "ec2-public")
      if public_endpoint['name']
        public_endpoint['uri'] = "#{public_endpoint['scheme']}://#{public_endpoint['name']}:#{public_endpoint['port']}#{public_endpoint['path']}"
      end
      admin_endpoint = get_access_endpoint(role, ns, "ec2-public")
      admin_path = get_settings_by_role(role, ns)['services']['ec2-admin']['path']
      admin_endpoint['uri'] = "#{admin_endpoint['scheme']}://#{admin_endpoint['host']}:#{admin_endpoint['port']}#{admin_path}"
      internal_endpoint = admin_endpoint.clone
    when "identity"
      public_endpoint = rcb_safe_deref(node, "#{ns}.services.service-api.uri") ? node[ns]["services"]["service-api"] : get_access_endpoint(role, ns, "service-api")
      if public_endpoint['name']
        public_endpoint['uri'] = "#{public_endpoint['scheme']}://#{public_endpoint['name']}:#{public_endpoint['port']}#{public_endpoint['path']}"
      end
      internal_endpoint = rcb_safe_deref(node, "#{ns}.services.internal-api.uri") ? node[ns]["services"]["internal-api"] : get_access_endpoint(role, ns, "internal-api")
      admin_endpoint  = rcb_safe_deref(node, "#{ns}.services.admin-api.uri") ? node[ns]["services"]["admin-api"] : get_access_endpoint(role, ns, "admin-api")
    else
      # ensure we use uri values for each endpoint type if they have been provided.  Else look them up
      # NOTE:(mancdaz) right now, unless you provide an override value for an endpoint type, it will use the
      # public endpoint.  This maintains current HA functionality.

      public_endpoint = rcb_safe_deref(node, "#{ns}.services.#{svc}.uri") ? node[ns]["services"][svc] : get_access_endpoint(role, ns, svc)
      if public_endpoint['name']
        public_endpoint['uri'] = "#{public_endpoint['scheme']}://#{public_endpoint['name']}:#{public_endpoint['port']}#{public_endpoint['path']}"
      end
      internal_endpoint = rcb_safe_deref(node, "#{ns}.services.internal-#{svc}.uri") ? node[ns]["services"]["internal-#{svc}"] : get_access_endpoint(role, ns, svc)
      admin_endpoint = rcb_safe_deref(node, "#{ns}.services.admin-#{svc}.uri") ? node[ns]["services"]["admin-#{svc}"] : internal_endpoint.clone
    end

    if endpoint_skip_list.include? "#{ns}-#{svc}"
      Chef::Log.info("Skipping reconfigure endpoint for #{ns}-#{svc}")
    else
      keystone_register "Recreate #{ns} Endpoint" do
        auth_host ks_admin_endpoint["host"]
        auth_port ks_admin_endpoint["port"]
        auth_protocol ks_admin_endpoint["scheme"]
        api_ver ks_admin_endpoint["path"]
        auth_token keystone["admin_token"]
        service_type svc_type
        endpoint_region node["osops"]["region"]
        endpoint_publicurl public_endpoint["uri"]
        endpoint_internalurl internal_endpoint["uri"]
        endpoint_adminurl admin_endpoint["uri"]
        retries 10
        retry_delay 5
        action :recreate_endpoint
      end
    end
  end
  # ********************************************************
end
