require 'spec_helper'

describe 'scaleio::sds_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}
  let (:default_params) {{ :ensure => 'present' }}

  it { is_expected.to contain_class('scaleio::sds_server') }

  it '001 open port 7072 for sds' do
    is_expected.to contain_firewall('001 Open Port 7072 for ScaleIO SDS').with(
      :dport   => '7072',
      :proto  => 'tcp',
      :action => 'accept',)
  end
  it 'ensures utilities' do
    is_expected.to contain_package('numactl').with_ensure('installed')
    is_expected.to contain_package('libaio1').with_ensure('installed')
  end
  it 'installs common packages for SDS' do
    is_expected.to contain_scaleio__common_server('install common packages for SDS')
  end

  context 'with pkg_src' do
    let (:params) {{
      :pkg_src => 'ftp://ftp',
    }}
    it 'installs sds package' do
      is_expected.to contain_scaleio__package('sds').with_ensure('present')
    end
  end

  it 'Apply noop IO scheduler for SSD/flash disks' do
    is_expected.to contain_exec('Apply noop IO scheduler for SSD/flash disks').with(
      :command => "bash -c 'for i in `lsblk -d -o ROTA,KNAME | awk \"/^ *0/ {print($2)}\"` ; do if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi ; done'",
      :path    => '/bin:/usr/bin')
  end
  it 'ensure noop IO scheduler persistent' do
    is_expected.to contain_file('Ensure noop IO scheduler persistent').with(
      :content => 'ACTION=="add|change", KERNEL=="[a-z]*", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="noop"',
      :path    => '/etc/udev/rules.d/60-scaleio-ssd-scheduler.rules')
  end

  context 'when xcache present and ftp configured' do
    it 'installs xcache package' do
      is_expected.to contain_scaleio__package('xcache').with(
        :ensure => 'present')
    end
    it 'runs xcache service' do
      is_expected.to contain_service('xcache').with(
        :ensure => 'running')
    end
    let :sync_conf do ({
      "repo_address"        => 'ftp://ftp.emc.com',
      "repo_user"           => 'QNzgdxXix',
      "repo_password"       => 'Aw3wFAwAq3',
      "local_dir"           => '/bin/emc/scaleio/xcache_sync/driver_cache/',
      "module_sigcheck"     => 1,
      "emc_public_gpg_key"  => '/bin/emc/scaleio/xcache_sync/RPM-GPG-KEY-ScaleIO',
      "repo_public_rsa_key" => '/bin/emc/scaleio/xcache_sync/xcache_repo_key.pub',
      "sync_pattern"        => '.*'})
    end
    it 'xcache driver sync' do
      is_expected.to contain_scaleio__driver_sync('xcache driver sync').with(
        :driver  => 'xcache',
        :ftp     => 'default',
        :require => 'Scaleio::Package[xcache]')
      is_expected.to contain_notify('FTP to use for xcache driver: ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com, ftp.emc.com, ftp, QNzgdxXix, Aw3wFAwAq3')
    is_expected.to contain_file('Ensure sync directory present: ').with(
      :ensure => 'directory',
      :path   => '/bin/emc/scaleio/xcache_sync',
      :mode   => '0755')
    is_expected.to contain_file('/bin/emc/scaleio/xcache_sync/RPM-GPG-KEY-ScaleIO').with(
      :ensure => 'present',
      :source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root')
    is_expected.to contain_exec('scaleio xcache repo public key').with(
      :command => 'ssh-keyscan ftp.emc.com | grep ssh-rsa > /bin/emc/scaleio/xcache_sync/xcache_repo_key.pub',
      :path    => ['/bin/', '/usr/bin', '/sbin'],
      :onlyif  => "echo 'ftp' | grep -q sftp")
    is_expected.to contain_file('Ensure sync config present: ').with(
      :ensure => 'file',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf')
    is_expected.to contain_config_sync('emc_public_gpg_key').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync emc_public_gpg_key').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^emc_public_gpg_key',
      :line   => 'emc_public_gpg_key=/bin/emc/scaleio/xcache_sync/RPM-GPG-KEY-ScaleIO')
    is_expected.to contain_config_sync('local_dir').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync local_dir').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^local_dir',
      :line   => 'local_dir=/bin/emc/scaleio/xcache_sync/driver_cache/')
    is_expected.to contain_config_sync('local_dir').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync local_dir').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^local_dir',
      :line   => 'local_dir=/bin/emc/scaleio/xcache_sync/driver_cache/')
    is_expected.to contain_config_sync('module_sigcheck').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync module_sigcheck').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^module_sigcheck',
      :line   => 'module_sigcheck=1')
    is_expected.to contain_config_sync('repo_address').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync repo_address').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^repo_address',
      :line   => 'repo_address=ftp://ftp.emc.com')
    is_expected.to contain_config_sync('repo_password').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync repo_password').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^repo_password',
      :line   => 'repo_password=Aw3wFAwAq3')
    is_expected.to contain_config_sync('repo_public_rsa_key').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync repo_public_rsa_key').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^repo_public_rsa_key',
      :line   => 'repo_public_rsa_key=/bin/emc/scaleio/xcache_sync/xcache_repo_key.pub')
    is_expected.to contain_config_sync('repo_user').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync repo_user').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^repo_user',
      :line   => 'repo_user=QNzgdxXix')
    is_expected.to contain_config_sync('sync_pattern').with(
      :driver => 'xcache',
      :config => sync_conf)
    is_expected.to contain_file_line('config_sync sync_pattern').with(
      :ensure => 'present',
      :path   => '/bin/emc/scaleio/xcache_sync/driver_sync.conf',
      :match  => '^sync_pattern',
      :line   => 'sync_pattern=.*')
    is_expected.to contain_exec('xcache sync and update').with(
      :command => 'update_driver_cache.sh && verify_driver.sh',
      :unless  => ['test ! -f /bin/emc/scaleio/xcache_sync/verify_driver.sh', 'verify_driver.sh'],
      :path    => ['/bin/emc/scaleio/xcache_sync/', '/bin/', '/usr/bin', '/sbin'],
      :notify  => 'Service[xcache]')
    end
  end
end
