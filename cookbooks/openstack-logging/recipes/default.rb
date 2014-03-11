# Cookbook Name:: openstack_syslog
# Recipe:: default
#
# Copyright 2013, Rackspace US, Inc.
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

# delete old rsyslog files from folsom cookbooks
%w{/etc/rsyslog.d/24-cinder.conf /etc/rsyslog.d/22-glance.conf
   /etc/rsyslog.d/23-keystone.conf /etc/rsyslog.d/21-nova.conf}.each do |rmf|
  file rmf do
    action :delete
    only_if { ::File.exists?(rmf) }
  end
end

if node.recipe?("rsyslog::server")
  template "/etc/rsyslog.d/01-rpc-setup.conf" do
    source "rpc-server-setup.conf.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :restart, "service[rsyslog]", :delayed
  end

  template "/etc/logrotate.d/rpc-logging.conf" do
    source "rpc-logging.conf.erb"
    owner "root"
    group "root"
    mode "0600"
  end

  template "/etc/rsyslog.d/02-rpc-os-log-dest.conf" do
    source "rpc-server-os-logs.conf.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :restart, "service[rsyslog]", :delayed
  end
elsif node.recipe?("rsyslog::client")
  # borrowed from the rsyslog cookbook
  if !node['rsyslog']['server'] and node['rsyslog']['server_ip'].nil? and Chef::Config[:solo]
    Chef::Log.fatal("Chef Solo does not support search, therefore it is a requirement of the rsyslog::client recipe that the attribute 'server_ip' is set when using Chef Solo. 'server_ip' is not set.")
  elsif !node['rsyslog']['server']
    if Chef::Config[:solo]
      Chef::Log.warn("openstack-logging/default.rb: This recipe uses search. Chef Solo does not support search.")
    else
      rsyslog_server = node['rsyslog']['server_ip'] ||
                       search(:node, node['rsyslog']['server_search']).first['ipaddress'] rescue nil
      rsyslog_port = node['rsyslog']['port'] ||
                       search(:node, node['rsyslog']['server_search']).port rescue nil
    end

    if rsyslog_server.nil?
      Chef::Application.fatal!("The rsyslog::client recipe was unable to determine the remote syslog server. Checked both the server_ip attribute and search()")
    end
  end

  template "/etc/rsyslog.d/01-rpc-setup.conf" do
    source "rpc-client-setup.conf.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :restart, "service[rsyslog]", :delayed
  end

  template "/etc/rsyslog.d/11-rpc-log-shipping.conf" do
    source "rpc-log-shipping.conf.erb"
    owner "root"
    group "root"
    mode "0600"
    variables(
      "rsyslog_server" => rsyslog_server,
      "rsyslog_port" => rsyslog_port
    )
    notifies :restart, "service[rsyslog]", :delayed
  end

  include_recipe "openstack-logging::keystone"
  include_recipe "openstack-logging::nova"
  include_recipe "openstack-logging::glance"
  include_recipe "openstack-logging::cinder"
end
