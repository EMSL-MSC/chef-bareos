# encoding: UTF-8
#
# Copyright (C) 2016 Leonard TAVAE
#
# Cookbook Name:: chef-bareos
# Recipe:: client
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

# Include the OpenSSL library for generating random passwords
::Chef::Recipe.send(:include, OpenSSLCookbook::RandomPassword)
node.normal_unless['bareos']['fd_password'] = random_password(length: 30, mode: :base64)
node.normal_unless['bareos']['mon_password'] = random_password(length: 30, mode: :base64)

node.save # FC075: Cookbook uses node.save to save partial node data to the chef-server mid-run

include_recipe 'chef-bareos::repo'

# Installation of the BAREOS File Daemon
package 'bareos-filedaemon'

# Determine the list of BAREOS directors
dir_search_query = node['bareos']['director']['dir_search_query']
dir_search_result = search(:node, dir_search_query)
if dir_search_result.empty?
  dir_search_result = search(:node, "fqdn:#{node['fqdn']}")
end

# Setup the configs for any local/remote File Daemons clients
template '/etc/bareos/bareos-fd.conf' do
  source 'bareos-fd.conf.erb'
  owner 'root'
  group 'bareos'
  mode '0640'
  variables(
    bareos_dir: dir_search_result
  )
  sensitive node['bareos']['clients']['sensitive_configs']
end

# Allow the restart of the File Daemon with tests upfront, if called
execute 'restart-fd' do
  command 'bareos-fd -t -c /etc/bareos/bareos-fd.conf'
  action :nothing
  subscribes :run, 'template[/etc/bareos/bareos-fd.conf]', :delayed
  notifies :restart, 'service[bareos-fd]', :delayed
end

# Start and enable the BAREOS File Daemon
service 'bareos-fd' do
  supports status: true, restart: true, reload: false
  action [:enable, :start]
end
