Support
=======

Issues have been disabled for this repository.
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef
-cookbooks/issues)

Please title the issue as follows:

[ceilometer]: \<short description of problem\>

In the issue description, please include a longer description of the issue, alon
g with any relevant log/command/error output.
If logfiles are extremely long, please place the relevant portion into the issue
description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Installs the OpenStack Ceilometer service from packages

Requirements
============

Chef 11 or higher

Platform
--------

* CentOS >= 6.3
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* database
* keystone
* monitoring
* mysql
* openssl
* osops-utils
* keepalived

Resources/Providers
===================

None


Recipes
=======

ceilometer-common
-------
- Installs common packages and sets up config file

ceilometer-setup
-----
- Sets up database, config files and keystone config
- Handles keystone registration and glance database creation

ceilometer-api
------
- Installs the ceilometer-api server

ceilometer-compute
--------
- Installs the ceilometer-compute agent on a nova-compute node

ceilometer-central-agent
--------------
- installs the ceilometer central (polling) agent

ceilometer-collector
----------
- installs the collector services (consumes messages from the message bus)


Attributes
==========

* `ceilometer["db"]["name"]` = "ceilometer"
* `ceilometer["db"]["username"]` = "ceilometer"
* `ceilometer["service_tenant_name"]` = "service"
* `ceilometer["service_user"]` = "ceilometer"
* `ceilometer["service_role"]` = "admin"
* `ceilometer["services"]["api"]["scheme"]` = "http"
* `ceilometer["services"]["api"]["network"]` = osops-network on which to run the api
* `ceilometer["services"]["api"]["port"]` = 8777
* `ceilometer["services"]["api"]["path"]` = "/"
* `ceilometer["syslog"]["use"]` = true
* `ceilometer["syslog"]["facility"]` = "LOG_LOCAL3"
* `ceilometer["logging"]["debug"]` = "false"
* `ceilometer["logging"]["verbose"]` = "false"

Templates
=========

* `ceilometer.conf.erb` - rsyslog config file for glance

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)  

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
