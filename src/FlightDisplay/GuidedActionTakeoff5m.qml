import QGroundControl.Controls

ToolStripAction {
    text:       "5m"
    iconSource: "/res/takeoff.svg"
    visible:    true
    onTriggered: {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            QGroundControl.multiVehicleManager.activeVehicle.guidedModeTakeoff(5)
        }
    }
}