/*
 * showPost.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.2

Page {
    
    id: sp
    
    property string sp_postid
    property alias sp_apostid: sp.sp_postid
    property variant sp_myObj
    
    property bool post_show_page;
    property bool show_img: false
    
    onCreationCompleted: {
        /* hack to avoid app crash on 10.2.0.429 */
        webView.html = "<html><img src=\"local:///assets/images/blank.png\" alt=\"desc\" /></html>";
    }
    
    onSp_postidChanged: {
        wpu.buildWPXML("wp.getPost", true, ["post_id"], [sp.sp_postid], [], []);
        /* assumes pages and posts are treated at the same way **/
      //  wpu.getPost(sp.post_show_page, sp.sp_postid);
     //   if ( sp.post_show_page )
       //     wpu.dataReady_getPage.connect(sp.sp_onDataReady);
       // else 
       wpu.dataReady_getPost.connect(sp.sp_onDataReady);
    }
    
    function sp_onDataReady() {
        //aspe`
        sp_myObj = wpu.getRes();
        if ( sp_myObj.post_content.indexOf("img") != -1 )
        	sp.show_img = true;
        else webView.settings.viewport = { "initial-scale" : 1.0}
        
        if ( spind.running )
        	spind.stop();
        	
        webView.html = getWebViewText();
        
    }
    
    function getLabelText()
    {
        var res = "";
        if ( sp_myObj )
        {
            if ( !sp.show_img )
                return "<html>" + qsTr(sp_myObj.post_content) + "</html>"
        }
        
        return res
    }
    
    function getWebViewText() {
        if (sp_myObj) {
            if ( sp.show_img )
            	return "<html><span style='font-size:50pt'>" + qsTr(sp_myObj.post_content) + "</span></html>"
            else return "<html>" + qsTr(sp_myObj.post_content) + "</html>";
        } 
    }
    
    actionBarVisibility: ChromeVisibility.Visible
    
    actions: [
        InvokeActionItem {
            ActionBar.placement: ActionBarPlacement.OnBar
            query {
                mimeType: "text/plain"
                invokeActionId: "bb.action.SHARE"
            }
            onTriggered: {
                data = sp_myObj.post_title + "\n" + sp_myObj.link;
            }
        }
    ]
    
    
    titleBar: TitleBar {
        title: (sp_myObj) ? qsTr(sp_myObj.post_title) : ""
    }
    content: ScrollView {
        verticalAlignment: VerticalAlignment.Fill
        
        topMargin: 30
        bottomMargin: 30
        leftMargin: 30
        rightMargin: 30
        
        scrollViewProperties {
            scrollMode: ScrollMode.Both
            pinchToZoomEnabled: true
            maxContentScale: 5
            minContentScale: 0.5
        }
        
        Container {
            layout: DockLayout { }
            
            ActivityIndicator {
                id: spind
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                
                preferredHeight: 500
                preferredWidth: 500
                
                running: true
            }
            
            Container {
                layout: StackLayout { }
                
                verticalAlignment: VerticalAlignment.Fill
                
                topMargin: 15
                bottomMargin: 15
                leftMargin: 15
                rightMargin: 15
                topPadding: 15
                bottomPadding: 15
                rightPadding: 15
                leftPadding: 15
                
                WebView {
                    id: webView
                    preferredWidth: 738
                	settings.activeTextEnabled: true
                	settings.defaultFontSize: 18
                	settings.imageDownloadingEnabled: true
                 	settings.textAutosizingEnabled: true
            	}
            }
        }

    }

}
