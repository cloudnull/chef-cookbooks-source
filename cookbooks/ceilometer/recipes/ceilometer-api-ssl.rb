#
# Cookbook Name:: nova
# Recipe:: nova-ssl
#
# Copyright 2012, Rackspace US, Inc.
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

include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"
include_recipe "osops-utils::ssl_packages"

# Remove monit file if it exists
if node.attribute?"monit"
  if node["monit"].attribute?"conf.d_dir"
    file "#{node['monit']['conf.d_dir']}/ceilometer-api.conf" do
      action :delete
      notifies :reload, "service[monit]", :immediately
    end
  end
end

# setup cert files
case node["platform"]
when "ubuntu", "debian"
  grp = "ssl-cert"
else
  grp = "root"
end

cookbook_file "#{node["ceilometer"]["ssl"]["dir"]}/certs/#{node["ceilometer"]["services"]["api"]["cert_file"]}" do
  source "ceilometer.pem"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "#{node["ceilometer"]["ssl"]["dir"]}/private/#{node["ceilometer"]["services"]["api"]["key_file"]}" do
  source "ceilometer.key"
  mode 0644
  owner "root"
  group grp
end

# setup wsgi file

directory "#{node["apache"]["dir"]}/wsgi" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["ceilometer"]["services"]["api"]["wsgi_file"]}" do
  source "ceilometer-api-mod_wsgi.py"
  mode 0644
  owner "root"
  group "root"
end

unless node["ceilometer"]["services"]["api"].attribute?"cert_override"
  cert_location = "#{node["ceilometer"]["ssl"]["dir"]}/certs/#{node["ceilometer"]["services"]["api"]["cert_file"]}"
else
  cert_location = node["ceilometer"]["services"]["api"]["cert_override"]
end

unless node["ceilometer"]["services"]["api"].attribute?"key_override"
  key_location = "#{node["ceilometer"]["ssl"]["dir"]}/private/#{node["ceilometer"]["services"]["api"]["key_file"]}"
else
  key_location = node["ceilometer"]["services"]["api"]["key_override"]
end

ceilometer_bind = get_access_endpoint("ceilometer-api", "ceilometer", "api")

template value_for_platform(
  ["ubuntu", "debian", "fedora"] => {
    "default" => "#{node["apache"]["dir"]}/sites-available/openstack-ceilometer-api"
  },
  "fedora" => {
    "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-ceilometer-api"
  },
  ["redhat", "centos"] => {
    "default" => "#{node["apache"]["dir"]}/conf.d/openstack-ceilometer-api"
  },
  "default" => {
    "default" => "#{node["apache"]["dir"]}/openstack-ceilometer-api"
  }
) do
  source "modwsgi_vhost.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :listen_ip => ceilometer_bind["host"],
    :service_port => ceilometer_bind["port"],
    :cert_file => cert_location,
    :key_file => key_location,
    :wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["ceilometer"]["services"]["api"]["wsgi_file"]}",
    :proc_group => "ceilometer",
    :log_file => "/var/log/ceilometer/ceilometer.log"
  )
  notifies :reload, "service[apache2]", :delayed
end

apache_site "openstack-ceilometer-api" do
  enable true
  notifies :restart, "service[apache2]", :immediately
end
