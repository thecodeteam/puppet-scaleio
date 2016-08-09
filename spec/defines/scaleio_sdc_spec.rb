require 'spec_helper'

describe 'scaleio::sdc' do

  let (:title) { 'title' }
  let (:default_params) {{ :ip => '1.2.3.4' }}
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__sdc(title).with_ip('1.2.3.4') }

  context 'ensure is absent' do
    let (:params) { default_params.merge(:ensure => 'absent')}
    it 'removes sdc' do
      is_expected.to contain_scaleio__cmd('SDC 1.2.3.4 absent').with(
        :action => 'remove_sdc',
        :ref => 'sdc_ip',
        :value => '1.2.3.4',
        :extra_opts => '--i_am_sure')
    end
    it do
      is_expected.to contain_exec('scli  --approve_certificate --remove_sdc --sdc_ip 1.2.3.4   --i_am_sure').with(
        :command => 'scli  --approve_certificate --remove_sdc --sdc_ip 1.2.3.4   --i_am_sure',
        :path => ['/bin/'],)
    end
    it do
      is_expected.to contain_notify('SCLI COMMAND: scli  --approve_certificate --remove_sdc --sdc_ip 1.2.3.4   --i_am_sure')
    end
  end

  context 'ensure is present' do
    let (:params) { default_params.merge(:ensure => 'present')}
    it { is_expected.to contain_exec("Apply high_performance profile for SDC 1.2.3.4").with(
      :command => 'scli  --set_performance_parameters --all_sdc --apply_to_mdm --profile high_performance',
      :path    => '/bin:/usr/bin')}

    it 'doesnt removes sdc' do
      is_expected.not_to contain_scaleio__cmd(:ensure)
    end
  end
end