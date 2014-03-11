#
# Cookbook Name:: ceilometer
#
# Copyright 2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default["ceilometer"]["db"]["name"] = "ceilometer"
default["ceilometer"]["db"]["username"] = "ceilometer"

# Set the notification Driver
# Options are no_op, rpc, log
default["ceilometer"]["notification"]["driver"] = "no_op"
default["ceilometer"]["notification"]["topics"] = "notifications"

default["ceilometer"]["service_tenant_name"] = "service"
default["ceilometer"]["service_user"] = "ceilometer"
default["ceilometer"]["service_role"] = "admin"

default["ceilometer"]["services"]["api"]["scheme"] = "http"
default["ceilometer"]["services"]["api"]["network"] = "public"
default["ceilometer"]["services"]["api"]["port"] =  8777
default["ceilometer"]["services"]["api"]["path"] = ""
default["ceilometer"]["services"]["api"]["cert_file"] = "ceilometer.pem"
default["ceilometer"]["services"]["api"]["key_file"] = "ceilometer.key"
default["ceilometer"]["services"]["api"]["wsgi_file"] = "ceilometer-api"

default["ceilometer"]["services"]["internal-api"]["scheme"] = "http"
default["ceilometer"]["services"]["internal-api"]["network"] = "management"
default["ceilometer"]["services"]["internal-api"]["port"] =  8777
default["ceilometer"]["services"]["internal-api"]["path"] = ""

default["ceilometer"]["services"]["admin-api"]["scheme"] = "http"
default["ceilometer"]["services"]["admin-api"]["network"] = "management"
default["ceilometer"]["services"]["admin-api"]["port"] =  8777
default["ceilometer"]["services"]["admin-api"]["path"] = ""

default["ceilometer"]["services"]["central"]["scheme"] = "tcp"
default["ceilometer"]["services"]["central"]["network"] = "management"
default["ceilometer"]["services"]["central"]["port"] =  8777

# should there be syslog settings here?
default["ceilometer"]["syslog"]["use"] = true
default["ceilometer"]["syslog"]["facility"] = "LOG_LOCAL3"

default["ceilometer"]["logging"]["debug"] = "false"
default["ceilometer"]["logging"]["verbose"] = "true"

# metering secret should be secret and unguessable, to prevent
# spoofing metrics
# default["ceilometer"]["metering_secret"] = "ceilometer"

procmatch_base = '^((/usr/bin/)?python\d? )?(/usr/bin/)?'

case platform_family
when "rhel"
  default["ceilometer"]["platform"] = {
    "supporting_packages" => ["openstack-ceilometer-common",
      "MySQL-python", "python-ceilometerclient"],
    "central_agent_package_list" => ["openstack-ceilometer-central"],
    "central_agent_service" => "openstack-ceilometer-central",
    "central_agent_procmatch" => procmatch_base + 'ceilometer-agent-central\b',
    "collector_package_list" => ["openstack-ceilometer-collector"],
    "collector_service" => "openstack-ceilometer-collector",
    "collector_procmatch" => procmatch_base + 'ceilometer-collector\b',
    "api_package_list" => ["openstack-ceilometer-api"],
    "api_service" => "openstack-ceilometer-api",
    "api_procmatch" => procmatch_base + 'ceilometer-api\b',
    "compute_package_list" => ["openstack-ceilometer-compute"],
    "compute_service" => "openstack-ceilometer-compute",
    "compute_procmatch" => procmatch_base + 'ceilometer-agent-compute\b',
    "service_bin" => "/sbin/service",
    "package_options" => ""
  }
  default["ceilometer"]["ssl"]["dir"] = "/etc/pki/tls"
when "debian"
  default["ceilometer"]["platform"] = {
    "supporting_packages" => ["ceilometer-common", "python-mysqldb",
      "python-ceilometerclient"],
    "central_agent_package_list" => ["ceilometer-agent-central"],
    "central_agent_service" => "ceilometer-agent-central",
    "central_agent_procmatch" => procmatch_base + 'ceilometer-agent-central\b',
    "collector_package_list" => ["ceilometer-collector"],
    "collector_service" => "ceilometer-collector",
    "collector_procmatch" => procmatch_base + 'ceilometer-collector\b',
    "api_package_list" => ["ceilometer-api"],
    "api_service" => "ceilometer-api",
    "api_procmatch" => procmatch_base + 'ceilometer-api\b',
    "compute_package_list" => ["ceilometer-agent-compute"],
    "compute_service" => "ceilometer-agent-compute",
    "compute_procmatch" => procmatch_base + 'ceilometer-agent-compute\b',
    "service_bin" => "/usr/sbin/service",
    "package_options" => "-o Dpkg::Options:='--force-confold'"\
      " -o Dpkg::Options:='--force-confdef'"
  }
  default["ceilometer"]["ssl"]["dir"] = "/etc/ssl"
end
