#
# Cookbook Name:: glance
# Recipe:: glance-common
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
#
#

# Install all of glance
execute "install_genastack_glance" do
  command "genastack glance"
  action :run
end


# only run this if do_package_upgrade is enabled.  If you upgrade the package
# outside of chef you will need to run 'glance-manage db_sync' by hand.
execute "glance-manage db_sync" do
  user "glance"
  group "glance"
  command "glance-manage db_sync"
  action :nothing
end

replicator_count = get_nodes_by_recipe("glance::replicator").length

if get_role_count("ceilometer-setup") == 1 or replicator_count > 0
  node.set["glance"]["api"]["notifier_strategy"] = "rabbit"
end

# Search for rabbit endpoint info
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
rabbit_settings = get_settings_by_role("rabbitmq-server", "rabbitmq")


# Search for mysql endpoint info
mysql_info = get_mysql_endpoint

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")

# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")

# Get settings from role[glance-api]
glance = get_settings_by_role("glance-api", "glance")

# Get settings from role[glance-setup]
if ! (settings = get_settings_by_role("glance-setup", "glance"))
  msg = "No servers in your environment contain the glance::setup role!"
  Chef::Application.fatal!(msg)
end

# Get api/registry endpoint bind info
api_bind = get_bind_endpoint("glance", "api")
registry_bind = get_bind_endpoint("glance", "registry")

# Search for glance-registry endpoint info
registry_endpoint = get_access_endpoint("glance-registry", "glance", "registry")

# Only use glance image cacher if we aren't using file for our backing store.
glance_flavor = settings["api"]["flavor"]

# Possible combinations of options here
# - default_store=file
#     * no other options required
# - default_store=swift
#     * if swift_store_auth_address is not defined
#         - default to local swift
#     * else if swift_store_auth_address is defined
#         - get swift_store_auth_address, swift_store_user, swift_store_key,
#           and swift_store_auth_version from the node attributes and use them
#           to connect to the swift compatible API service running elsewhere
#           (possibly Rackspace Cloud Files).
#
if glance["api"]["swift_store_auth_address"].nil? and glance["api"]["default_store"] == "swift"

  swift_store_auth_address =
    "http://#{ks_admin_endpoint['host']}:" +
    ks_service_endpoint['port'] +
    ks_service_endpoint['path']

  swift_store_user =
    "#{glance['service_tenant_name']}:#{glance['service_user']}"

  swift_store_key = settings["service_pass"]
  swift_store_auth_version = 2
else
  swift_store_auth_address = settings["api"]["swift_store_auth_address"]
  swift_store_auth_version = settings["api"]["swift_store_auth_version"]
  swift_store_key  = settings["api"]["swift_store_key"]
  swift_store_user = settings["api"]["swift_store_user"]
end


template "/etc/glance/glance-cache.conf" do
  source "glance-cache.conf.erb"
  owner "glance"
  group "glance"
  mode "0600"
  variables(
    "use_debug" => glance["use_debug"],
    "image_cache_max_size" => glance["api"]["cache"]["image_cache_max_size"],
    "registry_ip_address" => registry_endpoint["host"],
    "registry_port" => registry_endpoint["port"],
    "default_store" => glance["api"]["default_store"],
    "swift_store_key" => swift_store_key,
    "swift_store_user" => swift_store_user,
    "swift_store_auth_address" => swift_store_auth_address,
    "swift_store_auth_version" => swift_store_auth_version,
    "swift_large_object_size" => glance["api"]["swift"]["store_large_object_size"],
    "swift_large_object_chunk_size" => glance["api"]["swift"]["store_large_object_chunk_size"],
    "swift_store_container" => glance["api"]["swift"]["store_container"],
    "swift_enable_snet" => glance["api"]["swift"]["enable_snet"]
  )
end


template "/etc/glance/glance-scrubber.conf" do
  source "glance-scrubber.conf.erb"
  owner "glance"
  group "glance"
  mode "0600"
  variables(
    "use_debug" => glance["use_debug"],
    "registry_bind_address" => registry_bind["host"],
    "registry_port" => registry_bind["port"]
  )
end


