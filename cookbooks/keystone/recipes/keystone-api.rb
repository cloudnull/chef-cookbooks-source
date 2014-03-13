#
# Cookbook Name:: keystone
# Recipe:: server
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

# Install all of keystone
execute "install_genastack_keystone_api" do
  command "genastack keystone_api"
  action :run
end

ks_setup_role = node["keystone"]["setup_role"]
ks_api_role = node["keystone"]["api_role"]

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "osops-utils"

include_recipe "keystone::keystone-common"

keystone = get_settings_by_role(ks_setup_role, "keystone")

ks_admin_bind = get_bind_endpoint("keystone", "admin-api")
ks_service_bind = get_bind_endpoint("keystone", "service-api")
ks_internal_bind = get_bind_endpoint("keystone", "internal-api")
end_point_schemes = [
  ks_service_bind["scheme"],
  ks_admin_bind["scheme"],
  ks_internal_bind["scheme"]
]

platform_options = node["keystone"]["platform"]
service "keystone" do
  service_name platform_options["keystone_service"]
  supports :status => true, :restart => true
  unless end_point_schemes.any? {|scheme| scheme == "https"}
    action :enable
    subscribes :restart, "template[/etc/keystone/keystone.conf]", :immediately
    notifies :run, "execute[Keystone: sleep]", :immediately
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
      notifies :restart, "service[apache2]", :immediately
    end
  end
end

ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_internal_endpoint = get_access_endpoint(ks_api_role, ks_ns, "internal-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")

## Add Endpoints ##
node.set["keystone"]["adminURL"] = ks_admin_endpoint["uri"]
node.set["keystone"]["internalURL"] = ks_internal_endpoint["uri"]
node.set["keystone"]["publicURL"] = ks_service_endpoint["uri"]

Chef::Log.info "Keystone AdminURL: #{ks_admin_endpoint["uri"]}"
Chef::Log.info "Keystone InternalURL: #{ks_internal_endpoint["uri"]}"
Chef::Log.info "Keystone PublicURL: #{ks_service_endpoint["uri"]}"

# Add tenants
node["keystone"]["tenants"].each do |tenant_name|
  ## Add openstack tenant ##
  keystone_tenant "Create '#{tenant_name}' Tenant" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    tenant_name tenant_name
    tenant_description "#{tenant_name} Tenant"
    tenant_enabled true # Not required as this is the default
    action :create
  end
end

## Add Roles ##
node["keystone"]["roles"].each do |role_key|
  keystone_role "Create '#{role_key.to_s}' Role" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    role_name role_key
    action :create
  end
end

# FIXME: Workaround for https://bugs.launchpad.net/keystone/+bug/1176270
keystone_role "Get Member role-id" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token node["keystone"]["admin_token"]
  action :get_member_role_id
end

node["keystone"]["users"].each do |username, user_info|
  keystone_user "Create '#{username}' User" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]
    user_name username
    user_pass user_info["password"]
    tenant_name user_info["default_tenant"]
    user_enabled true # Not required as this is the default
    action :create
  end

  user_info["roles"].each do |rolename, tenant_list|
    tenant_list.each do |tenantname|
      keystone_role "Grant '#{rolename}' Role to '#{username}' User in '#{tenantname}' Tenant" do
        auth_host ks_admin_endpoint["host"]
        auth_port ks_admin_endpoint["port"]
        auth_protocol ks_admin_endpoint["scheme"]
        api_ver ks_admin_endpoint["path"]
        auth_token node["keystone"]["admin_token"]
        user_name username
        role_name rolename
        tenant_name tenantname
        action :grant
      end
    end
  end
end

node["keystone"]["published_services"].each do |service|
  keystone_service "Create #{service['name']}" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token node["keystone"]["admin_token"]

    service_name service["name"]
    service_type service["type"]
    service_description service["description"]

    action :create
  end

  if service.has_key?("endpoints")
    service["endpoints"].each do |region, endpoint|
      keystone_endpoint "Create #{region} #{service['name']} endpoint" do
        auth_host ks_admin_endpoint["host"]
        auth_port ks_admin_endpoint["port"]
        auth_protocol ks_admin_endpoint["scheme"]
        api_ver ks_admin_endpoint["path"]
        auth_token node["keystone"]["admin_token"]

        service_type service["type"]
        endpoint_region region
        endpoint_adminurl endpoint["admin_url"]
        endpoint_internalurl endpoint["internal_url"]
        endpoint_publicurl endpoint["public_url"]

        action :create
      end
    end
  end
end

if ks_service_endpoint["name"]
  ks_service_endpoint["uri"] = "#{ks_service_endpoint["scheme"]}://#{ks_service_endpoint["name"]}:#{ks_service_endpoint["port"]}#{ks_service_endpoint["path"]}"
end

## Add Services ##
keystone_service "Create Identity Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "keystone"
  service_type "identity"
  service_description "Keystone Identity Service"
  action :create
end

keystone_endpoint "Create/Update Identity Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "identity"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl ks_admin_endpoint["uri"]
  endpoint_internalurl ks_internal_endpoint["uri"]
  endpoint_publicurl ks_service_endpoint["uri"]
  action :recreate
end

# Create EC2 Users
node["keystone"]["users"].each do |username, user_info|
  keystone_credentials "Create EC2 credentials for '#{username}' user" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"]
    user_name username
    tenant_name user_info["default_tenant"]
  end
end

