--
-- Copyright (c) 2018 Red Hat, Inc.
--
-- This software is licensed to you under the GNU General Public License,
-- version 2 (GPLv2). There is NO WARRANTY for this software, express or
-- implied, including the implied warranties of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
-- along with this software; if not, see
-- http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
--
-- Red Hat trademarks are not licensed under GPLv2. No permission is
-- granted to use or replicate Red Hat trademarks that are incorporated
-- in this software or its documentation.
--

CREATE TABLE rhnCompsType
(
  id      NUMERIC NOT NULL
              CONSTRAINT rhn_comps_type_id_pk primary key,
  label   VARCHAR(32) NOT NULL
              CONSTRAINT rhn_comps_type_type_uq UNIQUE
);

INSERT INTO rhnCompsType (id, label) VALUES (1, 'comps');
INSERT INTO rhnCompsType (id, label) VALUES (2, 'modules');
