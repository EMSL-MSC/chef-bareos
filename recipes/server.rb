# encoding: UTF-8
#
# Copyright (C) 2016 Leonard TAVAE
#
# Cookbook Name:: chef-bareos
# Recipe:: server
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# By default here including both the repo and client recipes
# This is just so Bareos has SOMETHING to backup (i.e. Catalog)
include_recipe 'chef-bareos::client'

# Include the OpenSSL library for generating random passwords
::Chef::Recipe.send(:include, OpenSSLCookbook::RandomPassword)
node.normal_unless['bareos']['dir_password'] = random_password(length: 30, mode: :base64)
node.normal_unless['bareos']['mon_password'] = random_password(length: 30, mode: :base64)

node.save # FC075: Cookbook uses node.save to save partial node data to the chef-server mid-run

# Install BAREOS Server Packages
package %w(bareos-director bareos-tools)

# Create the custom config directory and placeholder file
directory '/etc/bareos/bareos-dir.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/etc/bareos/bareos-dir.d/dir_helper.conf' do
  source 'dir_helper.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0644'
  variables(
    dir_help: node['bareos']['director']['conf']['help']
  )
  sensitive node['bareos']['director']['sensitive_configs']
  action :create
end

# Director Config
template '/etc/bareos/bareos-dir.conf' do
  source 'bareos-dir.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    db_driver: node['bareos']['database']['dbdriver'],
    db_name: node['bareos']['database']['dbname'],
    db_user: node['bareos']['database']['dbuser'],
    db_password: node['bareos']['database']['dbpassword'],
    db_address: node['bareos']['database']['dbaddress'],
    dir_name: node['bareos']['director']['name']
  )
  sensitive node['bareos']['director']['sensitive_configs']
  only_if { ::File.exist?('/etc/bareos/bareos-dir.d/dir_helper.conf') }
end

# Create clients config based on sets of hashes, see attributes file for default example(s)
client_search_query = node['bareos']['clients']['client_search_query']
client_search_result = search(:node, client_search_query)
if client_search_result.empty?
  client_search_result = search(:node, "fqdn:#{node['fqdn']}")
end

template '/etc/bareos/bareos-dir.d/clients.conf' do
  source 'clients.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    unmanaged_clients: node['bareos']['clients']['unmanaged'],
    bareos_clients: client_search_result,
    client_conf: node['bareos']['clients']['conf']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end

# Create other various configs based on sets of hashes
template '/etc/bareos/bareos-dir.d/jobs.conf' do
  source 'jobs.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    jobs: node['bareos']['clients']['jobs']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end
template '/etc/bareos/bareos-dir.d/job_definitions.conf' do
  source 'job_definitions.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    job_definitions: node['bareos']['clients']['job_definitions']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end
template '/etc/bareos/bareos-dir.d/filesets.conf' do
  source 'filesets.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    fileset_config: node['bareos']['clients']['filesets']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end
template '/etc/bareos/bareos-dir.d/pools.conf' do
  source 'pools.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    client_pools: node['bareos']['clients']['pools']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end
template '/etc/bareos/bareos-dir.d/schedules.conf' do
  source 'schedules.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    client_schedules: node['bareos']['clients']['schedules']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end
template '/etc/bareos/bareos-dir.d/storages.conf' do
  source 'storages.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0640'
  variables(
    client_storages: node['bareos']['clients']['storages']
  )
  sensitive node['bareos']['director']['sensitive_configs']
end

# Allow a reload of the director daemon configs if called with tests up front
execute 'reload-dir' do
  command 'su - bareos -s /bin/sh -c "/usr/sbin/bareos-dir -t -c /etc/bareos/bareos-dir.conf"'
  action :nothing
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/storages.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/schedules.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/pools.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/filesets.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/job_definitions.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/jobs.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.d/clients.conf]', :delayed
  subscribes :run, 'template[/etc/bareos/bareos-dir.conf]', :delayed
  if node['bareos']['director']['config_change_notify'] == 'restart'
    notifies :restart, 'service[bareos-dir]', :delayed
  else
    notifies :start, 'service[bareos-dir]', :immediate
    notifies :run, 'execute[bareos-dir_reload]', :delayed
  end
end

# Enable and start the bareos-dir service
service 'bareos-dir' do
  supports status: true, restart: true, reload: false
  action [:enable, :start]
  subscribes :restart, 'service[postgresql]', :delayed
end

# Optional reload of the director config via execute
execute 'bareos-dir_reload' do
  command 'echo reload | bconsole'
  action :nothing
end
