name 'chef-bareos'
maintainer 'dsi'
maintainer_email 'leonard.tavae@informatique.gov.pf'
license 'Apache 2.0'
description 'Installs/Configures bareos'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.1.28'

%w( centos redhat scientific ).each do |os|
  supports os, '>= 6.0'
end

%w( fedora debian ubuntu ).each do |os|
  supports os
end

depends 'apt'
depends 'openssl'
depends 'postgresql'
depends 'yum'