template "/etc/glance/glance-registry.conf" do
  source "glance-registry.conf.erb"
  owner "glance"
  group "glance"
  mode "0600"
  variables(
    "use_debug" => glance["use_debug"],
    "registry_bind_address" => registry_bind["host"],
    "registry_port" => registry_bind["port"],
    "db_ip_address" => mysql_info["host"],
    "db_user" => node["glance"]["db"]["username"],
    "db_password" => settings["db"]["password"],
    "db_name" => node["glance"]["db"]["name"],
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "keystone_service_protocol" => ks_service_endpoint["scheme"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "service_tenant_name" => node["glance"]["service_tenant_name"],
    "service_user" => node["glance"]["service_user"],
    "service_pass" => settings["service_pass"],
    "glance_flavor" => glance_flavor
  )
  if registry_bind["scheme"] == "https"
    notifies :restart, "service[apache2]", :immediately
  end
end

cookbook_file "/etc/glance/glance-registry-paste.ini" do
  source "glance-registry-paste.ini"
  owner "glance"
  group "glance"
  mode "0600"
  if registry_bind["scheme"] == "https"
    notifies :restart, "service[apache2]", :immediately
  end
end

# Set the notifications topic
if glance["api"]["default_store"] == "file" and get_role_count('single-controller', true) == 0
  glance_notifications = "glance_notifications"
else
  glance_notifications = glance["api"]["notification_topic"]
end

template "/etc/glance/glance-api.conf" do
  source "glance-api.conf.erb"
  owner "glance"
  group "glance"
  mode "0600"
  variables(

    "use_debug" => glance["use_debug"],

    "api_bind_address" => api_bind["host"],
    "api_bind_port" => api_bind["port"],
    "glance_workers" => glance["api"]["workers"],

    "registry_ip_address" => registry_endpoint["host"],
    "registry_port" => registry_endpoint["port"],
    "registry_scheme" => registry_endpoint["scheme"],

    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "rabbit_ha_queues" => rabbit_settings["cluster"] ? "True" : "False",

    "default_store" => glance["api"]["default_store"],
    "notifier_strategy" => glance["api"]["notifier_strategy"],
    "notification_topic" => glance_notifications,
    "glance_flavor" => glance_flavor,

    "swift_store_key" => swift_store_key,
    "swift_store_user" => swift_store_user,
    "swift_store_auth_address" => swift_store_auth_address,
    "swift_store_auth_version" => swift_store_auth_version,
    "swift_large_object_size" => glance["api"]["swift"]["store_large_object_size"],
    "swift_large_object_chunk_size" => glance["api"]["swift"]["store_large_object_chunk_size"],
    "swift_store_container" => glance["api"]["swift"]["store_container"],
    "swift_enable_snet" => glance["api"]["swift"]["enable_snet"],
    "swift_store_region" => glance["api"]["swift"]["store_region"],

    "rbd_store_ceph_conf" => glance["api"]["rbd"]["rbd_store_ceph_conf"],
    "rbd_store_user" => glance["api"]["rbd"]["rbd_store_user"],
    "rbd_store_pool" => glance["api"]["rbd"]["rbd_store_pool"],
    "rbd_store_chunk_size" => glance["api"]["rbd"]["rbd_store_chunk_size"],
    "show_image_direct_url" => glance["api"]["show_image_direct_url"],

    "db_ip_address" => mysql_info["host"],
    "db_user" => settings["db"]["username"],
    "db_password" => settings["db"]["password"],
    "db_name" => settings["db"]["name"],

    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "keystone_service_protocol" => ks_service_endpoint["scheme"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_admin_token" => keystone["admin_token"],

    "service_tenant_name" => settings["service_tenant_name"],
    "service_user" => settings["service_user"],
    "service_pass" => settings["service_pass"]
  )
  if api_bind["scheme"] == "https"
    notifies :restart, "service[apache2]", :immediately
  end
end

cookbook_file "/etc/glance/glance-api-paste.ini" do
  source "glance-api-paste.ini"
  owner "glance"
  group "glance"
  mode "0600"
  if api_bind["scheme"] == "https"
    notifies :restart, "service[apache2]", :immediately
  end
end
