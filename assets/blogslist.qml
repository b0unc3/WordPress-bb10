/*
 * blogslist.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.data 1.0
import bb.system 1.0

Page {
    id: blp
    
    property string blogid: ""
    property string blogurl: ""
    
    property string mystr;
    property alias bl_xml: blp.mystr
    
    actions: [
        MultiSelectActionItem {
            id: msa
            multiSelectHandler: listView.multiSelectHandler
            title: qsTr("select blog(s)")
        }
    ]
    
    attachedObjects: [
        SystemToast {
            id: myQmlToast
            body: qsTr("Unable to register account\nPlease try again.")
            button.label: "Ok"
            button.enabled: true
        }
    
    ]
    
    function moveOn()
    {
        navigationPane.mb = true;
        navigationPane.pop();
    }
    
    onMystrChanged: {
        listView.setDataModel(wpu.setModel(mystr));
    }
    
    content: Container {
        layout: DockLayout {}
        
        ListView {
            id: listView
            multiSelectAction: MultiSelectActionItem { }
            

            multiSelectHandler {
                status: qsTr("None selected");
                actions: [
                    ActionItem {
                        title: qsTr("add selected")
                        imageSource: "asset:///images/add.png"
                        
                        onTriggered: {
                            if (enabled) {
                                var selectionList = listView.selectionList();
                                for (var i = 0; i < selectionList.length; i ++) {
                                    var selectedItem = listView.dataModel.data(selectionList[i]);
                                    wpu.setBlogsInfo(selectedItem.blogid, selectedItem.xmlrpc);
                                    
                                    moveOn();
                                }

                            }
                        }
                    }
                ]
            }

            onSelectionChanged: {
                if (selectionList().length > 1) {
                    multiSelectHandler.status = selectionList().length + " blogs selected";
                } else if (selectionList().length == 1) {
                    multiSelectHandler.status = "1 blog selected";
                } else {
                    multiSelectHandler.status = "None selected";
                }
            }

            listItemComponents: [
                ListItemComponent {
                    type: "item"
                    StandardListItem {
                        id: bitem
                        imageSpaceReserved: false
                        textFormat: TextFormat.Html
                        title: qsTr(ListItemData.blogName)
                        description: ListItemData.url
                        
                        
                    
                    } // end of second ListItemComponent
                } // end standardlistitem
            ] // end of listItemComponents list
           

            onTriggered: {
                var selectedItem = listView.dataModel.data(indexPath);
                blogid = selectedItem.blogid;
                blogurl = selectedItem.xmlrpc;
            }
        } // end of ListView
    } // end of Container
}

