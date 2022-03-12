/* eslint-disable */
'use strict';

import * as React from 'react';
import ReactDOM from 'react-dom';
import { AsyncButton, Button } from 'components/buttons';
import Network from 'utils/network';
import { Messages } from 'components/messages';
import { Utils as MessagesUtils } from 'components/messages';
import { Utils } from 'utils/functions';
import { Dialog } from 'components/dialog/Dialog';
import { showDialog } from 'components/dialog/util';
import { DeleteDialog } from 'components/dialog/DeleteDialog';

const msgMap = {
  "minion_unreachable": t("Cleanup timed out. Please check if the machine is reachable."),
  "apply_result_missing" : t("No result found in state apply response.")
};

class DeleteSystem extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      messages: [],
      cleanupErr: false
    };
  }

  handleDelete = (cleanupErr) => {
    const nocleanupParam = cleanupErr ? {"nocleanup": "true"} : {};
    return Network.post(`/rhn/manager/api/systems/${this.props.serverId}/delete`, $.param(nocleanupParam))
    .promise.then(data => {
        if (data.success && this.props.onDeleteSuccess) {
          this.props.onDeleteSuccess();
        } else {
          this.setState({
            messages: MessagesUtils.error(data.messages.map(m => msgMap[m]))
          });
          this.showErrorDialog();
        }

    })
    .catch(jqXHR => {
      this.handleResponseError(jqXHR);
    });
  }

  handleResponseError = (jqXHR, arg = "") => {
    this.setState({
      messages:
            Network.responseErrorMessage(jqXHR,
              (status, msg) => msgMap[msg] ? t(msgMap[msg], arg) : null)
    });
    this.showErrorDialog();
  }

  showErrorDialog = () => {
        showDialog("delete-errors-" + this.props.serverId);
  }

  render() {
    const buttons = <span>
            <AsyncButton
                id={"btn-delete-confirm-" + this.props.serverId}
                text={t("Delete Profile Without Cleanup") }
                title={t("Delete Profile Without Cleanup") }
                icon="fa-trash"
                defaultType={this.props.buttonClass}
                action={() => this.handleDelete(true)}
            />
            <Button
                className="btn-default"
                text={t("Cancel")}
                title={t("Cancel")}
                icon="fa-close"
                handler={() => {
                    jQuery("#delete-errors-" + this.props.serverId).modal('hide');
                }}
            />
    </span>
    return (<span>
      <Dialog id={"delete-errors-" + this.props.serverId}
        title={t("An error occurred during cleanup")}
        content={this.state.messages.length > 0 && <Messages items={this.state.messages}/>}
        buttons={buttons}
      />
      <AsyncButton id={"btn-delete-" + this.props.serverId}
        icon="fa-trash"
        action={() => this.handleDelete(false)}
        text={this.props.buttonText}
        defaultType={this.props.buttonClass}
        />
    </span>);
  }

}

export {
  DeleteSystem,
};