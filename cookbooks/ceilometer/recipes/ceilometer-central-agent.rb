#
# Cookbook Name:: ceilometer
# Recipe:: ceilometer-central-agent
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

# TODO(mancdaz)only a single central-agent can be running at any one time so we need to
# add in the keepalived stuff here to sit an ip on top of multiple instances

platform_options = node["ceilometer"]["platform"]

platform_options["central_agent_package_list"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

include_recipe "ceilometer::ceilometer-common"

service platform_options["central_agent_service"] do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "template[/etc/ceilometer/ceilometer.conf]", :delayed
end

# is there a vip for us? if so, set up keepalived vrrp
if rcb_safe_deref(node, "vips.ceilometer-central")
  network = node["ceilometer"]["services"]["central"]["network"]
  service = platform_options["central_agent_service"]

  include_recipe "keepalived"
  vip = node["vips"]["ceilometer-central"]
  vrrp_name = "vi_#{vip.gsub(/\./, '_')}"
  vrrp_interface = get_if_for_net(network, node)
  # TODO(anyone): fix this in a way that lets us run multiple clusters in the
  #               same broadcast domain.
  # this doesn't solve for the last octect == 255
  router_id = vip.split(".")[3].to_i + 1

  keepalived_chkscript "ceilometer" do
    script "#{platform_options["service_bin"]} #{service} status"
    interval 5
    action :create
  end

  keepalived_vrrp vrrp_name do
    interface vrrp_interface
    virtual_ipaddress Array(vip)
    virtual_router_id router_id  # Needs to be a integer between 1..255
    track_script "ceilometer"
    notify_master "#{platform_options["service_bin"]} #{service} restart"
    notify_backup "#{platform_options["service_bin"]} #{service} restart"
    notify_fault  "#{platform_options["service_bin"]} #{service} restart"
    notifies :restart, "service[keepalived]"
  end

end
