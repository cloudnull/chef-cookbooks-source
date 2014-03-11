name             "collectd"
maintainer       "Rackspace US, Inc"
maintainer_email "rcb-deploy@lists.rackspace.com"
license          "Apache 2.0"
description      "Install and configure the collectd monitoring daemon"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION'))

%w{ amazon centos debian fedora oracle redhat scientific ubuntu }.each do |os|
  supports os
end

%w{ apache2 collectd-plugins yum }.each do |dep|
  depends dep
end

recipe "collectd::default",
  "Installs and configures collectd"

recipe "collectd::client",
  "Installs and configures collectd client"

recipe "collectd::server",
  "Installs and configures collectd server"

recipe "collectd::collectd_web",
  "Installs and configures collectd apache web interface"


attribute "collectd/types_db",
  :description => "The collectd types db location",
  :default => "/usr/share/collectd/types.db"

attribute "collectd/interval",
  :description => "The collectd collection interval",
  :default => "10"

attribute "collectd/read_threads",
  :description => "The number of read threads for collection",
  :default => "5"

attribute "collectd/is_proxy",
  :description => "Determin if collected will proxy",
  :default => "true"

attribute "collectd/remote/ip",
  :description => "The remote collectd collector",
  :default => "1.2.3.4"

attribute "collectd/timeout",
  :description => "The collectd collection timeout",
  :default => "30"

attribute "collectd/collectd_web/path",
  :description => "The collectd web interface source path",
  :default => "/srv/collectd_web"

attribute "collectd/collectd_web/hostname",
  :description => "The collectd web interface hostname",
  :default => "collectd"
