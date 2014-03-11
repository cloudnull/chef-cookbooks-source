#
# Cookbook Name:: collectd_test
# Recipe:: default
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

describe_recipe "collectd_test::default" do
  include CollectdTestHelpers

  describe "collectd" do

    it "should install specified packages" do
      node["collectd"]["platform"]["collectd_packages"].each do |pkg|
        package(pkg).must_be_installed
      end
    end

    it "should start collectd daemon" do
      service("collectd").must_be_enabled
      service("collectd").must_be_running
    end

    it "should create a collectd configuration file" do
      file(node['collectd']['platform']['collectd_config_file']).must_exist
    end

  end
end
