require "spec_helper"

describe 'scaleio::sdc_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}
  let (:default_params) {{
    :ensure => 'present',
    :pkg_src => 'ftp://ftp',
  }}

  it { is_expected.to contain_class('scaleio::sdc_server')}

  it 'contains install common packages for SDC' do
    is_expected.to contain_scaleio__common_server('install common packages for SDC')
  end
  it 'installs numactl package' do
    is_expected.to contain_package('numactl').with_ensure('installed')
  end
  it 'installs libaio1 package' do
    is_expected.to contain_package('libaio1').with_ensure('installed')
  end

  it 'installs emc-scaleio-sdc package' do
    is_expected.to contain_scaleio__package('sdc').with_ensure('present')
  end

  it do
    is_expected.to contain_file('/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO').with(
      :ensure => 'present',
      :source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root',)
  end
  it do
    is_expected.to contain_exec('scaleio scini repo public key').with(
      :command => 'ssh-keyscan ftp.emc.com | grep ssh-rsa > /bin/emc/scaleio/scini_sync/scini_repo_key.pub',
      :path    => '["/bin/", "/usr/bin", "/sbin"]')
  end
  it 'ensures sync config present' do
    is_expected.to contain_file('Ensure sync config present: ').with(
      :ensure => 'file',
      :path   => '/bin/emc/scaleio/scini_sync/driver_sync.conf')
  end

  let :config do ({
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
  it 'contains scini_syncs' do
    is_expected.to contain_config_sync('repo_address').with_config(config)
    is_expected.to contain_config_sync('repo_user').with_config(config)
    is_expected.to contain_config_sync('repo_password').with_config(config)
    is_expected.to contain_config_sync('local_dir').with_config(config)
    is_expected.to contain_config_sync('module_sigcheck').with_config(config)
    is_expected.to contain_config_sync('repo_public_rsa_key').with_config(config)
    is_expected.to contain_config_sync('emc_public_gpg_key').with_config(config)
    is_expected.to contain_config_sync('sync_pattern').with_config(config)
  end
  it 'contains file_lines' do
    is_expected.to contain_file_line('config_sync repo_address')
    is_expected.to contain_file_line('config_sync repo_user')
    is_expected.to contain_file_line('config_sync repo_password')
    is_expected.to contain_file_line('config_sync local_dir')
    is_expected.to contain_file_line('config_sync module_sigcheck')
    is_expected.to contain_file_line('config_sync repo_public_rsa_key')
    is_expected.to contain_file_line('config_sync emc_public_gpg_key')
    is_expected.to contain_file_line('config_sync sync_pattern')
  end
  it do
    is_expected.to contain_exec('scini sync and update').with(
      :command => 'update_driver_cache.sh && verify_driver.sh',
      :unless  => '["test ! -f /bin/emc/scaleio/scini_sync/verify_driver.sh", "verify_driver.sh"]',
      :path    => '["/bin/emc/scaleio/scini_sync/", "/bin/", "/usr/bin", "/sbin"]')
  end
  it do
    is_expected.to contain_service('scini').with_ensure('running')
  end
  it 'contains scini driver sync' do
    is_expected.to contain_scaleio__driver_sync('scini driver sync').with(
      :driver  => 'scini',
      :ftp     => 'default',
      :require => 'Scaleio::Package[sdc]',)
  end
  it 'ensures sync directory present' do
    is_expected.to contain_file('Ensure sync directory present: ').with(
      :ensure => 'directory',
      :path   => '/bin/emc/scaleio/scini_sync',
      :mode   => '0755')
  end

  context 'with mdm_ip and ensure properties' do
    let (:params) {{
        :mdm_ip => '1.2.3.4',
        :ensure_properties => 'present'}}
    it 'sets mdm ip addresses' do
      is_expected.to contain_file_line('Set MDM IP addresses in drv_cfg.txt').with(
        :ensure  => 'present',
        :line    => 'mdm 1.2.3.4',
        :path    => '/bin/emc/scaleio/drv_cfg.txt',
        :match   => '^mdm .*',
        :require => 'Scaleio::Package[sdc]',
      )
      is_expected.to contain_notify('FTP to use for scini driver: ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com, ftp.emc.com, ftp, QNzgdxXix, Aw3wFAwAq3')
    end
  end
  context 'with mdm_ip and absent ensure properties' do
    let (:params) {{
        :mdm_ip => '1.2.3.4',
        :ensure_properties => 'absent'}}
    it 'doesnot connect to mdm' do
      is_expected.not_to contain_file_line('Set MDM IP addresses in drv_cfg.txt')
      is_expected.not_to contain_file_line('Reset MDM IP addresses in drv_cfg.txt')
    end
  end
  context 'with undefined mdm_ip and present ensure properties' do
    let (:params) {{ 
      :mdm_ip => '',
      :ensure_properties => 'present' }}
    it 'doesnot connect to mdm' do
      is_expected.not_to contain_file_line('Set MDM IP addresses in drv_cfg.txt')
      is_expected.not_to contain_file_line('Reset MDM IP addresses in drv_cfg.txt')
    end
  end
  context 'with undefined mdm_ip and absent ensure properties' do
    let (:params) {{
      :mdm_ip => '',
      :ensure_properties => 'absent' }}
    it 'reset mdm ips' do
      is_expected.to contain_file_line('Reset MDM IP addresses in drv_cfg.txt').with(
          :ensure            => 'absent',
          :line              => '',
          :path              => '/bin/emc/scaleio/drv_cfg.txt',
          :match             => '^mdm .*',
          :match_for_absence => true,
          :require           => 'Scaleio::Package[sdc]',
          :replace           => false,
          :notify            => 'Service[scini]')
    end
  end

  context 'with ftp' do
    let (:params) {{
        :ftp => 'ftp://ftp'}}
    it do
      is_expected.to contain_scaleio__driver_sync('scini driver sync').with(
        :driver  => 'scini',
        :ftp     => 'ftp://ftp',
        :require => 'Scaleio::Package[sdc]')
      is_expected.to contain_notify('FTP to use for scini driver: ftp://ftp, , ftp, ftp, ')
    end
  end
  context 'without ftp' do
    let (:params) {{
        :ftp => ''}}
    it do
      is_expected.not_to contain_scaleio__driver_sync('scini driver sync')
    end
  end
end
