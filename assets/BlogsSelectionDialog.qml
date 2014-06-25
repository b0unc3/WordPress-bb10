/*
 * BlogsSelectionDialog.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Dialog {
    id: bsd
    property int wb: 0;
    function getRegisteredBlogs()
    {
        wpu.getBlogs(wpu.getUsername(), wpu.getPassword(), "");
        //(wpu.getUsername(), wpu.getPassword(), "");
        wpu.dataReady_getUsersBlogs.connect(bsd.onDataReady);
    }
    function onDataReady()
    {
        var infobj = wpu.getRes();
        console.log(infobj)
        if ( infobj['oneblog'] )
        {
            console.log("ONE BLOG FOUND!"); 
        }
        console.log("len =  " + infobj.length);
        for(var x = 0; x < infobj.length; x++) 
        { 
            console.log("entry: " + x); 
            console.log(infobj[x].blogName); 
        }
        
        console.log("here with = " + infobj);
        console.log("1 = " + infobj["blogName"] + " url =" + infobj["url"]);
        for ( var b in infobj )
        {
        	console.log("blog name = " + b["blogName"])
        	var opt = optionControlDefinition.createObject();
        	opt.value = b["blogid"] + "|" + b["url"]
        	opt.text = b["blogName"]
        }	
         
        /*
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
        */
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
                if ( wb == 0 ) 
                {
                	wpu.setCurrentBlog(bdd.selectedOption.value, bdd.selectedOption.text);
                	bsdo.close();
                } else if ( wb == 1 ) /* adding a new blog */
                {
                    wpu.setBlogsInfo(bdd.selectedOption.value.split("|")[0], bdd.selectedOption.value.split("|")[1]);
                    bsdo.close();
                } else if ( wb == 2 ) /* delete a blog */
                {
                	if ( wpu.deleteBlog(bdd.selectedOption.value.split("|")[0], bdd.selectedOption.value.split("|")[1]) )
                		console.log("delete ok");
                	else console.log("delete fails");
                	
                	bsdo.close();
                	
                }
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

