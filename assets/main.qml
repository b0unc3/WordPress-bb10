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

    Menu.definition: MenuDefinition {
        actions: [
            ActionItem {
                title: qsTr("Change blog");
                enabled: wpu.blogsInfo(); 
                
                onTriggered: {
                    bsdo.open();
                }
            }
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
        ComponentDefinition {
            id: pagesList
            source: "pageslist.qml"
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
                navpostpane.push(newPage);
                newPage.post_loadData();

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
                    console.log("first page is here ");
                    navpostpane.firstPage.post_restoreItems()
                } else {
                    var p = postsList.createObject();
                    navpostpane.push(p);
                    p.post_loadData();

                }
            }

        }

        onTriggered: {
            if (navpostpane.count() == 0) {
                var newPage = postsList.createObject();
                navpostpane.push(newPage);
                newPage.post_loadData();
            } else { 
                if ( navpostpane.firstPage )
                {
                	navpostpane.firstPage.post_loadData();
                } else {
                	var p = postsList.createObject();
                	navpostpane.push(p);
                	p.post_loadData();
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
                if (page) page.destroy();

                if (navpagepane.firstPage) {
                    navpagepane.firstPage.post_restoreItems()
                } else {
                    var p = postsList.createObject();
                    p.post_showpage = true;
                    navpagepane.push(p);
                    p.post_loadData();
                }
            }

        }

        onTriggered: {
            if (navpagepane.count() == 0) {
                var newPage = postsList.createObject();
                newPage.post_showpage = true;
                navpagepane.push(newPage);
                newPage.post_loadData();
            } else { //}if ( navpostpane.firstPage ){
                if (navpagepane.firstPage) {
                    navpagepane.firstPage.post_loadData();
                } else {
                    var p = postsList.createObject();
                    p.post_showpage = true;
                    navpagepane.push(p);
                    //p.restoreItems()
                    p.post_loadData();
                }
            }

        }
    }
}

