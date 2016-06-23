# Tests some spurious parameters
# Real parameters are tested in other defines

require 'spec_helper'

describe 'scaleio::cmd' do

  let (:title) { 'title' }
  let :default_params do {
    :action => 'present',
    :entity => 'entity',
    :ref => 'ref',
    :value => 'value',
    :scope_entity => 'scope_entity',
    :scope_ref => 'scope_ref',
    :scope_value => 'scope_value',
    :value_in_title => false,
    :paired_ref => 'paired_ref',
    :paired_hash => {},
    :extra_opts => 'extra_opts',
    :unless_query => 'unless_query',
    :approve_certificate => '--approve_certificate',}
  end
  let (:params) { default_params }
  it { is_expected.to contain_scaleio__cmd(title) }
  it { is_expected.to contain_notify("SCLI COMMAND: scli  --approve_certificate --add_entity --entity_ref value --scope_entity_scope_ref scope_value  extra_opts") }
  it { is_expected.to contain_notify("SCLI UNLESS: scli  --approve_certificate  --unless_query value") }
  it { is_expected.to contain_exec('scli  --approve_certificate --add_entity --entity_ref value --scope_entity_scope_ref scope_value  extra_opts').with(
    :command => 'scli  --approve_certificate --add_entity --entity_ref value --scope_entity_scope_ref scope_value  extra_opts',
    :path => '/bin/',
    :unless => "scli  --approve_certificate  --unless_query value",) }
end
