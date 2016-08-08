require "spec_helper"

describe 'scaleio::sdc_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}

  let (:default_params) {{ :ensure => 'present' }}

  it { is_expected.to contain_class('scaleio::sdc_server')}

  it 'installs numactl package' do
    is_expected.to contain_package('numactl').with_ensure('installed')
  end
  it 'installs libaio1 package' do
    is_expected.to contain_package('libaio1').with_ensure('installed')
  end
  it 'installs emc-scaleio-sdc package' do
    is_expected.to contain_package('emc-scaleio-sdc').with_ensure('present')
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

  context 'with mdm_ip' do
    let (:params) { {:mdm_ip => '1.2.3.4'} }
    context 'when ensure is present' do
      let (:ensure) {'present'}
      it 'adds ip' do
        is_expected.to contain_scaleio__sdc_server__add_ip('1.2.3.4')
      end
      it 'executes add_ip' do
        is_expected.to contain_exec('add ip 1.2.3.4').with(
          :command  => "drv_cfg --add_mdm --ip 1.2.3.4",
          :path     => '/opt/emc/scaleio/sdc/bin:/bin',
          :require  => 'Package[emc-scaleio-sdc]',
          :unless   => "drv_cfg --query_mdms | grep 1.2.3.4")
      end
    end
    it 'sets mdm ip addresses' do
      is_expected.to contain_file_line('Set MDM IP addresses in drv_cfg.txt').with(
        :ensure  => 'present',
        :line    => 'mdm 1.2.3.4',
        :path    => '/bin/emc/scaleio/drv_cfg.txt',
        :match   => '^mdm .*',
        :require => 'Package[emc-scaleio-sdc]',
      )
    end
  end

  context 'with undefined mdm_ip' do
    let (:params) { { :mdm_ip => '' } }
    it 'doesnot connect to mdm' do
      is_expected.not_to contain_file_line('Set MDM IP addresses in drv_cfg.txt')
    end
  end
end