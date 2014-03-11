name             "openstack-ceph"
maintainer       "Rackspace US, Inc."
license          "Apache 2.0"
description      "Wrapper around installing Ceph with Keystone Integration"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), "VERSION"))


%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ keystone osops-utils ceph }.each do |dep|
 depends dep
end
