/*
 * pageslist.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.system 1.0

Page {
    id: plp

    function init()
    {
    	if ( !pslind.running )
    		pslind.start();
    		
    	if ( pListView.dataModel )
    		pListView.setDataModel(null);
    	
        wpu.getPosts(true);
        wpu.dataReady_getPosts.connect(plp.onDataReady);
    }

    function onDataReady() {
        var a = wpu.getRes();

        if (a["ERROR"]) {
           // myQmlToast.show();
            console.log("ERRORE");
            // wpu.resetRes();
        } else if ( a['delpost'] ) {
            if (a["delpost"] == 1) {
                deldialog.cancel();
                pslind.stop();
            } else console.log("fail to delete the page!");
        } else {
	    pListView.setDataModel(wpu.setModel("mystr"));
            pslind.stop();
        }

    }

    titleBar: TitleBar {
        title: "Pages"
    }

    actions: [
        ActionItem {
            title: "New"
            imageSource: "asset:///images/add.png"
            ActionBar.placement: ActionBarPlacement.InOverflow

        },
        ActionItem {
            title: "Refresh"
            imageSource: "asset:///images/refresh.png"

            ActionBar.placement: ActionBarPlacement.InOverflow
            
            onTriggered: {
                plp.init();
            }
        }
    ]
    
    attachedObjects: [
        SystemDialog {
            property string paid
            id: delDialog
            title: qsTr("DELETE PAGE")
            body: qsTr("Are you sure to delete this page?")
            confirmButton.label: qsTr("Yes")
            confirmButton.enabled: true
            cancelButton.label: qsTr("Cancel")
            cancelButton.enabled: true
            onFinished: {
                var x = result;
                if (x == SystemUiResult.ConfirmButtonSelection) {
                    delprog.body = "Deleting comment\nPlease wait...";
                    delprog.open();
                    pslind.start();
                    wpu.deletePost(paid);
                    wpu.dataReady_delPost.connect(cp.onDataReady);
                } else if (x == SystemUiResult.CancelButtonSelection) {
                    console.log("cancel");
                }
            }
        }
    ]

    content: Container {
        layout: DockLayout {
        }

        ActivityIndicator {
            id: pslind
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center

            preferredHeight: 500
            preferredWidth: 500

            running: true
        }

        Container {
            layout: StackLayout {
            }

            ListView {
                id: pListView
                
                function deletePage(id)
                {
                    delDialog.paid = id
                    delDialog.show();
                }

                listItemComponents: [
                    ListItemComponent {
                        type: "item"
                        id: listItemContainer

                        StandardListItem {
                            id: psli
                            
                            textFormat: TextFormat.Html
                            title: ListItemData.post_title
                            description: ListItemData.post_date
                            status: ListItemData.post_status
                            imageSpaceReserved: false

                            contextActions: [
                                ActionSet {
                                    title: ListItemData.title
                                    ActionItem {
                                        title: "Edit"
                                        imageSource: "asset:///images/edit.png";
                                        onTriggered: {

                                        }
                                    }
                                    DeleteActionItem {
                                        title: "Delete"
                                        
                                        onTriggered: {
                                            psli.ListItem.view.deletePage(psli.ListItem.page_id);
                                        }

                                    }
                                }
                            ]
                        }
                    }
                ]
                onTriggered: {
                    var selectedItem = pListView.dataModel.data(indexPath);
                }
            } // end of pListView
        }
    }

    onCreationCompleted: {
        if (! pListView.dataModel) 
        	plp.init();

    }
}
