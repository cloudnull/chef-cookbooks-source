#
# Cookbook Name:: mysql-openstack
# Recipe:: server
#
# Copyright 2012-2013, Rackspace US, Inc.
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
# replication parts inspired by https://gist.github.com/1105416

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "osops-utils"
include_recipe "mysql::ruby"
require 'mysql'

platform_options = node["mysql"]["platform"]

# Lookup endpoint info, and properly set mysql attributes
mysql_network = node["mysql"]["services"]["db"]["network"]

# override default attributes in the upstream mysql cookbook
node.set["mysql"]["bind_address"] = bind_ip = get_ip_for_net(node['mysql']['services']['db']['network'])
node.set['mysql']['tunable']['innodb_thread_concurrency']       = "0"
node.set['mysql']['tunable']['innodb_commit_concurrency']       = "0"
node.set['mysql']['tunable']['innodb_read_io_threads']          = "4"
node.set['mysql']['tunable']['innodb_flush_log_at_trx_commit']  = "2"
node.set['mysql']['tunable']['log_bin'] = nil
node.set['mysql']['tunable']['skip-name-resolve'] = true


# search for first_master id (1).  If found, assume we are the second server
# and configure accordingly.  If not, assume we are the first

if node["mysql"]["myid"].nil?
  # then we have not yet been through setup - try and find first master
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
    first_master = search(:node, "chef_environment:#{node.chef_environment} AND mysql_myid:1")
  end

  if first_master.length == 0
    # we must be first master
    Chef::Log.info("*** I AM FIRST MYSQL MASTER - SETTING PASSWORDS ***")
    node.set["mysql"]["tunable"]["server_id"] = '1'
    node.set_unless["mysql"]["server_repl_password"] = secure_password
    node.set["mysql"]["auto-increment-offset"] = "1"

    # now we have set the necessary tunables, install the mysql server
    include_recipe "mysql::server"

    # wait for all the install_db stuff to finish before we enable binlogging
    execute "wait for mysql_install_db to finish" do
      command "sleep 10s"
    end

    cookbook_file "#{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf" do
      source "binlog.cnf"
      path "#{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf"
      action :create_if_missing
      mode "0644"
      notifies :restart, "service[mysql]", :immediately
    end

    # since we are first master, create the replication user
    mysql_connection_info = {:host => bind_ip , :username => 'root', :password => node['mysql']['server_root_password']}

    mysql_database_user 'repl' do
      connection mysql_connection_info
      password node["mysql"]["server_repl_password"]
      action :create
    end

    mysql_database_user 'repl' do
      connection mysql_connection_info
      privileges ['REPLICATION SLAVE']
      action :grant
      host '%'
    end

    # officially make us the first master
    node.set_unless["mysql"]["myid"] = "1"

  elsif first_master.length == 1
    # then we are second master
    Chef::Log.info("*** I AM SECOND MYSQL MASTER - GRABBING PASSWORD FROM FIRST MASTER ***")
    node.set_unless["mysql"]["server_repl_password"] = first_master[0]["mysql"]["server_repl_password"]
    node.set_unless["mysql"]["server_root_password"] = first_master[0]["mysql"]["server_root_password"]
    node.set["mysql"]["tunable"]["server_id"] = '2'

    node.set["mysql"]["auto-increment-offset"] = "2"

    #now we have set the necessary tunables, install the mysql server
    include_recipe "mysql::server"

    # wait for all the install_db stuff to finish before we enable binlogging
    execute "wait for mysql_install_db to finish" do
      command "sleep 10s"
    end

    cookbook_file "#{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf" do
      source "binlog.cnf"
      path "#{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf"
      action :create_if_missing
      mode "0644"
      notifies :restart, "service[mysql]", :immediately
    end

    first_master_ip = get_ip_for_net(mysql_network, first_master[0])
    # connect to master
    ruby_block "configure slave" do
      block do
        mysql_conn = Mysql.new(bind_ip, "root", node["mysql"]["server_root_password"])
        command = %Q{
        CHANGE MASTER TO
          MASTER_HOST="#{first_master_ip}",
          MASTER_USER="repl",
          MASTER_PASSWORD="#{node["mysql"]["server_repl_password"]}",
          MASTER_LOG_FILE="mysql-binlog.000001",
          MASTER_LOG_POS=0;
          }
          Chef::Log.info "Sending start replication command to mysql: "
          Chef::Log.info command

        mysql_conn.query("stop slave")
        mysql_conn.query(command)
        mysql_conn.query("start slave")

      end
    end

    # officially make us the second master
    node.set_unless["mysql"]["myid"] = 2

  elsif first_master.length > 1
    # error out here as something is wrong
    Chef::Application.fatal! "I discovered multiple mysql first masters - there can be only one!"

  end
elsif node["mysql"]["tunable"]["server_id"].nil?
  node.set["mysql"]["tunable"]["server_id"] = node["mysql"]["myid"]
end

