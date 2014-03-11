#
# Cookbook Name:: sosreport
# Recipe:: default
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

# RedHat has their own package
if platform_family?("debian")
  include_recipe "osops-utils::packages"
end

platform_options = node["sosreport"]["platform"]
platform_options["sosreport_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_options"]
  end
end

cookbook_file "/usr/lib/python2.6/site-packages/sos/plugins/openstack.py" do
  source "openstack.py"
  mode "0644"
  action :create
  only_if { platform?("redhat") }
end
