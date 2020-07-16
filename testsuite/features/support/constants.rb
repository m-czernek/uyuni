# Copyright (c) 2019-2020 SUSE LLC
# Licensed under the terms of the MIT license.

ADDRESSES = { 'network'     => '0',
              'client'      => '2',
              'minion'      => '3',
              'pxeboot'     => '4',
              'range begin' => '128',
              'range end'   => '253',
              'proxy'       => '254',
              'broadcast'   => '255' }.freeze

FIELD_IDS = { 'NIC'                             => 'branch_network#nic',
              'IP'                              => 'branch_network#ip',
              'domain name server'              => 'dhcpd#domain_name_servers#0',
              'network IP'                      => 'dhcpd#subnets#0#$key',
              'dynamic IP range begin'          => 'dhcpd#subnets#0#range#0',
              'dynamic IP range end'            => 'dhcpd#subnets#0#range#1',
              'broadcast address'               => 'dhcpd#subnets#0#broadcast_address',
              'routers'                         => 'dhcpd#subnets#0#routers#0',
              'next server'                     => 'dhcpd#subnets#0#next_server',
              'network mask'                    => 'dhcpd#subnets#0#netmask',
              'filename'                        => 'dhcpd#subnets#0#filename',
              'first reserved IP'               => 'dhcpd#hosts#0#fixed_address',
              'second reserved IP'              => 'dhcpd#hosts#1#fixed_address',
              'third reserved IP'               => 'dhcpd#hosts#2#fixed_address',
              'first reserved hostname'         => 'dhcpd#hosts#0#$key',
              'second reserved hostname'        => 'dhcpd#hosts#1#$key',
              'third reserved hostname'         => 'dhcpd#hosts#2#$key',
              'first reserved MAC'              => 'dhcpd#hosts#0#hardware',
              'second reserved MAC'             => 'dhcpd#hosts#1#hardware',
              'third reserved MAC'              => 'dhcpd#hosts#2#hardware',
              'domain name'                     => 'dhcpd#domain_name',
              'listen interfaces'               => 'dhcpd#listen_interfaces#0',
              'first option'                    => 'bind#config#options#0#0',
              'first value'                     => 'bind#config#options#0#1',
              'first configured zone name'      => 'bind#configured_zones#0#$key',
              'first available zone name'       => 'bind#available_zones#0#$key',
              'first file name'                 => 'bind#available_zones#0#file',
              'first name server'               => 'bind#available_zones#0#soa#ns',
              'first contact'                   => 'bind#available_zones#0#soa#contact',
              'first A name'                    => 'bind#available_zones#0#records#A#0#0',
              'second A name'                   => 'bind#available_zones#0#records#A#1#0',
              'third A name'                    => 'bind#available_zones#0#records#A#2#0',
              'fourth A name'                   => 'bind#available_zones#0#records#A#3#0',
              'fifth A name'                    => 'bind#available_zones#2#records#A#0#0',
              'first NS'                        => 'bind#available_zones#0#records#NS#@#0',
              'first CNAME alias'               => 'bind#available_zones#0#records#CNAME#0#0',
              'first CNAME name'                => 'bind#available_zones#0#records#CNAME#0#1',
              'second CNAME alias'              => 'bind#available_zones#0#records#CNAME#1#0',
              'second CNAME name'               => 'bind#available_zones#0#records#CNAME#1#1',
              'third CNAME alias'               => 'bind#available_zones#0#records#CNAME#2#0',
              'third CNAME name'                => 'bind#available_zones#0#records#CNAME#2#1',
              'second configured zone name'     => 'bind#configured_zones#1#$key',
              'second name server'              => 'bind#available_zones#1#soa#ns',
              'second contact'                  => 'bind#available_zones#1#soa#contact',
              'second NS'                       => 'bind#available_zones#1#records#NS#@#0',
              'second for zones'                => 'bind#available_zones#1#generate_reverse#for_zones#0',
              'second generate reverse network' => 'bind#available_zones#1#generate_reverse#net',
              'second file name'                => 'bind#available_zones#1#file',
              'second available zone name'      => 'bind#available_zones#1#$key',
              'third configured zone name'      => 'bind#configured_zones#2#$key',
              'third available zone name'       => 'bind#available_zones#2#$key',
              'third file name'                 => 'bind#available_zones#2#file',
              'third name server'               => 'bind#available_zones#2#soa#ns',
              'third contact'                   => 'bind#available_zones#2#soa#contact',
              'third NS'                        => 'bind#available_zones#2#records#NS#@#0',
              'first A address'                 => 'bind#available_zones#0#records#A#0#1',
              'second A address'                => 'bind#available_zones#0#records#A#1#1',
              'third A address'                 => 'bind#available_zones#0#records#A#2#1',
              'fourth A address'                => 'bind#available_zones#0#records#A#3#1',
              'fifth A address'                 => 'bind#available_zones#2#records#A#0#1',
              'TFTP base directory'             => 'tftpd#root_dir',
              'internal network address'        => 'tftpd#listen_ip',
              'branch id'                       => 'pxe#branch_id',
              'disk id'                         => 'partitioning#0#$key',
              'disk device'                     => 'partitioning#0#device',
              'disk label'                      => 'partitioning#0#disklabel',
              'first filesystem format'         => 'partitioning#0#partitions#0#format',
              'first partition flags'           => 'partitioning#0#partitions#0#flags',
              'first partition id'              => 'partitioning#0#partitions#0#$key',
              'first partition size'            => 'partitioning#0#partitions#0#size_MiB',
              'first mount point'               => 'partitioning#0#partitions#0#mountpoint',
              'first OS image'                  => 'partitioning#0#partitions#0#image',
              'second filesystem format'        => 'partitioning#0#partitions#1#format',
              'second partition flags'          => 'partitioning#0#partitions#1#flags',
              'second partition id'             => 'partitioning#0#partitions#1#$key',
              'second partition size'           => 'partitioning#0#partitions#1#size_MiB',
              'second mount point'              => 'partitioning#0#partitions#1#mountpoint',
              'second OS image'                 => 'partitioning#0#partitions#1#image',
              'third OS image'                  => 'partitioning#0#partitions#2#image',
              'third filesystem format'         => 'partitioning#0#partitions#2#format',
              'timezone name'                   => 'timezone#name',
              'language'                        => 'keyboard_and_language#language',
              'keyboard layout'                 => 'keyboard_and_language#keyboard_layout' }.freeze

