import bb.cascades 1.2

Page {
    Container {
        layout: StackLayout { }
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
            onClicked: {
                /* set the new blog */
                wpu.setCurrentBlog(bdd.selectedOption.value, bdd.selectedOption.text);
                bsdo.close();
            }
        }
        
        Divider {
        
        }
        
        Label {
            text: "Logout"
        }
        
        Button {
            horizontalAlignment: HorizontalAlignment.Center
            text: qsTr("Lougout")
        }
        
        
        Divider {
        
        }
        
        Label {
            text: "Add Blog"
        }
        
        Button {
            horizontalAlignment: HorizontalAlignment.Center
            text: qsTr("Add blog")
        }
        
        Divider {
        
        }
        
        Label {
            text: "Remove blog"
        }
        
        Button {
            horizontalAlignment: HorizontalAlignment.Center
            text: qsTr("Remove blog");
        }
        
        Divider {
        
        }
        
        Button {
            horizontalAlignment: HorizontalAlignment.Center
            text: qsTr("Done")
            
        }
        
    }
}
