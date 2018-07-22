# Check Packages are installed
%w(bareos-filedaemon bareos-storage bareos-director).each do |bareos_pkgs|
  describe package(bareos_pkgs) do
    it { should be_installed }
  end
end

# Check if Bareos services are enabled and running
%w(bareos-fd bareos-sd bareos-dir).each do |bareos_srv|
  describe service(bareos_srv) do
    it { should be_enabled }
    it { should be_running }
  end
end

describe bash("echo 'status director' | bconsole") do
  its('exit_status') { should eq 0 }
end

# Check if the graphite plugin was installed
plugin_dir = '/opt/bareos_contrib/misc/performance/graphite'

describe file("#{plugin_dir}/bareos-graphite-poller.py") do
  its('type') { should cmp 'file' }
  its('content') { should match /BAREOS/ }
  it { should exist }
end

describe file("#{plugin_dir}/graphite-poller.conf") do
  it { should exist }
  its('type') { should cmp 'file' }
  its('content') { should match /\[director\]/ }
  its('content') { should match /\[graphite\]/ }
end

describe crontab('root').commands(
  "source /opt/bareos_graphite_venv/bin/activate && \
  #{plugin_dir}/bareos-graphite-poller.py -c \
  #{plugin_dir}/graphite-poller.conf >/dev/null 2>&1"
) do
  its('hours') { should cmp '*' }
  its('minutes') { should cmp '*' }
end
