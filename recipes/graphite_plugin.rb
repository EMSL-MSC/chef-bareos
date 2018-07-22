# encoding: UTF-8
#
# Cookbook Name:: chef-bareos
# Recipe:: graphite_plugin
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

include_recipe 'chef-bareos::repo'

poise_git node['bareos']['plugins']['graphite']['git_path'] do
  repository 'https://github.com/bareos/bareos-contrib.git'
end

python_runtime 'bareos_graphite_python2' do
  version '2'
end

package %w(python-bareos)

python_virtualenv 'bareos_graphite_virtualenv' do
  path '/opt/bareos_graphite_venv'
end

python_package 'bareos_graphite_requirements' do
  package_name %w(django requests)
  python 'bareos_graphite_python2'
  virtualenv 'bareos_graphite_virtualenv'
end

template 'bareos_graphite_poller_conf' do
  path "#{node['bareos']['plugins']['graphite']['git_path']}/misc/performance/graphite/graphite-poller.conf"
  source 'graphite-poller.conf.erb'
  owner 'bareos'
  group 'bareos'
  mode '0740'
  sensitive node['bareos']['plugins']['graphite']['sensitive_configs']
end

cron 'bareos_graphite_poller_cron' do
  command node['bareos']['plugins']['graphite']['cron_command']
  mailto node['bareos']['plugins']['graphite']['mail_to']
  only_if { node['bareos']['plugins']['graphite']['cron_job'] }
end
