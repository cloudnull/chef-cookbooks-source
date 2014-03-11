# Cookbook Name:: openstack-ceph
# Recipe:: radosgw
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "osops-utils"

unless node["ceph"]["service_pass"]
    Chef::Log.info("Running swift setup - setting swift passwords")
end

# Set a secure keystone service password
node.set_unless['ceph']['service_pass'] = secure_password

# register with keystone
keystone = get_settings_by_role("keystone-setup", "keystone")
ks_admin = get_access_endpoint("keystone-api","keystone","admin-api")
ks_service = get_access_endpoint("keystone-api","keystone","service-api")
rgw_access = get_access_endpoint("ceph-radosgw","ceph", "radosgw")

node.set["ceph"]["config"]["rgw"]["rgw keystone url"] = "#{ks_admin['scheme']}://#{ks_admin['host']}:#{ks_admin['port']}/v2.0/"
node.set["ceph"]["config"]["rgw"]["rgw keystone admin token"] = "#{keystone['admin_token']}"

node.set["ceph"]["radosgw"]["keystone_signing"] = "/root/keystone/signing_cert.pem"
node.set["ceph"]["radosgw"]["keystone_ca"] = "/root/keystone/ca.pem"

directory "/root/keystone" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

if node["keystone"]["pki"]["enabled"] == true
  file "/root/keystone/signing_cert.pem" do
    owner   "root"
    group   "root"
    mode    "0644"
    content keystone["pki"]["cert"]
  end

  file "/root/keystone/ca.pem" do
    owner   "root"
    group   "root"
    mode    "0444"
    content keystone["pki"]["cacert"]
  end
else
  raise "keystone not using PKI so certs can't be created"
end

# Register Service Tenant
keystone_tenant "Create Service Tenant" do
  auth_host ks_admin["host"]
  auth_port ks_admin["port"]
  auth_protocol ks_admin["scheme"]
  api_ver ks_admin["path"]
  auth_token keystone["admin_token"]
  tenant_name node["ceph"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled true # Not required as this is the default
  action :create
end

# Register Service User
keystone_user "Create Service User" do
  auth_host ks_admin["host"]
  auth_port ks_admin["port"]
  auth_protocol ks_admin["scheme"]
  api_ver ks_admin["path"]
  auth_token keystone["admin_token"]
  tenant_name node["ceph"]["service_tenant_name"]
  user_name node["ceph"]["service_user"]
  user_pass node["ceph"]["service_pass"]
  user_enabled true # Not required as this is the default
  action :create
end

## Grant Admin role to Service User for Service Tenant ##
keystone_role "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host ks_admin["host"]
  auth_port ks_admin["port"]
  auth_protocol ks_admin["scheme"]
  api_ver ks_admin["path"]
  auth_token keystone["admin_token"]
  tenant_name node["ceph"]["service_tenant_name"]
  user_name node["ceph"]["service_user"]
  role_name node["ceph"]["service_role"]
  action :grant
end

# Register Storage Service
keystone_service "Create Storage Service" do
  auth_host ks_admin["host"]
  auth_port ks_admin["port"]
  auth_protocol ks_admin["scheme"]
  api_ver ks_admin["path"]
  auth_token keystone["admin_token"]
  service_name "swift"
  service_type "object-store"
  service_description "Swift Object Storage Service"
  action :create
end

# Register Storage Endpoint
keystone_endpoint "Register Storage Endpoint" do
  auth_host ks_admin["host"]
  auth_port ks_admin["port"]
  auth_protocol ks_admin["scheme"]
  api_ver ks_admin["path"]
  auth_token keystone["admin_token"]
  service_type "object-store"
  endpoint_region "RegionOne"
  endpoint_adminurl rgw_access['uri']
  endpoint_internalurl rgw_access['uri']
  endpoint_publicurl rgw_access['uri']
  action :create
end

# This is a work around until PR https://github.com/ceph/ceph-cookbooks/pull/79 is merged.
# Once merged remove below this point although it shouldn't cause any issues.

include_recipe "apache2"

case node['platform_family']
when "debian"
  packages = %w{
    libnss3-tools
  }
when "rhel","fedora","suse"
  packages = %w{
    nss-tools
  }
end

packages.each do |pkg|
  package pkg do
    action :upgrade
  end
end

if !(node["ceph"]["radosgw"]["keystone_ca"].nil? || node["ceph"]["radosgw"]["keystone_signing"].nil? || node["ceph"]["config"]["rgw"]["nss db path"].nil?)
  directory "#{node['ceph']['config']['rgw']['nss db path']}" do
    owner "root"
    group "root"
    mode 0755
    recursive true
    action :create
  end
  unless (File.exists?("#{node['ceph']['config']['rgw']['nss db path']}/cert8.db") && File.exists?("#{node['ceph']['config']['rgw']['nss db path']}/key3.db") && File.exists?("#{node['ceph']['config']['rgw']['nss db path']}/secmod.db"))
    execute "keystone-ca certutil" do
      command "openssl x509 -in #{node['ceph']['radosgw']['keystone_ca']} -pubkey | certutil -d #{node['ceph']['config']['rgw']['nss db path']} -A -n ca -t 'TCu,Cu,Tuw'"
    end
    execute "keystone-signing certutil" do
      command "openssl x509 -in #{node['ceph']['radosgw']['keystone_signing']} -pubkey | certutil -A -d #{node['ceph']['config']['rgw']['nss db path']} -n signing_cert -t 'P,P,P'"
    end
  end
  file "#{node['ceph']['config']['rgw']['nss db path']}/cert8.db" do
    owner node['apache']['user']
  end
  file "#{node['ceph']['config']['rgw']['nss db path']}/key3.db" do
    owner node['apache']['user']
  end
  file "#{node['ceph']['config']['rgw']['nss db path']}/secmod.db" do
    owner node['apache']['user']
  end
end
