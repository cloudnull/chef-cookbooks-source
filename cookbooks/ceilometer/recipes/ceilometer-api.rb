#
# Cookbook Name:: ceilometer
# Recipe:: ceilometer-compute
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

# this sets up ceilometer on compute nodes (runs the compute agent)

platform_options = node["ceilometer"]["platform"]

platform_options["api_package_list"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

include_recipe "ceilometer::ceilometer-common"
include_recipe "ceilometer::ceilometer-fix-sqlalchemy"

ceilometer_api = get_bind_endpoint("ceilometer", "api")

service platform_options["api_service"] do
  supports :status => true, :restart => true
  unless ceilometer_api["scheme"] == "https"
    action [:enable, :start]
    subscribes :restart, "template[/etc/ceilometer/ceilometer.conf]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL

if ceilometer_api["scheme"] == "https"
  include_recipe "ceilometer::ceilometer-api-ssl"
else
  if node.recipe?"apache2"
    apache_site "openstack-ceilometer-api" do
      enable false
      notifies :restart, "service[apache2]", :immediately
    end
  end
end

ceilometer_api = get_bind_endpoint("ceilometer", "api")
ceilometer_internal_api = get_bind_endpoint("ceilometer", "internal-api")
ceilometer_admin_api = get_bind_endpoint("ceilometer", "admin-api")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup", "keystone")

# register the endpoint
keystone_endpoint "Register Ceilometer Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "metering"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl ceilometer_admin_api["uri"]
  endpoint_internalurl ceilometer_internal_api["uri"]
  endpoint_publicurl ceilometer_api["uri"]
  action :recreate
end
