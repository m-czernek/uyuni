# Copyright (c) 2021-2022 SUSE LLC
# Licensed under the terms of the MIT license.

@sle_minion
@scope_onboarding
Feature: bootstrapping with reactivation key
  In order to re-register valid minions
  As an authorized user
  I want to avoid re-registration with invalid input parameters

  Scenario: Log in as admin user
    Given I am authorized for the "Admin" section
    And I am logged in API as user "admin" and password "admin"

  Scenario: Generate a re-activation key
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Reactivation"
    And I click on "Generate New Key"
    Then I should see a "Key:" text

  Scenario: Bootstrap should fail when minion already exists
    When I follow the left menu "Systems > Bootstrapping"
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I click on "Bootstrap"
    And I wait until I see "A salt key for this host" text
    Then I should not see a "GenericSaltError" text
    And I should see a "seems to already exist, please check!" text

  Scenario: Bootstrap should fail when system already exists in the server
    Given I delete "sle_minion" key in the Salt master
    When I follow the left menu "Systems > Bootstrapping"
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I click on "Bootstrap"
    And I wait until I see "seems to already exist, please check!" text
    Then I should not see a "GenericSaltError" text
    And I should see a "with minion id" text

  Scenario: Bootstrap a SLES minion with reactivation key
    When I follow the left menu "Systems > Bootstrapping"
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I enter the reactivation key of "sle_minion"
    And I click on "Bootstrap"
    And I wait until I see "Successfully bootstrapped host!" text
    And I follow the left menu "Systems > Overview"
    And I wait until I see the name of "sle_minion", refreshing the page

  Scenario: Check the events history for the reactivation
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Events" in the content area
    And I follow "History" in the content area
    And I wait until I see "Server reactivated as Salt minion" text, refreshing the page
    And I wait until event "Apply states [certs, channels, packages, services.salt-minion] scheduled by admin" is completed

  Scenario: Cleanup: delete SLES minion after reactivation tests
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    And I wait until I see "has been deleted" text
    Then "sle_minion" should not be registered

  Scenario: Cleanup: bootstrap a SLES minion after reactivation tests
    When I follow the left menu "Systems > Bootstrapping"
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I select the hostname of "proxy" from "proxies" if present
    And I click on "Bootstrap"
    And I wait until I see "Successfully bootstrapped host!" text
    And I follow the left menu "Systems > Overview"
    And I wait until I see the name of "sle_minion", refreshing the page

  Scenario: Cleanup: subscribe again to base channel after reactivation tests
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Software" in the content area
    And I follow "Software Channels" in the content area
    And I wait until I do not see "Loading..." text
    And I wait until I see "SUSE Channels" text, refreshing the page
    And I check radio button "SLE-Product-SLES15-SP4-Pool for x86_64"
    And I wait until I do not see "Loading..." text
    And I include the recommended child channels
    And I check "SLE-Module-DevTools15-SP4-Pool for x86_64"
    And I check "Fake-RPM-SLES-Channel"
    And I click on "Next"
    Then I should see a "Confirm Software Channel Change" text
    When I click on "Confirm"
    Then I should see a "Changing the channels has been scheduled." text
    When I wait until event "Subscribe channels scheduled by admin" is completed

  Scenario: Cleanup: Logout from API
    When I logout from API
