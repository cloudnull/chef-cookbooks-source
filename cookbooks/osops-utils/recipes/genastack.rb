#
## Cookbook Name:: osops-utils
## Recipe:: genastack
##
## Copyright 2012-2013, Rackspace US, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

genastack = "git+https://github.com/cloudnull/genastack"

execute "install_genastack" do
  command "pip install #{genastack} && touch /etc/genastack_installed.lock"
  creates "/etc/genastack_installed.lock"
  action :run
end
