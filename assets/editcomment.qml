import bb.cascades 1.0

Page {
    id: ecp
    
    actionBarVisibility: ChromeVisibility.Visible
    
    property string ec_comment_id;
    property variant ec_cinfos;
    
    onEc_comment_idChanged: {
        wpu.getComment(ec_comment_id);
        wpu.dataReady_getComment.connect(ecp.ec_onDataReady);
    }
    
    function ec_onDataReady()
    {
        var ec_a = wpu.getRes();
        
        if ( ec_a['delpost'] )
        {
            ec_ci.close();
            navcommentspane.pop();
            navcommentspane.firstPage.comment_init();
            
        } else {
            ec_cinfos = ec_a;
            edind.stop();
        }
    }
    
    actions: [
        ActionItem {
            title: "Edit"
            imageSource: "asset:///images/save.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            
            onTriggered: {
                //crude sanity check
                if ( auth.text != "" && authmail.text !="" && authurl.text != "" && ccontent.text !="" && cstate.selectedValue != "" )
                {
                    ec_ci.body = "Making changes\nPlease wait...";
                    ec_ci.open();
                    wpu.editComment(ec_comment_id, cstate.selectedValue, ccontent.text, auth.text, authmail.text, authurl.text);
                    wpu.dataReady_editComment.connect(ecp.ec_onDataReady);
                }
            }
        }
    ]
    
    attachedObjects: [
        CustomIndicator {
            id: ec_ci
        }
    ]

    titleBar: TitleBar {
        title: qsTr("Edit Comment")
    }
    
    content: Container {
        layout: DockLayout { }
        
        
        
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            
            topMargin: 25
            bottomMargin: 25
            rightMargin: 25
            leftMargin: 25
            topPadding: 25
            bottomPadding: 25
            rightPadding: 25
            leftPadding: 25
            
            Label {
                text: qsTr("Author");
            }
            TextField {
                id: auth
                text: (ec_cinfos) ? ec_cinfos.author : ""
            }
            Label {
                text: qsTr("Author e-mail")
            }
            TextField {
                id: authmail
                text: (ec_cinfos) ? ec_cinfos.author_email : ""
            }
            Label {
                text: qsTr("Author url")
            }
            TextField {
                id: authurl
                text: (ec_cinfos) ? ec_cinfos.author_url : ""
            }
            Label {
                text: qsTr("content")
            }
            TextArea {
                id: ccontent
                preferredHeight: 200
                text: (ec_cinfos) ? ec_cinfos.content : ""
            }
            Divider {
            
            }
            DropDown {
                id: cstate
                title: qsTr("State")
                
                Option {
                    value: "approve"
                    text: qsTr("Approved")
                    selected: (ec_cinfos) ? (value == ec_cinfos.status) : false
                }
                Option {
                    value: "hold"
                    text: qsTr("Waiting for approve")
                    selected: (ec_cinfos) ? (value == ec_cinfos.status) : false
                }
                Option {
                    value: "spam"
                    text: qsTr("Spam")
                    selected: (ec_cinfos) ? (value == ec_cinfos.status) : false
                }
            }
            Divider {
            
            }
        }
        ActivityIndicator {
            id: edind
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom

            preferredHeight: 500
            preferredWidth: 500

            running: true
        }
    }
}

