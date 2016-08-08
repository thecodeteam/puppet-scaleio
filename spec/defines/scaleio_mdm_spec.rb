require 'spec_helper'

describe 'scaleio::mdm' do

  let (:title) { 'title' }
  let :default_params do
  {
    :sio_name => 'name',
    :ensure => 'present',
    :ensure_properties      => 'present',
    :role                   => 'manager'
  }
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__mdm(title).with_sio_name('name') }

  context 'when ensure is present' do
    let :params do
      default_params.merge(:ensure => 'present')
    end
    context 'without management_ips && without port' do
      let :params do
        default_params.merge(
          :management_ips => '',
          :port => '')
      end
      it { is_expected.to contain_scaleio__cmd('MDM title present').with(
        :action => 'add_standby_mdm',
        :ref => 'new_mdm_name',
        :value => 'name',
        :scope_ref => 'mdm_role',
        :scope_value => 'manager',
        :extra_opts => '--new_mdm_ip    --force_clean --i_am_sure',
        :unless_query => 'query_cluster | grep')}
      it { is_expected.to contain_exec('scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip    --force_clean --i_am_sure').with(
        :command => 'scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip    --force_clean --i_am_sure',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate --query_cluster | grep name ')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip    --force_clean --i_am_sure')}
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep name ')}
    end
    context 'without management_ips && with port' do
      let :params do
        default_params.merge(
          :management_ips => '',
          :port => '4332')
      end
      it { is_expected.to contain_scaleio__cmd('MDM title present').with(
        :action => 'add_standby_mdm',
        :ref => 'new_mdm_name',
        :value => 'name',
        :scope_ref => 'mdm_role',
        :scope_value => 'manager',
        :extra_opts => '--new_mdm_ip  --new_mdm_port 4332  --force_clean --i_am_sure',
        :unless_query => 'query_cluster | grep')}
      it { is_expected.to contain_exec('scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332  --force_clean --i_am_sure').with(
        :command => 'scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332  --force_clean --i_am_sure',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate --query_cluster | grep name ')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332  --force_clean --i_am_sure')}
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep name ')}
    end
    context 'with management_ips && without port' do
      let :params do
        default_params.merge(
          :management_ips => '1.2.3.4,1.2.3.5',
          :port => '')
      end
      it { is_expected.to contain_scaleio__cmd('MDM title present').with(
        :action => 'add_standby_mdm',
        :ref => 'new_mdm_name',
        :value => 'name',
        :scope_ref => 'mdm_role',
        :scope_value => 'manager',
        :extra_opts => '--new_mdm_ip   --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure',
        :unless_query => 'query_cluster | grep')}
      it { is_expected.to contain_exec('scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip   --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure').with(
        :command => 'scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip   --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate --query_cluster | grep name ')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip   --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure')}
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep name ')}
    end
    context 'with management_ips && with port' do
      let :params do
        default_params.merge(
          :management_ips => '1.2.3.4,1.2.3.5',
          :port => '4332')
      end
      it { is_expected.to contain_scaleio__cmd('MDM title present').with(
        :action => 'add_standby_mdm',
        :ref => 'new_mdm_name',
        :value => 'name',
        :scope_ref => 'mdm_role',
        :scope_value => 'manager',
        :extra_opts => '--new_mdm_ip  --new_mdm_port 4332 --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure',
        :unless_query => 'query_cluster | grep')}
      it { is_expected.to contain_exec('scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332 --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure').with(
        :command => 'scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332 --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate --query_cluster | grep name ')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_standby_mdm --new_mdm_name name --mdm_role manager  --new_mdm_ip  --new_mdm_port 4332 --new_mdm_management_ip 1.2.3.4,1.2.3.5 --force_clean --i_am_sure')}
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep name ')}
    end
  end
  context 'when ensure is absent' do
    let :params do
      default_params.merge(:ensure => 'absent')
    end
    it { is_expected.to contain_scaleio__cmd('MDM title absent').with(
      :action => 'remove_standby_mdm',
      :ref => 'remove_mdm_name',
      :value => 'name',
      :onlyif_query => 'query_cluster | grep')}
    it { is_expected.to contain_exec('scli  --approve_certificate --remove_standby_mdm --remove_mdm_name name   ').with(
      :command => 'scli  --approve_certificate --remove_standby_mdm --remove_mdm_name name   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_standby_mdm --remove_mdm_name name   ')}
    it { is_expected.to contain_notify('SCLI ONLYIF: scli  --approve_certificate --query_cluster | grep name')}
  end

  context 'with management_ips' do
    let :params do
      default_params.merge(
        :management_ips => '1.2.3.4,1.2.3.5')
    end
    it do
      is_expected.to contain_scaleio__cmd('properties title present').with(
        :action => 'modify_management_ip', 
        :ref => 'target_mdm_name', 
        :value => 'name',
        :extra_opts => '--new_mdm_management_ip 1.2.3.4,1.2.3.5',
        :unless_query => 'query_cluster | grep -B 1 "Management IPs: 1.2.3.4,1.2.3.5" | grep')
    end
    it { is_expected.to contain_exec('scli  --approve_certificate --modify_management_ip --target_mdm_name name   --new_mdm_management_ip 1.2.3.4,1.2.3.5').with(
      :command => 'scli  --approve_certificate --modify_management_ip --target_mdm_name name   --new_mdm_management_ip 1.2.3.4,1.2.3.5',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_management_ip --target_mdm_name name   --new_mdm_management_ip 1.2.3.4,1.2.3.5')}
    it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep -B 1 "Management IPs: 1.2.3.4,1.2.3.5" | grep name ')}
  end
end
