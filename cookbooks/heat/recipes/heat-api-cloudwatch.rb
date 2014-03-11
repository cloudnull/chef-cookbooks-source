#
# Cookbook Name:: heat
# Recipe:: heat-api-cloudwatch
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

platform_options["cloudwatch_api_package_list"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

include_recipe "heat::heat-common"

# Drop The Default Alarm File in our Templates.
cookbook_file "/etc/heat/templates/AWS_CloudWatch_Alarm.yaml" do
  source "AWS_CloudWatch_Alarm.yaml"
  owner "heat"
  group "heat"
  mode "0644"
end

# Set service start
service platform_options["cloudwatch_api_service"] do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "template[/etc/heat/heat.conf]", :delayed
end
