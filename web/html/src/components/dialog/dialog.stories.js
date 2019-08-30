import React from 'react';
import { storiesOf } from '@storybook/react';
import { DeleteDialog } from "./DeleteDialog";
import { ModalLink } from "./ModalLink";


storiesOf('Dialogs', module)
  .add('delete dialog', () => (
    <div>
      <div style={{height: "100px", display: "flex", alignItems: "center",  justifyContent:"center"}}>
        <ModalLink
          id={`delete-modal-link`}
          text="delete (Click me for Testing the modal!!)"
          target="delete-modal"
        />
      </div>
      <DeleteDialog id="delete-modal"
                    title={t("Delete project")}
                    content={
                      <span>
                        {t("Are you sure you want to delete project ")}
                        <strong>{'CLM2'}</strong>
                      </span>
                    }
                    onConfirm={() => alert("deleted pressed")}
                    onClosePopUp={() => alert("modal closed")}
      />
    </div>
  ))

