name              "openstack-ha"
maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Configures vrrp IPs and virtual_servers for openstack services"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           IO.read(File.join(File.dirname(__FILE__), "VERSION"))

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ keepalived nova osops-utils }.each do |dep|
  depends dep
end

depends "haproxy",  ">= 1.0.6"
