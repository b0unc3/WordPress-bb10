import bb.cascades 1.0

Page {
    id: ep
    
    property string post_id;
    property variant pinfos

    property bool post_showpage: false
    
    onPost_idChanged: {
        wpu.getPost(post_id);
        wpu.dataReady_getPost.connect(ep.ep_onDataReady);
    }
    
    function ep_onDataReady() {
        var ep_a = wpu.getRes();
        if (ep_a['delpost'] )
        {
        	ci_ep.close();
            if ( !post_showpage )
            {
                navpostpane.pop();
                navpostpane.firstPage.post_loadData();
            } else {
                navpagepane.pop();
                navpagepane.firstPage.post_loadData();
            }
        } else {
            pinfos = ep_a;
            epind.stop();
        }
    }
    
    attachedObjects: [
        CustomIndicator {
            id: ci_ep
        }
    ]
    
    actions: [
        ActionItem {
            title: "Edit"
            imageSource: "asset:///images/save.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                if ( ptitle.text != "" && pcontent.text != "" && pstate.selectedValue != "" && pformat.selectedValue != "" )
                {
                                    ci_ep.body = "Editing post\nPlease wait...";
                                    ci_ep.open();
                                    wpu.editPost(ep.post_id,ptitle.text,pcontent.text,pstate.selectedValue, pformat.selectedValue);
                                    wpu.dataReady_editPost.connect(ep.ep_onDataReady);
                }
            }
        }
    ]

    titleBar: TitleBar {
        title: (!post_showpage) ? qsTr("Edit Post") : qsTr("Edit Page")
        
    }

    content: Container {
        layout: DockLayout { }
        
        ActivityIndicator {
            id: epind
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom
            
            preferredHeight: 500
            preferredWidth: 500
            
            running: true
        }
        
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            
            topMargin: 15
            topPadding: 15
            bottomMargin: 15
            bottomPadding: 15
            rightMargin: 15
            rightPadding: 15
            leftMargin: 15
            leftPadding: 15
            
            TextField {
                id: ptitle
                text: pinfos.post_title
            }
            TextArea {
                id: pcontent
                preferredHeight: 300
                text: (pinfos) ? pinfos.post_content : ""
            }
            /*
             * ***FIXME****
             * to be implemented
             TextField {
             id: ptags
             text: pinfos.name
             }
             */
            Divider {
                preferredHeight: 50
            }
            
            DropDown {
                id: pstate
                title: qsTr("Status")
                Option {
                    text: qsTr("Public")
                    value: "public"
                    selected: (pinfos) ? (value == pinfos.post_status ) : false
                }
                Option {
                    text: qsTr("Private")
                    value: "private"
                    selected: (pinfos) ? (value == pinfos.post_status ) : false
                }
            }
            
            
            DropDown {
                id: pformat
                title: "Type"
                visible: !post_showpage
                selectedIndex: -1
                Option {
                    text: qsTr("Standard")
                    value: "post"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
                Option {
                    text: qsTr("Aside")
                    value: "aside"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
                Option {
                    text: qsTr("Image")
                    value: "image"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
                Option {
                    text: qsTr("Video")
                    value: "video"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
                Option {
                    text: qsTr("Quote")
                    value: "quote"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
                Option {
                    text: qsTr("Link")
                    value: "link"
                    selected: (pinfos) ? (value == pinfos.post_type ) : false
                }
            }
        }
    }
}

