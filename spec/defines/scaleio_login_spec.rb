require 'spec_helper'

describe 'scaleio::login' do

  let (:title) { 'title' }
  let (:params) {{ :password => 'password' }}

  it { is_expected.to contain_scaleio__login(title) }

  it do
    is_expected.to contain_scaleio__cmd('title login').with(
      'action' =>'login', 
      'ref' =>'password',
      'value' => 'password',
      'scope_ref' =>'username', 
      'scope_value' =>'admin',)
  end
  it do
    is_expected.to contain_exec('scli  --approve_certificate --login --password password --username admin  ').with(
      :command => 'scli  --approve_certificate --login --password password --username admin  ',
      :path => '/bin/')
  end
  it do
    is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --login --password password --username admin  ')
  end
end
