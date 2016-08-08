require 'spec_helper'

describe 'scaleio::protection_domain' do
  let (:title) { 'title' }
  let :default_params do
  {
    :sio_name => 'name',
    :ensure  => 'present',
    :ensure_properties  => 'present',
  }
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__protection_domain(title).with_sio_name('name') }

  it 'contains protection domain' do
    is_expected.to contain_scaleio__cmd('Protection domain title present').with(
      :action => 'present',
      :entity => 'protection_domain',
      :value => 'name')
  end
  it do
    is_expected.to contain_exec('scli  --approve_certificate --add_protection_domain --protection_domain_name name   ').with(
      :command => 'scli  --approve_certificate --add_protection_domain --protection_domain_name name   ',
      :path => ['/bin/'],
      :unless => 'scli  --approve_certificate  --query_protection_domain --protection_domain_name name ')
  end
  it do
    is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_protection_domain --protection_domain_name name   ')
  end
  it do
    is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_protection_domain --protection_domain_name name ')
  end

  context 'with fault sets' do
    let :params do
      default_params.merge(:fault_sets => ['a', 'b'])
    end
    it 'cmd fault sets resources' do
      is_expected.to contain_scaleio__cmd('a,1').with(
        :action => 'present',
        :entity => 'fault_set',
        :value_in_title => true,
        :scope_entity => 'protection_domain', 
        :scope_value => 'name')

      is_expected.to contain_scaleio__cmd('b,1').with(
        :action => 'present',
        :entity => 'fault_set',
        :value_in_title => true,
        :scope_entity => 'protection_domain',
        :scope_value => 'name')
    end
    it do
      is_expected.to contain_exec('scli  --approve_certificate --add_fault_set --fault_set_name a --protection_domain_name name  ').with(
        :command => 'scli  --approve_certificate --add_fault_set --fault_set_name a --protection_domain_name name  ',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate  --query_fault_set --fault_set_name a --protection_domain_name name')
      is_expected.to contain_exec('scli  --approve_certificate --add_fault_set --fault_set_name b --protection_domain_name name  ').with(
        :command => 'scli  --approve_certificate --add_fault_set --fault_set_name b --protection_domain_name name  ',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate  --query_fault_set --fault_set_name b --protection_domain_name name')
    end
    it do
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_fault_set --fault_set_name a --protection_domain_name name  ')
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_fault_set --fault_set_name b --protection_domain_name name  ')
    end
    it do
      is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_fault_set --fault_set_name a --protection_domain_name name')
      is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_fault_set --fault_set_name b --protection_domain_name name')
    end
  end

  context 'with storage pools' do
    let :params do
      default_params.merge(:storage_pools => ['aa','bb'])
    end
    it 'cmd storage pools' do
      is_expected.to contain_scaleio__cmd('aa,2').with(
        :action => 'present',
        :entity => 'storage_pool',
        :value_in_title => true,
        :scope_entity => 'protection_domain',
        :scope_value => 'name')
      is_expected.to contain_scaleio__cmd('bb,2').with(
        :action => 'present',
        :entity => 'storage_pool',
        :value_in_title => true,
        :scope_entity => 'protection_domain',
        :scope_value => 'name')
     end
    it do
      is_expected.to contain_exec('scli  --approve_certificate --add_storage_pool --storage_pool_name aa --protection_domain_name name  ').with(
        :command => 'scli  --approve_certificate --add_storage_pool --storage_pool_name aa --protection_domain_name name  ',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate  --query_storage_pool --storage_pool_name aa --protection_domain_name name')
      is_expected.to contain_exec('scli  --approve_certificate --add_storage_pool --storage_pool_name bb --protection_domain_name name  ').with(
        :command => 'scli  --approve_certificate --add_storage_pool --storage_pool_name bb --protection_domain_name name  ',
        :path => ['/bin/'],
        :unless => 'scli  --approve_certificate  --query_storage_pool --storage_pool_name bb --protection_domain_name name')
    end
    it do
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_storage_pool --storage_pool_name aa --protection_domain_name name  ')
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --add_storage_pool --storage_pool_name bb --protection_domain_name name  ')
     end
    it do
      is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_storage_pool --storage_pool_name aa --protection_domain_name name')
      is_expected.to contain_notify('SCLI UNLESS: scli  --approve_certificate  --query_storage_pool --storage_pool_name bb --protection_domain_name name')
    end
  end
end