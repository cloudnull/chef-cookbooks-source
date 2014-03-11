Support
=======

Issues have been disabled for this repository.
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef
-cookbooks/issues)

Please title the issue as follows:

[heat]: \<short description of problem\>

In the issue description, please include a longer description of the issue, alon
g with any relevant log/command/error output.
If logfiles are extremely long, please place the relevant portion into the issue
description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.


Description
===========

Installs the OpenStack Heat (Orchestration) services from packages


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
* mysql
* openssl
* osops-utils
* keepalived


Resources/Providers
===================

None


Recipes
=======

**heat-setup**
- Sets up database, config files and keystone config
- Handles keystone registration and database creation

**heat-engine**
- Sets up the Heat Engine

**heat-common**
- Installs common packages and sets up config file

**heat-api**
- Installs the heat-api server

**heat-api-cloudwatch**
- Installs the heat-api-cloudwatch server

**heat-api-cfn**
- Installs the heat-api-cfn server


Attributes
==========

**Database**
* `heat["db"]["name"]` = "heat"
* `heat["db"]["username"]` = "heat"


**Service Information**
* `heat["service_tenant_name"]` = "service"
* `heat["service_user"]` = "heat"
* `heat["service_role"]` = "admin"
* `heat["auth_encryption_key"]` = "AnyStringWillDoJustFine"


**Logging Options**
* `heat["syslog"]["use"]` = false
* `heat["syslog"]["facility"]` = "LOG_LOCAL3"
* `heat["logging"]["debug"]` = "false"
* `heat["logging"]["verbose"]` = "true"


**Policy**
* `heat["policy_file"]` = "policy.json"
* `heat["policy_default_rule"]` = "default"


**Heartbeat**
* `heat["heartbeat"]["freq"]` = 300
* `heat["heartbeat"]["ttl"]` = 600


**Default SQL Stuffs**
* `heat["sql"]["backend"]` = "sqlalchemy"
* `heat["sql"]["max_retries"]` = 10
* `heat["sql"]["retry_interval"]` = 10


**Salve Database Stuffs**
* `heat["sql"]["slave"]["enabled"]` = false
* `heat["sql"]["slave"]["salve_user"]` = nil
* `heat["sql"]["slave"]["salve_password"]` = nil
* `heat["sql"]["slave"]["salve_host"]` = nil
* `heat["sql"]["slave"]["salve_db"]` = "mysql"


**Max Template Size**
* `heat["template_size"]` =  20480


**Heat Engine**
* `heat["services"]["engine"]["name"]` = "heat"


**General SSL**
* `heat["ssl"]["enabled"]` = false
* `heat["ssl"]["ca_file"]` = nil
* `heat["ssl"]["cert_file"]` = "heat.pem"
* `heat["ssl"]["key_file"]` = "heat.key"
* `heat["ssl"]["dir"]` = "/etc/heat/certs"


**Cloud Watch API**
* `heat["services"]["cloudwatch_api"]["enabled"]` = true
* `heat["services"]["cloudwatch_api"]["scheme"]` = "http"
* `heat["services"]["cloudwatch_api"]["network"]` = "public"
* `heat["services"]["cloudwatch_api"]["port"]` = 8003
* `heat["services"]["cloudwatch_api"]["path"]` = ""
* `heat["services"]["cloudwatch_api"]["backlog"]` = 4096
* `heat["services"]["cloudwatch_api"]["cert"]` = "heat.pem"
* `heat["services"]["cloudwatch_api"]["key"]` = "heat.key"
* `heat["services"]["cloudwatch_api"]["workers"]` = 10


**Cloud Formation API**
* `heat["services"]["cfn_api"]["enabled"]` = true
* `heat["services"]["cfn_api"]["scheme"]` = "http"
* `heat["services"]["cfn_api"]["network"]` = "public"
* `heat["services"]["cfn_api"]["port"]` = 8000
* `heat["services"]["cfn_api"]["path"]` = "/v1/$(tenant_id)s"
* `heat["services"]["cfn_api"]["backlog"]` = 4096
* `heat["services"]["cfn_api"]["cert"]` = "heat.pem"
* `heat["services"]["cfn_api"]["key"]` = "heat.key"
* `heat["services"]["cfn_api"]["workers"]` = 10

*Internal API*
* `heat["services"]["cfn_internal_api"]["scheme"]` = "http"
* `heat["services"]["cfn_internal_api"]["network"]` = "management"
* `heat["services"]["cfn_internal_api"]["port"]` = 8000
* `heat["services"]["cfn_internal_api"]["path"]` = "/v1/$(tenant_id)s"

*Admin API*
* `heat["services"]["cfn_admin_api"]["scheme"]` = "http"
* `heat["services"]["cfn_admin_api"]["network"]` = "management"
* `heat["services"]["cfn_admin_api"]["port"]` = 8000
* `heat["services"]["cfn_admin_api"]["path"]` = "/v1/$(tenant_id)s"


**Heat API**
* `heat["services"]["base_api"]["enabled"]` = true
* `heat["services"]["base_api"]["scheme"]` = "http"
* `heat["services"]["base_api"]["network"]` = "public"
* `heat["services"]["base_api"]["port"]` = 8004
* `heat["services"]["base_api"]["path"]` = "/v1/$(tenant_id)s"
* `heat["services"]["base_api"]["backlog"]` = 4096
* `heat["services"]["base_api"]["cert"]` = "heat.pem"
* `heat["services"]["base_api"]["key"]` = "heat.key"
* `heat["services"]["base_api"]["workers"]` = 10

*Internal API*
* `heat["services"]["base_internal_api"]["scheme"]` = "http"
* `heat["services"]["base_internal_api"]["network"]` = "management"
* `heat["services"]["base_internal_api"]["port"]` = 8004
* `heat["services"]["base_internal_api"]["path"]` = "/v1/$(tenant_id)s"

*Admin API*
* `heat["services"]["base_admin_api"]["scheme"]` = "http"
* `heat["services"]["base_admin_api"]["network"]` = "management"
* `heat["services"]["base_admin_api"]["port"]` = 8004
* `heat["services"]["base_admin_api"]["path"]` = "/v1/$(tenant_id)s"


Templates
=========

* `heat.conf.erb` - Heat configuration file template


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
Author:: Kevin Carter (<kevin.carter@rackspace.com>)  
Author:: Zack Feldstein (<zack.feldstein@racksapce.com>)  


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
