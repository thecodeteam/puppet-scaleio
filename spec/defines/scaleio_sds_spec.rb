require 'spec_helper'

describe 'scaleio::sds' do

  let (:title) { 'title' }
  let :default_params do {
    :sio_name => 'name',
    :ensure => 'absent',
    :ensure_properties => 'present',  # present|absent - Add or remove SDS properties
    :protection_domain  => 'domain',
  }
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__sds(title).with_sio_name('name') }

  context 'when pools_count != 0, device_paths_count == 0' do
    let :params do
      default_params.merge({
        :storage_pools => 'sp'})
    end
    it { should raise_error(Puppet::Error, /Either storage pools or device paths are not provided: pools_count=1, device_paths_count=0/)}
  end
  context 'when pools_count == 0, device_paths_count != 0' do
    let :params do
      default_params.merge({
        :device_paths => '/device/path'})
    end
    it { should raise_error(Puppet::Error, /Either storage pools or device paths are not provided: pools_count=0, device_paths_count=1/)}
  end
  context 'when pools_count != device_paths_count == 0' do
    let :params do
      default_params.merge({
        :storage_pools => 'sp1,sp2',
        :device_paths  => '/device/path'})
    end
    it { should raise_error(Puppet::Error,
                    /Number of storage pools should be either 1 or equal to number of storage devices: pools_count=2, device_paths_count=1/)}
  end
  context 'when ips_count != ip_roles_count == 0' do
    let :params do
      default_params.merge({
        :ips => '1.2.3.4,1.2.3.5',
        :ip_roles  => 'role'})
    end
    it { should raise_error(Puppet::Error,
                    /Number of ips should be equal to the number of ips roles: ips_count=2, ip_roles_count=1/)}
  end

  describe 'when ensure is absent' do
    let :params do
      default_params.merge(:ensure => 'absent')
    end
    it { is_expected.to contain_scaleio__cmd('SDS title absent').with(
      :action => 'absent',
      :entity => 'sds',
      :value => 'name',)}
    it { is_expected.to contain_exec('scli  --approve_certificate --remove_sds --sds_name name   ').with(
      :command => 'scli  --approve_certificate --remove_sds --sds_name name   ',
      :path => '/bin/',)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds --sds_name name   ')}
  end
  describe 'ensure is present' do
    let :default_params do {
      :sio_name => 'name',
      :ensure => 'present',
      :protection_domain  => 'domain'}
    end
    it { is_expected.to contain_exec('Apply high_performance profile for SDS title present').with(
      :command => 'scli  --set_performance_parameters --sds_name name --apply_to_mdm --profile high_performance',
      :path    => '/bin:/usr/bin',
    )}
    it do
      is_expected.to contain_scaleio__cmd('SDS title present').with(
        :action       => 'present',
        :entity       => 'sds',
        :value        => 'name',
        :scope_entity => 'protection_domain',
        :scope_value  => 'domain',
        :extra_opts   => "--sds_ip      ")
      is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ').with(
        :command   => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ',
        :path      => ['/bin/'],
        :unless    => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip      ')
      is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
    end

    context 'when ips are defined' do
      let :params do
        default_params.merge({
          :ips => '1.2.3.4,1.2.3.5',
          :ip_roles => 'role1,role2'})
      end
      it do
        is_expected.to contain_scaleio__cmd('SDS title present').with(
          :action       => 'present',
          :entity       => 'sds',
          :value        => 'name',
          :scope_entity => 'protection_domain',
          :scope_value  => 'domain',
          :extra_opts   => '--sds_ip 1.2.3.4,1.2.3.5  --sds_ip_role role1,role2   ')
        is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5  --sds_ip_role role1,role2   ').with(
          :command   => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5  --sds_ip_role role1,role2   ',
          :path      => ['/bin/'],
          :unless    => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
        is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.4,1.2.3.5  --sds_ip_role role1,role2   ')
        is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
      end


      context 'when ensure_properties is present' do
        it 'add first sds ip' do
          is_expected.to contain_scaleio__cmd('1.2.3.4,name1').with(
            :action         => 'add_sds_ip',
            :ref            => 'new_sds_ip',
            :value_in_title => true,
            :scope_entity   => 'sds',
            :scope_value    => 'name',
            :unless_query   => 'query_sds --sds_ip',
            :require        => 'Scaleio::Cmd[SDS title present]' )
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ').with(
            :command   => 'scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ',
            :path      => ['/bin/'],
            :unless    => 'scli  --approve_certificate --query_sds --sds_ip 1.2.3.4 ',
            :try_sleep => '5',)
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.4 --sds_name name  ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_ip 1.2.3.4 ')

          is_expected.to contain_scaleio__cmd('1.2.3.4,name2').with(
            :action => 'modify_sds_ip_role',
            :scope_entity => 'sds',
            :scope_value => 'name',
            :ref => 'sds_ip_to_modify',
            :value_in_title => true,
            :paired_ref => 'new_sds_ip_role',
            :paired_hash => {"1.2.3.4"=>"role1", "1.2.3.5"=>"role2"},
            :unless_query => 'query_sds --sds_name name | grep',
            :unless_query_ext      => ' | grep',
            :unless_query_ext_hash => {"all"=>"All", "sdc_only"=>"SDC Only", "sds_only"=>"SDS Only"},
            :require               => 'Scaleio::Cmd[SDS title present]')
          is_expected.to contain_exec('scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name --new_sds_ip_role role1 ').with(
            :command => 'scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name --new_sds_ip_role role1 ',
            :path => '/bin/',
            :unless    => "scli  --approve_certificate --query_sds --sds_name name | grep 1.2.3.4  | grep ''")
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.4 --sds_name name --new_sds_ip_role role1 ')
          is_expected.to contain_notify("SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep 1.2.3.4  | grep ''")
        end

        it 'add second sds ip' do
          is_expected.to contain_scaleio__cmd('1.2.3.5,name1').with(
            :action         => 'add_sds_ip',
            :ref            => 'new_sds_ip',
            :value_in_title => true,
            :scope_entity   => 'sds',
            :scope_value    => 'name',
            :unless_query   => 'query_sds --sds_ip',
            :require        => 'Scaleio::Cmd[SDS title present]' )
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ').with(
            :command   => 'scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ',
            :path      => ['/bin/'],
            :unless    => 'scli  --approve_certificate --query_sds --sds_ip 1.2.3.5 ',
            :try_sleep => '5',)
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_ip --new_sds_ip 1.2.3.5 --sds_name name  ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_ip 1.2.3.5 ')

          is_expected.to contain_scaleio__cmd('1.2.3.5,name2').with(
            :action => 'modify_sds_ip_role',
            :scope_entity => 'sds',
            :scope_value => 'name',
            :ref => 'sds_ip_to_modify',
            :value_in_title => true,
            :paired_ref => 'new_sds_ip_role',
            :paired_hash => {"1.2.3.4"=>"role1", "1.2.3.5"=>"role2"},
            :unless_query => 'query_sds --sds_name name | grep',
            :unless_query_ext      => ' | grep',
            :unless_query_ext_hash => {"all"=>"All", "sdc_only"=>"SDC Only", "sds_only"=>"SDS Only"},
            :require               => 'Scaleio::Cmd[SDS title present]')
          is_expected.to contain_exec('scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.5 --sds_name name --new_sds_ip_role role2 ').with(
            :command => 'scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.5 --sds_name name --new_sds_ip_role role2 ',
            :path => '/bin/',
            :unless    => "scli  --approve_certificate --query_sds --sds_name name | grep 1.2.3.5  | grep ''")
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_sds_ip_role --sds_ip_to_modify 1.2.3.5 --sds_name name --new_sds_ip_role role2 ')
          is_expected.to contain_notify("SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep 1.2.3.5  | grep ''")
        end
      end

      context 'with ensure_properties is absent' do
        let :params do
          default_params.merge(
            :ensure_properties => 'absent',
            :ips => '1.2.3.6',
            :ip_roles => 'role')
        end
        it 'removes sds ip' do
          is_expected.to contain_scaleio__cmd('1.2.3.6,name3').with(
            :action => 'remove_sds_ip',
            :ref => 'sds_ip_to_remove',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name')
          is_expected.to contain_exec('scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.6 --sds_name name  ').with(
            :command => 'scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.6 --sds_name name  ',
            :path => '/bin/')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds_ip --sds_ip_to_remove 1.2.3.6 --sds_name name  ')

          is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.6  --sds_ip_role role   ').with(
            :command => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.6  --sds_ip_role role   ',
            :path => '/bin/',)
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip 1.2.3.6  --sds_ip_role role   ')
        end
      end
    end

    context 'when device_paths are defined' do
      let :params do
        default_params.merge(:device_paths => '/device/path1,/device/path2', :storage_pools => 'sp1,sp2')
      end
      context 'with ensure_properties present' do
        it do
          is_expected.to contain_scaleio__cmd('SDS title present').with(
            :action       => 'present',
            :entity       => 'sds',
            :value        => 'name',
            :scope_entity => 'protection_domain',
            :scope_value  => 'domain',
            :extra_opts   => "--sds_ip    --storage_pool_name sp1,sp2 --device_path /device/path1,/device/path2 ")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp1,sp2 --device_path /device/path1,/device/path2 ').with(
            :command   => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp1,sp2 --device_path /device/path1,/device/path2 ',
            :path      => ['/bin/'],
            :unless    => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp1,sp2 --device_path /device/path1,/device/path2 ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
        end

        it 'adds first sds device' do
          is_expected.to contain_scaleio__cmd('/device/path1,name4').with(
            :action => 'add_sds_device',
            :ref => 'device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name',
            :paired_ref => 'storage_pool_name',
            :paired_hash => '{"/device/path1"=>"sp1", "/device/path2"=>"sp2"}',
            :unless_query => "query_sds --sds_name name | grep")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_device --device_path /device/path1 --sds_name name --storage_pool_name sp1 ').with(
            :command => 'scli  --approve_certificate --add_sds_device --device_path /device/path1 --sds_name name --storage_pool_name sp1 ',
            :path => '/bin/',
            :unless => 'scli  --approve_certificate --query_sds --sds_name name | grep /device/path1 ')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_device --device_path /device/path1 --sds_name name --storage_pool_name sp1 ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep /device/path1 ')
        end

        it 'adds second sds device' do
          is_expected.to contain_scaleio__cmd('/device/path2,name4').with(
            :action => 'add_sds_device',
            :ref => 'device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name',
            :paired_ref => 'storage_pool_name',
            :paired_hash => '{"/device/path1"=>"sp1", "/device/path2"=>"sp2"}',
            :unless_query => "query_sds --sds_name name | grep")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_device --device_path /device/path2 --sds_name name --storage_pool_name sp2 ').with(
            :command => 'scli  --approve_certificate --add_sds_device --device_path /device/path2 --sds_name name --storage_pool_name sp2 ',
            :path => '/bin/',
            :unless => 'scli  --approve_certificate --query_sds --sds_name name | grep /device/path2 ')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_device --device_path /device/path2 --sds_name name --storage_pool_name sp2 ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep /device/path2 ')
        end
      end

      context 'with ensure_properties absent' do
        let :params do
          default_params.merge(
            :device_paths => '/device/path',
            :storage_pools => 'sp',
            :ensure_properties => 'absent')
        end
        it do
          is_expected.to contain_scaleio__cmd('SDS title present').with(
            :action       => 'present',
            :entity       => 'sds',
            :value        => 'name',
            :scope_entity => 'protection_domain',
            :scope_value  => 'domain',
            :extra_opts   => "--sds_ip    --storage_pool_name sp --device_path /device/path ")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp --device_path /device/path ').with(
            :command   => 'scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp --device_path /device/path ',
            :path      => ['/bin/'],
            :unless    => 'scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds --sds_name name --protection_domain_name domain  --sds_ip    --storage_pool_name sp --device_path /device/path ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_sds --sds_name name --protection_domain_name domain')
        end

        it 'removes sds device' do
          is_expected.to contain_scaleio__cmd('/device/path,name5').with(
            :action => 'remove_sds_device',
            :ref => 'device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name')
          is_expected.to contain_exec('scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ').with(
            :command => 'scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ',
            :path => '/bin/')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds_device --device_path /device/path --sds_name name  ')
        end
      end
    end

    context 'when rfcache_devices are defined' do
      let :params do
        default_params.merge(:rfcache_devices => '/device/rfcache1,/device/rfcache2')
      end
      context 'with ensure_properties present' do
        it do
          is_expected.to contain_scaleio__cmd('sds name rfcache enable').with(
            :action       => 'enable_sds_rfcache',
            :scope_entity => 'sds',
            :scope_value  => 'name',
            :require      => 'Scaleio::Cmd[SDS title present]')
          is_expected.to contain_exec('scli  --approve_certificate --enable_sds_rfcache  --sds_name name  ').with(
            :command   => 'scli  --approve_certificate --enable_sds_rfcache  --sds_name name  ',
            :path      => ['/bin/'])
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --enable_sds_rfcache  --sds_name name  ')
        end
        it 'adds first rfcache device' do
          is_expected.to contain_scaleio__cmd('/device/rfcache1,name6').with(
            :action => 'add_sds_rfcache_device',
            :ref => 'rfcache_device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name',
            :unless_query => "query_sds --sds_name name | grep")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache1 --sds_name name  ').with(
            :command => 'scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache1 --sds_name name  ',
            :path => '/bin/',
            :unless => 'scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache1 ')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache1 --sds_name name  ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache1 ')
        end
        it 'adds second rfcache device' do
          is_expected.to contain_scaleio__cmd('/device/rfcache2,name6').with(
            :action => 'add_sds_rfcache_device',
            :ref => 'rfcache_device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name',
            :unless_query => "query_sds --sds_name name | grep")
          is_expected.to contain_exec('scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache2 --sds_name name  ').with(
            :command => 'scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache2 --sds_name name  ',
            :path => '/bin/',
            :unless => 'scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache2 ')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_sds_rfcache_device --rfcache_device_path /device/rfcache2 --sds_name name  ')
          is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache2 ')
        end
      end

      context 'with ensure_properties absent' do
        let :params do
          default_params.merge(
            :rfcache_devices => '/device/rfcache',
            :ensure_properties => 'absent')
        end
        it do
          is_expected.to contain_scaleio__cmd('sds name rfcache disable').with(
            :action       => 'disable_sds_rfcache',
            :scope_entity => 'sds',
            :scope_value  => 'name',
            :require      => 'Scaleio::Cmd[SDS title present]')
          is_expected.to contain_exec('scli  --approve_certificate --disable_sds_rfcache  --sds_name name  ').with(
            :command   => 'scli  --approve_certificate --disable_sds_rfcache  --sds_name name  ',
            :path      => ['/bin/'])
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --disable_sds_rfcache  --sds_name name  ')
        end

        it 'removes sds device' do
          is_expected.to contain_scaleio__cmd('/device/rfcache,name6').with(
            :action => 'remove_sds_rfcache_device',
            :ref => 'rfcache_device_path',
            :value_in_title => true,
            :scope_entity => 'sds',
            :scope_value => 'name',
            :onlyif_query   => 'query_sds --sds_name name | grep',
            :require        => 'Scaleio::Cmd[sds name rfcache disable]')
          is_expected.to contain_exec('scli  --approve_certificate --remove_sds_rfcache_device --rfcache_device_path /device/rfcache --sds_name name  ').with(
            :command => 'scli  --approve_certificate --remove_sds_rfcache_device --rfcache_device_path /device/rfcache --sds_name name  ',
            :path    => '/bin/',
            :onlyif  => 'scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache')
          is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sds_rfcache_device --rfcache_device_path /device/rfcache --sds_name name  ')
          is_expected.to contain_notify('SCLI ONLYIF: scli  --approve_certificate --query_sds --sds_name name | grep /device/rfcache')
        end
      end
    end
  end
end