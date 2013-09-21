/*
 * ReplyDialog.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Dialog {
    id: rd
    property string parent_id;
    property string post_id;
    
    function rd_onDataReady()
    {
        var rd_a = wpu.getRes();

        if (rd_a["ERROR"]) {
            //myQmlToast.show(); <- TBD
            console.log("ERRORE");
            // wpu.resetRes();
        } else if (rd_a["newcommentid"]) {
            close();
        }
    }
    
    
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        layout: StackLayout { }
        
        background: Color.create(0.0, 0.0, 0.0, 0.8)

        Container {
            layout: DockLayout {
                
            }
            
            Label {
                horizontalAlignment: HorizontalAlignment.Left
                text: "Leave a reply"
            }
            
            
            Button {
                horizontalAlignment: HorizontalAlignment.Right
                text: "Cancel reply"
                
                onClicked: {
                    close();
                }
            
            }
        }
        Container {
            layout: StackLayout { }
            
            TextArea {
                id: rep_content
                horizontalAlignment: HorizontalAlignment.Fill
                preferredHeight: 250;
                hintText: "Enter your comment here";
            }
        }
        
        Button {
            id: pc
            horizontalAlignment: HorizontalAlignment.Right
            verticalAlignment: VerticalAlignment.Bottom
            text: "Post Comment"
            
            
            onClicked: {
                if ( rep_content.text && post_id && parent_id )
                {
                    pc.imageSource = "asset:///images/loading.gif";
                    pc.enabled = false;
                    wpu.newComment(post_id, rep_content.text, parent_id);
                    wpu.dataReady_newComment.connect(rd.rd_onDataReady);
                }
                
            }
        }
    }
    
    onOpened: {
        pc.imageSource = '';
        pc.enabled = true;
        rep_content.text = '';
    }
}

