/**
 * Copyright (c) 2016 SUSE LLC
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
package com.suse.manager.webui.services;

import com.redhat.rhn.common.conf.ConfigDefaults;
import com.redhat.rhn.domain.channel.Channel;
import com.redhat.rhn.domain.org.Org;
import com.redhat.rhn.domain.server.ManagedServerGroup;
import com.redhat.rhn.domain.server.MinionServer;
import com.redhat.rhn.domain.server.MinionServerFactory;
import com.redhat.rhn.domain.server.ServerGroup;
import com.redhat.rhn.domain.server.ServerGroupFactory;
import com.redhat.rhn.domain.state.OrgStateRevision;
import com.redhat.rhn.domain.state.ServerGroupStateRevision;
import com.redhat.rhn.domain.state.ServerStateRevision;
import com.redhat.rhn.domain.state.StateFactory;
import com.redhat.rhn.domain.state.StateRevision;
import com.redhat.rhn.domain.user.User;
import com.suse.manager.webui.controllers.StatesAPI;
import com.suse.manager.webui.services.impl.SaltAPIService;
import com.suse.manager.webui.utils.SaltCustomState;
import com.suse.manager.webui.utils.SaltPillar;
import com.suse.manager.webui.utils.TokenBuilder;
import org.apache.log4j.Logger;
import org.jose4j.lang.JoseException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static com.suse.manager.webui.utils.SaltFileUtils.defaultExtension;

/**
 * Service to manage the Salt states generated by Suse Manager.
 */
public class SaltStateGeneratorService {

    /** Logger */
    private static final Logger LOG = Logger.getLogger(SaltStateGeneratorService.class);

    private static class LazyHolder {
        // Inner classes are not loaded until they are referenced
        private static final SaltStateGeneratorService INSTANCE = new SaltStateGeneratorService();
    }

    public static final String SERVER_SLS_PREFIX = "custom_";
    public static final String SALT_CUSTOM_STATES = "custom";

    public static final String PILLAR_DATA_PATH = "/srv/susemanager/pillar_data";

    public static final String PILLAR_DATA_FILE_PREFIX = "pillar";

    public static final String PILLAR_DATA_FILE_EXT = "yml";

    private String generatedSlsRoot;

    private String pillarDataPath;

    public SaltStateGeneratorService() {
        generatedSlsRoot = SaltCustomStateStorageManager.GENERATED_SLS_ROOT;
        pillarDataPath = PILLAR_DATA_PATH;
    }

    public static SaltStateGeneratorService instance() {
        return LazyHolder.INSTANCE;
    }

    /**
     * Generate server specific pillar if the given server is a minion.
     * @param minion the minion server
     */
    public void generatePillar(MinionServer minion) {
        LOG.debug("Generating pillar file for server name= " + minion.getName() +
                " digitalId=" + minion.getDigitalServerId());

        List<ManagedServerGroup> groups = ServerGroupFactory.listManagedGroups(minion);
        List<Long> groupIds = groups.stream()
                .map(g -> g.getId()).collect(Collectors.toList());
        SaltPillar pillar = new SaltPillar();
        pillar.add("org_id", minion.getOrg().getId());
        pillar.add("group_ids", groupIds.toArray(new Long[groupIds.size()]));

        Map<String, Object> chanPillar = new HashMap<>();
        try {
            TokenBuilder tokenBuilder = new TokenBuilder(minion.getOrg().getId());
            tokenBuilder.useServerSecret();
            String token = tokenBuilder.getToken();

            for (Channel chan : minion.getChannels()) {
                Map<String, Object> chanProps = new HashMap<>();
                chanProps.put("alias", "susemanager:" + chan.getLabel());
                chanProps.put("name", chan.getName());
                chanProps.put("enabled", "1");
                chanProps.put("autorefresh", "1");
                chanProps.put("host", ConfigDefaults.get().getCobblerHost());
                chanProps.put("token", token);
                chanProps.put("type", "rpm-md");
                chanProps.put("gpgcheck", "0");
                chanProps.put("repo_gpgcheck", "0");
                chanProps.put("pkg_gpgcheck", "1");

                chanPillar.put(chan.getLabel(), chanProps);

            }
            pillar.add("channels", chanPillar);
        }
        catch (JoseException e) {
            LOG.error(String.format(
                "Generating channel pillar for server with serverId '%s' failed.",
                minion.getId()), e);
        }

        try {
            Path baseDir = Paths.get(pillarDataPath);
            Files.createDirectories(baseDir);
            Path filePath = baseDir.resolve(getServerPillarFileName(minion));
            com.suse.manager.webui.utils.SaltStateGenerator saltStateGenerator =
                    new com.suse.manager.webui.utils.SaltStateGenerator(filePath.toFile());
            saltStateGenerator.generate(pillar);
        }
        catch (IOException e) {
            LOG.error(e.getMessage(), e);
        }
    }

