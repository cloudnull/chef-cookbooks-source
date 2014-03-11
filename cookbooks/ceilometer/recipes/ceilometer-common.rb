#
# Cookbook Name:: ceilometer
# Recipe:: ceilometer-common
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
#

platform_options = node["ceilometer"]["platform"]

# Get Services Data
ceilometer = get_settings_by_recipe("ceilometer\:\:ceilometer-setup", "ceilometer")
ce_service_endpoint = get_bind_endpoint("ceilometer", "api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")

# get MySQL Things
mysql_connect_ip = get_mysql_endpoint["host"]

# Get my Rabbit Queues and Settings
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
rabbit_settings = get_settings_by_role("rabbitmq-server", "rabbitmq")

# Install Packages
platform_options["supporting_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

# all ceilometers, server or client can share the same conf file

directory "/etc/ceilometer" do
  action :create
  owner "ceilometer"
  group "ceilometer"
  mode "0770"
end

# signing dir is here, even for clients
directory "/var/lib/ceilometer" do
  action :create
  owner "ceilometer"
  group "ceilometer"
  mode "700"
end

template "/etc/ceilometer/pipeline.yaml" do
  source "pipeline.yaml.erb"
  owner "ceilometer"
  group "ceilometer"
  mode "0644"
  not_if {File.exists?("/etc/ceilometer/pipeline.yaml")}
end

template "/etc/ceilometer/sources.json" do
  source "sources.json.erb"
  owner "ceilometer"
  group "ceilometer"
  mode "0644"
  not_if {File.exists?("/etc/ceilometer/sources.json")}
end

template "/etc/ceilometer/policy.json" do
  source "policy.json.erb"
  owner "ceilometer"
  group "ceilometer"
  mode "0644"
  not_if {File.exists?("/etc/ceilometer/policy.json")}
end

notification_provider = node["ceilometer"]["notification"]["driver"]
case notification_provider
when "no_op"
  notification_driver = "ceilometer.openstack.common.notifier.no_op_notifier"
when "rpc"
  notification_driver = "ceilometer.openstack.common.notifier.rpc_notifier"
when "log"
  notification_driver = "ceilometer.openstack.common.notifier.log_notifier"
else
  msg = "#{notification_provider}, is not currently supported by these cookbooks."
  Chef::Application.fatal! msg
end


template "/etc/ceilometer/ceilometer.conf" do
  source "ceilometer.conf.erb"
  owner "ceilometer"
  group "ceilometer"
  mode "0660"
  variables(
    "verbose" => ceilometer["logging"]["verbose"],
    "debug" => ceilometer["logging"]["debug"],
    "metering_secret" => ceilometer["metering_secret"],
    "mysql_user" => ceilometer["db"]["username"],
    "mysql_password" => ceilometer["db"]["password"],
    "mysql_host" => mysql_connect_ip,
    "mysql_db" => ceilometer["db"]["name"],
    "ceilometer_admin" => ceilometer["service_user"],
    "ceilometer_password" => ceilometer["service_pass"],
    "ceilometer_tenant" => ceilometer["service_tenant_name"],
    "bind_host" => ce_service_endpoint["host"],
    "bind_port" => ce_service_endpoint["port"],
    "keystone_auth_url" => ks_service_endpoint["uri"],
    "keystone_service_protocol" => ks_service_endpoint["scheme"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "keystone_service_host" => ks_service_endpoint["host"],
    "keystone_auth_protocol" => ks_admin_endpoint["scheme"],
    "keystone_auth_port" => ks_admin_endpoint["port"],
    "keystone_auth_host" => ks_admin_endpoint["host"],
    "rabbit_host" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "rabbit_ha_queues" => rabbit_settings["cluster"] ? "True" : "False",
    "notification_driver" => notification_driver,
    "notification_topics" => node["ceilometer"]["notification"]["topics"]
  )
end
