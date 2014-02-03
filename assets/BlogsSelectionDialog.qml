/*
 * BlogsSelectionDialog.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Dialog {
    id: bsd
    
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
    
    attachedObjects: [
        ComponentDefinition {
            id: optionControlDefinition
            Option {
            }
        }
    ]

    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center

        background: Color.create(0.0, 0.0, 0.0, 0.5)

        layout: StackLayout {
        }

        DropDown {
            id: bdd
        }

        Divider {

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
    }

	onOpened: {
        getRegisteredBlogs();
    }
	onClosed: {
        if ( navcommentspane.firstPage )
                navcommentspane.firstPage.comment_restoreItems()
        else if ( navpostpane.firstPage )
                navpostpane.firstPage.post_loadData();
        else if ( navpagepane.firstPage )
            	navpagepane.firstPage.post_loadData();
        
    }
}

