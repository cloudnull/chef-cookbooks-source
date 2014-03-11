Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[collectd-plugins]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

# Requirements #

Chef 11.0 or higher required (for Chef environment use).

## Platforms ##

This cookbook is actively tested on the following platforms/versions:

* Ubuntu-12.04
* CentOS-6.3

While not actively tested, this cookbook should also work the following platforms:

* Debian/Mint derivitives
* Amazon/Oracle/Scientific/RHEL

## Cookbooks ##

The following cookbooks are dependencies:

* collectd

# DESCRIPTION #

Configure plugins for the [collectd](http://collectd.org/) monitoring daemon.

# USAGE #

A number of recipes for standard plugins are available:

* `collectd_plugins::rrdtool` - Output to RRD database files.
* `collectd_plugins::syslog` Log errors to syslog.
* `collectd_plugins::cpu` - CPU usage.
* `collectd_plugins::df` - Free space on disks.
* `collectd_plugins::disk` - Disk I/O operations.
* `collectd_plugins::interface` - Network I/O operations.
* `collectd_plugins::memory` - Memory usage.
* `collectd_plugins::swap` - Swap file usage.

It is recommended to always enable the first two (rrdtool and syslog), but the others are entirely optional. For convenience, the `collectd_plugins` default recipe will include all of these.

## Redis ##

A plugin to monitor [Redis](http://redis.io/) is included as `collectd_plugins::redis`. This recipe requires that you be using our [redis cookbook](https://github.com/AtariTech/cookbooks/tree/master/redis)
for your servers, but can be trivially modified to look for a different recipe or role name.

# LICENSE & AUTHOR #

Author:: Noah Kantrowitz (<noah@coderanger.net>)
Copyright:: 2010, Atari, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
