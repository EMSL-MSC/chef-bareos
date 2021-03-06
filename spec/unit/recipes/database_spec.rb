#
# Cookbook Name:: chef-bareos
# Spec:: database_spec
#
# Copyright (C) 2016 Leonard TAVAE

require 'spec_helper'

describe 'chef-bareos::database' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
    stub_command(%r{ls \/.*\/recovery.conf}).and_return(false)
  end
  supported_platforms.each do |platform, versions|
    versions.each do |version|
      context "on an #{platform.capitalize}-#{version} box" do
        cached(:chef_run) do
          runner = ChefSpec::ServerRunner.new(platform: platform, version: version)
          runner.converge(described_recipe)
        end
        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end
      end
    end
  end
end
