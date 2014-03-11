#
# Cookbook Name:: tempest
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


case node["platform_family"]
when "debian"
  %w{python-dev libxml2 libxslt1-dev libpq-dev}.each do |pkg|
    package pkg do
      action :install
    end
  end
when "rhel"
  %w{libxslt-devel postgresql-devel}.each do |pkg|
    package pkg do
      action :install
    end
  end
end

%w{git python-unittest2 python-nose python-httplib2 python-paramiko python-testtools python-novaclient python-glanceclient testrepository python-testresources}.each do |pkg|
  package pkg do
    action :install
  end
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
keystone = get_settings_by_role("keystone-setup", "keystone")
glance_api = get_access_endpoint("glance-api", "glance","api")

# Register tempest tenant for user#1
keystone_tenant "Register tempest tenant#1" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user1_tenant"]
  tenant_description "Tempest Monitoring Tenant #1"
  tenant_enabled true # Not required as this is the default
  action :create
end

# Register tempest user#1
keystone_user "Register tempest user #1" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user1_tenant"]
  user_name node["tempest"]["user1"]
  user_pass node["tempest"]["user1_pass"]
  user_enabled true # Not required as this is the default
  action :create
end

## Grant Member role to Tempest user#1 for tempest tenant
keystone_role "Grant 'member' Role to tempest user for tempest tenant#1" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user1_tenant"]
  user_name node["tempest"]["user1"]
  role_name "Member"
  action :grant
end

# Register tempest tenant for user#2
keystone_tenant "Register tempest tenant#2" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user2_tenant"]
  tenant_description "Tempest Monitoring Tenant #2"
  tenant_enabled true # Not required as this is the default
  action :create
end

# Register tempest user#2
keystone_user "Register tempest user#2" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user2_tenant"]
  user_name node["tempest"]["user2"]
  user_pass node["tempest"]["user2_pass"]
  user_enabled true # Not required as this is the default
  action :create
end

## Grant Member role to Tempest user#2 for tempest tenant
keystone_role "Grant 'member' Role to tempest user#2 for tempest tenant#2" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["tempest"]["user2_tenant"]
  user_name node["tempest"]["user2"]
  role_name "Member"
  action :grant
end

# need to check that this is running on a node where glance is.  presumably
# this would be on a infra node
#
# if you don't want glance to upload images then set your own image id
#
if node["tempest"]["test_img1"]["id"].nil?
  Chef::Log.info "tempest/default: test_img1::id was nil so we are going to upload an image for you"
  glance_image "Image setup for cirros-tempest-test" do
    image_url node["tempest"]["test_img1"]["url"]
    image_name "cirros-#{node['tempest']['user1_tenant']}"
    keystone_user node["tempest"]["user1"]
    keystone_pass node["tempest"]["user1_pass"]
    keystone_tenant node["tempest"]["user1_tenant"]
    keystone_uri ks_admin_endpoint["uri"]
    action :upload
  end
else
  Chef::Log.info "tempest/default Using image UUID #{node["tempest"]["test_img1"]["id"]} for tempest tests"
  img1_uuid = node["tempest"]["test_img1"]["id"]
end

execute "clean_tempest_checkout" do
  command "git clean -df"
  cwd "/opt/tempest"
  user "root"
  action :nothing
end

git "/opt/tempest" do
  repository "https://github.com/openstack/tempest"
  reference "stable/havana"
  action :sync
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
keystone = get_settings_by_role("keystone-setup", "keystone")
glance_api = get_access_endpoint("glance-api", "glance","api")

template "/opt/tempest/monitoring.sh" do
  source "monitoring.sh.erb"
  owner "root"
  group "root"
  mode "0555"
  variables("test_list" => node["tempest"]["runlist"])
end

# this is placed in a ruby block so we can use a notify when the image is updated and we can get the uuid of the image
if node['tempest']['test_img1']['id'].nil?
  ruby_block "get_image1_uuid" do
    action :create
    block do
      shell_cmd="nova --no-cache --os-username=#{node['tempest']['user1']} --os-password=#{node['tempest']['user1_pass']} --os-tenant-name=#{node['tempest']['user1_tenant']} --os-auth-url=#{ks_admin_endpoint['uri']} image-show cirros-#{node['tempest']['user1_tenant']}-image | awk '{if($2==\"id\") print $4}'"
      img1_uuid_test = Mixlib::ShellOut.new(shell_cmd)
      img1_uuid_test.run_command
      img1_uuid=img1_uuid_test.stdout
      img1_uuid.delete("\n")
      if img1_uuid.length > 0
        # guard against a failure in getting the UUID of the image.
        node.set["tempest"]["tempest_img1_uuid"] = img1_uuid
      else
        node.set["tempest"]["tempest_img1_uuid"] = "Failed to get uploaded image id"
      end
    end
  end
else
  node.set["tempest"]["tempest_img1_uuid"] = node['tempest']['test_img1']['id']
end

if not node["keystone"]["users"][node["keystone"]["admin_user"]]["password"].nil?
  node.set["tempest"]["admin_pass"] = node["keystone"]["users"][keystone["admin_user"]]["password"]
end
node.save


template "/opt/tempest/etc/tempest.conf" do
  source "tempest.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({
            "tempest_use_ssl" => node["tempest"]["use_ssl"],
            "keystone_access_point" => ks_service_endpoint["host"],
            "keystone_port" => ks_service_endpoint["port"],
            "tempest_region" => node["osops"]["region"],
            "tempest_tenant_isolation" => node["tempest"]["tenant_isolation"],
            "tempest_tenant_reuse" => node["tempest"]["tenant_reuse"],
            "tempest_user1" => node["tempest"]["user1"],
            "tempest_user1_pass" => node["tempest"]["user1_pass"],
            "tempest_user1_tenant" => node["tempest"]["user1_tenant"],
            "tempest_img_flavor1" => node["tempest"]["img1_flavor"],
            "tempest_img_flavor2" => node["tempest"]["img2_flavor"],
            "glance_endpoint" => glance_api["host"],
            "glance_port" => glance_api["port"],
            "tempest_admin" => node["tempest"]["admin"],
            "tempest_admin_tenant" => node["tempest"]["admin_tenant"],
            "tempest_admin_pass" => node["tempest"]["admin_pass"],
            "tempest_alt_ssh_user" => node["tempest"]["alt_ssh_user"],
            "tempest_ssh_user" => node["tempest"]["ssh_user"],
            "tempest_user2" => node["tempest"]["user2"],
            "tempest_user2_pass" => node["tempest"]["user2_pass"],
            "tempest_user2_tenant" => node["tempest"]["user2_tenant"],
            "tempest_img_ref1" => node["tempest"]["tempest_img1_uuid"],
            "tempest_img_ref2" => node["tempest"]["tempest_img1_uuid"]
            })
end

template "/etc/cron.d/tempest" do
  source "tempest.cron.erb"
  owner "root"
  group "root"
  mode "0555"
  variables(
           "test_interval" => node["tempest"]["interval"]
  )
  only_if { node["tempest"]["use_cron"] }
end

template "/etc/logrotate.d/tempest" do
  source "tempest.logrotate.erb"
  owner "root"
  group "root"
  mode "0555"
end
