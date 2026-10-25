import QtQuick

// One page of the showcase, as listed on the home page
QtObject {
    required property string title
    // The components it shows
    required property string summary
    // An app component page rather than a library one
    property bool app: false
    // A GroupPage
    required property Component page
    // File name for --capture
    required property string slug
}
