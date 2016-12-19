# == Class: osmco
#
# A module to manage the open source version of MCO
#
class osmco(
  # Class parameters are populated from module hiera data
  String $stomp_version,
  String $bin_path,
  String $mco_config_path,
  String $pa_config_path,
  String $mco_config_file_name,
  String $mco_config_file_path    = "${mco_config_path}/${mco_config_file_name}",
  String $run_path,
  String $pid_file_path           = "${run_path}/mcollective.pid",
  String $mcollectived_path       = "${bin_path}/mcollectived",
  String $plugins_path,
  String $pa_bin_path,
  String $lib_path,
  String $ssl_path                = "${mco_config_path}/ssl",
  String $mco_public_key_name,
  String $mco_public_key_name,
  #String $peadmin_public_key_name,
  String $mco_private_key_path    = "${mco_config_path}/${mco_private_key_name}",
  String $mco_public_key_path     = "${mco_config_path}/${mco_public_key_name}",
  String $ssl_client_key_path     = "${ssl_path}/clients",
  #String $peadmin_public_key_path = "${ssl_client_key_path}/${peadmin_public_key_name}",

  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $activemq_passwd         = "",
  String $mco_public_key          = "",
  String $mco_private_key         = "",
  String $peadmin_public_key      = "",
) {

  $mcollective_control_file = @(END)
[Unit]
Description=The Marionette Collective
After=network.target

[Service]
Type=forking
StandardOutput=syslog
StandardError=syslog
ExecStart=<%= $mcollectived_path %> --config=<%= $mco_config_file_path %> --pidfile=<%= $pid_file_path %> --daemonize
ExecReload=/bin/kill -USR1 $MAINPID
PIDFile=<%= $pid_file_path %>

[Install]
WantedBy=multi-user.target
END

  file { $lib_path:
    ensure                                           => directory,
  } ->
  package { 'stomp':
    ensure                                           => $stomp_version,
    provider                                         => 'gem',
  } ->
  file { "${bin_path}/mco":
    ensure                                           => file,
    mode                                             => '0755',
    source                                           => "puppet:///modules/osmco/bin/mco",
  } ->
  file { "${bin_path}/mcollectived":
    ensure                                           => file,
    mode                                             => '0755',
    source                                           => "puppet:///modules/osmco/bin/mcollectived",
  } ->
  file { "$lib_path/mcollective.rb":
    ensure                                           => file,
    mode                                             => '0644',
    source                                           => "puppet:///modules/osmco/lib/mcollective.rb",
  } ->
  file { "$lib_path/mcollective":
    ensure                                           => directory,
    force                                            => true,
    purge                                            => true,
    recurse                                          => true,
    source                                           => "puppet:///modules/osmco/lib/mcollective",
  } ->
  file { "$plugins_path/mcollective":
    ensure                                           => directory,
    force                                            => true,
    purge                                            => true,
    recurse                                          => true,
    source                                           => "puppet:///modules/osmco/plugins/",
  } ->
  file { $run_path:
    ensure                                           => directory,
  } ->
  file { $mco_config_path:
    ensure                                           => directory,
  } ->
  file { $mco_public_key_path:
    ensure                                           => file,
    mode                                             => '0644',
    content                                          => $mco_public_key,
  } ->
  file { $mco_private_key_path:
    ensure                                           => file,
    mode                                             => '0644',
    content                                          => $mco_private_key,
  } ->
  file { $peadmin_public_key_path:
    ensure                                           => file,
    mode                                             => '0644',
    content                                          => $peadmin_public_key,
  } ->
  file { $mco_config_file_path:
    ensure                                           => file,
    mode                                             => '0644',
    content                                          => epp("osmco/${mco_config_file_name}.epp",
      {
        plugins_path                                 => $plugins_path,
        activemq_passwd                              => $activemq_passwd,
        pa_bin_path                                  => $pa_bin_path,
        pa_config_path                               => $pa_config_path,
        mco_private_key_path                         => $mco_private_key_path,
        mco_public_key_path                          => $mco_public_key_path,
        ssl_client_key_path                          => $ssl_client_key_path,
      } ),
  } ->
  file { '/etc/systemd/system/mcollectived.service':
    ensure                                           => file,
    content                                          => inline_epp($mcollective_control_file,
      {
        mcollectived_path                            => $mcollectived_path,
        pid_file_path                                => $pid_file_path,
        mco_config_file_path                         => $mco_config_file_path,
      }),
  } ->
  exec { 'mcollectived systemctl daemon-reload':
    command                                          => 'systemctl daemon-reload',
    path                                             => ['/usr/bin', '/usr/sbin'],
    refreshonly                                      => true,
  } ->
  service { 'mcollectived':
    ensure                                           => running,
    enable                                           => true,
  }

}



