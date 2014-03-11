# -*- mode: ruby -*-
# vi: set ft=ruby :
# encoding: utf-8

site :opscode

metadata

group :test do
  cookbook "apache2",          :git => "https://github.com/opscode-cookbooks/apache2.git"
  cookbook "apt",              :git => "https://github.com/opscode-cookbooks/apt.git"
  cookbook "collectd-plugins", :git => "https://github.com/rcbops-cookbooks/collectd-plugins.git", :branch => "grizzly"
  cookbook "yum",              :git => "https://github.com/opscode-cookbooks/yum.git"

  # use our local test cookbooks
  cookbook "collectd_test", :path => "./test/cookbooks/collectd_test"

  # use specific version until minitest file discovery is fixed
  cookbook "minitest-handler", "0.1.7"
end
