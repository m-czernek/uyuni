// @flow
import * as React from 'react';
import {useState} from 'react';
import {Panel} from 'components/panels/Panel';
import {Button} from 'components/buttons';

import type {ClusterProviderType} from '../shared/api/use-clusters-api';

type Props = {
  selectedProvider: ?string,
  providers: Array<ClusterProviderType>,
  onNext: (string) => void
};

const SelectProvider = (props: Props) => {
    const [selectedProvider, setSelectedProvider] = useState<?string>(props.selectedProvider);
    
    return (
            <Panel
                headingLevel="h4"
                title={t("Available cluster providers")}
                footer={
                    <div className="btn-group">
                        <Button
                            id="btn-next"
                            disabled={!selectedProvider}
                            text={t("Next")}
                            className="btn-success"
                            icon="fa-arrow-right"
                            handler={() => {if (selectedProvider) { props.onNext(selectedProvider)}}}
                        />
                    </div>
                }>
                <form>
                {props.providers.map(type =>
                    <div>
                        <label>
                            <input type="radio" value={type.label} 
                                        checked={selectedProvider === type.label} 
                                        onChange={(ev: SyntheticInputEvent<HTMLInputElement>) => setSelectedProvider(ev.target.value)} />
                            {type.name}
                            <h5>{type.description}</h5>
                        </label>
                    </div>
                )}
                </form> 
            </Panel>
            );
}

export default SelectProvider;
