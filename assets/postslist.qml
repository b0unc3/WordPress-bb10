/*
 * postslist.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.system 1.0

Page {
    id: post_plp

    property bool post_showpage;
    property variant post_savemodel;
    property string post_type;


	onPost_showpageChanged: {
     if ( post_plp.post_showpage )
         post_type = "page";
     else post_type = "post"
    }
	
    function post_restoreItems()
    {
        if ( post_savemodel )
        {
        	post_plListView.setDataModel(null);
        	post_plListView.setDataModel(post_savemodel);
        } else {
            post_plp.post_loadData();
        }
    }

    function post_loadData() {
        if (post_plListView.dataModel) //plListView.dataModel.clear();
        	post_plListView.setDataModel(null);

        post_plind.start();
        wpu.buildWPXML("wp.getPosts", true, [], [], ["post_type"], [post_type]);
        if ( post_plp.post_showpage )
        	wpu.dataReady_getPages.connect(post_plp.post_onDataReady);
        else wpu.dataReady_getPosts.connect(post_plp.post_onDataReady);
    }

    function post_onDataReady(val) {
        var d = new Date();

        var post_pa = wpu.getRes();

        if (post_pa["ERROR"]) {
            //myQmlToast.show();
            console.log("ERRORE");
            // wpu.resetRes();
        } else if (post_pa["delpost"]) {
            if (post_pa["delpost"] == 1) {
                post_delDialog.cancel();
                post_ci_pl.close();
                post_plp.post_loadData();
            } else console.log("delete fail");

        } else {
            post_plListView.setDataModel(wpu.setModel("post_mystr"));
            post_plind.stop();
        }

    }

    titleBar: TitleBar {
        title: (!post_plp.post_showpage ) ? qsTr("Posts") : qsTr("Pages")
    }

    attachedObjects: [
        ComponentDefinition {
            id: post_showPost
            source: "showPost.qml"
        },
        ComponentDefinition {
            id: post_makePost
            source: "makePost.qml"
        },
        ComponentDefinition {
            id: post_editPost
            source: "editpost.qml"
        },
        CustomIndicator {
            id: post_ci_pl
        },
        SystemDialog {
            property string ptitle
            property string pid
            id: post_delDialog
            title: qsTr("DELETE POST")
            body: qsTr("Are you sure to delete post \"" + ptitle + "\" ?");
            //id = " + pid)
            
            confirmButton.label: qsTr("Yes")
            confirmButton.enabled: true
            cancelButton.label: qsTr("Cancel")
            cancelButton.enabled: true
            onFinished: {
                var x = result;
                if (x == SystemUiResult.ConfirmButtonSelection) {
                    post_ci_pl.body = qsTr("Deleting post \"" + ptitle + "\" \nPlease wait...");
                    post_ci_pl.open();
                    wpu.buildWPXML("wp.deletePost", true, ["post_id"], [pid], [], []);
                    wpu.dataReady_delPost.connect(post_plp.post_onDataReady);
                    /*
                    wpu.deletePost(post_plp.post_showpage,pid);
                    if ( post_plp.post_showpage )
                    	wpu.dataReady_delPage.connect(post_plp.post_onDataReady);
                    else wpu.dataReady_delPost.connect(post_plp.post_onDataReady);
                    */
                } else if (x == SystemUiResult.CancelButtonSelection) {
                    console.log("cancel");
                }
            }
        }
    ]

    actions: [
        ActionItem {
            title: qsTr("New")
            imageSource: "asset:///images/add.png"
            ActionBar.placement: ActionBarPlacement.InOverflow

            onTriggered: {
                post_savemodel = post_plListView.dataModel;
                var newPage = post_makePost.createObject();
                newPage.post_showpage = post_plp.post_showpage
                if (post_plp.post_showpage) 
                	navpagepane.push(newPage);
                else navpostpane.push(newPage);
            }
        },
        ActionItem {
            title: qsTr("Refresh")
            imageSource: "asset:///images/refresh.png"

            ActionBar.placement: ActionBarPlacement.InOverflow

            onTriggered: {
                post_plp.post_loadData();
            }
        }
    ]

    content: Container {
        layout: DockLayout {
        }

        ActivityIndicator {
            id: post_plind
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
                id: post_plListView

                listItemComponents: [
                    ListItemComponent {
                        type: "item"
                        id: post_listItemContainer

                        StandardListItem {
                            id: post_sli
                            property variant internalWpu
                            textFormat: TextFormat.Html
                            title: qsTr(ListItemData.post_title)
                            description: ListItemData.date //post_date
                            status: ListItemData.post_status
                            imageSpaceReserved: false

                            contextActions: [
                                ActionSet {
                                    title: ListItemData.post_title
                                    ActionItem {
                                        title: "Edit"
                                        imageSource: "asset:///images/edit.png"
                                        onTriggered: {
                                            post_sli.ListItem.view.post_goEdit(ListItemData.post_id);
                                        }
                                    }
                                    DeleteActionItem {
                                        title: "Delete"
                                        onTriggered: {
                                            post_sli.ListItem.view.post_goToDel(ListItemData.post_id, ListItemData.post_title)
                                        }

                                    }
                                }
                            ]
                        }
                    }
                ]
                function post_goToDel(id, title) {
                    post_delDialog.pid = id;
                    post_delDialog.ptitle = title;
                    post_delDialog.show();
                }
                function post_goEdit(id) {
                    post_savemodel = post_plListView.dataModel;
                    var p = post_editPost.createObject();
                    p.post_id = id;
                    p.post_showpage = post_plp.post_showpage;
                    if (post_plp.post_showpage) 
                    	navpagepane.push(p)
                    else navpostpane.push(p);
                }
                onTriggered: {
                    post_savemodel = post_plListView.dataModel;
                    var selectedItem = post_plListView.dataModel.data(indexPath);
                    var newPage = post_showPost.createObject();
                    newPage.post_show_page = post_plp.post_showpage;
                    newPage.sp_apostid = selectedItem.post_id;
                    if ( post_plp.post_showpage )
                    	navpagepane.push(newPage)
                    else navpostpane.push(newPage);
                }
            } // end of plListView

        }

    }
    
}

