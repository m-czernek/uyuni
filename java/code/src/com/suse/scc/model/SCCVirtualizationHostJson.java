/*
 * Copyright (c) 2023 SUSE LLC
 *
 * This software is licensed to you under the GNU General Public License,
 * version 2 (GPLv2). There is NO WARRANTY for this software, express or
 * implied, including the implied warranties of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
 * along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 *
 * Red Hat trademarks are not licensed under GPLv2. No permission is
 * granted to use or replicate Red Hat trademarks that are incorporated
 * in this software or its documentation.
 */
package com.suse.scc.model;

import com.redhat.rhn.domain.server.Server;
import com.redhat.rhn.domain.server.VirtualInstance;

import com.google.gson.annotations.SerializedName;

/**
 * SCCVirtualizationHostJson
 */
public class SCCVirtualizationHostJson {

    private String identifier;

    @SerializedName("group_name")
    private String groupName;

    private SCCVirtualizationHostPropertiesJson properties;

    private SCCVirtualizationHostSystemsJson systems;

    /**
     * Constructor
     * @param identifierIn the host identifier
     * @param groupNameIn the group name
     * @param propertiesIn host properties
     * @param systemsIn virtual system list
     */
    public SCCVirtualizationHostJson(String identifierIn, String groupNameIn,
                                     SCCVirtualizationHostPropertiesJson propertiesIn,
                                     SCCVirtualizationHostSystemsJson systemsIn) {
        identifier = identifierIn;
        groupName = groupNameIn;
        properties = propertiesIn;
        systems = systemsIn;
    }

    /**
     * Constructor
     * @param identifierIn the host identifier
     * @param s the server object of the host
     * @param vi the virtual instance object
     */
    public SCCVirtualizationHostJson(String identifierIn, Server s, VirtualInstance vi) {
        identifier = identifierIn;
        groupName = s.getName();
        properties = new SCCVirtualizationHostPropertiesJson(s, vi);
        systems = new SCCVirtualizationHostSystemsJson(vi);
    }

    /**
     * @return the identifier
     */
    public String getIdentifier() {
        return identifier;
    }

    /**
     * @return the group name
     */
    public String getGroupName() {
        return groupName;
    }

    /**
     * @return the host properties
     */
    public SCCVirtualizationHostPropertiesJson getProperties() {
        return properties;
    }

    /**
     * @return the virtual systems
     */
    public SCCVirtualizationHostSystemsJson getSystems() {
        return systems;
    }
}
