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
describe file('/usr/sbin/bareos-graphite-poller.py') do
  its('type') { should cmp 'file' }
  it { should exist }
end

describe file('/etc/bareos/graphite-poller.conf') do
  it { should exist }
  its('type') { should cmp 'file' }
  its('content') { should match /\[director\]/ }
  its('content') { should match /\[graphite\]/ }
end

describe file('/usr/sbin/bareos-graphite-poller.py') do
  its('content') { should match /BAREOS/ }
end

describe crontab('root').commands('/usr/sbin/bareos-graphite-poller.py -c /etc/bareos/graphite-poller.conf >/dev/null 2>&1') do
  its('hours') { should cmp '*' }
  its('minutes') { should cmp '*' }
end