    private String getServerPillarFileName(MinionServer minion) {
        return PILLAR_DATA_FILE_PREFIX + "_" +
               minion.getMinionId() + "." +
               PILLAR_DATA_FILE_EXT;
    }

    /**
     * Remove the corresponding pillar data if the server is a minion.
     * @param minion the minion server
     */
    public void removePillar(MinionServer minion) {
        LOG.debug("Removing pillar file for server name= " + minion.getName() +
                " digitalId=" + minion.getDigitalServerId());
        Path baseDir = Paths.get(pillarDataPath);
        Path filePath = baseDir.resolve(
                getServerPillarFileName(minion));
        try {
            Files.deleteIfExists(filePath);
        }
        catch (IOException e) {
            LOG.error("Could not remove pillar file " + filePath);
        }
    }

    /**
     * Remove the custom states assignments for minion server.
     * @param minion the minion server
     */
    public void removeCustomStateAssignments(MinionServer minion) {
        removeCustomStateAssignments(getServerStateFileName(server.getDigitalServerId()));
    }

    /**
     * Remove the custom states assignments for server group.
     * @param group the server group
     */
    public void removeCustomStateAssignments(ServerGroup group) {
        removeCustomStateAssignments(getGroupStateFileName(group.getId()));
    }

    /**
     * Remove the custom states assignments for an organization.
     * @param org the organization
     */
    public void removeCustomStateAssignments(Org org) {
        removeCustomStateAssignments(getOrgStateFileName(org.getId()));
    }

