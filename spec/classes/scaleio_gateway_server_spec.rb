require 'spec_helper'

describe 'scaleio::gateway_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}
  let :default_params do
  {
    :password     => '123',
    :port         => '4443',
    :im_port      => '8081',
    :ensure       => 'present'
  }
  end

  it {is_expected.to contain_class('scaleio::gateway_server')}

  context 'ensure is present' do

    it 'contains firewall' do
      is_expected.to contain_firewall('001 for ScaleIO Gateway').with(
        :dport  => '["4443", "8081"]',
        :proto  => 'tcp',
        :action => 'accept')
    end
    it 'installs utilities' do
      is_expected.to contain_package('numactl').with_ensure('installed')
      is_expected.to contain_package('libaio1').with_ensure('installed')
    end
    it 'runs java8 repo' do
      is_expected.to contain_exec('add java8 repo').with(
         :command => 'add-apt-repository ppa:webupd8team/java && apt-get update')
    end
    it 'java license accepting step 1' do
      is_expected.to contain_exec('java license accepting step 1').with(
        :command     => 'echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections')
    end
    it 'java license accepting step 2' do
      is_expected.to contain_exec('java license accepting step 2').with(
        :command     => 'echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections')
    end
    it 'installs utilities' do
      is_expected.to contain_package('oracle-java8-installer').with_ensure('installed')
      is_expected.to contain_package('emc-scaleio-gateway').with_ensure('installed')
    end
    it 'sets security bypass' do
      is_expected.to contain_file_line('Set security bypass').with(
        :line    => "security.bypass_certificate_check=true",
        :path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        :match   => '^security.bypass_certificate_check=')
    end
    it 'sets gateway port' do
      is_expected.to contain_file_line('Set gateway port').with(
        :line    => "ssl.port=4443",
        :path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
        :match   => "^ssl.port=")
    end
    it 'sets IM web-app port' do
      is_expected.to contain_file_line('Set IM web-app port').with(
        :ensure  => 'present',
        :line    => 'http.port=8081',
        :path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
        :match   => '^http.port=')
    end
    it 'runs service' do
      is_expected.to contain_service('scaleio-gateway').with_ensure('running')
    end

    context 'defined mdm_ip' do

      let :params do
        {:mdm_ips => '1.2.3.4,1.2.3.5'}
      end
      it 'connect to mdm' do
        is_expected.to contain_file_line('Set MDM IP addresses').with(
          :line    => "mdm.ip.addresses=1.2.3.4;1.2.3.5",
          :path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
          :match   => '^mdm.ip.addresses=.*',
          :ensure  => 'present',
          :require => 'Package[emc-scaleio-gateway]',
          :notify  => 'Service[scaleio-gateway]')
      end
    end

    context 'undefined mdm_ip' do

      let :params do
        {:mdm_ips => ''}
      end

      it 'doesnot connect to mdm' do
        should_not contain_file_line('Set MDM IP addresses')
      end
    end
    context 'defined password' do
      let :params do
        {:password => 'password'}
      end

      it 'connect to mdm' do
        is_expected.to contain_exec('Set gateway admin password').with(
          :command => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password 'password' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
          :path => '/etc/alternatives')
      end
    end

    context 'undefined password' do
      let :params do
        {:password => ''}
      end
      it 'doesnot connect to mdm' do
        is_expected.not_to contain_exex('Set gateway admin password')
      end
    end
  end
  context 'ensure is absent' do

    let :params do
      { :ensure   => 'absent' }
    end

    it 'doesnt contains anything' do
      is_expected.to contain_package('emc-scaleio-gateway').with_ensure('absent')
    end
  end
end
