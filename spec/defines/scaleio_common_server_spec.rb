require 'spec_helper'

describe 'scaleio::common_server' do

  let (:title) { 'title' }

  context 'on RedHat' do
    let (:facts) {{ :osfamily => 'RedHat' }}
    let (:params) {{ :ensure_java => '' }}

    it { is_expected.to contain_scaleio__common_server('title')}
    it { is_expected.to contain_package('libaio').with(
      :ensure => 'installed')}
    it { is_expected.to contain_package('numactl').with(
      :ensure => 'installed')}
    it { is_expected.to contain_package('wget').with(
      :ensure => 'installed')}

    context 'when ensure_java is present' do
    let (:params) {{ :ensure_java => 'present' }}
      it { is_expected.to contain_package('java-1.8.0-openjdk').with(
        :ensure  => 'installed')}
    end
  end
  context 'on Debian' do
    let (:facts) {{ :osfamily => 'Debian' }}
    let (:params) {{ :ensure_java => '' }}

    it { is_expected.to contain_scaleio__common_server('title')}
    it { is_expected.to contain_package('libaio1').with(
      :ensure => 'installed')}
    it { is_expected.to contain_package('numactl').with(
      :ensure => 'installed')}
    it { is_expected.to contain_package('wget').with(
      :ensure => 'installed')}

    context 'when ensure_java is present' do
    let (:params) {{ :ensure_java => 'present' }}
      it { is_expected.to contain_package('oracle-java8-installer').with(
        :ensure  => 'installed')}
      it { is_expected.to contain_exec('add java8 repo').with(
        :command => 'add-apt-repository ppa:webupd8team/java && apt-get update')}
      it { is_expected.to contain_exec('java license accepting step 1').with(
        :command => 'echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections')}
      it { is_expected.to contain_exec('java license accepting step 2').with(
        :command => 'echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections')}
    end
  end

  context 'on Debian' do
    let (:facts) {{ :osfamily => 'Faux' }}
    it { should raise_error(Puppet::Error, /Unsupported OS family: Faux/)}
  end
end
