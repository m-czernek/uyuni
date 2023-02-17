---
name: New joiner checklist
about: Use this template when someone joins the SUSE Manager team
title: 'New joiner <name>'
labels: team
assignees: ''
---

General template for new joiners of the SUSE Manager team.

- [ ] Go through the general [onboarding guide](https://geekos.io/onboarding) for new employees.
- [ ] GitHub account with SUSE email address
  - [ ] [Add to SUSE org](https://confluence.suse.com/pages/viewpage.action?spaceKey=IAM&title=Github+account+and+access)
  - [ ] Add to [SUSE Manager Team](https://github.com/orgs/SUSE/teams/suse-manager-team/) on GitHub
  - [ ] Add to Uyuni organization and teams (@juliogonzalez or [another owner](https://github.com/orgs/uyuni-project/people?query=role%3Aowner))
- [ ] Add SUMA account on [manager.mgr.suse.de](https://manager.mgr.suse.de)
- [ ] [Trello account](https://confluence.suse.com/display/IAM/Trello+account+and+access)
- [ ] Confluence
  - [ ] Add to [SUMA squads](https://confluence.suse.com/display/SUSEMANAGER/Squads%2C+People+and+Topics) page
  - [ ] Add to [Confluence overview page](https://confluence.suse.com/display/SUSEMANAGER/SUSE+Manager) of the team
- [ ] Mailing lists
  - [ ] [SUSE](https://mailman.suse.de)
    - [ ] galaxy-team
    - [ ] galaxy-devel
    - [ ] suse-manager
    - [ ] consider others (e.g. galaxy-ci)
  - [ ] [openSUSE](https://lists.opensuse.org)
  - [ ] [Uyuni](https://www.uyuni-project.org/pages/contact.html)
- [ ] [Meeting invitations](https://confluence.suse.com/display/SUSEMANAGER/Meeting+Timetable): Forward via https://outlook.office.com/calendar (right click event -> forward -> all events)
  - [ ] SUSE Manager Team Review
  - [ ] Priorities, Help and Planning (PHP)
  - [ ] SUSE Manager Team Retrospective
- [ ] Slack
  - [ ] Update workflows (daily standup, meetings, etc.)
  - [ ] Add to user groups (`susemanager-engineers` and squad specific groups, open a ticket on https://sd.suse.com)
- [ ] Outlook groups of the [SUSE Manager Engineering Team](https://outlook.office.com/people/group/mysuse.onmicrosoft.com/suma-all) and squad (if available)
- [ ] Add SSH public key to [SUMA infrastructure](https://gitlab.suse.de/galaxy/infrastructure/-/blob/master/srv/salt/ssh/init.sls)
- [ ] Provide default passwords if applicable (testsuite VMs, maybe https://gitlab.suse.de/galaxy/credentials)
- [ ] Add user to SCC organization `SUSE Manager Team Playground` for SCC mirror credentials
- [ ] Add to groups in IBS if applicable (e.g. `qam-manager` for QE)
- [ ] Add the new employee to our [GitLab group](https://gitlab.suse.de/galaxy)
- [ ] Schedule new joiner meetups with at least one [member from each squad](https://confluence.suse.com/x/OIGAOQ)
- [ ] Update the [finglonger config](https://gitlab.suse.de/galaxy/infrastructure/-/blob/master/srv/salt/bugguy-finglonger/galaxy.edn) and [ION squad finglonger config](https://gitlab.suse.de/galaxy/infrastructure/-/blob/master/srv/salt/bugguy-finglonger/salt.edn)