if node['mysql']['myid'] == '1'
  # we were the first master, but have we connected back to the second master yet?
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
    second_master = search(:node, "chef_environment:#{node.chef_environment} AND mysql_myid:2")
  end

  if second_master.length == 1
    Chef::Log.info("I am the first mysql master, and I have found the second mysql master")

    second_master_ip = get_ip_for_net(mysql_network, second_master[0])

    # attempt to connect to second master as a slave
    ruby_block "configure slave check" do
      block do
        mysql_conn = Mysql.new(bind_ip, "root", node["mysql"]["server_root_password"])
        slave_sql_running = ""
        slave_repl_user = ""
        mysql_conn.query("show slave status") {|r|
          r.each_hash {|h|
            slave_sql_running = h['Slave_SQL_Running']
            slave_repl_user = h['Master_User']
          }
        }
        if slave_sql_running != "Yes" and slave_repl_user != "repl"
          command = %Q{
          CHANGE MASTER TO
            MASTER_HOST="#{second_master_ip}",
            MASTER_USER="repl",
            MASTER_PASSWORD="#{node["mysql"]["server_repl_password"]}",
            MASTER_LOG_FILE="mysql-binlog.000001",
            MASTER_LOG_POS=0;
            }
          Chef::Log.info("Attempting to connect back to second master as a slave")
          Chef::Log.info "Sending start replication command to mysql: "
          Chef::Log.info command

          mysql_conn.query("stop slave")
          mysql_conn.query(command)
          mysql_conn.query("start slave")
        else
          Chef::Log.info("Skipping slave configuration.  Either already configured or slave is in error")
        end
      end
    end
  else
  Chef::Log.info("I am currently the only mysql master")
  end
end

# to ensure that we pick up attr/config changes and are able to do upgrades etc after a deployment,
# we need to include the mysql::server recipe again here, since all of the above blocks are skipped
# after the initial deployment.
include_recipe "mysql::server"

# need to ensure this is dropped in here, in case you are coming from an older
# cookbook version where binlogging was enabled in the main config file
cookbook_file "ensure #{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf" do
  source "binlog.cnf"
  path "#{node['mysql']['server']['directories']['confd_dir']}/binlog.cnf"
  action :create_if_missing
  mode "0644"
  notifies :restart, "service[mysql]", :immediately
end

# Cleanup the craptastic mysql default users
ruby_block "cleanup insecure default mysql users" do
  block do
    mysql_conn = Mysql.new(bind_ip, "root", node["mysql"]["server_root_password"])
    Chef::Log.info("Removing insecure default mysql users")
    mysql_conn.query("DELETE FROM mysql.user WHERE User=''")
    mysql_conn.query("DELETE FROM mysql.user WHERE Password=''")
    mysql_conn.query("DROP DATABASE IF EXISTS test")
    mysql_conn.query("FLUSH privileges")
  end
  only_if do
    mysql_conn = Mysql.new(bind_ip, "root", node["mysql"]["server_root_password"])
    exists = mysql_conn.query("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'test'")
    exists.num_rows > 0
  end
end

template "/root/.my.cnf" do
  source "dotmycnf.erb"
  owner "root"
  group "root"
  mode "0600"
  not_if "test -f /root/.my.cnf"
  variables :rootpasswd => node['mysql']['server_root_password']
end

# is there a vip for us? If so, set up keepalived vrrp
if rcb_safe_deref(node, "vips.mysql-db")
  include_recipe "keepalived"
  vip = node["vips"]["mysql-db"]
  vrrp_name = "vi_#{vip.gsub(/\./, '_')}"
  if not vrrp_network = rcb_safe_deref(node, "vips_config_#{vip}_network","_")
    Chef::Application.fatal! "You have not configured a Network for the VIP.  Please set node[\"vips\"][\"config\"][\"#{vip}\"][\"network\"]"
  end
  vrrp_interface = get_if_for_net(vrrp_network, node)
  src_ip = get_ip_for_net(vrrp_network, node)

  if router_id = rcb_safe_deref(node, "vips_config_#{vip}_vrid","_")
    Chef::Log.debug "using #{router_id} for vips.config.#{vip}.vrid"
  elsif router_id = rcb_safe_deref(node, "mysql.ha.vrid")
    Chef::Application.fatal! "node[\"mysql\"][\"ha\"][\"vrid\"] is deprecated.  Please set node[\"vips\"][\"config\"][\"#{vip}\"][\"vrid\"] instead"
  else
    Chef::Application.fatal! "You have not configured a VRID for the VIP.  Please set node[\"vips\"][\"config\"][\"#{vip}\"][\"vrid\"]"
  end

  keepalived_chkscript "mysql" do
    script "#{platform_options["service_bin"]} #{platform_options["mysql_service"]} status"
    interval 5
    action :create
  end

  keepalived_vrrp vrrp_name do
    interface vrrp_interface
    virtual_router_id router_id  # Needs to be a integer between 1..255
    track_script "mysql"
    notify_master "/etc/keepalived/notify.sh add #{vrrp_interface} #{vip} #{src_ip}"
    notify_backup "/etc/keepalived/notify.sh del #{vrrp_interface} #{vip} #{src_ip}"
    notify_fault "/etc/keepalived/notify.sh del #{vrrp_interface} #{vip} #{src_ip}"
    notify_stop "/etc/keepalived/notify.sh del #{vrrp_interface} #{vip} #{src_ip}"
    notifies :restart, "service[keepalived]", :immediately
  end
end
