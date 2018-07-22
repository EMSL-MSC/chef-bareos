#
# Cookbook Name:: chef-bareos
# Spec:: graphite_plugin_spec
#
# Copyright (C) 2016 Leonard TAVAE

require 'spec_helper'

describe 'chef-bareos::graphite_plugin' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
  end
  supported_platforms.each do |platform, versions|
    versions.each do |version|
      context "on an #{platform.capitalize}-#{version} box" do
        cached(:chef_run) do
          runner = ChefSpec::ServerRunner.new(platform: platform, version: version)
          runner.node.default['bareos']['plugins']['graphite']['config_path'] = '/opt/bareos_contrib/misc/performance/graphite'
          runner.node.default['bareos']['plugins']['graphite']['plugin_path'] = '/opt/bareos_contrib/misc/performance/graphite'
          runner.node.default['bareos']['plugins']['graphite']['mailto'] = 'bareos'
          runner.node.default['bareos']['plugins']['graphite']['cron_job'] = true
          runner.converge(described_recipe)
        end
        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end
        it 'installs plugin dependencies' do
          expect(chef_run).to install_package(['python-bareos'])
        end
        it 'creates the graphite-poller.conf via the template resource with attributes' do
          expect(chef_run).to create_template('bareos_graphite_poller_conf').with(
            user:                 'bareos',
            group:                'bareos',
            mode:                 '0740'
          )
          chef_run
        end
        it 'creates the bareos_graphite_poller cronjob with attributes' do
          expect(chef_run).to create_cron('bareos_graphite_poller_cron').with(
            minute:               '*',
            hour:                 '*',
            user:                 'root'
          )
          chef_run
        end
      end
    end
  end
end
