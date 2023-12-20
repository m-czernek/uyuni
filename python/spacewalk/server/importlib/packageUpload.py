# pylint: disable=missing-module-docstring,invalid-name
# Copyright (c) 2008--2016 Red Hat, Inc.
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
#
# Package import code on the app side
#

from uyuni.common import rhn_rpm
from spacewalk.common.rhnLog import log_debug
from spacewalk.common.rhnException import rhnFault

from spacewalk.server import rhnChannel, taskomatic, rhnSQL
from spacewalk.server.importlib.backendOracle import SQLBackend
from spacewalk.server.importlib.headerSource import createPackage
from spacewalk.server.importlib.importLib import Collection
from spacewalk.server.importlib.packageImport import packageImporter
from spacewalk.server.importlib.errataCache import schedule_errata_cache_update


def uploadPackages(info, source=0, force=0, caller=None):  #  pylint: disable=invalid-name
    log_debug(4, source, force, caller)
    batch = Collection()
    packageList = info.get("packages") or []  #  pylint: disable=invalid-name
    if not packageList:
        raise Exception("Nothing to do")  #  pylint: disable=broad-exception-raised

    org_id = info.get("orgId")
    if org_id == "":
        org_id = None

    if source:
        channelList = []  #  pylint: disable=invalid-name
    else:
        channelList = info.get("channels") or []  #  pylint: disable=invalid-name

    for package in packageList:
        p = __processPackage(package, org_id, channelList, source)
        batch.append(p)

    backend = SQLBackend()
    importer = packageImporter(batch, backend, source, caller=caller)

    importer.setUploadForce(force)

    importer.run()
    if not source:
        importer.subscribeToChannels()

    # Split the result in two lists - already uploaded and new packages
    newpkgs = []
    uploaded = []
    for pkg in importer.status():
        if pkg.ignored or pkg.diff:
            uploaded.append(pkg)
        else:
            newpkgs.append(pkg)

    # Schedule an errata cache update only if we touched the channels
    if not source:
        # makes sense only for binary packages
        schedule_errata_cache_update(importer.affected_channels)
        taskomatic.add_to_repodata_queue_for_channel_package_subscription(
            importer.affected_channels, batch, caller
        )
        rhnSQL.commit()

    return _formatStatus(uploaded), _formatStatus(newpkgs)


def __processPackage(package, org_id, channels, source):  #  pylint: disable=invalid-name
    log_debug(4, org_id, channels, source)
    if "md5sum" in package:  # for old rhnpush compatibility
        package["checksum_type"] = "md5"
        package["checksum"] = package["md5sum"]
        del package["md5sum"]

    if "checksum" not in package:
        raise rhnFault(50, "The package's checksum digest has not been specified")
    if "packageSize" not in package:
        raise rhnFault(50, "The package size has not been specified")

    header = rhn_rpm.headerLoad(package["header"].data)
    if not header:
        raise rhnFault(50)
    packageSize = package["packageSize"]  #  pylint: disable=invalid-name
    relpath = package.get("relativePath")

    if "header_start" in package:
        header_start = package["header_start"]
    else:
        header_start = 0
    if "header_end" in package:
        header_end = package["header_end"]
    else:
        # Just say the whole package
        header_end = packageSize

    checksum_type = package["checksum_type"]
    checksum = package["checksum"]
    p = createPackage(
        header,
        packageSize,
        checksum_type,
        checksum,
        relpath,
        org_id,
        header_start,
        header_end,
        channels,
    )
    return p


def _formatStatus(status):  #  pylint: disable=invalid-name
    objlist = []
    for pkg in status:
        name = pkg.name
        epoch = pkg.evr[0]
        if epoch is None:
            epoch = ""
        else:
            epoch = str(epoch)
        version = pkg.evr[1]
        release = pkg.evr[2]
        arch = pkg.arch
        hash = {}  #  pylint: disable=redefined-builtin
        ignored = pkg.ignored
        if ignored is None:
            ignored = 0
        hash["ignored"] = ignored
        hash["diff"] = _dump(pkg.diff)
        objlist.append([name, version, release, epoch, arch, hash])
    return objlist


def _dump(object):  #  pylint: disable=redefined-builtin
    if object is None:
        return ""
    from uyuni.common.usix import IntType, StringType, FloatType  #  pylint: disable=import-outside-toplevel

    if type(object) in (IntType, StringType, FloatType):
        return object
    from uyuni.common.usix import ListType  #  pylint: disable=import-outside-toplevel

    if isinstance(object, ListType):
        return list(map(_dump, object))
    from uyuni.common.usix import TupleType  #  pylint: disable=import-outside-toplevel

    if isinstance(object, TupleType):
        return tuple(map(_dump, object))
    from uyuni.common.usix import DictType  #  pylint: disable=import-outside-toplevel

    if isinstance(object, DictType):
        dict = {}  #  pylint: disable=redefined-builtin
        for h, v in list(object.items()):
            dict[_dump(h)] = _dump(v)
        return dict
    return str(object)


def listChannelsSource(channelList):  #  pylint: disable=invalid-name,invalid-name
    return _listChannels(channelList, True, False)


def listChannels(channelList):  #  pylint: disable=invalid-name,invalid-name
    return _listChannels(channelList, False, False)


def listChannelsChecksum(channelList):  #  pylint: disable=invalid-name,invalid-name
    return _listChannels(channelList, False, True)


def _listChannels(channelList, is_source, include_checksums):  #  pylint: disable=invalid-name,invalid-name
    # Lists the packages from these channels
    # Uniquify the channels
    channels = set(channelList)
    rez = []
    for channel in channels:
        c_info = rhnChannel.channel_info(channel)
        if not c_info:
            # No packages in this channel
            continue

        if is_source:
            packageList = rhnChannel.list_packages_source(c_info["id"])  #  pylint: disable=invalid-name
        else:
            if include_checksums:
                packageList = rhnChannel.list_packages_checksum_sql(c_info["id"])  #  pylint: disable=invalid-name
            else:
                packageList = rhnChannel.list_packages_sql(c_info["id"])  #  pylint: disable=invalid-name
        for p in packageList:
            if is_source:
                for pkg in range(len(p)):
                    if p[pkg] is None:
                        p[pkg] = ""
                print(p)
                rez.append([p[0], p[1], p[2], p[3], channel])
            else:
                if include_checksums:
                    rez.append([p[0], p[1], p[2], p[3], p[4], p[6], p[7], channel])
                else:
                    rez.append([p[0], p[1], p[2], p[3], p[4], channel])
    return rez
