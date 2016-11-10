require 'spec_helper'

describe 'scaleio::mdm_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}

  it { is_expected.to contain_class('scaleio::mdm_server') }

  let (:default_params) {{ :ensure  => 'present' }}

  context 'ensure is present' do
    it '001 Open Ports 6611 and 9011 for ScaleIO MDM' do
      is_expected.to contain_firewall('001 Open Ports 6611 and 9011 for ScaleIO MDM').with(
        :dport   => [6611, 9011],
        :proto  => 'tcp',
        :action => 'accept')
    end
    it 'contains install common packages for MDM' do
      is_expected.to contain_scaleio__common_server('install common packages for MDM')
    end
    it 'has utilities installed' do
      is_expected.to contain_package('numactl').with_ensure('installed')
      is_expected.to contain_package('libaio1').with_ensure('installed')
      is_expected.to contain_package('mutt').with_ensure('installed')
      is_expected.to contain_package('python').with_ensure('installed')
      is_expected.to contain_package('python-paramiko').with_ensure('installed')
    end

    context 'with pkg_src' do
      let (:params) {{
        :pkg_src => 'ftp://ftp',
      }}
      it 'installs mdm package' do
        is_expected.to contain_scaleio__package('mdm').with_ensure('present')
      end
    end
    it 'runs mdm service' do
      is_expected.to contain_service('mdm').with(
        'ensure'    => 'running',
        'enable'    => true,
        'hasstatus' => true)
    end

    it 'creates cluster' do
      is_expected.to contain_exec('create_cluster').with(
        :command => 'sleep 2 ; scli --query_cluster --approve_certificate || scli --approve_certificate --accept_license --create_mdm_cluster --use_nonsecure_communication --master_mdm_name  --master_mdm_ip  ',
        :path => '/bin:/usr/bin',
        :onlyif => "test -n ''",
        :require => 'Service[mdm]',)
    end

    context 'with defined is_manager' do
      let (:params) {{ :is_manager => true }}
      it do
        is_expected.to contain_file_line('mdm role').with(
          :path    => '/opt/emc/scaleio/mdm/cfg/conf.txt',
          :line    => 'actor_role_is_manager=true',
          :match   => '^actor_role_is_manager',
          :require => 'Scaleio::Package[mdm]',
          :notify  => 'Service[mdm]',
          :before  => 'Exec[create_cluster]',)
      end
    end
    context 'with undefined is_manager' do
      let (:params) {{ :is_manager => '' }}
      it { is_expected.not_to contain_file_line('mdm role') }
    end
  end

  context 'ensure is absent' do
    let (:params) {{ :ensure => 'absent' }}

    it 'doesnot installs mdm package' do
      is_expected.to contain_scaleio__package('mdm').with_ensure('absent')
    end
  end
end