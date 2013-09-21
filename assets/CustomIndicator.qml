/*
 * CustomIndicator.qml
 *
 *      Author: Daniele (b0unc3) Maio
 */

import bb.cascades 1.0

Dialog {
    id: bi
    property alias body: theBody.text

    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        layout: DockLayout {
        }

        ImageView {
            imageSource: "asset:///images/overlay.png"
        }

        Container {

            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center

            preferredHeight: 363
            preferredWidth: 557

            background: Color.create(0.0, 0.0, 0.0, 0.8)

            ActivityIndicator {
                id: theIndicator
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                preferredHeight: 150
                preferredWidth: 150
            }

            Divider {
                preferredWidth: 25
            }

            Label {
                id: theBody
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                multiline: true

                textStyle {
                    base: SystemDefaults.TextStyles.BodyText
                    color: Color.White
                    fontWeight: FontWeight.Bold
                }
            }
        }
    }
    onOpened: {
        theIndicator.running = true;
    }
    onClosed: {
        theIndicator.running = false;
    }
}

