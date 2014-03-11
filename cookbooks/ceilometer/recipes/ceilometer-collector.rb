#
# Cookbook Name:: ceilometer
# Recipe:: ceilometer-collector
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

# this sets up ceilometer on collector (runs the ceilometer collector to process
# queue messages that are placed there by the agents)

platform_options = node["ceilometer"]["platform"]

platform_options["collector_package_list"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

include_recipe "ceilometer::ceilometer-common"

service platform_options["collector_service"] do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "template[/etc/ceilometer/ceilometer.conf]", :delayed
end
