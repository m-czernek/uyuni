// @flow
'use strict';

const React = require('react');
const Network = require('../utils/network');
const {Loading} = require('./loading');
const ChannelUtils = require('../utils/channels');
const {ChannelAnchorLink} = require("./links");

type ChildChannelsProps = {
  key: number,
  channels: Array,
  base: Object,
  showBase: Boolean,
  selectedChannelsIds: Array<number>,
  handleChannelChange: Function,
  saveState: Function,
  loadState: Function
}

type ChildChannelsState = {
  requiredChannels: Map<number, Array<number>>,
  requiredByChannels: Map<number, Array<number>>,
  mandatoryChannelsRaw: Map,
  dependencyDataAvailable: Boolean
}

class ChildChannels extends React.Component<ChildChannelsState, ChildChannelsProps> {
  constructor(props) {
    super(props);

    this.state = {
      requiredChannels: new Map(),
      requiredByChannels: new Map(),
      mandatoryChannelsRaw: new Map(),
      dependencyDataAvailable: false
    }
  }

  componentWillUnmount() {
    if (this.props.saveState) {
      this.props.saveState(this.state);
    }
  }

  componentWillMount() {
    if (this.props.loadState) {
      if (this.props.loadState()) {
        this.state = this.props.loadState();
      }
    }

    // fetch dependencies data for all child channels and base channel as well
    const needDepsInfoChannels = this.props.base && this.props.base.id != -1 ?
        [this.props.base.id, ...this.props.channels.map(c => c.id)]
      : this.props.channels.map(c => c.id);
    this.fetchMandatoryChannelsByChannelIds(needDepsInfoChannels);
  }

  fetchMandatoryChannelsByChannelIds(channelIds: Array<number>) {
    const mandatoryChannelsNotCached = channelIds.filter((channelId) => !this.state.mandatoryChannelsRaw[channelId]);
    if(mandatoryChannelsNotCached.length > 0) {
      Network.post('/rhn/manager/api/admin/mandatoryChannels', JSON.stringify(mandatoryChannelsNotCached), "application/json").promise
        .then((data : JsonResult<Map<number, Array<number>>>) => {
          const allTheNewMandatoryChannelsData = Object.assign({}, this.state.mandatoryChannelsRaw, data.data);
          let {requiredChannels, requiredByChannels} = ChannelUtils.processChannelDependencies(allTheNewMandatoryChannelsData);

          this.setState({
            mandatoryChannelsRaw: allTheNewMandatoryChannelsData,
            requiredChannels,
            requiredByChannels,
            dependencyDataAvailable: true,
          });
        })
        .catch(this.handleResponseError);
    } else {
      this.setState({
        dependencyDataAvailable: true,
      })
    }
  }

  handleResponseError(jqXHR, arg = '') {
    const msg = Network.responseErrorMessage(jqXHR,
      (status, msg) => msgMap[msg] ? t(msgMap[msg], arg) : null);
    this.setState((prevState) => ({
        messages: prevState.messages.concat(msg)
      })
    );
  }

  dependenciesTooltip = (channelId: number) => {
    const resolveChannelNames = (channelIds: Array<number>) => {
      return Array.from(channelIds || new Set())
        .map(channelId => this.props.channels.find(c => c.id == channelId))
        .filter(channel => channel != null)
        .map(channel => channel.name);
    }
    return ChannelUtils.dependenciesTooltip(
      resolveChannelNames(this.state.requiredChannels.get(channelId)),
      resolveChannelNames(this.state.requiredByChannels.get(channelId)));
  }

  render() {
    let channels;
    if(!this.state.dependencyDataAvailable) {
      channels = <Loading text='Loading dependencies..' />;
    }
    else {
      if (this.props.channels.length == 0) {
        channels = <span>&nbsp;{t('no child channels')}</span>;
      }
      else {
        channels =
          this.props.channels.map(c => {
              const toolTip = this.dependenciesTooltip(c.id);
              const isMandatory =
                  this.props.base &&
                  this.state.requiredChannels.has(this.props.base.id) &&
                  this.state.requiredChannels.get(this.props.base.id).has(c.id);
              const isDisabled = isMandatory && this.props.selectedChannelsIds.includes(c.id);
              return (
                <div key={c.id} className='checkbox'>
                  <input type='checkbox'
                      value={c.id}
                      id={'child_' + c.id}
                      name='childChannels'
                      checked={this.props.selectedChannelsIds.includes(c.id)}
                      disabled={isDisabled}
                      onChange={this.props.handleChannelChange}
                  />
                  {
                    /** HACK **/
                    // add an hidden carbon-copy of the disabled input since the disabled one will not be included in the form submit
                    isDisabled ?
                      <input type='checkbox' value={c.id} name='childChannels'
                          hidden='hidden' checked={this.props.selectedChannelsIds.includes(c.id)} readOnly={true}/>
                      : null
                  }
                  <label title={toolTip} htmlFor={"child_" + c.id}>{c.name}</label>
                  &nbsp;
                  {
                    toolTip ?
                      <a href="#"><i className="fa fa-info-circle spacewalk-help-link" title={toolTip}></i></a>
                      : null
                  }
                  &nbsp;
                  {
                    c.recommended ?
                      <span className='recommended-tag-base' title={'This channel is recommended'}>{t('recommended')}</span>
                      : null
                  }
                  {
                    isMandatory ?
                      <span className='mandatory-tag-base' title={'This channel is mandatory'}>{t('mandatory')}</span>
                      : null
                  }
                  <ChannelAnchorLink id={c.id} newWindow={true}/>
                </div>
              )
          })
      }
    }

    return (
      <div className='child-channels-block'>
        {
          this.props.showBase ?
            <h4>{this.props.base.name}</h4>
            : null
        }
        <Toggler
            handler={this.toggleRecommended.bind(this)}
            value={this.areRecommendedChildrenSelected()}
            text={t("include recommended")}
            disabled={!this.props.channels.some(channel => channel.recommended)}
        />
        {channels}
        <hr/>
      </div>
    );
  }
}

module.exports = {
  ChildChannels: ChildChannels
}