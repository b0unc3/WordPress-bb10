/*
 * viewcomment.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Page {
    id: vcp
    
    property string vc_cid;
    property variant vc_infos;
    
    onVc_cidChanged: {
        wpu.buildWPXML("wp.getComment", true, ["comment_id"], [vcp.vc_cid], [], []);
        wpu.dataReady_getComment.connect(vcp.vc_onDataReady);
    }
    
    function vc_onDataReady()
    {
            var vc_a = wpu.getRes();
            vc_infos = vc_a;
            vcind.stop();
    }
    
    actions: [
        InvokeActionItem {
            ActionBar.placement: ActionBarPlacement.OnBar
            query {
                mimeType: "text/plain"
                invokeActionId: "bb.action.SHARE"
            }
            onTriggered: {
                data = vc_infos.post_title + "\n" + vc_infos.link
            }
        }
    ]
    
    content: Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Top
        layout: DockLayout { }
        ActivityIndicator {
            id: vcind
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            
            preferredHeight: 500
            preferredWidth: 500
            
            running: true
        }
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            
            topPadding: 25
            bottomPadding: 25
            rightPadding: 25
            leftPadding: 25
            
            Label {
                id: auth
                text: ( vc_infos ) ? qsTr(vc_infos.author) : ""
                
                textStyle.base: SystemDefaults.TextStyles.BodyText
            }
            Label {
                id: authmail
                text: (vc_infos ) ?  "<html><a href=\""+vc_infos.author_email+"\">" + vc_infos.author_email + "</a></html>" : ""
                
                textFormat: TextFormat.Html
                textStyle.base: SystemDefaults.TextStyles.SubtitleText
            }
            Label {
                id: authurl
                text: (vc_infos ) ?  "<html><a href=\"" + vc_infos.author_url + "\">" + vc_infos.author_url + "</a></html>" : ""
                
                textFormat: TextFormat.Html
                textStyle.base: SystemDefaults.TextStyles.SubtitleText
            }
            Label {
                id: dc
                text: ( vc_infos ) ? vc_infos.date  : ""
                
                textStyle.base: SystemDefaults.TextStyles.SmallText
            }
            Label {
                id: pt
                text: ( vc_infos ) ? qsTr(vc_infos.post_title) : ""
                
                textFormat: TextFormat.Html
                textStyle.base: SystemDefaults.TextStyles.TitleText
            }
            Divider {
                horizontalAlignment: HorizontalAlignment.Fill
                preferredHeight: 50
            }
            Label {
                id: cont
                text: ( vc_infos ) ? qsTr(vc_infos.content) : ""
                multiline: true
                
                textFormat: TextFormat.Html
                textStyle.base: SystemDefaults.TextStyles.BodyText
            }
        }
    }


}

