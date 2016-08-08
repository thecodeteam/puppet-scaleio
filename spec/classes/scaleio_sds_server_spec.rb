require 'spec_helper'

describe 'scaleio::sds_server' do
  let(:facts) {{
    :osfamily => 'Debian'
  }}

  it { is_expected.to contain_class('scaleio::sds_server') }

  it '001 open port 7072 for sds' do
    is_expected.to contain_firewall('001 Open Port 7072 for ScaleIO SDS').with(
      :dport   => '7072',
      :proto  => 'tcp',
      :action => 'accept',)
  end
  it 'ensures utilities' do
    is_expected.to contain_package('numactl').with_ensure('installed')
    is_expected.to contain_package('libaio1').with_ensure('installed')
  end
  it 'installs sds package' do
    is_expected.to contain_package('emc-scaleio-sds').with_ensure('present')
  end
end
