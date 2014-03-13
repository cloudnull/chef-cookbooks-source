#
# Cookbook Name:: keystone
# Recipe:: keystone-common
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

# Install all of keystone
execute "install_genastack_keystone_api" do
  command "genastack keystone_api"
  action :run
end

directory "/etc/keystone" do
  action :create
  owner "keystone"
  group "keystone"
  mode "0700"
end

execute "keystone-manage pki_setup" do
  user "keystone"
  group "keystone"
  command "keystone-manage pki_setup"
  action :run
end

# fixup the keystone.log ownership if it exists
file "/var/log/keystone/keystone.log" do
  owner "keystone"
  group "keystone"
  mode "0600"
  only_if { ::File.exists?("/var/log/keystone/keystone.log") }
end

file "/var/lib/keystone/keystone.db" do
  action :delete
end

ks_setup_role = node["keystone"]["setup_role"]
ks_mysql_role = node["keystone"]["mysql_role"]
ks_api_role = node["keystone"]["api_role"]

if node.recipe? "apache2"
  # Used if SSL was or is enabled
  vhost_location = value_for_platform(
    ["ubuntu", "debian", "fedora"] => {
      "default" => "#{node["apache"]["dir"]}/sites-enabled/openstack-keystone"
    },
    "fedora" => {
      "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-keystone"
    },
    ["redhat", "centos"] => {
      "default" => "#{node["apache"]["dir"]}/conf.d/openstack-keystone"
    },
    "default" => {
      "default" => "#{node["apache"]["dir"]}/openstack-keystone"
    }
  )
  # If no URI is SSL enabled check to see if vhost existed,
  # delete it and bounce httpd
  # Used when going from https -> http
  execute "Disable https" do
    command "rm -f #{vhost_location}"
    only_if { File.exists?(vhost_location) }
    notifies :restart, "service[apache2]", :delayed
    action :nothing
  end
end

platform_options = node["keystone"]["platform"]

execute "Keystone: sleep" do
  command "sleep 10s"
  action :nothing
end

ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_service_bind = get_bind_endpoint("keystone", "service-api")
ks_internal_bind = get_bind_endpoint("keystone", "internal-api")
end_point_schemes = [ks_service_bind["scheme"],
                     ks_admin_bind["scheme"],
                     ks_internal_bind["scheme"]]

service "keystone" do
  service_name platform_options["keystone_service"]
  supports :status => true, :restart => true
  unless end_point_schemes.any? {|scheme| scheme == "https"}
    action :enable
    subscribes :restart, "template[/etc/keystone/keystone.conf]", :delayed
    notifies :run, "execute[Keystone: sleep]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL if "scheme" is set to https
if end_point_schemes.any? {|scheme| scheme == "https"}
  include_recipe "keystone::keystone-ssl"
else
  if node.recipe? "apache2"
    apache_site "openstack-keystone" do
      enable false
      notifies :restart, "service[apache2]", :delayed
    end
  end
end

settings = get_settings_by_role(ks_setup_role, "keystone")
mysql_info = get_mysql_endpoint(ks_mysql_role)

# only bind to 0.0.0.0 if we're not using openstack-ha w/ a keystone-admin-api VIP,
# otherwise HAProxy will fail to start when trying to bind to keystone VIP
ha_role = "openstack-ha"
vip_key = "vips.keystone-admin-api"
if get_role_count(ha_role) > 0 and rcb_safe_deref(node, vip_key)
  ip_address = ks_admin_bind["host"]
else
  ip_address = "0.0.0.0"
end

# Setup db_info hash for use in the template
db_info = {
  "user" => settings["db"]["username"],
  "pass" => settings["db"]["password"],
  "name" => settings["db"]["name"],
  "ipaddress" => mysql_info["host"]
}

ks_admin_endpoint = get_access_endpoint(ks_api_role, "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, "keystone", "service-api")

notification_provider = node["keystone"]["notification"]["driver"]
case notification_provider
when "no_op"
  notification_driver = "keystone.openstack.common.notifier.no_op_notifier"
when "rpc"
  notification_driver = "keystone.openstack.common.notifier.rpc_notifier"
when "log"
  notification_driver = "keystone.openstack.common.notifier.log_notifier"
else
  msg = "#{notification_provider}, is not currently supported by these cookbooks."
  Chef::Application.fatal! msg
end

template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  owner "keystone"
  group "keystone"
  mode "0600"
  variables(
    :debug => settings["debug"],
    :verbose => settings["verbose"],
    :db_info => db_info,
    :ip_address => ip_address,
    :service_port => ks_service_bind["port"],
    :admin_port => ks_admin_bind["port"],
    :admin_token => settings["admin_token"],
    :member_role_id => node["keystone"]["member_role_id"],
    :auth_type => settings["auth_type"],
    :ldap_options => settings["ldap"],
    :pki_token_signing => settings["pki"]["enabled"],
    :token_expiration => settings["token_expiration"],
    :admin_endpoint => "#{ks_admin_endpoint['scheme']}://#{ks_admin_endpoint['host']}:#{ks_admin_endpoint['port']}",
    :public_endpoint => "#{ks_service_endpoint['scheme']}://#{ks_service_endpoint['host']}:#{ks_service_endpoint['port']}",
    :notification_driver => notification_driver,
    :notification_topics => node["keystone"]["notification"]["topics"]
  )

  # FIXME: Workaround for https://bugs.launchpad.net/keystone/+bug/1176270
  subscribes :create, "keystone_role[Get Member role-id]", :delayed
  unless end_point_schemes.any? {|scheme| scheme == "https"}
    notifies :restart, "service[keystone]", :delayed
  else
    notifies :restart, "service[apache2]", :delayed
  end
end

# set up a token cleaning job
template "/etc/cron.d/keystone-token-cleanup" do
  source "keystone-token-cleanup.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
      "keystone_db_user" => db_info["user"],
      "keystone_db_password" => db_info["pass"],
      "keystone_db_host" => db_info["ipaddress"],
      "keystone_db_name" => db_info["name"]
  )
end
