//@flow
/* global moment */
import _isEmpty from "lodash/isEmpty";
import filtersEnum from "../shared/business/filters.enum";
import type {FilterFormType, FilterServerType} from "../shared/type/filter.type";
import Functions from "utils/functions";

export function mapFilterFormToRequest(filterForm: FilterFormType, projectLabel: string, localTime: string): FilterServerType {
  const requestForm = {};
  requestForm.projectLabel = projectLabel;
  requestForm.name = filterForm.name;
  requestForm.rule = filterForm.rule;
  requestForm.entityType = filtersEnum.findByKey(filterForm.type).entityType;
  requestForm.matcher = filtersEnum.findByKey(filterForm.type).matcher;
  if (filterForm.type === filtersEnum.enum.PACKAGE_NEVRA.key) {
    const epochName = !_isEmpty(filterForm.epoch) ? `${filterForm.epoch}:` : '';
    if(_isEmpty(filterForm.architecture)){
      requestForm.criteriaKey = "nevr"
      requestForm.criteriaValue =
        `${filterForm.packageName || ""}-${epochName}${filterForm.version|| ""}-${filterForm.release|| ""}`;
    } else {
      requestForm.criteriaKey = "nevra"
      requestForm.criteriaValue =
        `${filterForm.packageName || ""}-${epochName}${filterForm.version || ""}-${filterForm.release || ""}.${filterForm.architecture}`;
    }
  } else if (filterForm.type === filtersEnum.enum.ERRATUM_PKG_NAME.key) {
    requestForm.criteriaKey = "package_name";
    requestForm.criteriaValue = filterForm.criteria;
  } else if (filterForm.type === filtersEnum.enum.ERRATUM_PKG_LT_EVR.key ||
             filterForm.type === filtersEnum.enum.ERRATUM_PKG_LE_EVR.key ||
             filterForm.type === filtersEnum.enum.ERRATUM_PKG_EQ_EVR.key ||
             filterForm.type === filtersEnum.enum.ERRATUM_PKG_GE_EVR.key ||
             filterForm.type === filtersEnum.enum.ERRATUM_PKG_GT_EVR.key) {
    const epochName = !_isEmpty(filterForm.epoch) ? `${filterForm.epoch}:` : '';
    requestForm.criteriaKey = "package_nevr"
    requestForm.criteriaValue =
      `${filterForm.packageName || ""} ${epochName}${filterForm.version|| ""}-${filterForm.release|| ""}`;
  } else if (filterForm.type === filtersEnum.enum.ERRATUM.key) {
    requestForm.criteriaKey = "advisory_name";
    requestForm.criteriaValue = filterForm.advisoryName;
  } else if (filterForm.type === filtersEnum.enum.ERRATUM_BYTYPE.key) {
    requestForm.criteriaKey = "advisory_type";
    requestForm.criteriaValue = filterForm.advisoryType;
  } else if (filterForm.type === filtersEnum.enum.ERRATUM_BYDATE.key) {
    requestForm.criteriaKey = "issue_date";
    requestForm.criteriaValue = filterForm.issueDate
      ? moment(Functions.Utils.dateWithoutTimezone(filterForm.issueDate, localTime)).format("YYYY-MM-DDTHH:mm:ss.SSSZ")
      :  "";
  } else if (filterForm.type === filtersEnum.enum.ERRATUM_BYSYNOPSIS.key || filterForm.type === filtersEnum.enum.ERRATUM_BYSYNOPSIS_CONTAINS.key) {
    requestForm.criteriaKey = "synopsis";
    requestForm.criteriaValue = filterForm.synopsis;
  } else {
    requestForm.criteriaKey = "name";
    requestForm.criteriaValue = filterForm.criteria;
  }
  return requestForm;
}

