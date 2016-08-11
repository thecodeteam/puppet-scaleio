require 'spec_helper'

describe 'scaleio::storage_pool' do

  let (:title) { 'title' }
  let :default_params do {
    :sio_name => 'name',
    :ensure => 'present',  # present|absent - Add or remove storage pool
    :protection_domain => 'domain',
    :scanner_mode => 'disable',  # 'device_only'|'data_comparison'|'disable'
    :rfcache_usage => 'dont_use'
    }
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__storage_pool(title) }

  it 'present' do
    is_expected.to contain_scaleio__cmd('storage pool domain:name present').with(
      :action => 'present',
      :entity => 'storage_pool',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain')
  end
  it { is_expected.to contain_exec('scli  --approve_certificate --add_storage_pool --storage_pool_name name --protection_domain_name domain  ').with(
    :command => 'scli  --approve_certificate --add_storage_pool --storage_pool_name name --protection_domain_name domain  ',
    :path => ['/bin/'],
    :unless => 'scli  --approve_certificate  --query_storage_pool --storage_pool_name name --protection_domain_name domain')}
  it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_storage_pool --storage_pool_name name --protection_domain_name domain  ')}
  it { is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_storage_pool --storage_pool_name name --protection_domain_name domain')}

### Checks checksum_mode

  context 'with checksum_mode is enabled' do
    let (:params) { default_params.merge(:checksum_mode => 'enable')}

    it 'sets checksum mode' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_checksum_mode').with(
        :is_defined => 'enable',
        :change => "--enable_checksum")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_checksum_mode').with(
      :action => 'set_checksum_mode',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--enable_checksum")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --enable_checksum').with(
      :command => 'scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --enable_checksum',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --enable_checksum')}
  end
  context 'with checksum_mode is disabled' do
    let (:params) { default_params.merge(:checksum_mode => 'disable')}
    it 'sets checksum mode' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_checksum_mode').with(
        :is_defined => 'disable',
        :change => "--disable_checksum")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_checksum_mode').with(
      :action => 'set_checksum_mode',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--disable_checksum")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --disable_checksum').with(
      :command => 'scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --disable_checksum',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_checksum_mode --storage_pool_name name --protection_domain_name domain  --disable_checksum')}
  end

