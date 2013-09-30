/*
 * commentslist.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.system 1.0

Page {
    id: comment_cp
    
    property variant comment_cp_savemodel;
    
    function comment_restoreItems()
    {
        if ( comment_cp_savemodel )
        {
            comment_clListView.setDataModel(null);
            comment_clListView.setDataModel(comment_cp_savemodel);
        } else comment_init();
    }
    function comment_init()
    {
        if ( !comment_clind.running )
        	comment_clind.start();
        	
        if ( comment_clListView.dataModel )
        	comment_clListView.setDataModel(null);
        	
        wpu.getComments();
        wpu.dataReady_getComments.connect(comment_cp.comment_onDataReady);
    }
    
    function comment_onDataReady() {
        var comment_a = wpu.getRes();
        
        if (comment_a["ERROR"]) {
            //myQmlToast.show(); <- TBD
            console.log("ERRORE");
            // wpu.resetRes();
        } else if (comment_a["delpost"]) {
            if (comment_a["delpost"] == 1) {
                comment_cp.comment_init();
                comment_delprog.close();
                comment_deldialog.cancel();
                
                
            } else console.log("delete fail");

        } else {
	    comment_clListView.setDataModel(wpu.setModel("comment_mystr"));
            comment_clind.stop();
        }
    
    }
    
    titleBar: TitleBar {
        title: qsTr("Comments")
    }

    actions: [
        ActionItem {
            title: qsTr("Refresh")
            imageSource: "asset:///images/refresh.png"

            ActionBar.placement: ActionBarPlacement.InOverflow
            onTriggered: {
                comment_cp.comment_init();
            }
        }
    ]
    
    attachedObjects: [
        ComponentDefinition {
            id: comment_vc
            source: "viewcomment.qml"
        },
        ComponentDefinition {
            id: comment_ec
            source: "editcomment.qml"
        },
        ReplyDialog {
            id: comment_crd
            
            onClosed: {
                comment_init();
            }
        },
        CustomIndicator {
            id:comment_delprog
            
        },
        SystemDialog {
            property string cid
            id: comment_delDialog
            title: qsTr("DELETE COMMENT")
            body: qsTr("Are you sure to delete this comment?");
            confirmButton.label: qsTr("Yes")
            confirmButton.enabled: true
            cancelButton.label: qsTr("Cancel")
            cancelButton.enabled: true
            onFinished: {
                var x = result;
                if (x == SystemUiResult.ConfirmButtonSelection) {
                    comment_delprog.body = qsTr("Deleting comment\nPlease wait...");
                    comment_delprog.open();
                    wpu.deleteComment(cid);
                    wpu.dataReady_delComment.connect(comment_cp.comment_onDataReady);
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
            id: comment_clind
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
                id: comment_clListView

                property variant commentsbyid: {'ciao': 'test'}

				function goEdit(id)
				{
				    comment_cp_savemodel = comment_clListView.dataModel;
                    var p = comment_ec.createObject();
                    p.ec_comment_id = id;
                    navcommentspane.push(p);
                }
				function rep(id, pid)
				{
				    comment_crd.post_id = pid
				    comment_crd.parent_id = id;
				    comment_crd.open();
				}
                function delComment(id) {
                    comment_delDialog.cid = id;
                    comment_delDialog.show();
                }

                function modIt(id, action) {
                    comment_clind.start();
                    comment_clListView.resetDataModel();
                    wpu.editComment(id, action, "", "", "", "");
                    wpu.dataReady_editComment.connect(comment_clListView.comment_onDataReady);
                }

                function comment_onDataReady(val)
                {
                    var comment_ca = wpu.getRes();

                    if (comment_ca["ERROR"]) {
                        //myQmlToast.show();
                        console.log("ERRORE");
                        // wpu.resetRes();
                    } else if (comment_ca["delpost"]) {
                        if (comment_ca["delpost"] == 1) {
                            wpu.getComments();
                            wpu.dataReady_getComments.connect(comment_cp.comment_onDataReady);
                        } else console.log("mod fail");

                    }
                }
                
                onDataModelChanged: {
                    if ( comment_clListView.dataModel ) //<-- needs to debug!
                    {
                    	for (var i=0;i<comment_clListView.dataModel.size();i++)
                    	{
                         	var cid = comment_clListView.dataModel.data([ i ]).comment_id
                            var aut = comment_clListView.dataModel.data([ i ]).author
                            var temp = comment_clListView.commentsbyid;
                            temp[""+cid] = aut;
                            comment_clListView.commentsbyid = temp;
                        }
                    }
                }

                listItemComponents: [
                    ListItemComponent {
                        type: "item"
                        id: comment_listItemContainer

                        StandardListItem {
                            id: comment_csli
                            
                            function getDescription(p,d)
                            {   
                                if ( p != "0" )
                                {   
                                 	if (comment_csli.ListItem.view.commentsbyid["" + p]) 
                                 		return d + "<i> in reply to </i>" + comment_csli.ListItem.view.commentsbyid["" + p];
                                 	else return d;
                                } else return d;
                                
                            }
                            function getStatus(s)
                            {
                                if ( s == "approve" )
                                	return "<html><p style='color: green;'><b>" + s + "</b></p></html>";
                                else if ( s == "hold" )
                                	return "<html><p style='color: orange;'><b>" + s + "</b></p></html>";
                                else return s;

                            }
                            
                            textFormat: TextFormat.Html
                            title: qsTr(ListItemData.content)
                            description: getDescription(ListItemData.parent, ListItemData.author)
                            status: getStatus(ListItemData.status) // + "\n" + ListItemData.date //_created_gmt
                            imageSpaceReserved: false
                            
                            property bool current_status: (ListItemData.status == "hold")

                            contextActions: [
                                ActionSet {
                                    //title: ListItemData.title
                                    ActionItem {
                                        title: qsTr("Approve");
                                        imageSource: "asset:///images/approve.png"
                                        enabled: current_status
                                        
                                        onTriggered: {
                                            
                                            comment_csli.ListItem.view.modIt(ListItemData.comment_id, "approve");

                                        }
                                    }
                                    ActionItem {
                                        title: qsTr("Unapprove")
                                        enabled: !current_status //ListItemData.status == "approve"
                                        imageSource: "asset:///images/unapprove.png"

                                        onTriggered: {
                                            comment_csli.ListItem.view.modIt(ListItemData.comment_id, "hold");
                                        }
                                    }
                                    ActionItem {
                                        title: qsTr("Reply")
                                        imageSource: "asset:///images/reply.png"
                                        
                                        onTriggered: {
                                            comment_csli.ListItem.view.rep(ListItemData.comment_id, ListItemData.post_id);
                                        }
                                    }
                                    ActionItem {
                                        title: qsTr("Edit")
                                        imageSource: "asset:///images/edit.png"
                                        onTriggered: {
                                            comment_csli.ListItem.view.goEdit(ListItemData.comment_id);

                                        }
                                    }
                                    ActionItem {
                                        title: qsTr("Spam")
                                        imageSource: "asset:///images/spam.png"
                                        
                                        onTriggered: {
                                            comment_csli.ListItem.view.modIt(ListItemData.comment_id, "spam");
                                        }
                                    }
                                    DeleteActionItem {
                                        title: qsTr("Trash")
                                        
                                        onTriggered: {
                                            comment_csli.ListItem.view.delComment(ListItemData.comment_id);
                                        }

                                    }
                                }
                            ]
                        }
                    }
                ]
                onTriggered: {
                    comment_cp_savemodel = comment_clListView.dataModel;
                    var selectedItem = comment_clListView.dataModel.data(indexPath);
                    var vc_p = comment_vc.createObject();
                    vc_p.vc_cid = selectedItem.comment_id
                    navcommentspane.push(vc_p);
                }
                
            } // end of clListView
        }
    }
    
    onCreationCompleted: {
        if ( !comment_clListView.dataModel )
        	comment_cp.comment_init();
    }
}