    private void removeCustomStateAssignments(String file) {
        Path baseDir = Paths.get(generatedSlsRoot, SALT_CUSTOM_STATES);
        Path filePath = baseDir.resolve(defaultExtension(file));

        try {
            Files.deleteIfExists(filePath);
        }
        catch (IOException e) {
            LOG.error(e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Generate .sls file to assign custom states to a server.
     * @param serverStateRevision the state revision of a server
     */
    public void generateServerCustomState(ServerStateRevision serverStateRevision) {
        serverStateRevision.getServer().asMinionServer().ifPresent(minion -> {
            LOG.debug("Generating custom state SLS file for server: " + minion.getId());

            generateCustomStates(minion.getOrg().getId(), serverStateRevision,
                    getServerStateFileName(server.getDigitalServerId()));
        });
    }

    /**
     * Generate .sls file to assign custom states to a server group.
     * @param groupStateRevision the state revision of a server group
     */
    public void generateGroupCustomState(ServerGroupStateRevision groupStateRevision) {
        ServerGroup group = groupStateRevision.getGroup();
        LOG.debug("Generating custom state SLS file for server group: " + group.getId());

        generateCustomStates(group.getOrg().getId(), groupStateRevision,
                getGroupStateFileName(group.getId()));
    }

    /**
     * Generate .sls file to assign custom states to an org.
     * @param orgStateRevision the state revision of an org
     */

    public void generateOrgCustomState(OrgStateRevision orgStateRevision) {
        Org org = orgStateRevision.getOrg();
        LOG.debug("Generating custom state SLS file for organization: " + org.getId());

        generateCustomStates(org.getId(), orgStateRevision,
                getOrgStateFileName(org.getId()));
    }

    private void generateCustomStates(long orgId, StateRevision stateRevision,
                                      String fileName) {
        Set<String> stateNames = stateRevision.getCustomStates()
                .stream()
                .filter(s-> !s.isDeleted()) // skip deleted states
                .map(s -> s.getStateName())
                .collect(Collectors.toSet());

        generateCustomStateAssignmentFile(orgId, fileName, stateNames);
    }

    private void generateCustomStateAssignmentFile(long orgId, String fileName,
        Set<String> stateNames) {
        stateNames = SaltAPIService.INSTANCE.resolveOrgStates(
                orgId, stateNames);

        Path baseDir = Paths.get(generatedSlsRoot, SALT_CUSTOM_STATES);
        try {
            Files.createDirectories(baseDir);
            Path filePath = baseDir.resolve(defaultExtension(fileName));
            com.suse.manager.webui.utils.SaltStateGenerator saltStateGenerator =
                    new com.suse.manager.webui.utils.SaltStateGenerator(filePath.toFile());
            saltStateGenerator.generate(new SaltCustomState(stateNames));
        }
        catch (IOException e) {
            LOG.error(e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Generate pillar and custom states assignments for a
     * newly registered server.
     * @param minion newly registered minion
     */
    public void registerServer(MinionServer minion) {
        // TODO create an empty revision ?
        generatePillar(minion);
        generateCustomStateAssignmentFile(minion.getOrg().getId(),
                getServerStateFileName(server.getDigitalServerId()),
                Collections.emptySet());
    }

    /**
     * Remove pillars and custom states assignments of a server.
     * @param minion the minion
     */
    public void removeServer(MinionServer minion) {
        removePillar(minion);
        removeCustomStateAssignments(minion);
    }

    /**
     * Remove custom states assignments of a group.
     * @param group the group
     */
    public void removeServerGroup(ServerGroup group) {
        removeCustomStateAssignments(group);
    }

    /**
     * Remove custom states assignments of all servers in that org.
     * @param org the org
     */
    public void removeOrg(Org org) {
        MinionServerFactory.lookupByOrg(org.getId()).stream()
                .forEach(this::removeServer);
        removeCustomStateAssignments(org);
    }

    /**
     * Regenerate custom state assignments for org, group and severs where
     * the given state is used.
     * @param orgId org id
     * @param name custom state name
     */
    public void regenerateCustomStates(long orgId, String name) {
        StateFactory.CustomStateRevisionsUsage usage = StateFactory
                .latestStateRevisionsByCustomState(orgId, name);
        regenerateCustomStates(usage);
    }

    /**
     * Regenerate custom state assignments for org, group and severs for
     * the given usages.
     * @param usage custom states usages
     */
    public void regenerateCustomStates(StateFactory.CustomStateRevisionsUsage usage) {
        usage.getServerStateRevisions().forEach(rev ->
                generateServerCustomState(rev)
        );
        usage.getServerGroupStateRevisions().forEach(rev ->
                generateGroupCustomState(rev)
        );
        usage.getOrgStateRevisions().forEach(rev ->
                generateOrgCustomState(rev)
        );
    }

    /**
     * Regenerate pillar with the new org and create a new state revision without
     * any package or custom states.
     * @param minion the migrated server
     * @param user the user performing the migration
     */
    public void migrateServer(MinionServer minion, User user) {
        // generate a new state revision without any package or custom states
        ServerStateRevision newStateRev = StateRevisionService.INSTANCE
                .cloneLatest(minion, user, false, false);
        StateFactory.save(newStateRev);

        // refresh pillar, custom and package states
        generatePillar(minion);
        generateServerCustomState(newStateRev);
        StatesAPI.generateServerPackageState(minion);
    }

    private String getGroupStateFileName(long groupId) {
        return "group_" + groupId;
    }

    private String getOrgStateFileName(long orgId) {
        return "org_" + orgId;
    }


    private String getServerStateFileName(String digitalServerId) {
        return SERVER_SLS_PREFIX + digitalServerId;
    }


    /**
     * @param groupId the id of the server group
     * @return the name of the generated server group .sls file.
     */
    public String getServerGroupGeneratedStateName(long groupId) {
        return SALT_CUSTOM_STATES + "." + getGroupStateFileName(groupId);
    }

    /**
     * @param generatedSlsRootIn the root path where state files are generated
     */
    public void setGeneratedSlsRoot(String generatedSlsRootIn) {
        this.generatedSlsRoot = generatedSlsRootIn;
    }

    /**
     * @param generatedPillarRootIn the root path where pillar files are generated
     */
    public void setPillarDataPath(String generatedPillarRootIn) {
        this.pillarDataPath = generatedPillarRootIn;
    }

    /**
     * @return the root path where pillar files are generated
     */
    public String getPillarDataPath() {
        return this.pillarDataPath;
    }

    /**
     * Generate state files for a new server group.
     * @param serverGroup the new server group
     */
    public void createServerGroup(ServerGroup serverGroup) {
        generateCustomStateAssignmentFile(serverGroup.getOrg().getId(),
                getGroupStateFileName(serverGroup.getId()),
                Collections.emptySet());
    }

    /**
     * Generate state files for a new org.
     * @param org the new org
     */
    public void createOrg(Org org) {
        generateCustomStateAssignmentFile(org.getId(),
                getOrgStateFileName(org.getId()),
                Collections.emptySet());
    }
}
