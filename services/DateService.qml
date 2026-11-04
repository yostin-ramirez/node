pragma Singleton
import QtQuick

Item {
    id: root

    property string dayNumber: ""
    property string dayShort: ""
    property string dayFull: ""
    property string monthShort: ""
    property string monthFull: ""
    property string year: ""

    readonly property var _days: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var _daysFull: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var _months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var _monthsFull: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    Timer {
        id: syncTimer
        repeat: true
        onTriggered: root.updateDate()
    }

    function updateDate() {
        const now = new Date();

        root.dayNumber = now.getDate().toString().padStart(2, '0');

        const dayIdx = now.getDay();
        const monthIdx = now.getMonth();

        root.dayShort = _days[dayIdx];
        root.dayFull = _daysFull[dayIdx];
        root.monthShort = _months[monthIdx];
        root.monthFull = _monthsFull[monthIdx];
        root.year = now.getFullYear().toString();

        const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 100);
        const msUntilMidnight = midnight.getTime() - now.getTime();

        syncTimer.interval = msUntilMidnight;
        syncTimer.restart();
    }

    Component.onCompleted: updateDate()
}