### Checks zero_padding_policy

  context 'with zero_padding_policy is enabled' do
    let (:params) { default_params.merge(:zero_padding_policy => 'enable')}

    it 'modifies zero_padding policy' do
      is_expected.to contain_scaleio__set('storage pool domain:name modify_zero_padding_policy').with(
        :is_defined => 'enable',
        :change => "--enable_zero_padding")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name modify_zero_padding_policy').with(
      :action => 'modify_zero_padding_policy',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--enable_zero_padding")}
    it { is_expected.to contain_exec('scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --enable_zero_padding').with(
      :command => 'scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --enable_zero_padding',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --enable_zero_padding')}
    it { is_expected.to contain_notify("SCLI UNLESS: scli  --approve_certificate --query_storage_pool --protection_domain_name domain --storage_pool_name name | grep -B 1000 'Zero padding is enable' | grep -q  name ")}
  end
  context 'with zero_padding_policy is disabled' do
    let (:params) { default_params.merge(:zero_padding_policy => 'disable')}
    it 'modifies zero_padding policy' do
      is_expected.to contain_scaleio__set('storage pool domain:name modify_zero_padding_policy').with(
        :is_defined => 'disable',
        :change => "--disable_zero_padding")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name modify_zero_padding_policy').with(
      :action => 'modify_zero_padding_policy',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--disable_zero_padding")}
    it { is_expected.to contain_exec('scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --disable_zero_padding').with(
      :command => 'scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --disable_zero_padding',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_zero_padding_policy --storage_pool_name name --protection_domain_name domain  --disable_zero_padding')}
    it { is_expected.to contain_notify("SCLI UNLESS: scli  --approve_certificate --query_storage_pool --protection_domain_name domain --storage_pool_name name | grep -B 1000 'Zero padding is disable' | grep -q  name ")}
  end

### Checks rmcache_write_handling_mode

  context 'with rmcache_write_handling_mode is cached' do
    let (:params) { default_params.merge(:rmcache_write_handling_mode => 'cached')}

    it 'sets rmcache_write_handling_mode' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rmcache_write_handling_mode').with(
        :is_defined => 'cached',
        :change => "--rmcache_write_handling_mode cached --i_am_sure")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rmcache_write_handling_mode').with(
      :action => 'set_rmcache_write_handling_mode',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--rmcache_write_handling_mode cached --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode cached --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode cached --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode cached --i_am_sure')}
  end
  context 'with rmcache_write_handling_mode is passthrough' do
    let (:params) { default_params.merge(:rmcache_write_handling_mode => 'passthrough')}
    it 'sets rmcache_write_handling_mode' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rmcache_write_handling_mode').with(
        :is_defined => 'passthrough',
        :change => "--rmcache_write_handling_mode passthrough --i_am_sure")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rmcache_write_handling_mode').with(
      :action => 'set_rmcache_write_handling_mode',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--rmcache_write_handling_mode passthrough --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode passthrough --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode passthrough --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rmcache_write_handling_mode --storage_pool_name name --protection_domain_name domain  --rmcache_write_handling_mode passthrough --i_am_sure')}
  end

### Checks rmcache_usage

  context 'with rmcache_usage is used' do
    let (:params) { default_params.merge(:rmcache_usage => 'use')}

    it 'sets rmcache_usage' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rmcache_usage').with(
        :is_defined => 'use',
        :change => "--use_rmcache --i_am_sure")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rmcache_usage').with(
      :action => 'set_rmcache_usage',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--use_rmcache --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --use_rmcache --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --use_rmcache --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --use_rmcache --i_am_sure')}
  end
  context 'with rmcache_usage is dont_used' do
    let (:params) { default_params.merge(:rmcache_usage => 'dont_use')}
    it 'sets rmcache_usage' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rmcache_usage').with(
        :is_defined => 'dont_use',
        :change => "--dont_use_rmcache --i_am_sure")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rmcache_usage').with(
      :action => 'set_rmcache_usage',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--dont_use_rmcache --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rmcache --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rmcache --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rmcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rmcache --i_am_sure')}
  end

### Checks spare_policy

  context 'with spare_policy is defined' do
    let (:params) { default_params.merge(:spare_percentage => '10')}

    it 'modifies spare policy' do
      is_expected.to contain_scaleio__set('storage pool domain:name modify_spare_policy').with(
        :is_defined => '10',
        :change => "--spare_percentage 10 --i_am_sure")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name modify_spare_policy').with(
      :action => 'modify_spare_policy',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--spare_percentage 10 --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage 10 --i_am_sure').with(
      :command => 'scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage 10 --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage 10 --i_am_sure')}
  end
  context 'with spare_policy is undefined' do
    it 'modifies spare policy' do
      is_expected.to contain_scaleio__set('storage pool domain:name modify_spare_policy').with(
        :is_defined => nil,
        :change => "--spare_percentage  --i_am_sure")
    end
    it { is_expected.not_to contain_scaleio__cmd('storage pool domain:name modify_spare_policy')}
    it { is_expected.not_to contain_exec('scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage disable')}
    it { is_expected.not_to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage disable')}
  end
  context 'with spare_policy is string' do
    let (:params) { default_params.merge(:spare_percentage => 'disable')}
    it 'modifies spare policy' do
      is_expected.to contain_scaleio__set('storage pool domain:name modify_spare_policy').with(
        :is_defined => 'disable',
        :change => "--spare_percentage disable --i_am_sure")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name modify_spare_policy').with(
      :action => 'modify_spare_policy',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--spare_percentage disable --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage disable --i_am_sure').with(
      :command => 'scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage disable --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --modify_spare_policy --storage_pool_name name --protection_domain_name domain  --spare_percentage disable --i_am_sure')}
  end

