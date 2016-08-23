require 'spec_helper'

describe 'scaleio::cluster' do

  let (:title) {'title'}
  let (:default_params) {{ :ensure => 'present' }}

  it { is_expected.to contain_scaleio__cluster(title) }
  context 'when cluster_mode is defined' do

    let :params do
      default_params.merge({ :cluster_mode => '1' })
    end
    it 'switches cluster mode' do
      is_expected.to contain_scaleio__cmd('switch cluster mode present').with(
        :action => 'switch_cluster_mode',
        :ref => 'cluster_mode',
        :value => '1_node',
        :extra_opts => "--add_slave_mdm_name  --add_tb_name  --i_am_sure",
        :unless_query => 'query_cluster | grep -A 1 "Cluster:" | grep')
    end
    it { is_expected.to contain_exec('scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --add_slave_mdm_name  --add_tb_name  --i_am_sure').with(
      :command => 'scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --add_slave_mdm_name  --add_tb_name  --i_am_sure',
      :path => ['/bin/'],
      :unless => 'scli  --approve_certificate --query_cluster | grep -A 1 "Cluster:" | grep 1_node ')}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --add_slave_mdm_name  --add_tb_name  --i_am_sure')}
    it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep -A 1 "Cluster:" | grep 1_node ')}

    context 'when ensure is absent' do
      let :params do
        default_params.merge({ :ensure => 'absent', :cluster_mode => '1' })
      end
      it 'switchs cluster mode' do
        is_expected.to contain_scaleio__cmd('switch cluster mode absent').with(
          :action => 'switch_cluster_mode',
          :ref => 'cluster_mode', 
          :value => '1_node',
          :extra_opts => "--remove_slave_mdm_name  --remove_tb_name  --i_am_sure",
          :unless_query => 'query_cluster | grep -A 1 "Cluster:" | grep')
      end
      it { is_expected.to contain_exec('scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --remove_slave_mdm_name  --remove_tb_name  --i_am_sure').with(
        :command => 'scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --remove_slave_mdm_name  --remove_tb_name  --i_am_sure',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate --query_cluster | grep -A 1 "Cluster:" | grep 1_node ')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --switch_cluster_mode --cluster_mode 1_node   --remove_slave_mdm_name  --remove_tb_name  --i_am_sure')}   
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_cluster | grep -A 1 "Cluster:" | grep 1_node ')}
    end
  end
  context 'when cluster_mode is undefined' do
    let :params do
      default_params.merge({ :cluster_mode => '' })
    end
    it { is_expected.not_to contain_scaleio__cmd('switch cluster mode')}
  end
  context 'when new_password is defined' do
    let :params do
      default_params.merge({ :new_password => 'new_password' })
    end
    it 'sets password' do
      is_expected.to contain_scaleio__cmd('set password').with(
        :action => 'set_password',
        :ref => 'new_password',
        :value => 'new_password',
        :scope_ref => 'old_password', 
        :scope_value => nil,
        :approve_certificate => '')
    end
    it { is_expected.to contain_exec('scli   --set_password --new_password new_password   ').with(
      :command => 'scli   --set_password --new_password new_password   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli   --set_password --new_password new_password   ')}
  end
  context 'when new_password isnt defined' do
    let :params do
     default_params.merge({ :new_password => '' })
    end
    it { is_expected.not_to contain_scaleio__cmd('set password')}
  end
  context 'when exists license_file_path' do
    let :params do
      default_params.merge({ :license_file_path => '/tmp/foo' })
    end
    it 'sets license' do
      is_expected.to contain_scaleio__cmd('set license').with(
        :action => 'set_license',
        :ref => 'license_file',
        :value => '/tmp/foo')
    end
    it { is_expected.to contain_exec('scli  --approve_certificate --set_license --license_file /tmp/foo   ').with(
      :command => 'scli  --approve_certificate --set_license --license_file /tmp/foo   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_license --license_file /tmp/foo   ')}
  end
  context 'when license_file_path doesnt exist' do
    let :params do
      default_params.merge({ :license_file_path => '' })
    end
    it { is_expected.not_to contain_scaleio__cmd('set license')}
  end

  context 'when slave_names_to_replace exists' do
    let :params do
      default_params.merge({ :slave_names_to_replace => 'slave_names' })
    end
    it 'replace cluster nodes' do
      is_expected.to contain_scaleio__cmd('replace cluster nodes  --remove_slave_mdm_name slave_names  ').with(
        :action => 'replace_cluster_mdm',
        :extra_opts => ' --remove_slave_mdm_name slave_names   --allow_leave_failed --i_am_sure')
    end
    it { is_expected.to contain_exec('scli  --approve_certificate --replace_cluster_mdm     --remove_slave_mdm_name slave_names   --allow_leave_failed --i_am_sure').with(
      :command => 'scli  --approve_certificate --replace_cluster_mdm     --remove_slave_mdm_name slave_names   --allow_leave_failed --i_am_sure',
      :path => ['/bin/'])}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --replace_cluster_mdm     --remove_slave_mdm_name slave_names   --allow_leave_failed --i_am_sure')}
    context 'add slaves' do
      let :params do
        default_params.merge({ :slave_names_to_replace => 'slave_names_to_remove', :slave_names => 'slave_names_to_add' })
      end
      it 'replace cluster nodes' do
        is_expected.to contain_scaleio__cmd('replace cluster nodes --add_slave_mdm_name slave_names_to_add --remove_slave_mdm_name slave_names_to_remove  ').with(
          :action => 'replace_cluster_mdm',
          :extra_opts => '--add_slave_mdm_name slave_names_to_add --remove_slave_mdm_name slave_names_to_remove   --allow_leave_failed --i_am_sure')
      end
      it { is_expected.to contain_exec('scli  --approve_certificate --replace_cluster_mdm    --add_slave_mdm_name slave_names_to_add --remove_slave_mdm_name slave_names_to_remove   --allow_leave_failed --i_am_sure').with(
        :command => 'scli  --approve_certificate --replace_cluster_mdm    --add_slave_mdm_name slave_names_to_add --remove_slave_mdm_name slave_names_to_remove   --allow_leave_failed --i_am_sure',
        :path => ['/bin/'])}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --replace_cluster_mdm    --add_slave_mdm_name slave_names_to_add --remove_slave_mdm_name slave_names_to_remove   --allow_leave_failed --i_am_sure')}
    end
  end

  context 'when tb_names_to_replace exists' do
    let :params do
      default_params.merge({ :tb_names_to_replace => 'tb_names' })
    end
    it 'replace cluster nodes' do
        is_expected.to contain_scaleio__cmd('replace cluster nodes    --remove_tb_name tb_names').with(
          :action => 'replace_cluster_mdm',
          :extra_opts => '   --remove_tb_name tb_names --allow_leave_failed --i_am_sure')
    end
    it { is_expected.to contain_exec('scli  --approve_certificate --replace_cluster_mdm       --remove_tb_name tb_names --allow_leave_failed --i_am_sure').with(
        :command => 'scli  --approve_certificate --replace_cluster_mdm       --remove_tb_name tb_names --allow_leave_failed --i_am_sure',
        :path => ['/bin/'])}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --replace_cluster_mdm       --remove_tb_name tb_names --allow_leave_failed --i_am_sure')}
    context 'add tie-breakers' do
      let :params do
        default_params.merge({ :tb_names_to_replace => 'tb_names_to_remove', :tb_names => 'tb_names_to_add' })
      end
      it 'replace cluster nodes' do
        is_expected.to contain_scaleio__cmd('replace cluster nodes   --add_tb_name tb_names_to_add --remove_tb_name tb_names_to_remove').with(
          :action => 'replace_cluster_mdm',
          :extra_opts => '  --add_tb_name tb_names_to_add --remove_tb_name tb_names_to_remove --allow_leave_failed --i_am_sure')
      end
      it { is_expected.to contain_exec('scli  --approve_certificate --replace_cluster_mdm      --add_tb_name tb_names_to_add --remove_tb_name tb_names_to_remove --allow_leave_failed --i_am_sure').with(
        :command => 'scli  --approve_certificate --replace_cluster_mdm      --add_tb_name tb_names_to_add --remove_tb_name tb_names_to_remove --allow_leave_failed --i_am_sure',
        :path => ['/bin/'])}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --replace_cluster_mdm      --add_tb_name tb_names_to_add --remove_tb_name tb_names_to_remove --allow_leave_failed --i_am_sure')}
    end
  end

  context 'when high perfomance is configured' do
    let :params do
      default_params.merge({ :performance_profile => 'high_perfomance' })
    end
    it { is_expected.to contain_exec('Apply high_performance profile for all').with(
      :command => 'scli  --set_performance_parameters --all_sdc --all_sds --apply_to_mdm --profile high_perfomance',
      :path    => '/bin:/usr/bin')}
  end

  context 'when capacity alert thresholds are configured' do
    let :params do
      default_params.merge({ :capacity_high_alert_threshold => '40', :capacity_critical_alert_threshold => '50'})
    end
    it { is_expected.to contain_exec('Set capacity allert thresholds').with(
      :command => 'scli  --set_capacity_alerts_threshold --capacity_high_threshold 40 --capacity_critical_threshold 50 --all_storage_pools --system_default',
      :path    => '/bin:/usr/bin')}
  end

  context 'when client password is configured' do
    let :params do
      default_params.merge({ :client_password => 'client_password' })
    end
    $user = 'scaleio_client'
    it { is_expected.to contain_file('/root/create_client_user.sh').with(
      :ensure => 'present',
      :source => 'puppet:///modules/scaleio/create_client_user.sh',
      :mode   => '0700',
      :owner  => 'root',
      :group  => 'root')}
    it { is_expected.to contain_exec('create_client_user').with(
      :unless  => 'scli  --query_user --username scaleio_client',
      :command => '/root/create_client_user.sh scaleio_client client_password ',
      :path    => '/bin:/usr/bin')}
  end
end
