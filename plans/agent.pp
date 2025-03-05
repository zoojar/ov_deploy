# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
# @param ca_server The Certificate Authority (CA) server.
# @param server The primary server.
# @param gpg_key_url The URL for the GPG key to verify package integrity.
# @param repo_url The URL for the package repository.
# @param pkg_name The name of the package to install.
#
plan ov_deploy::agent (
  TargetSpec $targets = ['agents'],
  String $ca_server   = get_target('primary').name,
  String $server      = get_targets('compilers')[0].name,
  String $gpg_key_url = 'https://s3.osuosl.org/openvox-yum/GPG-KEY-openvox.pub',
  String $repo_url    = 'https://s3.osuosl.org/openvox-yum/openvox8-release-el-9.noarch.rpm',
  String $pkg_name    = 'openvox-agent',
) {
  get_targets($targets).each |$target| {
    unless run_command('hostname', $target, 'catch_errors' => true).ok() {
      fail_plan('Unable to connect to target')
    }
    unless run_command('/usr/bin/yum --version', $target, 'catch_errors' => true).ok() {
      fail_plan('Unsupported target')
    }
    run_command("/usr/bin/curl -LO ${gpg_key_url}", $target, "Installing gpg key ${gpg_key_url}", 'catch_errors' => true)
    run_command("/usr/bin/rpm -Uvh ${repo_url}", $target, "Installing gpg key ${gpg_key_url}", 'catch_errors' => true)
    run_command("/usr/bin/yum -y install ${pkg_name}", $target, 'Installing agent', 'catch_errors' => true)
    run_command("/opt/puppetlabs/puppet/bin/puppet config set server ${server} --section agent", $target, 'Setting server in agent config')
    run_command("/opt/puppetlabs/puppet/bin/puppet config set ca_server ${ca_server} --section agent", $target, 'Setting server in agent config')
    run_command('/opt/puppetlabs/puppet/bin/puppet ssl bootstrap --waitforcert 0', $target, 'Requesting cert', 'catch_errors' => true)
    run_command("/opt/puppetlabs/bin/puppetserver ca sign --certname ${target.name}", 'primary', 'Signing cert')
    ctrl::do_until('interval' => 5) || {
      run_command('/opt/puppetlabs/bin/puppet agent -t', ['agents'], 'Running puppet', 'catch_errors' => true).ok()
    }
  }
}
