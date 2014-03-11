action :create do
  monitor_name = new_resource.monitor_name
  log "openstack-logging/rsyslog_filemonitor: Creating file monitor for #{monitor_name}"

  t = template "/etc/rsyslog.d/10-#{monitor_name}.conf" do
    source "file-monitor-generic.conf.erb"
    owner "root"
    group "root"
    mode "0600"
    variables(
      "monitor_logfile" => node['openstack-logging']['settings'][monitor_name]['monitor_logfile'],
      "injection_tag" => node['openstack-logging']['settings'][monitor_name]['injection_tag'],
      "monitor_state_file" => node['openstack-logging']['settings'][monitor_name]['monitor_state_file'],
      "injection_severity" => node['openstack-logging']['settings'][monitor_name]['injection_severity'],
      "injection_facility" => node['openstack-logging']['settings'][monitor_name]['injection_facility']
    )
    action :create
    notifies :restart, "service[rsyslog]", :delayed
  end
  new_resource.updated_by_last_action(t.updated_by_last_action?)
end

