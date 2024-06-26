#  pylint: disable=missing-module-docstring
#
# Copyright (c) 2008--2018 Red Hat, Inc.
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
import re

XML_ENCODING = '<?xml version="1.0" encoding="UTF-8"?>'


# pylint: disable-next=missing-class-docstring
class RepoView:
    def __init__(
        self,
        primary,
        filelists,
        other,
        updateinfo,
        groups,
        modules,
        fileobj,
        checksum_type,
    ):
        self.primary = primary
        self.filelists = filelists
        self.other = other
        self.updateinfo = updateinfo
        self.groups = groups
        self.modules = modules

        self.fileobj = fileobj
        if checksum_type == "sha1":
            self.checksum_type = "sha"
        else:
            self.checksum_type = checksum_type

    def _get_data(self, data_type, data_obj):
        output = []
        # pylint: disable-next=consider-using-f-string
        output.append('  <data type="%s">' % (data_type))
        # pylint: disable-next=consider-using-f-string
        output.append('    <location href="repodata/%s.xml.gz"/>' % (data_type))
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <checksum type="%s">%s</checksum>'
            % (self.checksum_type, data_obj["gzip_checksum"])
        )
        # pylint: disable-next=consider-using-f-string
        output.append("    <timestamp>%d</timestamp>" % (data_obj["timestamp"]))
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <open-checksum type="%s">%s</open-checksum>'
            % (self.checksum_type, data_obj["open_checksum"])
        )
        output.append("  </data>")
        return output

    def _get_comps_data(self):
        output = []
        if self.groups:
            output.append('  <data type="group">')
            output.append('    <location href="repodata/comps.xml"/>')
            output.append(
                # pylint: disable-next=consider-using-f-string
                '    <checksum type="%s">%s</checksum>'
                % (self.checksum_type, self.groups["open_checksum"])
            )
            # pylint: disable-next=consider-using-f-string
            output.append("    <timestamp>%d</timestamp>" % (self.groups["timestamp"]))
            output.append("  </data>")

        return output

    def _get_modules_data(self):
        output = []
        if self.modules:
            output.append('  <data type="group">')
            output.append('    <location href="repodata/modules.yaml"/>')
            output.append(
                # pylint: disable-next=consider-using-f-string
                '    <checksum type="%s">%s</checksum>'
                % (self.checksum_type, self.modules["open_checksum"])
            )
            # pylint: disable-next=consider-using-f-string
            output.append("    <timestamp>%d</timestamp>" % (self.groups["timestamp"]))
            output.append("  </data>")

        return output

    def write_repomd(self):
        output = []
        output.append(XML_ENCODING)
        output.append('<repomd xmlns="http://linux.duke.edu/metadata/repo">')
        output.extend(self._get_data("primary", self.primary))
        output.extend(self._get_data("filelists", self.filelists))
        output.extend(self._get_data("other", self.other))
        output.extend(self._get_data("updateinfo", self.updateinfo))
        output.extend(self._get_comps_data())
        output.extend(self._get_modules_data())
        output.append("</repomd>")
        self.fileobj.write("\n".join(output))


