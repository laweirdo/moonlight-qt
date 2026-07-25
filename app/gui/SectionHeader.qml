import QtQuick 2.9
import QtQuick.Layouts 1.3

// Section heading for TokenProof.qml. Always renders the provenance string
// alongside the title, so no section on the sheet can be read without knowing
// where its values came from.
ColumnLayout {
    property string title: ""
    property string source: ""
    // false => values are placeholder or inferred; heading is marked in coral
    property bool trusted: true

    spacing: 3

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: title
            color: "#F4EDE2"
            font.pixelSize: 16
            font.letterSpacing: 0.5
        }

        Rectangle {
            visible: !trusted
            implicitWidth: tag.implicitWidth + 10
            implicitHeight: tag.implicitHeight + 4
            radius: 3
            color: "#3A2226"
            border.color: "#E08B7D"
            border.width: 1

            Text {
                id: tag
                anchors.centerIn: parent
                text: "NOT FROM FIGMA"
                color: "#E08B7D"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.8
            }
        }

        Item { Layout.fillWidth: true }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: source
        color: trusted ? "#6F779B" : "#E08B7D"
        font.pixelSize: 10
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 3
        height: 1
        color: "#2A3050"
    }
}
