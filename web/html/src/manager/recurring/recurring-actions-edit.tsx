import * as React from "react";

import _isEqual from "lodash/isEqual";

import { Button } from "components/buttons";
import { AsyncButton } from "components/buttons";
import { InnerPanel } from "components/panels/InnerPanel";
import { RecurringEventPicker } from "components/picker/recurring-event-picker";
import { Toggler } from "components/toggler";

import Network from "utils/network";

import { DisplayHighstate } from "../state/display-highstate";

type Props = {
  schedule?: any;
  onEdit: (arg0: any) => any;
  onActionChanged: (arg0: any) => any;
};

type State = {
  minions?: any[];
  active: boolean;
  targetId?: any;
  recurringActionId?: any;
  scheduleName?: any;
  type?: any;
  targetType?: any;
  cron?: any;
  details?: any;
};

class RecurringActionsEdit extends React.Component<Props, State> {
  constructor(props) {
    super(props);

    this.state = {
      minions: window.minions,
      active: true,
      details: {},
    };

    if (this.isEdit()) {
      this.setSchedule(this.props.schedule);
    } else {
      this.getTargetType();
    }
  }

  getDetailsData(): void {
    Network.get(`/rhn/manager/api/recurringactions/${this.props.schedule.recurringActionId}/details`)
      .then((details) => {
        this.setState({ details });
      })
      .catch((e) => console.log(e));
  }

  componentDidMount(): void {
    if (this.props.schedule && this.props.schedule.recurringActionId) {
      this.getDetailsData();
    }
  }

  componentDidUpdate(prevProps: Readonly<Props>, prevState: Readonly<State>, snapshot?: any): void {
    if (!_isEqual(prevProps.schedule, this.props.schedule)) {
      this.getDetailsData();
    }
  }

  setSchedule = (schedule) => {
    Object.assign(this.state, schedule);
  };

  getTargetType = () => {
    if (window.entityType === "GROUP") {
      Object.assign(this.state, {
        targetType: window.entityType,
        targetId: window.groupId,
      });
    } else if (window.entityType === "ORG") {
      Object.assign(this.state, {
        targetType: window.entityType,
        targetId: window.orgId,
      });
    } else if (window.entityType === "MINION") {
      Object.assign(this.state, {
        targetType: window.entityType,
        targetId: window.minions?.[0].id,
      });
    }
  };

  isEdit = () => {
    return this.props.schedule ? true : false;
  };

  onEdit = () => {
    return this.props.onEdit({
      targetId: this.state.targetId,
      recurringActionId: this.state.recurringActionId,
      scheduleName: this.state.scheduleName,
      active: this.state.active,
      targetType: this.state.targetType,
      cron: this.state.cron,
      details: this.state.details,
    });
  };

  onScheduleNameChanged = (scheduleName) => {
    this.setState({ scheduleName: scheduleName });
  };

  onToggleActive = (active) => {
    this.setState({ active: active });
  };

  onTypeChanged = (type) => {
    let { details } = this.state;
    details.type = type;
    this.setState({ details });
  };

  onCronTimesChanged = (cronTimes) => {
    let { details } = this.state;
    details.cronTimes = cronTimes;
    this.setState({ details });
  };

  onCustomCronChanged = (cron) => {
    this.setState({ cron: cron });
  };

  toggleTestState = () => {
    let { details } = this.state;
    details.test = !this.state.details.test;
    this.setState({ details });
  };

  render() {
    if (!this.state.details.type && this.isEdit()) {
      return false;
    }
    const buttons = [
      <div className="btn-group pull-right">
        <Toggler
          text={t("Test mode")}
          value={this.state.details.test}
          className="btn"
          handler={this.toggleTestState.bind(this)}
        />
        <AsyncButton
          action={this.onEdit}
          defaultType="btn-success"
          text={(this.isEdit() ? t("Update ") : t("Create ")) + t("Schedule")}
        />
      </div>,
    ];
    const buttonsLeft = [
      <div className="btn-group pull-left">
        <Button
          id="back-btn"
          className="btn-default"
          icon="fa-chevron-left"
          text={t("Back to list")}
          handler={() => this.props.onActionChanged("back")}
        />
      </div>,
    ];

    return (
      <InnerPanel
        title={t("Schedule Recurring Highstate")}
        icon="spacewalk-icon-salt"
        buttonsLeft={buttonsLeft}
        buttons={buttons}
      >
        <RecurringEventPicker
          timezone={window.timezone}
          scheduleName={this.state.scheduleName}
          type={this.state.details.type}
          cron={this.state.cron}
          cronTimes={this.state.details.cronTimes}
          onScheduleNameChanged={this.onScheduleNameChanged}
          onTypeChanged={this.onTypeChanged}
          onCronTimesChanged={this.onCronTimesChanged}
          onCronChanged={this.onCustomCronChanged}
        />
        {window.entityType === "NONE" ? null : <DisplayHighstate minions={this.state.minions} />}
      </InnerPanel>
    );
  }
}

export { RecurringActionsEdit };
