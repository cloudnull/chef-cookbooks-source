#
# Cookbook Name:: collectd
# Attributes:: default
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

default['monitoring']['configs'] = []

default['collectd']['types_db'] = "/usr/share/collectd/types.db"        # node_attribute
default['collectd']['interval'] = 10                                    # node_attribute (inherited from cluster?)
default['collectd']['read_threads'] = 5                                 # node_attribute (inherited from cluster?)
default['collectd']['is_proxy'] = true                                  # node_attribute
default['collectd']['remote']['ip'] = '1.2.3.4'                         # node_attribute (inherited from cluster?)
default['collectd']['timeout'] = 30  # 5 minutes, with default interval # node_attribute (inherited from cluster?)

default['collectd']['collectd_web']['path'] = "/srv/collectd_web"       # node_attribute
default['collectd']['collectd_web']['hostname'] = "collectd"            # node_attribute

if platform_family?("rhel")
  default["collectd"]["platform"] = {
    "collectd_packages" => ["collectd"],                                # node_attribute
    "collectd_base_dir" => "/var/lib/collectd",                         # node_attribute
    "collectd_plugin_dir" => "/usr/lib64/collectd",                     # node_attribute
    "collectd_config_file" => "/etc/collectd.conf",                     # node_attribute
    "package_options" => ""                                           # node_attribute
  }
elsif platform_family?("debian")
  default["collectd"]["platform"] = {
    "collectd_packages" => ["collectd-core"],                           # node_attribute
    "collectd_base_dir" => "/var/lib/collectd",                         # node_attribute
    "collectd_plugin_dir" => "/usr/lib/collectd",                       # node_attribute
    "collectd_config_file" => "/etc/collectd/collectd.conf",            # node_attribute
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'" # node_attribute
  }
end
