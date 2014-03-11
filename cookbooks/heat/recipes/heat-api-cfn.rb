#
# Cookbook Name:: heat
# Recipe:: heat-api-cfn
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

platform_options = node["heat"]["platform"]

platform_options["cfn_api_package_list"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

include_recipe "heat::heat-common"

cookbook_file "/etc/heat/templates/AWS_RDS_DBInstance.yaml" do
  source "AWS_RDS_DBInstance.yaml"
  owner "heat"
  group "heat"
  mode "0644"
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup", "keystone")

# register the endpoint
heat_api_cfn = get_bind_endpoint("heat", "cfn_api")
heat_internal_api = get_bind_endpoint("heat", "cfn_internal_api")
heat_admin_api = get_bind_endpoint("heat", "cfn_admin_api")

# Create Service
keystone_service "Register Heat Cloudformation Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "heat-cfn"
  service_type "cloudformation"
  service_description "Heat Cloudformation Service"
  action :create
end

# Create Endpoint
keystone_endpoint "Register Heat Cloudformation Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "cloudformation"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl heat_admin_api["uri"]
  endpoint_internalurl heat_internal_api["uri"]
  endpoint_publicurl heat_api_cfn["uri"]
  action :recreate
end

# Set service start
service platform_options["cfn_api_service"] do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "template[/etc/heat/heat.conf]", :delayed
end
