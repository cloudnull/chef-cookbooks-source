# should we queue messages when the syslog target is offline?
default["syslog"]["queue_offline_messages"] = true

# default logging defs.
default["openstack-logging"]["settings"] = {
  # glance logging defs
  "glance-api" => {
    "monitor_logfile" => "/var/log/glance/api.log",
    "injection_tag" => "glance-api_log:",
    "monitor_state_file" => "glance-api_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "glance-registry" => {
    "monitor_logfile" => "/var/log/glance/registry.log",
    "injection_tag" => "glance-registry_log:",
    "monitor_state_file" => "glance-registry_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "glance-scrubber" => {
    "monitor_logfile" => "/var/log/glance/scrubber.log",
    "injection_tag" => "glance-scrubber:",
    "monitor_state_file" => "glance-scrubber_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "glance-cache" => {
    "monitor_logfile" => "/var/log/glance/image-cache.log",
    "injection_tag" => "glance-cache:",
    "monitor_state_file" => "glance-cache_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  # keystone logging defs
  "keystone" => {
    "monitor_logfile" => "/var/log/keystone/keystone.log",
    "injection_tag" => "keystone_log:",
    "monitor_state_file" => "keystone_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  # nova logging defs
  "nova-api-ec2" => {
    "monitor_logfile" => "/var/log/nova/nova-api-ec2.log",
    "injection_tag" => "nova-api-ec2_log:",
    "monitor_state_file" => "nova-api-ec2_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-api-os-compute" => {
    "monitor_logfile" => "/var/log/nova/nova-api-os-compute.log",
    "injection_tag" => "nova-api-os-compute_log:",
    "monitor_state_file" => "nova-api-os-compute_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-compute" => {
    "monitor_logfile" => "/var/log/nova/nova-compute.log",
    "injection_tag" => "nova-compute_log:",
    "monitor_state_file" => "nova-compute_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-api-metadata" => {
    "monitor_logfile" => "/var/log/nova/nova-api-metadata.log",
    "injection_tag" => "nova-api-metadata_log:",
    "monitor_state_file" => "nova-api-metadata_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-cert" => {
    "monitor_logfile" => "/var/log/nova/nova-cert.log",
    "injection_tag" => "nova-cert_log:",
    "monitor_state_file" => "nova-cert_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-conductor" => {
    "monitor_logfile" => "/var/log/nova/nova-conductor.log",
    "injection_tag" => "nova-conductor_log:",
    "monitor_state_file" => "nova-conductor_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-consoleauth" => {
    "monitor_logfile" => "/var/log/nova/nova-consoleauth.log",
    "injection_tag" => "nova-consoleauth_log:",
    "monitor_state_file" => "nova-consoleauth_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-manage" => {
    "monitor_logfile" => "/var/log/nova/nova-manage.log",
    "injection_tag" => "nova-manage_log:",
    "monitor_state_file" => "nova-manage_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-scheduler" => {
    "monitor_logfile" => "/var/log/nova/nova-scheduler.log",
    "injection_tag" => "nova-scheduler_log:",
    "monitor_state_file" => "nova-scheduler_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "nova-network" => {
    "monitor_logfile" => "/var/log/nova/nova-network.log",
    "injection_tag" => "nova-network_log:",
    "monitor_state_file" => "nova-network_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  # cinder logging defs
  "cinder-api" => {
    "monitor_logfile" => "/var/log/cinder/cinder-api.log",
    "injection_tag" => "cinder-api_log:",
    "monitor_state_file" => "cinder-api_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "cinder-scheduler" => {
    "monitor_logfile" => "/var/log/cinder/cinder-scheduler.log",
    "injection_tag" => "cinder-scheduler_log:",
    "monitor_state_file" => "cinder-scheduler_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  },
  "cinder-volume" => {
    "monitor_logfile" => "/var/log/cinder/cinder-volume.log",
    "injection_tag" => "cinder-volume_log:",
    "monitor_state_file" => "cinder-volume_log",
    "injection_severity" => "info",
    "injection_facility" => "local6"
  }
}
