import bb.cascades 1.0
import bb.cascades.pickers 1.0

Page {
    id: ep
    
    property string post_id;
    property variant pinfos
    property bool textHasChanged : true;

    property bool post_showpage;
    
    onPost_idChanged: {
        wpu.buildWPXML("wp.getPost", true, ["post_id"], [post_id], ["post_type"], [((ep.post_showpage) ? "page" : "post")]);
        if ( ep.post_showpage )
        	wpu.dataReady_getPage.connect(ep.ep_onDataReady);
        else wpu.dataReady_getPost.connect(ep.ep_onDataReady);
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
        } else if (ep_a['file']) {
            pcontent.editor.insertPlainText("<img src=\"" + ep_a['url'] + "\" alt=\"desc\" />"); // width=\"480\" height=\"800\" class=\"aligncenter\" />");
            ci_ep.close();
        } else {
            pinfos = ep_a;
            epind.stop();
        }
    }
    
    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            onTriggered: {
                if ( textHasChanged )
                {
                    warningDialog.show();
                } else {
                    if ( !post_showpage )
                        navpostpane.pop();
                    else navpagepane.pop();
                }
            }
        }
    }
    
    attachedObjects: [
        CustomIndicator {
            id: ci_ep
        },
        FilePicker {
            id: ep_filePicker
            type: FileType.Picture
            title: qsTr("Select Picture")
            mode: FilePickerMode.Picker
            onFileSelected: {
                wpu.uploadFile(selectedFiles[0]);
                wpu.dataReady.connect(ep.ep_onDataReady);
                ci_ep.body = qsTr("Uploading picture\nplease wait...");
                ci_ep.open();
            }
        }
    ]
    
    actions: [
        ActionItem {
            title: qsTr("Edit")
            imageSource: "asset:///images/save.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                if ( ptitle.text != "" && pcontent.text != "" && pstate.selectedValue != "" && pformat.selectedValue != "" )
                {
                                    ci_ep.body = qsTr("Editing post\nPlease wait...");
                                    ci_ep.open();
                                    wpu.buildWPXML("wp.editPost", true, ["post_id"], [ep.post_id], ["post_title", "post_content", "post_status", "post_format", "post_type"], [ptitle.text, pcontent.text, pstate.selectedValue, pformat.selectedValue, (ep.post_showpage) ? "page" : "post"] );
                                    if ( ep.post_showpage )
                                    	wpu.dataReady_editPage.connect(ep.ep_onDataReady);
                                    else wpu.dataReady_editPost.connect(ep.ep_onDataReady);
                }
            }
        },
        ActionItem {
            title: qsTr("Add Image")
            imageSource: "asset:///images/addimage.png"
            ActionBar.placement: ActionBarPlacement.OnBar

            onTriggered: {
                ep_filePicker.open();
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
                text: (pinfos) ? qsTr(pinfos.post_title) : ""
            }
            TextArea {
                id: pcontent
                preferredHeight: 300
                text: (pinfos) ? qsTr(pinfos.post_content) : ""
                onTextChanged: {
                    textHasChanged = !textHasChanged;
                }
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
                    text: qsTr("Draft")
                    value: "draft"
                    selected: (pinfos) ? (value == pinfos.post_status ) : false
                }
                Option {
                    text: qsTr("Pending")
                    value: "pending"
                    selected: (pinfos) ? (value == pinfos.post_status ) : false
                }
                Option {
                    text: qsTr("Public")
                    value: "publish"
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
                title: qsTr("Type")
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

