require 'spec_helper'

describe 'scaleio' do
  it { is_expected.to contain_class('scaleio') }
end