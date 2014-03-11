#
# Cookbook Name:: collectd_test
# Recipe:: server
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

describe_recipe "collectd_test::server" do
  include CollectdTestHelpers

  describe "collectd" do

    it "should create a collectd network plugin" do
      config = file("/etc/collectd/plugins/network.conf")

      config.must_exist
      config.must_include 'Listen "0.0.0.0"'
      config.must_include "Server \"#{node['collectd']['remote']['ip']}\""
      config.must_include 'Forward "True"'
    end

    it "should create a collectd syslog plugin" do
      config = file("/etc/collectd/plugins/syslog.conf")

      config.must_exist
      config.must_include 'LogLevel "Info"'
    end

    it "should create a collectd load plugin" do
      file("/etc/collectd/plugins/load.conf").must_exist
    end

    %w{cpu df disk interface memory swap}.each do |plugin|
      it "should create a collectd-plugin plugin for #{plugin}" do
        file("/etc/collectd/plugins/#{plugin}.conf").must_exist
      end
    end
  end
end
