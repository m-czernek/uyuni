-- oracle equivalent source sha1 aa5d5777cb5bbdfc7f242b167b3b969486f2d97b
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
-- triggers for suseImageProfile

create or replace function suse_imgprof_mod_trig_fun() returns trigger as
$$
begin
	new.modified := current_timestamp;
	return new;
end;
$$ language plpgsql;

create trigger
suse_imgprof_mod_trig
before insert or update on suseImageProfile
for each row
execute procedure suse_imgprof_mod_trig_fun();
