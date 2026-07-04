import QGroundControl.Controls

ToolStripAction {
    text:       "10m"
    iconSource: "/res/takeoff.svg"
    visible:    true
    onTriggered: {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            QGroundControl.multiVehicleManager.activeVehicle.guidedModeTakeoff(10)
        }
    }
}