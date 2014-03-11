#
# Cookbook Name:: keepalived
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "sysctl::default"
include_recipe "osops-utils::packages"

platform_options=node["keepalived"]["platform"]

# install netfilter things.
platform_options["required_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

package "keepalived" do
  action :install
end

# upgrade this package here to make sure we have the latest version that supports
# network namespaces.
package "iproute" do
  action :upgrade
end

directory "/etc/keepalived/conf.d" do
  action :create
  owner "root"
  group "root"
  mode "0775"
end

sysctl "net.ipv4.ip_nonlocal_bind" do
  value "1"
  only_if { node["keepalived"]["shared_address"] }
end

cookbook_file "/etc/keepalived/notify.sh" do
  source "notify.sh"
  mode 0700
  group "root"
  owner "root"
  notifies :restart, "service[keepalived]", :delayed
end

template "keepalived.conf" do
  path "/etc/keepalived/keepalived.conf"
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[keepalived]", :immediately
end

service "keepalived" do
  supports :restart => true, :status => true
  action :enable
end

node["keepalived"]["check_scripts"].each_pair do |name, script|
  keepalived_chkscript name do
    script script["script"]
    interval script["interval"]
    weight script["weight"]
    action :create
  end
end

node["keepalived"]["instances"].each_pair do |name, instance|
  keepalived_vrrp name do
    interface instance["interface"]
    virtual_router_id node["keepalived"]["instance_defaults"]["virtual_router_id"]
    nopreempt false
    priority node["keepalived"]["instance_defaults"]["priority"]
    virtual_ipaddress Array(instance["ip_addresses"])
    if instance["track_script"]
      track_script instance["track_script"]
    end
    if instance["auth_type"]
      auth_type instance["auth_type"]
      auth_pass instance["auth_pass"]
    end
    action :create
  end
end

# Add an execute resource for keepalived providers to notify
execute "reload-keepalived" do
  command "#{node['keepalived']['service_bin']} keepalived reload"
  action :nothing
end

