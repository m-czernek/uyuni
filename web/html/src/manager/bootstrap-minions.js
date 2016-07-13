'use strict';

const React = require("react");
const ReactDOM = require("react-dom");
const Panel = require("../components/panel").Panel;
const Messages = require("../components/messages").Messages;
const Network = require("../utils/network");
const {AsyncButton, LinkButton} = require("../components/buttons");

class BootstrapMinions extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            host: "",
            port: "22",
            user: "root",
            password: "",
            availableActivationKeys: availableActivationKeys,
            activationKey: "",
            ignoreHostKeys: false,
            messages: []
        };
        ["hostChanged", "portChanged", "userChanged", "passwordChanged", "onBootstrap", "ignoreHostKeysChanged", "activationKeyChanged"]
            .forEach(method => this[method] = this[method].bind(this));
    }


    hostChanged(event) {
        this.setState({
            host: event.target.value
        });
    }

    portChanged(event) {
        this.setState({
            port: event.target.value
        });
    }

    userChanged(event) {
        this.setState({
            user: event.target.value
        });
    }

    passwordChanged(event) {
        this.setState({
            password: event.target.value
        });
    }

    ignoreHostKeysChanged(event) {
        this.setState({
            ignoreHostKeys: event.target.checked
        });
    }

    activationKeyChanged(event) {
        this.setState({
            activationKey: event.target.value
        });
    }

    onBootstrap() {
        var formData = {};
        formData['host'] = this.state.host.trim();
        formData['port'] = this.state.port.trim();
        formData['user'] = this.state.user.trim();
        formData['password'] = this.state.password.trim();
        formData['activationKeys'] = this.state.activationKey === "" ? [] : [this.state.activationKey] ;
        formData['ignoreHostKeys'] = this.state.ignoreHostKeys;

        const request = Network.post(
            window.location.href,
            JSON.stringify(formData),
            "application/json"
        ).promise.then(data => {
            this.setState({
                success: data.success,
                messages: data.messages
            });
        }, (xhr) => {
            try {
                this.setState({
                    success: false,
                    messages: [JSON.parse(xhr.responseText)]
                })
            } catch (err) {
                this.setState({
                    success: false,
                    messages: [Network.errorMessageByStatus(xhr.status)]
                })
            }
        });
        return request;
    }

    render() {
        var messages = [];
        if (this.state.success && this.state.messages.length > 0) {
            messages = <Messages items={this.state.messages.map(function(msg) {
                return {severity: "info", text: msg};
            })}/>;
        } else if (this.state.messages.length > 0) {
            messages = <Messages items={this.state.messages.map(function(msg) {
                return {severity: "error", text: msg};
            })}/>;
        }

        var buttons = [
            <AsyncButton id="bootstrap-btn" icon="plus" name={t("Bootstrap")} action={this.onBootstrap}/>,
            <LinkButton id="cancel-btn" className="btn-default pull-right" text={t("Back to System Overview")} href="/rhn/systems/Overview.do"/>
        ];

        return (
        <Panel title={t("Bootstrap Minions")} icon="spacewalk-icon-salt-add">
            {messages}
            <div className="form-horizontal">
                <div className="form-group">
                    <label className="col-md-3 control-label">Host:</label>
                    <div className="col-md-6">
                        <input name="hostname" className="form-control" type="text" placeholder={t("e.g., host.domain.com")} onChange={this.hostChanged}/>
                    </div>
                </div>
                <div className="form-group">
                    <label className="col-md-3 control-label">SSH Port:</label>
                    <div className="col-md-6">
                        <input name="port" className="form-control numeric" type="text" maxLength="5"
                          defaultValue={this.state.port} onChange={this.portChanged} onKeyPress={numericValidate}
                          title={t('Port range: 1 - 65535')}/>
                    </div>
                </div>
                <div className="form-group">
                    <label className="col-md-3 control-label">User:</label>
                    <div className="col-md-6">
                        <input name="user" className="form-control" type="text" defaultValue={this.state.user} onChange={this.userChanged}/>
                    </div>
                </div>
                <div className="form-group">
                    <label className="col-md-3 control-label">Password:</label>
                    <div className="col-md-6">
                        <input name="password" className="form-control" type="password" placeholder={t("e.g., ••••••••••••")} onChange={this.passwordChanged}/>
                    </div>
                </div>
                <div className="form-group">
                    <label className="col-md-3 control-label">Activation Key:</label>
                    <div className="col-md-6">
                       <select value={this.state.activationKey} onChange={this.activationKeyChanged} className="form-control" name="activationKeys">
                         <option key="none" value="">None</option>
                         {
                             this.state.availableActivationKeys.map(k =>
                                <option key={k} value={k}>{ k }</option>
                             )
                         }
                       </select>
                    </div>
                </div>
                <div className="form-group">
                    <div className="col-md-3"></div>
                    <div className="col-md-6">
                        <div className="checkbox">
                            <label>
                                <input name="ignoreHostKeys" type="checkbox" checked={this.state.ignoreHostKeys} onChange={this.ignoreHostKeysChanged}/>
                                <span>Disable strict host key checking</span>
                            </label>
                        </div>
                    </div>
                </div>
                <div className="form-group">
                    <div className="col-md-offset-3 col-md-6">
                        {buttons}
                    </div>
                </div>
            </div>
        </Panel>
        )
    }
}

ReactDOM.render(
    <BootstrapMinions />,
    document.getElementById('bootstrap-minions')
);
