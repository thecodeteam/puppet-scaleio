require 'spec_helper'

describe 'scaleio::driver_sync' do

  let (:title) { 'title' }
  let (:default_params) {{ :driver => 'scini', :ftp => 'default' }}
  let (:params) { default_params }

  it { is_expected.to contain_scaleio__driver_sync('title')}
  it { is_expected.to contain_notify('FTP to use for scini driver: ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com, ftp.emc.com, ftp, QNzgdxXix, Aw3wFAwAq3' )}
  it { is_expected.to contain_file('Ensure sync directory present: ').with(
    :ensure => 'directory',
    :path   => '/bin/emc/scaleio/scini_sync',
    :mode   => '0755')}
  it { is_expected.to contain_file('/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO').with(
    :ensure => 'present',
    :source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
    :mode   => '0644',
    :owner  => 'root',
    :group  => 'root')}
  it { is_expected.to contain_exec('scaleio scini repo public key').with(
    :command => 'ssh-keyscan ftp.emc.com | grep ssh-rsa > /bin/emc/scaleio/scini_sync/scini_repo_key.pub',
    :path    => ['/bin/', '/usr/bin', '/sbin'],
    :onlyif  => "echo 'ftp' | grep -q sftp")}
  it { is_expected.to contain_file('Ensure sync config present: ').with(
    :ensure => 'file',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf')}
    let :sync_conf do ({
      "repo_address"        => 'ftp://ftp.emc.com',
      "repo_user"           => 'QNzgdxXix',
      "repo_password"       => 'Aw3wFAwAq3',
      "local_dir"           => '/bin/emc/scaleio/scini_sync/driver_cache/',
      "module_sigcheck"     => 1,
      "emc_public_gpg_key"  => '/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO',
      "repo_public_rsa_key" => '/bin/emc/scaleio/scini_sync/scini_repo_key.pub',
      "sync_pattern"        => '.*',
    })
  end
  it { is_expected.to contain_config_sync('emc_public_gpg_key').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync emc_public_gpg_key').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^emc_public_gpg_key',
    :line   => 'emc_public_gpg_key=/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO')}
  it { is_expected.to contain_config_sync('local_dir').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync local_dir').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^local_dir',
    :line   => 'local_dir=/bin/emc/scaleio/scini_sync/driver_cache/')}
  it { is_expected.to contain_config_sync('module_sigcheck').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync module_sigcheck').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^module_sigcheck',
    :line   => 'module_sigcheck=1')}
  it { is_expected.to contain_config_sync('repo_address').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync repo_address').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^repo_address',
    :line   => 'repo_address=ftp://ftp.emc.com')}
  it { is_expected.to contain_config_sync('repo_password').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync repo_password').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^repo_password',
    :line   => 'repo_password=Aw3wFAwAq3')}
  it { is_expected.to contain_config_sync('repo_public_rsa_key').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync repo_public_rsa_key').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^repo_public_rsa_key',
    :line   => 'repo_public_rsa_key=/bin/emc/scaleio/scini_sync/scini_repo_key.pub')}
  it { is_expected.to contain_config_sync('repo_user').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync repo_user').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^repo_user',
    :line   => 'repo_user=QNzgdxXix')}
  it { is_expected.to contain_config_sync('sync_pattern').with(
    :driver => 'scini',
    :config => sync_conf)}
  it { is_expected.to contain_file_line('config_sync sync_pattern').with(
    :ensure => 'present',
    :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
    :match  => '^sync_pattern',
    :line   => 'sync_pattern=.*')}
  it { is_expected.to contain_exec('scini sync and update').with(
    :command => 'update_driver_cache.sh && verify_driver.sh',
    :unless  => ['test ! -f /bin/emc/scaleio/scini_sync/verify_driver.sh', 'verify_driver.sh'],
    :path    => ['/bin/emc/scaleio/scini_sync/', '/bin/', '/usr/bin', '/sbin'],
    :notify  => 'Service[scini]')}
end

#define config_sync($driver, $config) {
#  file_line { "config_sync ${title}":
#    ensure => present,
#    path   => "/bin/emc/scaleio/${driver}_sync/driver_sync.conf",
#    match  => "^${title}",
#    line   => "${title}=${config[$title]}",
#  }
#}