# pylint: disable-next=missing-class-docstring
class PrimaryView(object):
    def __init__(self, channel, fileobj):
        self.channel = channel
        self.fileobj = fileobj

    def _get_deps(self, deps):
        output = []
        for dep in deps:
            if dep["flag"]:
                line = (
                    # pylint: disable-next=consider-using-f-string
                    '        <rpm:entry name="%s" flags="%s" \
                        epoch="%s" ver="%s" '
                    % (dep["name"], dep["flag"], dep["epoch"], dep["version"])
                )
                if dep["release"]:
                    # pylint: disable-next=consider-using-f-string
                    line += 'rel="%s" ' % dep["release"]
                line += "/>"
                output.append(line)
            else:
                output.append(
                    # pylint: disable-next=consider-using-f-string
                    '         <rpm:entry name="%s" />'
                    % (text_filter(dep["name"]))
                )
        return output

    def _get_files(self, files):
        output = []
        # pylint: disable-next=anomalous-backslash-in-string
        filere = re.compile(".*bin\/.*|^\/etc\/.*|^\/usr\/lib\.sendmail$")
        for pkg_file in files:
            if filere.match(pkg_file):
                # pylint: disable-next=consider-using-f-string
                output.append("      <file>%s</file>" % (text_filter(pkg_file)))
        return output

    def _get_package(self, package):
        output = []
        output.append('  <package type="rpm">')
        # pylint: disable-next=consider-using-f-string
        output.append("    <name>%s</name>" % (package.name))
        # pylint: disable-next=consider-using-f-string
        output.append("    <arch>%s</arch>" % (package.arch))
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <version epoch="%s" ver="%s" rel="%s" />'
            % (package.epoch, package.version, package.release)
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <checksum type="%s" pkgid="YES">%s</checksum>'
            % (package.checksum_type, package.checksum)
        )
        # pylint: disable-next=consider-using-f-string
        output.append("    <summary>%s</summary>" % (text_filter(package.summary)))
        output.append(
            # pylint: disable-next=consider-using-f-string
            "    <description>%s</description>"
            % (text_filter(package.description))
        )
        output.append("    <packager></packager>")
        output.append("    <url></url>")
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <time file="%d" build="%d" />'
            % (package.build_time, package.build_time)
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <size package="%d" installed="%d" '
            'archive="%d" />'
            % (package.package_size, package.installed_size, package.payload_size)
        )
        # pylint: disable-next=consider-using-f-string
        output.append('    <location href="getPackage/%s" />' % (package.filename))
        output.append("    <format>")
        output.append(
            # pylint: disable-next=consider-using-f-string
            "      <rpm:license>%s</rpm:license>"
            % (text_filter(package.copyright))
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            "      <rpm:vendor>%s</rpm:vendor>"
            % (text_filter(package.vendor))
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            "      <rpm:group>%s</rpm:group>"
            % (text_filter(package.package_group))
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            "      <rpm:buildhost>%s</rpm:buildhost>"
            % (text_filter(package.build_host))
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            "      <rpm:sourcerpm>%s</rpm:sourcerpm>"
            % (text_filter(package.source_rpm))
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            '      <rpm:header-range start="%d" end="%d" />'
            % (package.header_start, package.header_end)
        )

        output.append("      <rpm:provides>")
        output.extend(self._get_deps(package.provides))
        output.append("      </rpm:provides>")

        output.append("      <rpm:requires>")
        output.extend(self._get_deps(package.requires))
        output.append("      </rpm:requires>")

        output.append("      <rpm:recommends>")
        output.extend(self._get_deps(package.recommends))
        output.append("      </rpm:recommends>")

        output.append("      <rpm:suggests>")
        output.extend(self._get_deps(package.suggests))
        output.append("      </rpm:suggests>")

        output.append("      <rpm:supplements>")
        output.extend(self._get_deps(package.supplements))
        output.append("      </rpm:supplements>")

        output.append("      <rpm:enhances>")
        output.extend(self._get_deps(package.enhances))
        output.append("      </rpm:enhances>")

        output.append("      <rpm:conflicts>")
        output.extend(self._get_deps(package.conflicts))
        output.append("      </rpm:conflicts>")

        output.append("      <rpm:obsoletes>")
        output.extend(self._get_deps(package.obsoletes))
        output.append("      </rpm:obsoletes>")

        output.extend(self._get_files(package.files))

        output.append("    </format>")
        output.append("  </package>")

        return output

    def write_start(self):
        output = (
            XML_ENCODING
            + "\n"
            + '<metadata xmlns="http://linux.duke.edu/metadata/common" '
            + 'xmlns:rpm="http://linux.duke.edu/metadata/rpm" '
            # pylint: disable-next=consider-using-f-string
            + 'packages="%d">' % self.channel.num_packages
        )

        self.fileobj.write(output)

    def write_package(self, package):
        self.fileobj.write("\n".join(self._get_package(package)))

    def write_end(self):
        self.fileobj.write("</metadata>")


# pylint: disable-next=missing-class-docstring
class FilelistsView(object):
    def __init__(self, channel, fileobj):
        self.channel = channel
        self.fileobj = fileobj

    def _get_package(self, package):
        output = []
        output.append(
            # pylint: disable-next=consider-using-f-string
            '  <package pkgid="%s" name="%s" arch="%s">'
            % (package.checksum, package.name, package.arch)
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <version epoch="%s" ver="%s" rel="%s" />'
            % (package.epoch, package.version, package.release)
        )

        for file_name in package.files:
            # pylint: disable-next=consider-using-f-string
            output.append("    <file>%s</file>" % (text_filter(file_name)))
        output.append("  </package>")
        return output

    def write_start(self):
        output = (
            XML_ENCODING
            + "\n"
            + '<filelists xmlns="http://linux.duke.edu/metadata/filelists" '
            # pylint: disable-next=consider-using-f-string
            + 'packages="%d">' % self.channel.num_packages
        )

        self.fileobj.write(output)

    def write_package(self, package):
        self.fileobj.write("\n".join(self._get_package(package)))

    def write_end(self):
        self.fileobj.write("</filelists>")


