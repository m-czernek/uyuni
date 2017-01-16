--
-- Copyright (c) 2017 SUSE LLC
--
-- This software is licensed to you under the GNU General Public License,
-- version 2 (GPLv2). There is NO WARRANTY for this software, express or
-- implied, including the implied warranties of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
-- along with this software; if not, see
-- http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
--
--
-- triggers for suseImageProfile

create or replace trigger
suse_imgprof_mod_trig
before insert or update on suseImageProfile
for each row
begin
	:new.modified := current_timestamp;
end suse_imgprof_mod_trig;
/
show errors

