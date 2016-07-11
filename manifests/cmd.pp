# Logic compiling scli command from parameters and invoking it.
# For actions "add" checks with "query" in unless if such entity exists.
# Accepts actions "present" and "absent" instead of "add" and "remove".
# Supports calling with arrays for values, in which case $value shouldn't
# be used, instead $value_in_title flag should be set.
# facter mdm_ips variable should be set to "ip1,ip2,...".

# Parameters:
# action              - Action like present|absent|add|remove|add_sds|...
#                       if entity specified it's added to --action_entity
# entity              - Entity for action like --action_entity --entity_name
# ref                 - Type of the reference for entity like --entity_ref
#                       or full reference if entity omitted.
# value               - Value for the entity like --action_entity
#                       --entity_ref value, or --action --ref value
# scope_entity        - Scope for the Entity like Protection domain for
#                       Storage pools - same rules as above.
# scope_ref           - Scope reference - same meaning as ref, only for scope
# scope_value         - Scope Value - same meaning as value, only for scope
# value_in_title      - Flag to use value from $title - pass it with true for
#                     - this instead of $value
# paired_ref          - For arrays of titles used as a ref for value in
#                       paired_hash like for --new_sds_ip_role
# paired_hash         - Hash of values for arrays of titles
# extra_opts          - String with any extra options like '--i_am_sure'
# unless_query        - Explicit unless like "query_sds --sds_name ${sio_name} |
#                       grep" without value at the end or implicit for add
#                       commands
# onlyif_query        - Explicit onlyif query without value at the end
# unless_query_ext    - Addition to unless query checking complex conditions
#                       with help of unless_hash values.
#                       Example: modify_sds_ip_role where we have to check
#                       that the ip isn't already in such role by double grep.
# unless_query_ext_hash Dictionary of values from paired_hash to strings to use
#                       in unless_query_suffix, 
#                       like {'sds_only'=>'SDS', 'sdc_only'=>'SDC',...}
# approve_certificate - approve certificate by default
# retry               - Number of retries

define scaleio::cmd(
  $action,
  $entity                 = undef,
  $ref                    = 'name',
  $value                  = undef,
  $scope_entity           = undef,
  $scope_ref              = 'name',
  $scope_value            = undef,
  $value_in_title         = undef,
  $paired_ref             = undef,
  $paired_hash            = {},
  $extra_opts             = '',
  $unless_query           = undef,
  $onlyif_query           = undef,
  $unless_query_ext       = undef,
  $unless_query_ext_hash  = {},
  $approve_certificate    = '--approve_certificate',
  $retry                  = undef,
  )
{
  # Command
  $cmd = $action ? {
    'present' => 'add',
    'absent'  => 'remove',
    default   => $action}
  $cmd_opt = $entity ? {
    undef   =>  "--${cmd}",
    default => "--${cmd}_${entity}"}
  # Taking title for value for array values. Split is used to extract ips from
  # resources because one different extra character per call allows to
  # differentiate them. In case of title parameters like 'parameter,suffix",
  # suffix is just for avoiding resource duplication.
  if $value_in_title {
    $val_ = split($title, ',')
    $val  = $val_[0]
  } else {
    $val = $value
  }
  # Main object parts
  $obj_ref = $entity ? {
    undef   =>  "--${ref}",
    default => "--${entity}_${ref}"}
  $obj_ref_opt = $val ? {
    undef   => '',
    default => "${obj_ref} ${val}"}
  # Scope object parts (e.g. protection_domain for fault_sets)
  $scope_obj_ref = $scope_entity ? {
    undef   =>  "--${scope_ref}",
    default => "--${scope_entity}_${scope_ref}"}
  $scope_obj_ref_opt = $scope_value ? {
    undef   => '',
    default => "${scope_obj_ref} ${scope_value}"}
  # Paired values for arrays of pairs (e.g., ips and roles for SDS)
  $paired_obj_value   = $paired_hash[$val]
  $paired_obj_ref_opt = $paired_obj_value ? {
    undef   => '',
    default => "--${paired_ref} ${paired_obj_value}"}
  # Unless query extension preparation (ugly stuff used only for modify_sds_ip_role because puppet 3.7 
  # doesn't support 'each' loops and because the only way to determine ip role is to parse human-readable output of scli)
  $unless_hash_val = $paired_obj_value ? {
    undef => '',
    default => $unless_query_ext_hash[$paired_obj_value]
  }
  $unless_query_ext_opt = $unless_query_ext ? {
    undef => '',
    default => "${unless_query_ext} '${unless_hash_val}'"
  }

  # Command compilation
  $mdm_opts = $::mdm_ips ? {
    undef   => '',
    default => "--mdm_ip ${::mdm_ips}"}
  $command = "scli ${mdm_opts} ${approve_certificate} ${cmd_opt} ${obj_ref_opt} ${scope_obj_ref_opt} ${paired_obj_ref_opt} ${extra_opts}"
  $unless_cmd = $cmd ? {
    'add' => "scli ${mdm_opts} ${approve_certificate}  --query_${entity} ${obj_ref_opt} ${scope_obj_ref_opt}",
    default => undef}
  # Custom unless query for addition is set - will check existense of the val to be added
  $unless_command = $unless_query ? {
    undef   => $unless_cmd,
    default => "scli ${mdm_opts} ${approve_certificate} --${unless_query} ${val} ${unless_query_ext_opt}"}
  $onlyif_command = $onlyif_query ? {
    undef   => undef,
    default => "scli ${mdm_opts} ${approve_certificate} --${onlyif_query} ${val}"}

  notify { "SCLI COMMAND: ${command}": }
  if $unless_command {
    notify { "SCLI UNLESS: ${unless_command}": }
  }
  if $onlyif_command {
    notify { "SCLI ONLYIF: ${onlyif_command}": }
  }
  exec { $command:
    command   => $command,
    path      => ['/bin/'],
    unless    => $unless_command,
    onlyif    => $onlyif_command,
    tries     => $retry,
    try_sleep => 5,
  }
}