PATCH_BY_CLIENT = { 'ceos6_minion' => 'RHSA-2019:1774',
                    'ceos6_ssh_minion' => 'RHSA-2019:1774',
                    'ceos6_client' => 'RHSA-2019:1774',
                    'ceos7_minion' => 'RHBA-2019:3077',
                    'ceos7_ssh_minion' => 'RHBA-2019:3077',
                    'ceos7_client' => 'RHBA-2019:3077',
                    'sle11sp4_ssh_minion' => 'unzip-13984',
                    'sle11sp4_minion' => 'unzip-13984',
                    'sle11sp4_client' => 'unzip-13984',
                    'sle12sp4_ssh_minion' => 'SUSE-12-SP4-2019-2740',
                    'sle12sp4_minion' => 'SUSE-12-SP4-2019-2740',
                    'sle12sp4_client' => 'SUSE-12-SP4-2019-2740',
                    'sle15_ssh_minion' => 'SUSE-15-2019-1908',
                    'sle15_minion' => 'SUSE-15-2019-1908',
                    'sle15_client' => 'SUSE-15-2019-1908',
                    'sle15sp1_ssh_minion' => 'SUSE-15-SP1-2019-1919',
                    'sle15sp1_minion' => 'SUSE-15-SP1-2019-1919',
                    'sle15sp1_client' => 'SUSE-15-SP1-2019-1919' }.freeze

PACKAGE_BY_CLIENT = { 'ceos_minion' => 'apache',
                      'ceos_ssh_minion' => 'apache',
                      'ceos_client' => 'apache',
                      'ubuntu_minion' => 'apache',
                      'ubuntu_ssh_minion' => 'apache',
                      'ssh_minion' => 'apache',
                      'sle_minion' => 'apache',
                      'sle_client' => 'apache',
                      'sle_migrated_minion' => 'apache',
                      'ceos6_minion' => 'apache',
                      'ceos6_ssh_minion' => 'apache',
                      'ceos6_client' => 'apache',
                      'ceos7_minion' => 'apache',
                      'ceos7_ssh_minion' => 'apache',
                      'ceos7_client' => 'apache',
                      'ubuntu1604_minion' => 'apache',
                      'ubuntu1604_ssh_minion' => 'apache',
                      'ubuntu1804_minion' => 'apache',
                      'ubuntu1804_ssh_minion' => 'apache',
                      'sle11sp4_ssh_minion' => 'apache',
                      'sle11sp4_minion' => 'apache',
                      'sle11sp4_client' => 'apache',
                      'sle12sp4_ssh_minion' => 'apache',
                      'sle12sp4_minion' => 'apache',
                      'sle12sp4_client' => 'apache',
                      'sle15_ssh_minion' => '',
                      'sle15_minion' => 'apache',
                      'sle15_client' => 'apache',
                      'sle15sp1_ssh_minion' => 'apache',
                      'sle15sp1_minion' => 'apache',
                      'sle15sp1_client' => 'apache' }.freeze

