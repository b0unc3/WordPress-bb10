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
        var val = wpu.getBI();
        for (var event in val) {
            var dataCopy = val[event]

	    var option = optionControlDefinition.createObject();
            option.value = event;
            option.text = val[event];
            bdd.add(option);
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
                bsdo.close();
            }
        }
    }

	onOpened: {
        	getRegisteredBlogs();
    }
}

