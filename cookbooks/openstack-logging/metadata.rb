name             "openstack-logging"
maintainer       "Rackspace US, Inc."
license          "Apache 2.0"
description      "Installs/Configures openstack-logging"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), "VERSION"))


%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ rsyslog }.each do |dep|
	depends dep
end

depends "rsyslog", ">= 1.6.1"
