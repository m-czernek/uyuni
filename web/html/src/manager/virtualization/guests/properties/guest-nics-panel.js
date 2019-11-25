// @flow

const React = require('react');
const { Select } = require('components/input/Select');
const { Text } = require('components/input/Text');
const { Panel } = require('components/panels/Panel');
const { getOrderedItemsFromModel } = require('components/input/FormMultiInput');
const { Button } = require('components/buttons');
const { Messages } = require('components/messages');
const { Utils: MessagesUtils } = require('components/messages');

function addNic(model: Object, changeModel: Function, networks: Array<Object>) {
  const allNics = getOrderedItemsFromModel(model, 'network');
  const index = allNics[allNics.length - 1] + 1;
  const first_nic = networks.length > 0 ? networks[0].name : '';

  changeModel(Object.assign(model, {
    [`network${index}_type`]: 'network',
    [`network${index}_source`]: networks.find(item => item.name === 'default') ? 'default' : first_nic,
    [`network${index}_mac`]: '',
  }));
}

function guestNicFields(model: Object, index: number, networks: Array<Object>,
  onlyHandledNics: boolean, changeModel: Function): React.Node {
  const removeNic = (): void => {
    changeModel(Object.entries(model).reduce((res, entry) => {
      const property = !entry[0].startsWith(`network${index}_`) ? { [entry[0]]: entry[1] } : undefined;
      return Object.assign(res, property);
    }, {}));
  };
  const first_nic = networks.length > 0 ? networks[0].name : '';

  return (
    <Panel
      key={`network${index}`}
      title={t(`Network Interface ${model[`network${index}_mac`]}`)}
      headingLevel="h3"
      buttons={(
        <Button
          icon="fa-minus"
          title={t('Remove')}
          id={`remove_nic${index}`}
          className="btn-default btn-sm"
          handler={removeNic}
          disabled={!onlyHandledNics}
        />
      )}
    >
      {
        model[`network${index}_type`] !== 'network'
        && <Messages items={MessagesUtils.warning('Unhandled network interface type')} />
      }
      {
        model[`network${index}_type`] === 'network'
        && (
          <Select
            labelClass="col-md-3"
            divClass="col-md-6"
            label={t('Network')}
            name={`network${index}_source`}
            key={`network${index}_source`}
            disabled={!onlyHandledNics}
            required
            defaultValue={networks.find(net => net.name === 'default') ? 'default' : first_nic}
          >
            {
              networks.map(k => <option key={k.name} value={k.name}>{k.name}</option>)
            }
          </Select>
        )
      }
      <Text
        key={`network${index}_mac`}
        name={`network${index}_mac`}
        label={t('MAC address')}
        hint={t('Leave blank to generate a MAC address')}
        labelClass="col-md-3"
        divClass="col-md-6"
        disabled={!onlyHandledNics}
      />
    </Panel>
  );
}

function guestNicsPanel(model: Object, changeModel: Function, networks: Array<Object>): React.Node {
  const allNics = getOrderedItemsFromModel(model, 'network');
  const onlyHandledNics = allNics.every(index => model[`network${index}_type`] === 'network');

  return (
    <Panel
      key="network"
      title={t('Network Interfaces')}
      headingLevel="h2"
      buttons={(
        <Button
          icon="fa-plus"
          title={t('Add')}
          id="add_nic"
          className="btn-default btn-sm"
          handler={() => addNic(model, changeModel, networks)}
          disabled={!onlyHandledNics}
        />
      )}
    >
      {
        !onlyHandledNics
        && <Messages items={MessagesUtils.warning('At least one unsupported network interface: disabling editing.')} />
      }
      {
        allNics.map(net => guestNicFields(model,
          Number.parseInt(net.substring('network'.length), 10),
          networks,
          onlyHandledNics,
          changeModel))
      }
    </Panel>
  );
}

function getModelFromDefinition(definition: Object): Object {
  if (definition.interfaces === null) {
    return {};
  }

  return definition.interfaces.reduce(
    (result, nic, index) => {
      const net = {
        [`network${index}_type`]: nic.type,
        [`network${index}_source`]: nic.source,
        [`network${index}_mac`]: nic.mac,
      };
      return Object.assign(result, net);
    },
    { },
  );
}

function getRequestParams(model: Object, index: number): Object {
  return {
    type: model[`network${index}_type`],
    source: model[`network${index}_source`],
    mac: model[`network${index}_mac`],
  };
}

module.exports = {
  guestNicsPanel,
  getRequestParams,
  getModelFromDefinition,
};
