#
# Cookbook Name:: keystone
# Recipe:: setup
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
#

# make sure we die early if there are keystone-setups other than us
if get_role_count(node["keystone"]["setup_role"], false) > 0
  msg = "You can only have one node with the keystone-setup role"
  Chef::Application.fatal! msg
end

ks_mysql_role = node["keystone"]["mysql_role"]

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"

# Allow for using a well known db password
ks_ns = "keystone"
if node["developer_mode"] == true
  node.set_unless[ks_ns]["db"]["password"] = "keystone"
  node.set_unless[ks_ns]["admin_token"] = "999888777666"
  node.set_unless[ks_ns]["users"]["monitoring"]["password"] = "monitoring"
else
  node.set_unless[ks_ns]["db"]["password"] = secure_password
  node.set_unless[ks_ns]["admin_token"] = secure_password
  node.set_unless[ks_ns]["users"]["monitoring"]["password"] = secure_password
end

#creates db and user, returns connection info, defined in osops-utils/libraries
create_db_and_user(
  "mysql",
  node["keystone"]["db"]["name"],
  node["keystone"]["db"]["username"],
  node["keystone"]["db"]["password"],
  :role => ks_mysql_role
)

get_mysql_endpoint(ks_mysql_role)["host"]

include_recipe "keystone::keystone-common"

execute "keystone-manage db_sync" do
  user "keystone"
  group "keystone"
  command "keystone-manage db_sync"
  action :run
end

# This execute block and its referenced notifier is only required in Grizzly.
# The indexing has been added into Havana.
# Defined in osops-utils/libraries
# Up stream fix:
# https://github.com/openstack/keystone/commit/9faf255cf54c1386527c67a2d75074c547aa407a
add_index_stopgap(
  "mysql",
  node["keystone"]["db"]["name"],
  node["keystone"]["db"]["username"],
  node["keystone"]["db"]["password"],
  "rax_ix_token_valid",
  "token",
  "valid",
  "execute[keystone-manage db_sync]",
  :run,
  :role => ks_mysql_role
)

add_index_stopgap(
  "mysql",
  node["keystone"]["db"]["name"],
  node["keystone"]["db"]["username"],
  node["keystone"]["db"]["password"],
  "rax_ix_token_expires",
  "token",
  "expires",
  "execute[keystone-manage db_sync]",
  :run,
  :role => ks_mysql_role
)
