#
# Cookbook Name:: collectd-plugins_test
# Recipe:: rabbitmq
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

require_relative "./support/helpers"

describe_recipe "collectd-plugins_test::rabbitmq" do
  include CollectdPluginsTestHelpers

  describe "collectd_plugin" do
    let(:plugin) { file("/etc/collectd/plugins/python.conf") }
    let(:script) { file(File.join(node[:collectd][:platform][:collectd_plugin_dir], "rabbitmq_info.py")) }

    it "should enable the python plugin/rabbit script" do
      plugin.must_exist
      plugin.must_include 'Import "rabbitmq_info"'
    end

    it "should create a collectd rabbitmq script plugin file" do
      script.must_exist
    end

  end
end
