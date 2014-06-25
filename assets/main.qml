/*
 * main.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.system 1.0

TabbedPane {
    id: tabbedPane
    showTabsOnActionBar: false
    peekEnabled: false
    
    property alias mbs: navigationPane.mb

    Menu.definition: MenuDefinition {
        actions: [
            ActionItem {
                id: info
                title: qsTr("Info");
                onTriggered: {
                    infoToast.show();
                }
                
            }/*,
            ActionItem {
                id: cb
                title: qsTr("Change blog");
                enabled: mbs || !wpu.blogsInfo()

                onTriggered: {
                    bsdo.open();
                }
            }*/
        ]
    
    }
    attachedObjects: [
        BlogsSelectionDialog {
            id: bsdo
        },
        ComponentDefinition {
            id: postsList
            source: "postslist.qml"
        },
        ComponentDefinition {
            id: loginPage
            source: "Login.qml"
        },
        ComponentDefinition {
            id: blogsList
            source: "blogslist.qml"
        },
        ComponentDefinition {
            id: commentsList
            source: "commentslist.qml"
        },
        /* post */
        
        ComponentDefinition {
            id: post_showPost
            source: "showPost.qml"
        },
        ComponentDefinition {
            id: post_makePost
            source: "makePost.qml"
        },
        ComponentDefinition {
            id: post_editPost
            source: "editpost.qml"
        },
        SystemDialog {
            id: warningDialog
            title: "Warning"
            body: "Continue and you'll lose your changes"
            onFinished: {
                if (warningDialog.result == SystemUiResult.ConfirmButtonSelection)
                {
                    if ( tabbedPane.activeTab == postsTab )
                        navpostpane.pop();
                    else navpagepane.pop();
                }
            }
        },
        SystemToast {
            id: infoToast
            body: "Developer:\nDaniele (b0unc3) Maio\n\nWarranty:\nNo warranty. The app is provided as it is.\n\nLicense:\n OpenSource"
            button.label: "Ok"
            button.enabled: true
        }

    ]
    
    onCreationCompleted: {
        if (  wpu.info_registered() )
        {
        	tabbedPane.activeTab = postsTab;

        	tabbedPane.remove(loginregisterTab);
        	tabbedPane.showTabsOnActionBar = false;
        	tabbedPane.peekEnabled = true;

        	var newPage = postsList.createObject();
        	newPage.post_showpage = false;
            navpostpane.push(newPage);
        	newPage.post_loadData();
        } else console.log("no info registered");
    }
    Tab {
        id: loginregisterTab
    
        NavigationPane {
            id: navigationPane
            peekEnabled: false
            backButtonsVisible: false
            property bool mb: false;
            
            onCreationCompleted: {
                var page = loginPage.createObject();
                navigationPane.push(page);
            }
            
            onPopTransitionEnded: {
                if ( firstPage ) 
                	firstPage.destroy();
                
                if ( page )
                	page.destroy();
                //plp.loadData();

                
                
                tabbedPane.activeTab = postsTab;
                
                tabbedPane.remove(loginregisterTab);
                tabbedPane.showTabsOnActionBar = false;
                tabbedPane.peekEnabled = true;
                
                var newPage = postsList.createObject();
                newPage.post_showpage = false;
                navpostpane.push(newPage);
                newPage.post_loadData();
            }
        }
    }
    Tab {
        id: settingsTab
        title: qsTr("Settings")
        NavigationPane {
            id: settPane
        
        	onPopTransitionEnded: {
            	if ( page )
            		page.destroy();
            		
            	if ( firstPage )
            		firstPage.destroy(); 
            }
        Page {
            id: theSettingPage
            property bool mb: true;
            titleBar: TitleBar {
                title: qsTr("Settings")
            }
            function onDataReady()
            {
                var a = wpu.getRes();
                if ( a['oneblog'] )
                	mb = false
            }
            function getRegisteredBlogs()
            {
                bdd.removeAll();
                var val = wpu.getBI();
                var cb  = wpu.getCurrentBlog();
                var bi = cb.split("-");
                for (var event in val) {
                    var dataCopy = val[event]
                    
                    if ( event != "" && val[event] != "" )
                    {
                        console.log("event = " + event);
                        console.log("val[event] = " + val[event]);
                        var option = optionControlDefinition.createObject();
                        option.value = qsTr(event);
                        option.text = qsTr(val[event]);
                        if ( event == bi[0] && val[event] == bi[1])
                            option.selected = true;
                        
                        bdd.add(option);
                    }
                }
            }
            
            Container {
                topPadding: 20
                bottomMargin: 20
                leftPadding: 20
                rightMargin: 20
                topMargin: 20
                bottomPadding: 20
                leftMargin: 20
                rightPadding: 20
                
                layout: StackLayout { 
                    
                }
                Label {
                    text: "Change Blog"
                }
                DropDown {
                    id: bdd
                    enabled: !wpu.blogsInfo()
                }
                
                Button {
                    horizontalAlignment: HorizontalAlignment.Center
                    text: qsTr("Done")
                    enabled: !wpu.blogsInfo()
                    onClicked: {
                        /* set the new blog */
                        wpu.setCurrentBlog(bdd.selectedOption.value, bdd.selectedOption.text);
                    }
                }
                
                Divider {
                
                }
                
                Divider {
                
                }
                
                Label {
                    text: "Add Blog"
                }
                
                Button {
                    horizontalAlignment: HorizontalAlignment.Center
                    text: qsTr("Add blog")
                    enabled: theSettingPage.mb;
                    onClicked: {
                        bsdo.open();
                    }
                }
                
                Divider {
                
                }
                
                Label {
                    text: "Remove blog"
                }
                
                Button {
                    horizontalAlignment: HorizontalAlignment.Center
                    text: qsTr("Remove blog");
                    enabled: theSettingPage.mb
                }
                
                Divider {
                
                }
                
                Label {
                    text: "Logout"
                }
                
                Button {
                    horizontalAlignment: HorizontalAlignment.Center
                    text: qsTr("Lougout");
                    onClicked: {
                        if ( wpu.deleteData() )
                        {
                        	console.log("logout ok");
                        	//loginregisterTab.setEnabled(true);
                     //   	tabbedPane.add(loginregisterTab)
                     		var p = loginPage.createObject();
                     		settPane.push(p)
                     		settPane.backButtonsVisible = false;
                     		
                        	//tabbedPane.activePane = loginregisterTab; 
                        	
                        }
                        else console.log("something wrong with logout");
                    }
                }
            
                
                onCreationCompleted: {
                    theSettingPage.getRegisteredBlogs();
                    wpu.getBlogs(wpu.getUsername(), wpu.getPassword(), "");
                    wpu.dataReady_getUsersBlogs.connect(theSettingPage.onDataReady);
                }
        }    
            
            }
        }
    }
    Tab {
        id: postsTab
        title: qsTr("Posts")
        imageSource: "asset:///images/posts.png"
        

        NavigationPane {
            id: navpostpane
            
            

            onPopTransitionEnded: {
                if ( page )
                	page.destroy();
                	
                if (navpostpane.firstPage) {
                    navpostpane.firstPage.post_restoreItems()
                } else {
                    var post_ = postsList.createObject();
                    post_.post_showpage = false;
                    navpostpane.push(post_);
                    post_.post_loadData();

                }
            }

        }

        onTriggered: {
            console.log("here we are");
            if (navpagepane.count() > 0) {
                for (var i = 0; i < navpagepane.count(); i ++) 
                	navpagepane.remove(navpostpane.at(i));
            }
            if ( navpagepane.top ) {
                navpagepane.remove(navpagepane.top);
            }
            if (navpostpane.count() == 0) {
                var newPage_post_ = postsList.createObject();
                newPage_post_.post_showpage = false;
                navpostpane.push(newPage_post_);
                newPage_post_.post_loadData();
            } else { 
                if ( navpostpane.firstPage )
                {
                	navpostpane.firstPage.post_loadData();
                } else {
                	var post_p = postsList.createObject();
                	navpostpane.push(post_p);
                    post_p.post_showpage = false;
                    post_p.post_loadData();
                }
            }
            
        }
    }
    
    Tab {
        id: commentsTab
        title: qsTr("Comments")
        imageSource: "asset:///images/comments.png"
        
        NavigationPane {
            id: navcommentspane
            
            onPopTransitionEnded: {
                if ( page )
                	page.destroy();
                	
                if (navcommentspane.firstPage )
                {
                    navcommentspane.firstPage.comment_restoreItems()
                } else {
                    var p = commentsList.createObject();
                    navcommentspane.push(p);
                }
            }
            
        }

        onTriggered: {
            if (navpostpane.count() > 0) {
                for (var i = 0; i < navpostpane.count(); i ++) 
                	navpostpane.remove(navpostpane.at(i));
            }
            if ( navpostpane.top )
            {
             	navpostpane.remove(navpostpane.top);
            }
            if ( navcommentspane.count() == 0 )
            {
            	var newPage = commentsList.createObject();
            	navcommentspane.push(newPage);
            } else {
                navcommentspane.firstPage.comment_init();
            }
        }
        
    }
    Tab {
        id: pagesTab
        title: qsTr("Pages")
        imageSource: "asset:///images/pages.png"

        NavigationPane {
            id: navpagepane
            
            onPopTransitionEnded: {
                
                if ( page )
                    page.destroy();
                
                if (navpagepane.firstPage) {
                    navpagepane.firstPage.post_restoreItems()
                } else {
                    var post_ = postsList.createObject();
                    post_.post_showpage = true;
                    navpagepane.push(post_);
                    post_.post_loadData();
                
                }
            }
        
        }
        
        onTriggered: {
            if (navpostpane.count() > 0) {
                for (var i = 0; i < navpostpane.count(); i ++) 
                navpostpane.remove(navpagepane.at(i));
            }
            if ( navpostpane.top ) {
                navpostpane.remove(navpostpane.top);
            }
            if (navpagepane.count() == 0) {
                var newPage_post_ = postsList.createObject();
                newPage_post_.post_showpage = true;
                navpagepane.push(newPage_post_);
                newPage_post_.post_loadData();
            } else { 
                if ( navpagepane.firstPage )
                {
                    navpagepane.firstPage.post_loadData();
                } else {
                    var post_p = postsList.createObject();
                    navpagepane.push(post_p);
                    post_p.post_showpage = true;
                    post_p.post_loadData();
                }
            }
        
        }
        /*


            onPopTransitionEnded: {
                if (page) 
                	page.destroy();

                if (navpagepane.firstPage) {
                    navpagepane.firstPage.post_restoreItems()
                } else {
                    var page_p = pagesList.createObject();
                    page_p.post_showpage = true;
                    navpagepane.push(page_p);
                    page_p.post_loadData();
                }
            }

        }

        onTriggered: {
            if ( navpostpane.count() > 0)
            {
                for ( var i=0; i<navpostpane.count(); i++ )
                    navpostpane.remove(navpostpane.at(i));
            }
            if (navpostpane.top) {
                navpostpane.remove(navpostpane.top);
            }
            if (navpagepane.count() == 0) {
                var page_newPage = pagesList.createObject();
                page_newPage.post_showpage = true;
                navpagepane.push(page_newPage);
                page_newPage.post_loadData();
            } else { //}if ( navpostpane.firstPage ){
                if (navpagepane.firstPage) {
                    navpagepane.firstPage.post_loadData();
                } else {
                    var page_p2 = pagesList.createObject();
                    page_p2.post_showpage = true;
                    navpagepane.push(page_p2);
                    //p.restoreItems()
                    page_p2.post_loadData();
                }
            }

        }
*/
    }
}

