require 'spec_helper'

describe 'scaleio::package' do
  let (:title) { 'gateway' }
  let :default_params do
  {
    :pkg_ftp => 'pkg_ftp' }
  end

  let (:facts) {{ :osfamily => 'Debian' }}
  let (:params) { default_params }
    it { is_expected.to contain_scaleio__package(title)}


  context 'ensure is absent' do
    let :params do
      default_params.merge(:ensure => 'absent')
    end
    it 'not contain packages' do
      is_expected.not_to contain_scaleio__package('emc-scaleio-gateway')
    end
  end

  context 'ensure is present' do
    let :params do
      default_params.merge(:ensure => 'present')
    end

    it { is_expected.to contain_file('ensure get_package.sh for gateway').with(
      :ensure => 'present',
      :path   => '/root/get_package_gateway.sh',
      :source => 'puppet:///modules/scaleio/get_package.sh',
      :mode   => '0700',
      :owner  => 'root',
      :group  => 'root')}
    it { is_expected.to contain_exec('get_package gateway').with(
      :command => '/root/get_package_gateway.sh pkg_ftp/Ubuntu gateway',
      :path    => '/bin:/usr/bin')}
    it { is_expected.to contain_package('emc-scaleio-gateway').with(
      :ensure   => 'present',
      :source   => '/tmp/gateway/gateway.deb',
      :provider => 'dpkg')}
  end
end
