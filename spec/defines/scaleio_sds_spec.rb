require 'spec_helper'

describe 'scaleio::sds' do

  let (:title) { 'title' }
  let :default_params do {
    :name => 'name',
    :ensure => 'present',
    :ensure_properties => 'present',  # present|absent - Add or remove SDS properties
    :protection_domain  => 'domain',
  }
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__sds(title).with_name('name') }

  context 'when ensure is absent' do
    let :params do
      default_params.merge(:ensure => 'absent')
    end
    it { is_expected.to contain_scaleio__cmd('$ensure').with(
      :action => 'absent',
      :entity => 'sds',
      :value => 'name',)}
    it { is_expected.to contain_exec('scli  --approve_certificate --remove_sds --sds_name name   ').with(
      :command => 'scli  --approve_certificate --remove_sds --sds_name name   ',
      :path => '/bin/',)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds --sds_name name   ')}
  end

  describe 'ensure is present' do
    let (:params) { default_params }
    context 'when options arent defined' do
      it 'SDS present' do
        is_expected.to contain_scaleio__cmd('SDS title present').with(
          :action => 'present',
          :entity => 'sds',
          :value => 'name',
          :scope_entity => 'protection_domain',
          :scope_value => 'domain',
          :extra_opts => "--sds_ip      ")
      end
      it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ').with(
        :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ',
        :path => '/bin/',
        :unless => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ')}
      it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')}
    end

    context 'when options are defined' do
      let :params do
        default_params.merge(
          :port => '4332',
          :ip_roles => 'ip_role',
          :storage_pools => 'storage_pool',
          :device_paths => '/device/path',
          :fault_set => 'fault_set'
        )
      end
      it { is_expected.to contain_scaleio__cmd('SDS title present').with(
        :action => 'present',
        :entity => 'sds',
        :value => 'name',
        :scope_entity => 'protection_domain',
        :scope_value => 'domain',
        :extra_opts => "--sds_ip  --sds_port 4332 --sds_ip_role ip_role --storage_pool_name storage_pool --device_path /device/path --fault_set_name fault_set")}
      it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip  --sds_port 4332 --sds_ip_role ip_role --storage_pool_name storage_pool --device_path /device/path --fault_set_name fault_set').with(
        :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip  --sds_port 4332 --sds_ip_role ip_role --storage_pool_name storage_pool --device_path /device/path --fault_set_name fault_set',
        :path => '/bin/',
        :unless => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')}
      it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip  --sds_port 4332 --sds_ip_role ip_role --storage_pool_name storage_pool --device_path /device/path --fault_set_name fault_set')}
    end

    context 'when ips are defined' do
      let :params do
        default_params.merge( { :ips => '1.2.3.4,1.2.3.5' } )
      end
      context 'when ensure_properties is present' do

        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5     ').with(
          :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5     ',
          :path => '/bin/',)}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5     ')}

        it 'SDS present first IP' do
          is_expected.to contain_scaleio__cmd('1.2.3.4,name1').with(
            :action => 'add_sds_ip',
            :scope_entity => 'sds',
            :scope_value => 'name',
            :ref => 'new_sds_ip',
            :value_in_title => true,
            :unless_query => 'query_sds --sds_ip',
          )
        end
        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ').with(
          :command => 'scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ',
          :path => '/bin/',
          :unless => 'scli  --approve_certificate  --query_sds --sds_ip 1.2.3.4')}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ')}
        it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_ip 1.2.3.4')}

        it 'SDS present second IP' do
          is_expected.to contain_scaleio__cmd('1.2.3.5,name1').with(
            :action => 'add_sds_ip',
            :scope_entity => 'sds',
            :scope_value => 'name',)
        end
        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ').with(
          :command => 'scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ',
          :path => '/bin/',
          :unless => 'scli  --approve_certificate  --query_sds --sds_ip 1.2.3.5')}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ')}
        it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_ip 1.2.3.5')}

        context 'with ip_roles' do
          let :params do
            default_params.merge(
              :ip_roles => 'role1,role2',
              :ips => '1.2.3.4')
          end

          it { is_expected.to contain_scaleio__cmd('1.2.3.4,name2').with(
            :action => 'modify_sds_ip_role',
            :scope_entity => 'sds',
            :scope_value => 'name',
            :ref => 'sds_ip_to_modify',
            :value_in_title => true,
            :paired_ref => 'new_sds_ip_role',
          )}

          it { is_expected.to contain_exec('scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name  ').with(
            :command => 'scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name  ',
            :path => '/bin/',)}
          it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name  ')}

          it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4  --sds_ip_role role1,role2   ').with(
            :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4  --sds_ip_role role1,role2   ',
            :path => '/bin/',)}
          it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4  --sds_ip_role role1,role2   ')}

        end
      end
      context 'with ensure_properties is absent' do
        let :params do
          default_params.merge(:ensure_properties => 'absent', :ips => '1.2.3.4')
        end

        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4     ').with(
          :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4     ',
          :path => '/bin/',)}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4     ')}

        it { is_expected.to contain_scaleio__cmd('1.2.3.4,name3').with(
          :action => 'remove_sds_ip',
          :ref => 'sds_ip_to_remove',
          :value_in_title => true,
          :scope_entity => 'sds',
          :scope_value => 'name',
        )}
        it { is_expected.to contain_exec('scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.4 --sds_name name  ').with(
          :command => 'scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.4 --sds_name name  ',
          :path => '/bin/',)}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.4 --sds_name name  ')}
      end
    end

    context 'when device_paths are defined' do
      let :params do
        default_params.merge(:device_paths => '/device/path1, device/path2')
      end
      context 'with ensure_properties present' do
        let :params do
          default_params.merge(:ensure_properties => 'present', :device_paths => '/device/path')
        end
        it { is_expected.to contain_scaleio__cmd('/device/path,name4').with(
          :action => 'add_sds_device',
          :ref => 'device_path',
          :value_in_title => true,
          :scope_entity => 'sds',
          :scope_value => 'name',
          :paired_ref => 'storage_pool_name',
          :paired_hash => '{"/device/path"=>nil}',
          :unless_query => "query_sds --sds_name name | grep",
        )}

        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds_device --device_path /device/path --sds_name name  ').with(
          :command => 'scli  --approve_certificate --add_sds_device --device_path /device/path --sds_name name  ',
          :path => '/bin/',
          :unless => 'scli  --approve_certificate  --query_sds --sds_name name | grep /device/path')}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_device --device_path /device/path --sds_name name  ')}
        it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name | grep /device/path')}

        it { is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip     --device_path /device/path ').with(
          :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip     --device_path /device/path ',
          :path => '/bin/',)}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip     --device_path /device/path ')}
      end

      context 'with ensure_properties absent' do
        let :params do
          default_params.merge(:ensure_properties => 'absent', :device_paths => '/device/path')
        end

        it { is_expected.to contain_scaleio__cmd('/device/path,name5').with(
          :action => 'remove_sds_device',
          :ref => 'device_path',
          :value_in_title => true,
          :scope_entity => 'sds',
          :scope_value => 'name',
        )}
        it { is_expected.to contain_exec('scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ').with(
          :command => 'scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ',
          :path => '/bin/',)}
        it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ')}
      end
    end
  end
end