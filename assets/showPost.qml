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
            sp.show_img = true;
        
        if ( spind.running )
        	spind.stop();
        
        if (!sp.show_img)
        	cnt.text = getLabelText();
        else
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
        var res = "";
        if (sp_myObj) {
            if ( sp.show_img )
            	return "<html><span style='font-size:50pt'>" + qsTr(sp_myObj.post_content) + "</span></html>"
        }

        return res
    }
    
    actionBarVisibility: ChromeVisibility.Visible
    
    
    
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
                
                
                TextArea {
                    backgroundVisible: false
                    verticalAlignment: VerticalAlignment.Fill
                    topMargin: 30
                    bottomMargin: 30
                    leftMargin: 30
                    rightMargin: 30
                    editable: false
                    
                    
                    maxWidth: 738
                    preferredWidth: 738
                    
                    id: cnt
                    textFormat: TextFormat.Html
                    textStyle.base: SystemDefaults.TextStyles.BodyText
                    visible: !sp.show_img
                    textStyle.textAlign: TextAlign.Justify
                    textFit {
                        minFontSizeValue: 1
                        maxFontSizeValue: 10
                    }
                
                }
                WebView {
                    id: webView
                    maxWidth: 738
                    preferredWidth: 738
                    visible: sp.show_img
            	}
            }
        }

    }

}