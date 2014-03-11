#
# Cookbook Name:: heat
# Recipe:: heat-setup
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
# this does setup, registers the service with keystone
# and lays down the central agent (which can only exist once currently)

# die early if setup has already been run on another node
if get_role_count('heat-setup', false) > 0
  Chef::Application.fatal! "You can only have one node with the heat-setup role"
end

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

if node["developer_mode"] == true
  node.set_unless["heat"]["db"]["password"] = "heat"
else
  node.set_unless["heat"]["db"]["password"] = secure_password(16)
end

# Encryption Secrete
node.set_unless["heat"]["auth_encryption_key"] = secure_password(64)

# set a secure heat service password
node.set_unless["heat"]["service_pass"] = secure_password(24)

# Save our attributes
node.save

include_recipe "mysql::client"
include_recipe "mysql::ruby"

# Setup Keystone
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup", "keystone")

create_db_and_user(
  "mysql",
  node["heat"]["db"]["name"],
  node["heat"]["db"]["username"],
  node["heat"]["db"]["password"]
)

execute "heat db sync" do
  command "heat-manage db_sync"
  user "heat"
  group "heat"
  action :nothing
  subscribes :run, "template[/etc/heat/heat.conf]", :immediately
end

# register the service user
keystone_user "Register Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["heat"]["service_tenant_name"]
  user_name node["heat"]["service_user"]
  user_pass node["heat"]["service_pass"]
  user_enabled true
  action :create
end

# Grant the role
keystone_role "Grant Heat service role" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["heat"]["service_tenant_name"]
  user_name node["heat"]["service_user"]
  role_name node["heat"]["service_role"]
  action :grant
end

# Heat Service
keystone_service "Register Heat Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "heat"
  service_type "orchestration"
  service_description "Heat Service"
  action :create
end