# pylint: disable-next=missing-class-docstring
class OtherView(object):
    def __init__(self, channel, fileobj):
        self.channel = channel
        self.fileobj = fileobj

    def _get_package(self, package):
        output = []
        output.append(
            # pylint: disable-next=consider-using-f-string
            '  <package pkgid="%s" name="%s" arch="%s">'
            % (package.checksum, package.name, package.arch)
        )
        output.append(
            # pylint: disable-next=consider-using-f-string
            '    <version epoch="%s" ver="%s" rel="%s" />'
            % (package.epoch, package.version, package.release)
        )

        for changelog in package.changelog:
            output.append(
                # pylint: disable-next=consider-using-f-string
                '    <changelog author="%s" date="%d">'
                % (text_filter_attribute(changelog["author"]), changelog["date"])
            )
            output.append("      " + text_filter(changelog["text"]))
            output.append("    </changelog>")
        output.append("  </package>")
        return output

    def write_start(self):
        output = (
            XML_ENCODING
            + "\n"
            + '<otherdata xmlns="http://linux.duke.edu/metadata/other" '
            # pylint: disable-next=consider-using-f-string
            + 'packages="%d">' % self.channel.num_packages
        )

        self.fileobj.write(output)

    def write_package(self, package):
        self.fileobj.write("\n".join(self._get_package(package)))

    def write_end(self):
        self.fileobj.write("</otherdata>")


# pylint: disable-next=missing-class-docstring
class UpdateinfoView(object):
    def __init__(self, channel, fileobj):
        self.channel = channel
        self.fileobj = fileobj

    def _get_references(self, erratum):
        output = []
        output.append("    <references>")

        ref_string = '       <reference href="%s%s" id="%s" type="%s">'
        for cve_ref in erratum.cve_references:
            output.append(
                ref_string
                % (
                    "http://cve.mitre.org/cgi-bin/cvename.cgi?name=",
                    cve_ref,
                    cve_ref,
                    "cve",
                )
            )
            output.append("      </reference>")

        for bz_ref in erratum.bz_references:
            output.append(
                ref_string
                % (
                    "http://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=",
                    bz_ref["bug_id"],
                    bz_ref["bug_id"],
                    "bugzilla",
                )
            )
            output.append("        " + text_filter(bz_ref["summary"]))
            output.append("      </reference>")

        output.append("    </references>")
        return output

    def _get_packages(self, erratum):
        output = []

        output.append("    <pkglist>")
        output.append(
            # pylint: disable-next=consider-using-f-string
            '      <collection short="%s">'
            % text_filter_attribute(self.channel.label)
        )
        # pylint: disable-next=consider-using-f-string
        output.append("        <name>%s</name>" % text_filter(self.channel.name))

        for package in erratum.packages:
            output.append(
                # pylint: disable-next=consider-using-f-string
                '          <package name="%s" version="%s" '
                'release="%s" epoch="%s" arch="%s" src="%s">'
                % (
                    package.name,
                    package.version,
                    package.release,
                    package.epoch,
                    package.arch,
                    text_filter(package.source_rpm),
                )
            )
            output.append(
                # pylint: disable-next=consider-using-f-string
                "            <filename>%s</filename>"
                % text_filter(package.filename)
            )
            output.append(
                # pylint: disable-next=consider-using-f-string
                '            <sum type="%s">%s</sum>'
                % (package.checksum_type, package.checksum)
            )
            output.append("          </package>")

        output.append("      </collection>")
        output.append("    </pkglist>")
        return output

    def _get_erratum(self, erratum):
        output = []

        output.append(
            '  <update from="security@redhat.com" '
            # pylint: disable-next=consider-using-f-string
            + 'status="final" type="%s" version="%s">'
            % (erratum.advisory_type, erratum.version)
        )
        # pylint: disable-next=consider-using-f-string
        output.append("    <id>%s</id>" % erratum.readable_id)
        # pylint: disable-next=consider-using-f-string
        output.append("    <title>%s</title>" % text_filter(erratum.title))
        # pylint: disable-next=consider-using-f-string
        output.append('    <issued date="%s"/>' % erratum.issued)
        # pylint: disable-next=consider-using-f-string
        output.append('    <updated date="%s"/>' % erratum.updated)
        output.append(
            "    <description>%s</description>"
            # pylint: disable-next=anomalous-backslash-in-string,consider-using-f-string
            % text_filter("%s\n\n\%s" % (erratum.synopsis, erratum.description))
        )

        output.extend(self._get_references(erratum))
        output.extend(self._get_packages(erratum))

        output.append("  </update>")

        return output

    def write_updateinfo(self):
        output = XML_ENCODING + "\n" + "<updates>\n"

        self.fileobj.write(output)

        for erratum in self.channel.errata:
            self.fileobj.write("\n".join(self._get_erratum(erratum)))

        self.fileobj.write("\n</updates>")


class RepoMDView(object):
    def __init__(self, repomd):
        self.repomd = repomd

    def get_file(self):
        repomd_file = open(self.repomd.filename, "rb")
        return repomd_file


def text_filter(text):
    # do & first
    s = text.replace("&", "&amp;")
    s = s.replace("<", "&lt;")
    s = s.replace(">", "&gt;")
    return s


def text_filter_attribute(text):
    s = text_filter(text)
    s = s.replace('"', "&quot;")
    return s
