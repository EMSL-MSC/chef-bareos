# encoding: UTF-8
#
# Copyright (C) 2016 Leonard TAVAE
#
# Cookbook Name:: chef-bareos
# Recipe:: repo
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

if rhel?
  yum_repository node['bareos']['repository_name'] do
    description node['bareos']['description']
    baseurl node['bareos']['baseurl']
    gpgkey node['bareos']['gpgkey']
    action :create
  end
  yum_repository node['bareos']['contrib_repository_name'] do
    description node['bareos']['contrib_description']
    baseurl node['bareos']['contrib_baseurl']
    gpgkey node['bareos']['contrib_gpgkey']
    action :create
  end
elsif debian?
  apt_repository 'bareos' do
    uri node['bareos']['baseurl']
    components ['/']
    distribution ''
    key node['bareos']['gpgkey']
    action :add
  end
  apt_repository 'bareos_contrib' do
    uri node['bareos']['contrib_baseurl']
    components ['/']
    distribution ''
    key node['bareos']['contrib_gpgkey']
    action :add
  end
end
