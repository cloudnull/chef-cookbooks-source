Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[openstack-ha]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Installs haproxy using the haproxy cookbook, and adds floating IPs per load balanced service using the keepalived cookbook.


Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* CentOS >= 6.3
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* haproxy
* keepalived
* nova
* osops-utils

Recipes
=======

default
----
- Iterates through the list of services provided in the attributes/environment
- Adds a haproxy config file per service, and uses search to discover the relevant back ends for that service.
- Uses provided vip from the environment to add a floating IP using keepalived (eg node['vips']['glance']['api'] would contain the required VIP to be used for load balancing glance api requests


Attributes
==========

* `default['ha']['available_services']` - single attribute that contains a list of hashes, one hash per service.  
* Each service hash contains the following:  
 * _`role` - name of the role to be searched for when building the back ends for the haproxy config_
 * _`namespace` - name of the attribute namespace to be searched for (see for eg nova cookbook attributes)_
 * _`service` - name of the service to be searched for in the relevant service hash (see for eg nova cookbook attributes)_
 * _`service_type` - the type of service that keystone expects (identity, compute, ec2, volume, image, object-store)_


License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk)  

Copyright 2012-2013, Rackspace US, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
