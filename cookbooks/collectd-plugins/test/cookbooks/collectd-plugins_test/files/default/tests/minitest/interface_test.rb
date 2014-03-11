#
# Cookbook Name:: collectd-plugins_test
# Recipe:: interface
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

describe_recipe "collectd-plugins_test::interface" do
  include CollectdPluginsTestHelpers

  describe "collectd_plugin" do
    let(:plugin) { file("/etc/collectd/plugins/interface.conf") }

    it "should create a collectd interface configuration file" do
      plugin.must_exist
    end

    it "should include the lo interface" do
      plugin.must_include 'Interface "lo"'
    end

    it "should include the ingore selected option" do
      plugin.must_include 'IgnoreSelected true'
    end

  end
end
