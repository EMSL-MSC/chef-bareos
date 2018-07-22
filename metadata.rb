name              'chef-bareos'
maintainer        'dsi'
maintainer_email  'leonard.tavae@informatique.gov.pf'
license           'Apache-2.0'
description       'Installs/Configures BAREOS - Backup Archiving REcovery Open Sourced'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url        'https://github.com/sitle/chef-bareos/issues'
source_url        'https://github.com/sitle/chef-bareos.git'
version           '4.0.0'

chef_version      '>= 13.4.19'

supports          'debian', '>= 8'
supports          'ubuntu', '>= 14' # No binaries for bareos 15 on ubuntu 16
supports          'redhat', '>= 6'
supports          'centos', '>= 6'

depends           'chef-sugar'
depends           'openssl', '>= 4.0'
depends           'postgresql', '~> 7.0'
depends           'poise-git'
depends           'poise-python'
