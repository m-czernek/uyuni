# Copyright (c) 2017 SUSE Linux
# Licensed under the terms of the MIT license.

require 'xmlrpc/client'
require 'time'
require 'date'

def wait_action_complete(actionid)
  host = $server.full_hostname
  @cli = XMLRPC::Client.new2('http://' + host + '/rpc/api')
  @sid = @cli.call('auth.login', 'admin', 'admin')
  complete_timeout = 300
  Timeout.timeout(complete_timeout) do
    loop do
      list = @cli.call('schedule.list_completed_actions', @sid)
      list.each do |action|
        return true if action['id'] == actionid
        sleep(2)
      end
    end
  end
rescue Timeout::Error
  out = @cli.call('schedule.list_all_actions', @sid)
  raise "Action did not complete. It was not found in completed actions. All Actions:\n #{out}"
end

When(/^I authenticate to XML-RPC$/) do
  host = $server.full_hostname
  @cli = XMLRPC::Client.new2('http://' + host + '/rpc/api')
  @sid = @cli.call('auth.login', 'admin', 'admin')
end

When(/^I refresh the packages on "([^"]*)" through XML-RPC$/) do |host|
  node = get_target(host)
  node_id = retrieve_server_id(node.full_hostname)
  now = DateTime.now
  date_schedule_now = XMLRPC::DateTime.new(now.year, now.month, now.day, now.hour, now.min, now.sec)

  id_refresh = @cli.call('system.schedule_package_refresh', @sid, node_id, date_schedule_now)
  node.run('rhn_check -vvv')
  wait_action_complete(id_refresh)
end

When(/^I run a script on "([^"]*)" through XML-RPC$/) do |host|
  node = get_target(host)
  node_id = retrieve_server_id(node.full_hostname)
  now = DateTime.now
  date_schedule_now = XMLRPC::DateTime.new(now.year, now.month, now.day, now.hour, now.min, now.sec)
  script = "#! /usr/bin/bash \n uptime && ls"

  id_script = @cli.call('system.schedule_script_run', @sid, node_id, 'root', 'root', 500, script, date_schedule_now)
  node.run('rhn_check -vvv')
  wait_action_complete(id_script)
end

When(/^I reboot "([^"]*)" through XML-RPC$/) do |host|
  node = get_target(host)
  node_id = retrieve_server_id(node.full_hostname)
  now = DateTime.now
  date_schedule_now = XMLRPC::DateTime.new(now.year, now.month, now.day, now.hour, now.min, now.sec)

  @cli.call('system.schedule_reboot', @sid, node_id, date_schedule_now)
  node.run('rhn_check -vvv')
  reboot_timeout = 400
  check_shutdown(node.full_hostname, reboot_timeout)
  check_restart(node.full_hostname, node, reboot_timeout)

  @cli.call('schedule.list_failed_actions', @sid).each do |action|
    systems = @cli.call('schedule.list_failed_systems', @sid, action['id'])
    raise if systems.all? { |system| system['server_id'] == node_id }
  end
end

When(/^I unauthenticate from XML-RPC$/) do
  @cli.call('auth.logout', @sid)
end
