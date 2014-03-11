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

    it "installs perl libraries" do
      if node.platform_family?("debian")
        packages = %w(libhtml-parser-perl liburi-perl librrds-perl libjson-perl)
      elsif node.platform_family?("rhel")
        packages = %w{perl-HTML-Parser perl-URI rrdtool-perl perl-JSON}
      end

      packages.each do |name|
        package(name).must_be_installed
      end
    end

    it "should create a collectd site config" do
      file("#{node['apache']['dir']}/sites-available/collectd_web.conf").must_exist
    end

    it "should enable collectd site config" do
      file("#{node['apache']['dir']}/sites-enabled/collectd_web.conf").must_exist
    end

  end
end
