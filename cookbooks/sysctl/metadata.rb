maintainer       "Rackspace US, Inc."
name             "sysctl"
license          "Apache v2.0"
description      "Configures sysctl parameters"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION'))

%w{ debian ubuntu centos redhat }.each do |os|
  supports os
end
