#
# Cookbook Name:: ceilometer
# Recipe:: ceilometer-fix-sqlalchemy
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

platform_options = node["ceilometer"]["platform"]

rhel_patches = [
  "/usr/lib/python2.6/site-packages/ceilometer/storage/impl_sqlalchemy.py",
  "/usr/lib/python2.6/site-packages/ceilometer/storage/sqlalchemy/models.py",
  "/usr/lib/python2.6/site-packages/ceilometer/utils.py",
  "/usr/lib/python2.6/site-packages/ceilometer/storage/sqlalchemy/migrate_repo/versions/020_add_metadata_tables.py"
]

deb_patches = [
  "/usr/lib/python2.7/dist-packages/ceilometer/storage/impl_sqlalchemy.py",
  "/usr/lib/python2.7/dist-packages/ceilometer/storage/sqlalchemy/models.py",
  "/usr/lib/python2.7/dist-packages/ceilometer/utils.py",
  "/usr/lib/python2.7/dist-packages/ceilometer/storage/sqlalchemy/migrate_repo/versions/020_add_metadata_tables.py"
]

versions = {
  "2013.2.1-1.el6" => rhel_patches,
  "2013.2.2-1.el6" => rhel_patches,
  "2013.2-1.el6" => rhel_patches,
  "2013.2-0ubuntu1~cloud0" => deb_patches,
  "2013.2.1-0ubuntu2~cloud0" => deb_patches,
  "2013.2.2-0ubuntu1~cloud0" => deb_patches
}

versions.each do |version, files|
  files.each do |file|
    name = ::File.basename(file)
    template "#{version} #{name}" do
      source "patches/#{name}.erb"
      path file
      owner "root"
      group "root"
      mode "0644"
      only_if {
        ::Chef::Recipe::Patch.check_package_version("python-ceilometer", version, node)
      }
      notifies :restart, "service[#{platform_options["api_service"]}]", :delayed
    end
    if name == "020_add_metadata_tables.py"
      execute "update ceilometer db (migration)" do
        user "ceilometer"
        group "ceilometer"
        command "ceilometer-dbsync"
        action :nothing
        subscribes :run, "template[#{version} #{name}]", :immediately
      end 
    end
  end
end