### Checks background_device_scanner

  context 'with scanner_mode is disabled' do
    it 'sets disable_background_device_scanner' do
      is_expected.to contain_scaleio__set('storage pool domain:name disable_background_device_scanner').with(
        :is_defined => 'disable',
        :change => ' ')
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name disable_background_device_scanner').with(
      :action => 'disable_background_device_scanner',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => " ")}
    it { is_expected.to contain_exec('scli  --approve_certificate --disable_background_device_scanner --storage_pool_name name --protection_domain_name domain   ').with(
      :command => 'scli  --approve_certificate --disable_background_device_scanner --storage_pool_name name --protection_domain_name domain   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --disable_background_device_scanner --storage_pool_name name --protection_domain_name domain   ')}
  end

  context 'with scanner_mode is device_only' do
    let (:params) { default_params.merge(:scanner_mode => 'device_only')}

    it 'sets device_only_background_device_scanner' do
      is_expected.to contain_scaleio__set('storage pool domain:name device_only_background_device_scanner').with(
        :is_defined => 'device_only',
        :change => " ")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name device_only_background_device_scanner').with(
      :action => 'device_only_background_device_scanner',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => " ")}
    it { is_expected.to contain_exec('scli  --approve_certificate --device_only_background_device_scanner --storage_pool_name name --protection_domain_name domain   ').with(
      :command => 'scli  --approve_certificate --device_only_background_device_scanner --storage_pool_name name --protection_domain_name domain   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --device_only_background_device_scanner --storage_pool_name name --protection_domain_name domain   ')}
  end

  context 'with scanner_mode is data_comparison' do
    let (:params) { default_params.merge(:scanner_mode => 'data_comparison')}

    it 'sets data_comparision_background_device_scanner' do
      is_expected.to contain_scaleio__set('storage pool domain:name data_comparison_background_device_scanner').with(
        :is_defined => 'data_comparison',
        :change => " ")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name data_comparison_background_device_scanner').with(
      :action => 'data_comparison_background_device_scanner',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => " ")}
    it { is_expected.to contain_exec('scli  --approve_certificate --data_comparison_background_device_scanner --storage_pool_name name --protection_domain_name domain   ').with(
      :command => 'scli  --approve_certificate --data_comparison_background_device_scanner --storage_pool_name name --protection_domain_name domain   ',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --data_comparison_background_device_scanner --storage_pool_name name --protection_domain_name domain   ')}
  end

### Checks rfcache_usage

  context 'with rfcache_usage is dont_used' do
    it 'sets rfcache_usage' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rfcache_usage').with(
        :is_defined => 'dont_use',
        :change => "--dont_use_rfcache --i_am_sure")
    end
    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rfcache_usage').with(
      :action => 'set_rfcache_usage',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--dont_use_rfcache --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rfcache --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rfcache --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --dont_use_rfcache --i_am_sure')}
  end

  context 'with rfcache_usage is used' do
    let (:params) { default_params.merge(:rfcache_usage => 'use')}

    it 'sets rfcache_usage' do
      is_expected.to contain_scaleio__set('storage pool domain:name set_rfcache_usage').with(
        :is_defined => 'use',
        :change => "--use_rfcache --i_am_sure")
    end

    it { is_expected.to contain_scaleio__cmd('storage pool domain:name set_rfcache_usage').with(
      :action => 'set_rfcache_usage',
      :ref => 'storage_pool_name',
      :value => 'name',
      :scope_entity => 'protection_domain',
      :scope_value => 'domain',
      :extra_opts => "--use_rfcache --i_am_sure")}
    it { is_expected.to contain_exec('scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --use_rfcache --i_am_sure').with(
      :command => 'scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --use_rfcache --i_am_sure',
      :path => ['/bin/'],)}
    it { is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --set_rfcache_usage --storage_pool_name name --protection_domain_name domain  --use_rfcache --i_am_sure')}
  end

end