export function mapResponseToFilterForm(filtersResponse: Array<FilterServerType> = []): Array<FilterFormType> {
  return filtersResponse.map(filterResponse => {
    let filterForm = {};
    filterForm.id = filterResponse.id;
    filterForm.name = filterResponse.name;
    filterForm.rule = filterResponse.rule;
    filterForm.matcher = filterResponse.matcher;
    filterForm.projects = filterResponse.projects;

    if(filterResponse.criteriaKey === "nevr") {
      filterForm.type = filtersEnum.enum.PACKAGE_NEVRA.key;

      if(!_isEmpty(filterResponse.criteriaValue)) {
        const [
          ,
          packageName,
          ,
          epoch,
          version,
          release
        ] = filterResponse.criteriaValue.match(/(.*)-((.*):)?(.*)-(.*)/);

        filterForm.packageName = packageName;
        filterForm.epoch = epoch;
        filterForm.version = version;
        filterForm.release = release;
      }
    } else if (filterResponse.criteriaKey === "nevra") {
      filterForm.type = filtersEnum.enum.PACKAGE_NEVRA.key;

      if(!_isEmpty(filterResponse.criteriaValue)) {
        const [
          ,
          packageName,
          ,
          epoch,
          version,
          release,
          architecture
        ] = filterResponse.criteriaValue.match(/(.*)-((.*):)?(.*)-(.*)\.(.*)/);

        filterForm.packageName = packageName;
        filterForm.epoch = epoch;
        filterForm.version = version;
        filterForm.release = release;
        filterForm.architecture = architecture;
      }
    } else if(filterResponse.criteriaKey === "package_nevr") {
      if (filterForm.matcher === "contains_pkg_lt_evr") {
        filterForm.type = filtersEnum.enum.ERRATUM_PKG_LT_EVR.key;
      } else if (filterForm.matcher === "contains_pkg_le_evr") {
        filterForm.type = filtersEnum.enum.ERRATUM_PKG_LE_EVR.key;
      } else if (filterForm.matcher === "contains_pkg_eq_evr") {
        filterForm.type = filtersEnum.enum.ERRATUM_PKG_EQ_EVR.key;
      } else if (filterForm.matcher === "contains_pkg_ge_evr") {
        filterForm.type = filtersEnum.enum.ERRATUM_PKG_GE_EVR.key;
      } else if (filterForm.matcher === "contains_pkg_gt_evr") {
        filterForm.type = filtersEnum.enum.ERRATUM_PKG_GT_EVR.key;
      }

      if(!_isEmpty(filterResponse.criteriaValue)) {
        const [
          ,
          packageName,
          ,
          epoch,
          version,
          release
        ] = filterResponse.criteriaValue.match(/(.*) ((.*):)?(.*)-(.*)/);

        filterForm.packageName = packageName;
        filterForm.epoch = epoch;
        filterForm.version = version;
        filterForm.release = release;
      }
    } else if (filterResponse.criteriaKey === "advisory_name") {
      filterForm.type = filtersEnum.enum.ERRATUM.key;
      filterForm["advisoryName"] = filterResponse.criteriaValue;
    } else if (filterResponse.criteriaKey === "advisory_type") {
      filterForm.type = filtersEnum.enum.ERRATUM_BYTYPE.key;
      filterForm["advisoryType"] = filterResponse.criteriaValue;
    } else if (filterResponse.criteriaKey === "synopsis") {
      if (filterResponse.matcher === "equals") {
          filterForm.type = filtersEnum.enum.ERRATUM_BYSYNOPSIS.key;
      } else if (filterResponse.matcher === "contains") {
          filterForm.type = filtersEnum.enum.ERRATUM_BYSYNOPSIS_CONTAINS.key;
      }
      filterForm["synopsis"] = filterResponse.criteriaValue;
    } else if (filterResponse.criteriaKey === "issue_date") {
      filterForm.type = filtersEnum.enum.ERRATUM_BYDATE.key;
      filterForm["issueDate"] = Functions.Utils.dateWithTimezone(filterResponse.criteriaValue);
    } else if (filterResponse.criteriaKey === "package_name") {
      filterForm.type = filtersEnum.enum.ERRATUM_PKG_NAME.key
      filterForm.criteria = filterResponse.criteriaValue;
    } else if (filterResponse.criteriaKey === "name") {
      filterForm.type = filtersEnum.enum.PACKAGE.key;
      filterForm.criteria = filterResponse.criteriaValue;
    }

    return filterForm;
  })
}
