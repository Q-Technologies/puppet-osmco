# == Class: osmco
#
# A module to manage the open source version of MCO
#
class osmco(
  # Class parameters are populated from module hiera data
  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $activemq_passwd = "",
) {
  $bin_path = "/usr/local/bin"
  if $facts[osfamily] == "Debian" {
    $lib_path = "/usr/local/lib/site_ruby"
  }
  else {
    $lib_path = "/usr/lib64/ruby/site_ruby"
  }
  $pa_config_path = '/etc/puppetlabs/puppet'
  $mco_config_path = '/etc/puppetlabs/mcollective'
  $mco_config_file_name = "server.cfg"
  $mco_config_file_path = "${mco_config_path}/${mco_config_file_name}"
  $run_path = "/var/run/puppetlabs/"
  $pid_file_path = "${run_path}/mcollective.pid"
  $mcollectived_path = "${bin_path}/mcollectived"
  $plugins_path = "/usr/local/"
  $pa_bin_path = "/usr/local/bin"

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
    ensure  => directory,
  } ->
  package { 'stomp':
    ensure   => 'installed',
    provider => 'gem',
  } ->
  file { "${bin_path}/mco":
    ensure  => file,
    mode  => '0755',
    source => "puppet:///modules/osmco/bin/mco",
  } ->
  file { "${bin_path}/mcollectived":
    ensure  => file,
    mode  => '0755',
    source => "puppet:///modules/osmco/bin/mcollectived",
  } ->
  file { "$lib_path/mcollective.rb":
    ensure  => file,
    mode  => '0644',
    source => "puppet:///modules/osmco/lib/mcollective.rb",
  } ->
  file { "$lib_path/mcollective":
    ensure  => directory,
    force  => true,
    purge  => true,
    recurse  => true,
    source => "puppet:///modules/osmco/lib/mcollective",
  } ->
  file { "$plugins_path/mcollective":
    ensure  => directory,
    force  => true,
    purge  => true,
    recurse  => true,
    source => "puppet:///modules/osmco/plugins/",
  } ->
  file { $run_path:
    ensure  => directory,
  } ->
  file { $mco_config_path:
    ensure  => directory,
  } ->
  file { $mco_config_file_path:
    ensure  => file,
    mode  => '0644',
    content => epp("osmco/${mco_config_file_name}.epp", 
      { 
        plugins_path => $plugins_path, 
        activemq_passwd => $activemq_passwd, 
        pa_bin_path => $pa_bin_path,
        pa_config_path => $pa_config_path,
      } ),
  } ->
  file { '/etc/systemd/system/mcollectived.service':
    ensure  => file,
    content => inline_epp($mcollective_control_file, 
      { 
        mcollectived_path => $mcollectived_path, 
        pid_file_path => $pid_file_path, 
        mco_config_file_path => $mco_config_file_path,
      }),
  } ->
  exec { 'mcollectived systemctl daemon-reload':
    command     => 'systemctl daemon-reload',
    path        => ['/usr/bin', '/usr/sbin'],
    refreshonly => true,
  } ->
  service { 'mcollectived':
    ensure => running,
    enable => true,
  }

}



