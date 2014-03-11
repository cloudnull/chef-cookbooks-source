# Cookbook Name:: openstack-logging
# Recipe:: cinder
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

# Cinder rsyslog setup
openstack_logging_filemonitor "cinder-api" do
  monitor_name "cinder-api"
  action :create
  only_if { node.recipe?("cinder::cinder-api") }
end
openstack_logging_filemonitor "cinder-scheduler" do
  monitor_name "cinder-scheduler"
  action :create
  only_if { node.recipe?("cinder::cinder-api") }
end
openstack_logging_filemonitor "cinder-volume" do
  monitor_name "cinder-volume"
  action :create
  only_if { node.recipe?("cinder::cinder-volume") }
end
