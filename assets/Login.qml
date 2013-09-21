/*
 * Login.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0
import bb.system 1.0

Page {
    id: lp
    
    actionBarVisibility: ChromeVisibility.Hidden
    
    attachedObjects: [
        ComponentDefinition {
            id: pageDefinition
            source: "blogslist.qml"
        },
        SystemToast {
            id: myQmlToast
            body: "Unable to register account\nPlease try again."
            button.label: "Ok"
            button.enabled: true
        }
    
    ]
    
    function onDataReady() {
        var a = wpu.getRes();
        
        if (a["ERROR"]) {
            myQmlToast.show();
            usr.text = '';
            pwd.text = '';
            blgd.text = '';
            si.enabled = true
            si.imageSource = '';
            //    	wpu.resetRes();
        } else {
            wpu.setUsername(usr.text);
            wpu.setPassword(pwd.text);
            
            var newPage = pageDefinition.createObject();
            newPage.bl_xml = "val";
            
            si.imageSource = '';
            si.enabled = true
            usr.text = '';
            pwd.text = '';
            blgd.text = '';

            navigationPane.push(newPage);
        }
    
    }
    
    Container {
        layout: DockLayout {  }
        
        
        Container {
            layout: StackLayout {
            }
            
            Container {
                verticalAlignment: VerticalAlignment.Top
                horizontalAlignment: HorizontalAlignment.Center
                layout: StackLayout {
                }
                
                //header - logo
                ImageView {
                    
                    imageSource: "asset:///images/wplogo.png"
                }
            }
            Container {
                verticalAlignment: VerticalAlignment.Center
                horizontalAlignment: HorizontalAlignment.Center
                layout: StackLayout {
                }
                
                topPadding: 50
                leftPadding: 50
                rightPadding: 50
                bottomPadding: 50
                
                Label {
                    text: "Username"
                }
                
                TextField {
                    id: usr
                    clearButtonVisible: true
                    hintText: "username"
                    
                    input.flags: TextInputFlag.AutoCapitalizationOff
                }
                
                Label {
                    topMargin: 50
                    text: "Password"
                }
                
                TextField {
                    id: pwd
                    inputMode: TextFieldInputMode.Password
                    
                    hintText: "YouRpAsSwOrD"
                }
                
                Label {
                    topMargin: 50
                    text: "Blog Address"
                }
                
                TextField {
                    id: blgd
                    
                    hintText: "leave empty if unsure"
                    input.flags: TextInputFlag.AutoCapitalizationOff

                }
            }
            Container {
                verticalAlignment: VerticalAlignment.Bottom
                horizontalAlignment: HorizontalAlignment.Center
                layout: StackLayout {
                }
                
                topPadding: 50
                //bottomPadding: 25//50
                Button {
                    id: si
                    text: "Sign In"
                    
                    onClicked: {
                        if (usr.text && pwd.text) {
                            si.imageSource = "asset:///images/loading.gif";
                            si.enabled = false;
                            wpu.getBlogs(usr.text, pwd.text, blgd.text);
                            wpu.dataReady_getUsersBlogs.connect(lp.onDataReady);
                        } else {; /*** TODO ***/
                        }
                    }
                
                }
            }
        }
    }
}


