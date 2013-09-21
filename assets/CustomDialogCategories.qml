import bb.cascades 1.0

Dialog {
    id: cdcp
    
    property variant cats;
    
    function onDataReady(val)
    {
     	cats = wpu.getRes();
     	/* not work? */
        for (var event in cats) {
            var dataCopy = cats[event]
            
              for (var key in dataCopy) {
              	//console.log("dataCopy[key] = " + dataCopy[key]);
              }
           // console.log("event = " + event);
            if ( event == "name" ) {
              //  console.log("add name " + cats[event]);
                var option = optionControlDefinition.createObject();
                option.text = cats[event]
                dropDown.add(option)
            }
        }
        
     	cdcind.stop();
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
        
        layout: StackLayout {}
        
        DropDown {
            Option {
                text: cats.name //<--?
            }
        }
        
        Divider {
        
        }
        Button {
            horizontalAlignment: HorizontalAlignment.Center
            text: qsTr("Done");
            onClicked: {
                customdialogcat.close();
            }
        }
    }
    
    onCreationCompleted: {
        wpu.getCategories();
        wpu.dataReady.connect(cdcp.onDataReady);
    }
}