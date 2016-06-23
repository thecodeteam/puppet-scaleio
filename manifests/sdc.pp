# SDC configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::sdc (
  $ip,                                        # string - IP to specify SDC in cluster
  $ensure               = 'present',          # present|absent - 'absent' removes SDC from cluster
  $performance_profile  = 'high_performance', # performance profile for SDC: default or high_performance
  )
{
  if $ensure == 'absent' {
    cmd {"SDC ${ip} ${ensure}":
      action      => 'remove_sdc',
      ref         => 'sdc_ip',
      value       => $ip,
      extra_opts  => '--i_am_sure'}
  } else {
    #Apply profile high_performance
    $mdm_opts = $::mdm_ips ? {
      undef   => '',
      default => "--mdm_ip ${::mdm_ips}"}
    exec { "Apply high_performance profile for SDC ${ip}":
      command   => "scli ${mdm_opts} --set_performance_parameters --all_sdc --apply_to_mdm --profile ${performance_profile}",
      path      => '/bin:/usr/bin',
    }
  }
}
