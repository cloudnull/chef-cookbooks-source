#
# Cookbook Name:: collectd
# Recipe:: client
#
# Copyright 2010, Atari, Inc
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

include_recipe "collectd"

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else

  servers = []
  search(:node, "recipes:collectd\\:\\:server AND chef_environment:#{node.chef_environment}") do |n|
    servers << n['fqdn']
  end
end

if servers.empty?
  raise "No servers found.
  Please configure at least one node with collectd::server."
end

collectd_plugin "network" do
  options :server=>servers
end

collectd_plugin "syslog" do
  options :log_level => "Info"
end

# let's actually collect some stuff

include_recipe "collectd-plugins::cpu"
include_recipe "collectd-plugins::df"
include_recipe "collectd-plugins::disk"
include_recipe "collectd-plugins::interface"
include_recipe "collectd-plugins::memory"
include_recipe "collectd-plugins::swap"
collectd_plugin "load"
