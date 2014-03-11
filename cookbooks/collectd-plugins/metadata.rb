name             "collectd-plugins"
maintainer       "Rackspace US, Inc"
maintainer_email "rcb-deploy@lists.rackspace.com"
license          "Apache 2.0"
description      "Configure collectd plugins"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION'))

%w{ amazon centos debian fedora oracle redhat scientific ubuntu }.each do |os|
  supports os
end

%w{ collectd }.each do |dep|
  depends dep
end

recipe "collectd-plugins::default",
  "Installs and configures all collectd-plugin recipes"

recipe "collectd-plugins::cpu",
  "Installs and configures collectd cpu plugin"

recipe "collectd-plugins::df",
  "Installs and configures collectd df plugin"

recipe "collectd-plugins::disk",
  "Installs and configures collectd disk plugin"

recipe "collectd-plugins::interface",
  "Installs and configures collectd interface plugin"

recipe "collectd-plugins::memory",
  "Installs and configures collectd memory plugin"

recipe "collectd-plugins::rabbitmq",
  "Installs and configures collectd rabbitmq plugin"

recipe "collectd-plugins::redis",
  "Installs and configures collectd redis plugin and script"

recipe "collectd-plugins::rrdtool",
  "Installs and configures collectd rrdtool plugin and script"

recipe "collectd-plugins::swap",
  "Installs and configures collectd swap plugin"

recipe "collectd-plugins::syslog",
  "Installs and configures collectd syslogin plugin"
