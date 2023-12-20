#
# Copyright (c) 2008--2015 Red Hat, Inc.
# Copyright (c) 2021 SUSE LLC.
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
#
# Red Hat trademarks are not licensed under GPLv2. No permission is
# granted to use or replicate Red Hat trademarks that are incorporated
# in this software or its documentation.
#

"""
Database specific tests for rhnSQL drivers.

These tests require a database connection, usually configured in a
rhntests-*.py script.
"""

from random import randint
import pytest

from spacewalk.server import rhnSQL
from spacewalk.server.rhnSQL import sql_base

TEST_IDS = [1, 2, 3]
TEST_NAMES = ["Bill", "Susan", "Joe"]
TEST_NUMS = [900.12, 600.49, 34.98]

QUERY_CREATE_TABLE = """
    CREATE TABLE %s(id INT, name TEXT, num NUMERIC(5,2))
"""


@pytest.fixture()
def temp_table():
    table_name = "testtable%s" % randint(1, 10000000)  #  pylint: disable=consider-using-f-string

    create_table_query = QUERY_CREATE_TABLE % table_name
    cursor = rhnSQL.prepare(create_table_query)
    cursor.execute()
    insert_query = "INSERT INTO %s(id, name, num) VALUES(:id, :name, :num)" % table_name  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(insert_query)
    cursor.execute(id=TEST_IDS[0], name=TEST_NAMES[0], num=TEST_NUMS[0])
    cursor.execute(id=TEST_IDS[1], name=TEST_NAMES[1], num=TEST_NUMS[1])
    cursor.execute(id=TEST_IDS[2], name=TEST_NAMES[2], num=TEST_NUMS[2])

    yield table_name
    drop_table_query = "DROP TABLE %s" % table_name  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(drop_table_query)
    cursor.execute()
    rhnSQL.commit()


def test_execute_not_all_variables_bound(temp_table):  #  pylint: disable=redefined-outer-name
    query = "INSERT INTO %s(id, name) VALUES(:id, :name)" % temp_table  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(query)
    with pytest.raises(sql_base.SQLError):
        cursor.execute(name="Blah")


def test_statement_prepare_error():
    rhnSQL.transaction("test_statement_prepare_error")

    query = "aaa bbb ccc"
    cursor = rhnSQL.prepare(query)
    with pytest.raises(sql_base.SQLError):
        cursor.execute()

    rhnSQL.rollback("test_statement_prepare_error")


def test_execute_bindbyname_extra_params_passed(temp_table):  #  pylint: disable=redefined-outer-name
    query = "SELECT * FROM %s WHERE id = :id" % temp_table  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(query)
    cursor.execute(id=TEST_IDS[0], name="Sam")  # name should be ignored
    results = cursor.fetchone()
    assert results[0] == TEST_IDS[0]
    assert results[1] == TEST_NAMES[0]


def test_executemany(temp_table):  #  pylint: disable=redefined-outer-name
    query = "INSERT INTO %s(id, name) VALUES(:id, :name)" % temp_table  #  pylint: disable=consider-using-f-string
    ids = [1000, 1001]
    names = ["Somebody", "Else"]

    cursor = rhnSQL.prepare(query)
    cursor.executemany(id=ids, name=names)

    query = rhnSQL.prepare("SELECT * FROM %s WHERE id >= 1000 ORDER BY ID" % temp_table)  #  pylint: disable=consider-using-f-string
    query.execute()
    rows = query.fetchall()
    assert len(rows) == 2

    assert rows[0][0] == 1000
    assert rows[1][0] == 1001
    assert rows[0][1] == "Somebody"
    assert rows[1][1] == "Else"


def test_executemany2(temp_table):  #  pylint: disable=redefined-outer-name
    query = "SELECT * FROM %s" % temp_table  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(query)

    # Just want to see that this doesn't throw an exception:
    cursor.executemany()


def test_execute_bulk(temp_table):  #  pylint: disable=redefined-outer-name
    query = "INSERT INTO %s(id, name) VALUES(:id, :name)" % temp_table  #  pylint: disable=consider-using-f-string
    ids = [1000, 1001]
    names = ["Somebody", "Else"]

    cursor = rhnSQL.prepare(query)
    d = {
        "id": ids,
        "name": names,
    }
    cursor.executemany(**d)

    query = rhnSQL.prepare("SELECT * FROM %s WHERE id >= 1000 ORDER BY ID" % temp_table)  #  pylint: disable=consider-using-f-string
    query.execute()
    rows = query.fetchall()
    assert len(rows) == 2

    assert rows[0][0] == 1000
    assert rows[1][0] == 1001
    assert rows[0][1] == "Somebody"
    assert rows[1][1] == "Else"


def test_numeric_columns(temp_table):  #  pylint: disable=redefined-outer-name
    h = rhnSQL.prepare("SELECT num FROM %s WHERE id = %s" % (temp_table, TEST_IDS[0]))  #  pylint: disable=consider-using-f-string
    h.execute()
    row = h.fetchone()
    assert row[0] == TEST_NUMS[0]


def test_fetchone(temp_table):  #  pylint: disable=redefined-outer-name
    query = "SELECT * FROM %s WHERE id = 1 ORDER BY id" % temp_table  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(query)
    cursor.execute()
    results = cursor.fetchone()
    assert results[0] == TEST_IDS[0]
    assert results[1] == TEST_NAMES[0]


def test_fetchone_dict(temp_table):  #  pylint: disable=redefined-outer-name
    query = "SELECT * FROM %s WHERE id = 1 ORDER BY id" % temp_table  #  pylint: disable=consider-using-f-string
    cursor = rhnSQL.prepare(query)
    cursor.execute()
    results = cursor.fetchone_dict()
    assert results["id"] == TEST_IDS[0]
    assert results["name"] == TEST_NAMES[0]
    assert results["num"] == TEST_NUMS[0]


def test_fetchall(temp_table):  #  pylint: disable=redefined-outer-name
    query = rhnSQL.prepare("SELECT * FROM %s ORDER BY id" % temp_table)  #  pylint: disable=consider-using-f-string
    query.execute()
    rows = query.fetchall()
    assert len(rows) == len(TEST_IDS)

    i = 0
    while i < len(TEST_IDS):
        assert rows[i][0] == TEST_IDS[i]
        assert rows[i][1] == TEST_NAMES[i]
        i = i + 1


def test_fetchall_dict(temp_table):  #  pylint: disable=redefined-outer-name
    query = rhnSQL.prepare("SELECT * FROM %s ORDER BY id" % temp_table)  #  pylint: disable=consider-using-f-string
    query.execute()
    rows = query.fetchall_dict()
    assert len(rows) == len(TEST_IDS)

    i = 0
    while i < len(TEST_IDS):
        assert rows[i]["id"] == TEST_IDS[i]
        assert rows[i]["name"] == TEST_NAMES[i]
        i = i + 1


def test_unicode_string_argument(temp_table):  #  pylint: disable=redefined-outer-name
    query = rhnSQL.prepare("SELECT * FROM %s WHERE name=:name" % temp_table)  #  pylint: disable=consider-using-f-string
    query.execute(name="blah")