CHANNEL_BY_CLIENT = { 'proxy' => 'SLES15-SP1-Pool',
                      'sle_client' => 'SLES12-SP4-Pool',
                      'sle_minion' => 'SLES12-SP4-Pool',
                      'ssh_minion' => 'SLES12-SP4-Pool',
                      'ceos_minion' => 'RHEL x86_64 Server 7',
                      'ubuntu_minion' => 'ubuntu-18.04-pool',
                      'sle11sp4_minion' => 'SLES11-SP4-Pool',
                      'sle11sp4_ssh_minion' => 'SLES11-SP4-Pool',
                      'sle11sp4_client' => 'SLES11-SP4-Pool',
                      'sle12sp4_minion' => 'SLES12-SP4-Pool',
                      'sle12sp4_ssh_minion' => 'SLES12-SP4-Pool',
                      'sle12sp4_client' => 'SLES12-SP4-Pool',
                      'sle15_minion' => 'SLES15-Pool',
                      'sle15_ssh_minion' => 'SLES15-Pool',
                      'sle15_client' => 'SLES15-Pool',
                      'sle15sp1_minion' => 'SLES15-SP1-Pool',
                      'sle15sp1_ssh_minion' => 'SLES15-SP1-Pool',
                      'sle15sp1_client' => 'SLES15-SP1-Pool',
                      'ceos6_minion' => 'RHEL x86_64 Server 6',
                      'ceos6_ssh_minion' => 'RHEL x86_64 Server 6',
                      'ceos6_client' => 'RHEL x86_64 Server 6',
                      'ceos7_minion' => 'RHEL x86_64 Server 7',
                      'ceos7_ssh_minion' => 'RHEL x86_64 Server 7',
                      'ceos7_client' => 'RHEL x86_64 Server 7',
                      'ubuntu1604_ssh_minion' => 'ubuntu-16.04-pool',
                      'ubuntu1604_minion' => 'ubuntu-16.04-pool',
                      'ubuntu1804_ssh_minion' => 'ubuntu-18.04-pool',
                      'ubuntu1804_minion' => 'ubuntu-18.04-pool' }.freeze

PKGARCH_BY_CLIENT = { 'proxy' => 'x86_64',
                      'sle_client' => 'x86_64',
                      'sle_minion' => 'x86_64',
                      'ssh_minion' => 'x86_64',
                      'sle_migrated_minion' => 'x86_64',
                      'ceos_minion' => 'x86_64',
                      'ubuntu_minion' => 'x86_64',
                      'sle11sp4_minion' => 'x86_64',
                      'sle11sp4_ssh_minion' => 'x86_64',
                      'sle11sp4_client' => 'x86_64',
                      'sle12sp4_minion' => 'x86_64',
                      'sle12sp4_ssh_minion' => 'x86_64',
                      'sle12sp4_client' => 'x86_64',
                      'sle15_minion' => 'x86_64',
                      'sle15_ssh_minion' => 'x86_64',
                      'sle15_client' => 'x86_64',
                      'sle15sp1_minion' => 'x86_64',
                      'sle15sp1_ssh_minion' => 'x86_64',
                      'sle15sp1_client' => 'x86_64',
                      'ceos6_minion' => 'x86_64',
                      'ceos6_ssh_minion' => 'x86_64',
                      'ceos6_client' => 'x86_64',
                      'ceos7_minion' => 'x86_64',
                      'ceos7_ssh_minion' => 'x86_64',
                      'ceos7_client' => 'x86_64',
                      'ubuntu1604_ssh_minion' => 'x86_64',
                      'ubuntu1604_minion' => 'x86_64',
                      'ubuntu1804_ssh_minion' => 'x86_64',
                      'ubuntu1804_minion' => 'x86_64' }.freeze
