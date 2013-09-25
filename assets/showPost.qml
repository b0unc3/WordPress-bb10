/*
 * showPost.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Page {
    
    id: sp
    
    property string sp_postid
    property alias sp_apostid: sp.sp_postid
    property variant sp_myObj
    
    property bool post_show_page;
    property bool show_img: false
    
    onSp_postidChanged: {
        wpu.getPost(sp.post_show_page, sp.sp_postid);
        if ( sp.post_show_page )
        	wpu.dataReady_getPage.connect(sp.sp_onDataReady);
        else wpu.dataReady_getPost.connect(sp.sp_onDataReady);
    }
    
    function sp_onDataReady() {
        //aspe`
        sp_myObj = wpu.getRes();
        if ( sp_myObj.post_content.indexOf("img") != -1 )
            show_img = true;
            
        spind.stop();
        
        cnt.text = getLabelText();
        webView.html = getWebViewText();
    }
    
    function getLabelText()
    {
        var res = "";
        if ( sp_myObj )
        {
            if ( !show_img )
            	return "<html>" + sp_myObj.post_content + "</html>"
        }
        
        return res
    }
    
    function getWebViewText() {
        var res = "";
        if (sp_myObj) {
            if ( show_img )
            	return "<html><span style='font-size:60pt'>" + sp_myObj.post_content + "</span></html>"
        }
            	
        return res
    }
        
    actionBarVisibility: ChromeVisibility.Visible
    
    
    
    titleBar: TitleBar {
        title: (sp_myObj) ? sp_myObj.post_title : ""
    }
    content: Container {
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

            topMargin: 15
            bottomMargin: 15
            leftMargin: 15
            rightMargin: 15
            topPadding: 15
            bottomPadding: 15
            rightPadding: 15
            leftPadding: 15

            ScrollView {
                id: scrollView
                visible: !show_img

                topMargin: 30
                bottomMargin: 30
                leftMargin: 30
                rightMargin: 30
                /*
                scrollViewProperties {
                    scrollMode: ScrollMode.Both
                    pinchToZoomEnabled: true
                    maxContentScale: 5
                    minContentScale: 1
                }
                
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 1.0
                }*/
                
                Label {
                    topMargin: 30
                    bottomMargin: 30
                    leftMargin: 30
                    rightMargin: 30
                    id: cnt
                    multiline: true
                    textFormat: TextFormat.Html
                    textStyle.base: SystemDefaults.TextStyles.BodyText
                    text: getLabelText(); 
                    visible: !show_img
                }
            }
            ScrollView {
                id: scrollView_wv
                visible: show_img

                topMargin: 30
                bottomMargin: 30
                leftMargin: 30
                rightMargin: 30
                /*
                 * scrollViewProperties {
                 * scrollMode: ScrollMode.Both
                 * pinchToZoomEnabled: true
                 * maxContentScale: 5
                 * minContentScale: 1
                 * }
                 * 
                 * layoutProperties: StackLayoutProperties {
                 * spaceQuota: 1.0
                 * }*/
                WebView {
                    id: webView
                    html: getWebViewText()
                        //((show_img) ? ((post_show_page) ? sp_myObj.description : ((sp_myObj) ? "<html>" + sp_myObj.post_content + "</html>" : "")) : "")
                    //(show_img) ? ((sp_myObj) ? "<html>" + sp_myObj.post_content + "</html>" : "") : "";
                    visible: show_img
                    
                }
            }
                
        }
    }
}

