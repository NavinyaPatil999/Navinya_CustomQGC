/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property bool utmspActTrigger

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.right:          parent.right
        anchors.topMargin:      _layoutMargin
        anchors.rightMargin:    _layoutMargin
        maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 5)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        anchors.top:        parent.top
        anchors.bottom:     bottomRightRowLayout.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:           !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.margins:    _layoutMargin
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real bottomEdgeRightInset:     height + _layoutMargin
        property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        //Loader status logic
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: {
            if (!preFlightChecklistLoader.active) {
                preFlightChecklistLoader.active = true
            }
            preFlightChecklistLoader.item.open()
        }

        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    GripperMenu {
        id: gripperOptions
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
    Item {
        id: compassDirectionButtons
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth * 5
        anchors.bottomMargin:   ScreenTools.defaultFontPixelWidth * 28
        width:                  ScreenTools.defaultFontPixelWidth * 18
        height:                 width
        z:                      QGroundControl.zOrderWidgets
        visible:                true

        property real _btnSize: ScreenTools.defaultFontPixelWidth * 5
        property real _center:  width / 2 - _btnSize / 2

        function _sendHeading(deg) {
            if (QGroundControl.multiVehicleManager.activeVehicle) {
                var corrected = (deg + 180) % 360
                QGroundControl.multiVehicleManager.activeVehicle.guidedModeSetHeading(corrected)
            }
        }

        // N
        Rectangle {
            x: parent._center; y: 0
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: nMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "N"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85 }
            MouseArea { id: nMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(0) }
        }
        // NE
        Rectangle {
            x: parent.width - parent._btnSize; y: 0
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: neMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "NE"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.75 }
            MouseArea { id: neMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(45) }
        }
        // E
        Rectangle {
            x: parent.width - parent._btnSize; y: parent._center
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: eMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "E"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85 }
            MouseArea { id: eMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(90) }
        }
        // SE
        Rectangle {
            x: parent.width - parent._btnSize; y: parent.height - parent._btnSize
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: seMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "SE"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.75 }
            MouseArea { id: seMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(135) }
        }
        // S
        Rectangle {
            x: parent._center; y: parent.height - parent._btnSize
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: sMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "S"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85 }
            MouseArea { id: sMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(180) }
        }
        // SW
        Rectangle {
            x: 0; y: parent.height - parent._btnSize
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: swMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "SW"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.75 }
            MouseArea { id: swMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(225) }
        }
        // W
        Rectangle {
            x: 0; y: parent._center
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: wMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "W"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85 }
            MouseArea { id: wMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(270) }
        }
        // NW
        Rectangle {
            x: 0; y: 0
            width: parent._btnSize; height: parent._btnSize
            radius: parent._btnSize / 2
            color: nwMouse.containsMouse ? "#FF4444" : "#CC3A0000"
            border.color: "#FF4444"; border.width: 1
            Text { anchors.centerIn: parent; text: "NW"; color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.75 }
            MouseArea { id: nwMouse; anchors.fill: parent; hoverEnabled: true; onClicked: compassDirectionButtons._sendHeading(315) }
        }
    }
    // ── 3D Mission Planner (Extended) ─────────────────────────────
    Item {
        id: missionPlanner3D
        anchors.left:         parent.left
        anchors.bottom:       parent.bottom
        anchors.leftMargin:   ScreenTools.defaultFontPixelWidth * 2
        anchors.bottomMargin: ScreenTools.defaultFontPixelWidth * 30
        width:                ScreenTools.defaultFontPixelWidth * 100
        height:               _3dBtn.height + (_3dPanel.visible ? _3dPanel.height + 6 : 0)
        z:                    QGroundControl.zOrderWidgets
        visible:              true

        // ── Core state (unchanged) ────────────────────────────────
        property bool   _3dOpen:        false
        property real   _3dTakeoffAlt:  5
        property int    _3dTotalSteps:  0
        property real   _3dTotalDist:   0
        property int    _3dTotalTime:   0
        property real   _3dTotalVert:   0      // NEW: total vertical travel
        property int    _3dSelStep:     -1
        property bool   _3dRunning:     false
        property int    _3dCurStep:     -1
        property string _3dStatus:      "Ready"
        property string _3dPhase:       "move"
        property real   _3dVx:          0
        property real   _3dVy:          0
        property real   _3dVz:          0
        property var    _3dExec:        []
        // ════════════════════════════════════════════════════════════════════════
        // v22 AUDIT NOTE (paired with mission_3d_nogps_v22.lua)
        // ════════════════════════════════════════════════════════════════════════
        // Full direction/heading/frame audit confirms _3dRun()'s body-frame +
        // heading-rotation block below is BIT-IDENTICAL in sign convention and
        // rotation math to Lua's dir_to_ned() (same MSNCFG -> same vx/vy/vz).
        // NO CHANGES required here for the v22 takeover fixes -- both bugs
        // (forced GPS-Guided fallback on mode-switch, and an over-aggressive
        // remain_ms floor dropping the tail of a resumed step) were entirely
        // on the Lua side. This QML file is otherwise UNCHANGED from v22.
        // ════════════════════════════════════════════════════════════════════════
        // ── SYSTEM STATUS — READ BEFORE MODIFYING ───────────────────────────────
        //
        // ════════════════════════════════════════════════════════════════════════
        // v8 ROOT-CAUSE FIX: NoGPS movement now uses SET_ATTITUDE_TARGET
        // ════════════════════════════════════════════════════════════════════════
        //
        // ROOT CAUSE (confirmed from ArduPilot source):
        //   Guided_NoGPS mode ONLY accepts SET_ATTITUDE_TARGET (MAVLink #82).
        //   It silently ignores SET_POSITION_TARGET_LOCAL_NED (velocity commands).
        //   guidedModeSetVelocityNED() sends SET_POSITION_TARGET_LOCAL_NED.
        //   Therefore: in NoGPS mode, velocity commands are COMPLETELY IGNORED.
        //   The drone sits still, or drifts from IMU/wind noise only.
        //
        // THE FIX — virtualTabletJoystickValue(roll, pitch, yaw, thrust):
        //   This Q_INVOKABLE already exists in QGC Vehicle.h. It sends
        //   SET_ATTITUDE_TARGET with normalized inputs (all values –1.0 to +1.0):
        //     roll  (-1=left,   +1=right)   → lateral movement
        //     pitch (-1=back,   +1=forward) → forward/back movement
        //     yaw   (-1=CCW,    +1=CW)      → rotation (unused here, always 0)
        //     thrust (0=zero,   1.0=full)   → vertical (0.5 = hover hold)
        //
        //   IMPORTANT: thrust=0.5 means "maintain altitude" in Guided_NoGPS.
        //   Do NOT send thrust=0 during lateral moves — that commands a descent.
        //   Always pair any roll/pitch command with thrust=0.5 for altitude hold.
        //
        // GPS mode is UNCHANGED — still uses guidedModeSetVelocityNED().
        //   SET_POSITION_TARGET works correctly in GPS-Guided mode.
        //
        // VELOCITY → ATTITUDE TRANSLATION (_3dVx/_3dVy/_3dVz → attitude):
        //   _3dVx, _3dVy (horizontal NED m/s) are normalized to [-1, +1] by
        //   dividing by _3dMaxSpeed (default 1.0 m/s).
        //   _3dVz (NED vertical, negative = up):
        //     vz < 0  → thrust > 0.5 (climb)
        //     vz = 0  → thrust = 0.5 (hold)
        //     vz > 0  → thrust < 0.5 (descend)
        //   The thrust curve is: thrust = 0.5 - clamp(vz / _3dMaxSpeed, -0.5, 0.5)
        //
        // _3dMoveTimer (100ms) now calls _3dSendAttitude() in NoGPS mode
        // instead of guidedModeSetVelocityNED().
        //
        // FLIGHT-TESTED (do not change without re-testing):
        //   _3dInvert = false, _3dHeading = 0  — GPS mode, standard NED
        //   _3dInvert = true,  _3dHeading = 0  — NoGPS axis invert (original behavior)
        //   _3dMoveTimer, _3dStepTimer          — timing is confirmed working
        //   guidedModeSetVelocityNED() streaming at 100 ms interval (GPS only now)
        //   velocity sign convention: vz < 0 = climb in NED
        //
        // MODE SWITCHING — IMPORTANT:
        //   v.setFlightMode("Guided") is used (NOT setGuidedMode(true)).
        //   setFlightMode is Q_INVOKABLE confirmed in Vehicle.h line 306.
        //   setGuidedMode(true) was silently failing — root cause of drone not moving.
        //
        //   NoGPS takeoff sequence:
        //     1. v.guidedModeTakeoff(alt) — QGC arms + switches to Guided_NoGPS.
        //        Do NOT call setFlightMode("Guided") before this. Forcing GPS-Guided
        //        on a NoGPS drone immediately triggers a GPS failsafe.
        //     2. _3dTakeoffTimer polls baro altitude every 300ms.
        //     3. _3dSettleTimer fires after alt confirmed. Checks if already in a
        //        Guided variant (guidedMode=true OR flightMode contains "Guided").
        //        If yes, skips setFlightMode to avoid breaking Guided_NoGPS.
        //        If no, sends setFlightMode("Guided") and retries up to 5x.
        //     4. _3dGuidedWaitTimer confirms mode, then fires _3dRun(0).
        //
        //   Velocity climb (vz=-1) is NOT used for takeoff. ArduPilot ignores
        //   SET_POSITION_TARGET velocity commands until the drone is airborne,
        //   and guidedModeTakeoff() is more reliable for both GPS and NoGPS.
        //
        // TELEMETRY-CONFIRMED TAKEOFF (unchanged from v7):
        //   _3dTakeoffTimer polls altitudeRelative.rawValue every 300ms.
        //   Mission starts only when alt >= (target - 0.4m) or 30s timeout fires.
        //   GPS mode:   guidedModeTakeoff() + polling confirmation
        //   NoGPS mode: guidedModeTakeoff() + polling confirmation (no velocity climb)
        //   _3dSettleTimer: 800ms pause after altitude confirmed before step 0
        //   _3dAltTimeoutMs: 30000ms hard abort limit if altitude never reached
        //
        // MATHEMATICALLY IMPLEMENTED BUT NOT FLIGHT-TESTED:
        //   _3dHeading != 0           — heading rotation math is correct in theory
        //                               but has NOT been validated on a real drone
        //   _3dInvert + _3dHeading != 0 — 14 untested combinations (8 headings
        //                               × 2 invert states, minus the 2 tested above)
        //                               Do NOT assume these work correctly in the field.
        //   virtualTabletJoystickValue() attitude translation — v8 NEW, needs testing.
        //
        // DO NOT change the LOCAL_NED direction mapping, velocity signs, or timer
        // architecture without flight testing.
        // ────────────────────────────────────────────────────────────────────────
        property bool   _3dInvert:      false

        // ── NoGPS mode properties ─────────────────────────────────
        // When true: uses SET_ATTITUDE_TARGET (virtualTabletJoystickValue) instead
        // of guidedModeSetVelocityNED, no drift padding, baro-only takeoff.
        property bool   _3dNoGPS:       false

        // Maximum speed used for attitude normalisation in NoGPS mode.
        // vx/vy/vz are divided by this to produce the –1..+1 joystick input.
        // Increase if the drone feels sluggish; decrease if it overshoots.
        property real   _3dMaxSpeed:    1.0

        // Heading reference: direction the drone nose is physically pointing.
        // Supported values: 0, 45, 90, 135, 180, 225, 270, 315 (all 8 compass points, 45° steps).
        // 0 = nose pointing North (GPS/compass-aligned, no rotation applied).
        // Any other value rotates the NED velocity vector so "N" in the step list
        // means "drone forward" rather than compass North.
        // WARNING: heading != 0 combinations are NOT flight-tested. Validate before use.
        property int    _3dHeading:     0

        ListModel { id: _3dModel }

        // ── Minimum altitude guard for manual-takeoff workflow ────────
        // Pilot takes off manually, hovers at 2–5m, then presses START.
        // This threshold prevents accidental mission start on the ground.
        property real   _3dMinStartAlt: 0.5   // metres — must be above this to start
        property string _3dLuaStatus:   ""    // ARM LUA feedback line (empty = hidden)

        // Waits for Guided mode to settle, then kicks off step 0.
        // Retries up to 5 times (5 × 600ms = 3s) before proceeding anyway.
        property int _3dGuidedRetries: 0

        Timer {
            id:       _3dGuidedWaitTimer
            interval: 600
            repeat:   false
            onTriggered: {
                if (!missionPlanner3D._3dRunning) return
                var v = QGroundControl.multiVehicleManager.activeVehicle
                if (!v) { missionPlanner3D._3dAbort(); return }

                var mode   = v.flightMode
                var guided = v.guidedMode
                console.log("3D: mode=" + mode + " guidedMode=" + guided + " retry=" + missionPlanner3D._3dGuidedRetries)

                // ── Accept any Guided variant ────────────────────────────────
                // After setFlightMode("Guided"), optical-flow firmware may report
                // "Guided_NoGPS" instead of "Guided". Both accept velocity commands
                // (SET_POSITION_TARGET_LOCAL_NED). Exact match on "Guided" would
                // reject "Guided_NoGPS", retry 5 times, and abort. Use indexOf so
                // any Guided variant passes.
                var inGuidedVariant = v.guidedMode || mode.indexOf("Guided") !== -1

                if (!inGuidedVariant) {
                    if (missionPlanner3D._3dGuidedRetries < 5) {
                        missionPlanner3D._3dGuidedRetries++
                        missionPlanner3D._3dStatus = "Waiting for Guided... (" + missionPlanner3D._3dGuidedRetries + "/5)"
                        v.setFlightMode("Guided")
                        _3dGuidedWaitTimer.start()
                        return
                    }
                    // Mode switch failed after 5 retries (~3s) — ABORT.
                    // Running the mission in the wrong mode sends velocity commands
                    // that ArduPilot silently ignores. The drone sits still while
                    // the UI shows "Running" — this is worse than a clean abort.
                    // Root cause: EKF not healthy, FC rejected SET_MODE, or QGC
                    // flightMode property is mismatched. Check EKF status in QGC.
                    console.log("3D: Guided switch failed after 5 retries, aborting. mode=" + mode)
                    missionPlanner3D._3dStatus = "ERROR: Guided switch failed (" + mode + ") — check EKF"
                    missionPlanner3D._3dAbort()
                    return
                } else {
                    console.log("3D: Guided mode confirmed (" + mode + "), proceeding")
                }

                missionPlanner3D._3dGuidedRetries = 0
                console.log("3D: proceeding to step 0, mode=" + mode)
                missionPlanner3D._3dRun(0)
            }
        }

        // ── Attitude helper for NoGPS mode ───────────────────────
        // Sends SET_ATTITUDE_TARGET via virtualTabletJoystickValue().
        // All inputs are normalised to –1.0 … +1.0 (thrust: 0.0 … 1.0).
        //
        //   pitch : +1 = nose-down / forward,  –1 = nose-up / backward
        //   roll  : +1 = right,                –1 = left
        //   yaw   : 0  (we never yaw during a mission step)
        //   thrust: 0.5 = hover hold, >0.5 = climb, <0.5 = descend
        //
        // NED convention used by _3dVx/_3dVy/_3dVz:
        //   vx > 0 → North (forward for default heading=0)
        //   vy > 0 → East  (right)
        //   vz < 0 → UP    (climb)
        //
        // Translation:
        //   pitch  = clamp( vx / _3dMaxSpeed, -1, 1)
        //   roll   = clamp( vy / _3dMaxSpeed, -1, 1)
        //   thrust = 0.5   – clamp( vz / _3dMaxSpeed, –0.5, 0.5)
        //            (vz = –speed → thrust = 0.5 + 0.5 = 1.0  full climb)
        //            (vz =  speed → thrust = 0.5 – 0.5 = 0.0  full descend)
        function _3dSendAttitude() {
            var v = QGroundControl.multiVehicleManager.activeVehicle
            if (!v) return
            var maxSpd = _3dMaxSpeed > 0 ? _3dMaxSpeed : 1.0
            var pitch  = Math.max(-1.0, Math.min(1.0,  _3dVx / maxSpd))
            var roll   = Math.max(-1.0, Math.min(1.0,  _3dVy / maxSpd))
            var thrust = 0.5 - Math.max(-0.5, Math.min(0.5, _3dVz / maxSpd))
            // yaw rate = 0 — we never rotate during a mission step
            console.log("3D ATT pitch=" + pitch.toFixed(3) + " roll=" + roll.toFixed(3) + " thrust=" + thrust.toFixed(3))
            v.virtualTabletJoystickValue(roll, pitch, 0.0, thrust)
        }

        Timer {
            id:       _3dMoveTimer
            interval: 100
            repeat:   true
            onTriggered: {
                var v = QGroundControl.multiVehicleManager.activeVehicle
                if (!v) { _3dMoveTimer.stop(); return }

                // v9 TEST LOG — remove after confirming movement works
                console.log("3D MOVE | noGPS=" + missionPlanner3D._3dNoGPS + " vx=" + missionPlanner3D._3dVx.toFixed(2) + " vy=" + missionPlanner3D._3dVy.toFixed(2) + " vz=" + missionPlanner3D._3dVz.toFixed(2))

                // Bug 1 fix: auto-detect NoGPS from actual FC flight mode.
                // If the toggle was left on GPS but the FC is in Guided_NoGPS,
                // velocity commands (SET_POSITION_TARGET_LOCAL_NED) are silently
                // ignored. Check the real mode and use attitude control whenever
                // the drone is actually in Guided_NoGPS.
                var actualMode  = v.flightMode
                var useAttitude = missionPlanner3D._3dNoGPS || actualMode === "Guided_NoGPS"

                if (useAttitude) {
                    // ── NoGPS: use SET_ATTITUDE_TARGET ────────────────────
                    missionPlanner3D._3dSendAttitude()
                } else {
                    // ── GPS: stream velocity every 100ms including (0,0,0) ──
                    v.guidedModeSetVelocityNED(
                        missionPlanner3D._3dVx,
                        missionPlanner3D._3dVy,
                        missionPlanner3D._3dVz)
                }
            }
        }

        Timer {
            id:     _3dStepTimer
            repeat: false
            onTriggered: missionPlanner3D._3dNext()
        }

        // ── v22: State writer / MSNSTATE readback (300ms, active while _3dRunning) ──
        // Each tick:
        //   1. Read MSNSTATE back from FC. If ==2, Lua has taken ownership: stop all
        //      timers, set _3dLuaTakeoverActive, and return early — never write params again.
        //   2. Otherwise compute and write MSNSTATE=1, MSNSTEP, MSNPHASE, MSNPROG,
        //      MSNHOVMS, MSNSEQ (++_3dSeqCounter) via sendParamSet.
        Timer {
            id:       _3dStateTimer
            interval: 300
            repeat:   true
            onTriggered: {
                var v = QGroundControl.multiVehicleManager.activeVehicle
                if (!v) { _3dStateTimer.stop(); return }

                // ── 1. Read MSNSTATE back ───────────────────────────────────────
                // param broadcasts from Lua's param:set_and_save() arrive via the
                // standard PARAM_VALUE stream and update parameterManager automatically.
                var msnstate = 1  // assume still ours unless we can read it back
                try {
                    var stateParam = v.parameterManager.getParameter(-1, "MSNSTATE")
                    if (stateParam) msnstate = Math.round(stateParam.value)
                } catch(e) {}

                if (msnstate === 2) {
                    // Lua has claimed ownership — hand over immediately
                    _3dMoveTimer.stop()
                    _3dStepTimer.stop()
                    _3dStateTimer.stop()
                    missionPlanner3D._3dRunning = false
                    missionPlanner3D._3dLuaTakeoverActive = true
                    missionPlanner3D._3dStatus = "⚡ Lua takeover active"
                    console.log("3D: MSNSTATE==2 detected — Lua takeover active, all streaming stopped")
                    _3dTakeoverPollTimer.start()
                    return
                }

                // ── 2. Write progress params to FC ─────────────────────────────
                if (!missionPlanner3D._3dRunning) { _3dStateTimer.stop(); return }

                var curStep  = missionPlanner3D._3dCurStep   // 0-based
                // Guard: if _3dRun(0) hasn't been called yet, skip this tick
                // to avoid writing MSNSTEP=0 which Lua treats as invalid.
                if (curStep < 0) { return }

                var stepIdx1 = curStep + 1                    // 1-based for MSNSTEP (always >=1)
                var phase    = missionPlanner3D._3dPhase      // "move" or "hover"
                var now      = Date.now()
                var msnPhase = (phase === "hover") ? 1 : 0

                // Compute MSNPROG (0–1000)
                var progress = 0
                if (phase === "move") {
                    var stepStartMs  = missionPlanner3D._3dStepStartMs
                    var moveDurMs    = missionPlanner3D._3dMoveDurationMs
                    if (stepStartMs > 0 && moveDurMs > 0) {
                        progress = Math.round(Math.max(0, Math.min(1, (now - stepStartMs) / moveDurMs)) * 1000)
                    }
                } else {
                    // hover phase: progress within the hover window
                    var hoverStartMs = missionPlanner3D._3dHoverStartMs
                    var s = (curStep >= 0 && curStep < missionPlanner3D._3dExec.length)
                            ? missionPlanner3D._3dExec[curStep] : null
                    if (s && s.stepHover > 0 && hoverStartMs > 0) {
                        progress = Math.round(Math.max(0, Math.min(1, (now - hoverStartMs) / (s.stepHover * 1000))) * 1000)
                    }
                }

                // MSNHOVMS: how many ms of hover have elapsed
                var hovMs = 0
                if (phase === "hover" && missionPlanner3D._3dHoverStartMs > 0) {
                    hovMs = Math.round(now - missionPlanner3D._3dHoverStartMs)
                }

                missionPlanner3D._3dSeqCounter++
                var seq = missionPlanner3D._3dSeqCounter

                missionPlanner3D._3dWriteOneFact(v, "MSNSTATE",  1)
                missionPlanner3D._3dWriteOneFact(v, "MSNSTEP",   stepIdx1)
                missionPlanner3D._3dWriteOneFact(v, "MSNPHASE",  msnPhase)
                missionPlanner3D._3dWriteOneFact(v, "MSNPROG",   progress)
                missionPlanner3D._3dWriteOneFact(v, "MSNHOVMS",  hovMs)
                missionPlanner3D._3dWriteOneFact(v, "MSNSEQ",    seq)
            }
        }

        // ── v22: Poll for Lua mission completion after takeover ───────────────
        // Runs only while _3dLuaTakeoverActive == true. When MSNSTATE becomes 3
        // (Lua finished), clear the takeover banner and re-enable START.
        Timer {
            id:       _3dTakeoverPollTimer
            interval: 500
            repeat:   true
            onTriggered: {
                if (!missionPlanner3D._3dLuaTakeoverActive) { _3dTakeoverPollTimer.stop(); return }
                var v = QGroundControl.multiVehicleManager.activeVehicle
                if (!v) return
                var msnstate = -1
                try {
                    var stateParam = v.parameterManager.getParameter(-1, "MSNSTATE")
                    if (stateParam) msnstate = Math.round(stateParam.value)
                } catch(e) {}
                if (msnstate === 3) {
                    missionPlanner3D._3dLuaTakeoverActive = false
                    missionPlanner3D._3dStatus = "Complete ✓ (Lua)"
                    console.log("3D: MSNSTATE==3 — Lua mission complete, banner cleared")
                    _3dTakeoverPollTimer.stop()
                }
            }
        }

        // ── Summary calculation (extended with vertical) ──────────
        function _3dCalcSummary() {
            var dist = 0, time = 0, vert = 0, i, s, spd, dur
            for (i = 0; i < _3dModel.count; i++) {
                s    = _3dModel.get(i)
                dist += s.stepDist
                spd   = s.stepSpeed > 0 ? s.stepSpeed : 0.5
                dur   = s.stepDist  > 0 ? s.stepDist / spd : 0
                time += dur + s.stepHover
                if (s.stepDir === "UP" || s.stepDir === "DOWN") vert += s.stepDist
            }
            _3dTotalSteps = _3dModel.count
            _3dTotalDist  = Math.round(dist * 10) / 10
            _3dTotalTime  = Math.round(time)
            _3dTotalVert  = Math.round(vert * 10) / 10
        }

        // ── Step management (unchanged + new helpers) ─────────────
        function _3dAdd() {
            _3dModel.append({ stepDir:"N", stepDist:3, stepSpeed:0.5, stepHover:2, stepStatus:"pending" })
            _3dSelStep = _3dModel.count - 1
            _3dCalcSummary()
        }

        function _3dRemove(idx) {
            _3dModel.remove(idx)
            if (_3dSelStep >= _3dModel.count) _3dSelStep = _3dModel.count - 1
            _3dCalcSummary()
        }

        function _3dClear() {
            _3dModel.clear()
            _3dSelStep = -1
            _3dCalcSummary()
        }

        // NEW: Move step up
        function _3dMoveUp(idx) {
            if (idx <= 0) return
            var a = _3dModel.get(idx - 1)
            var b = _3dModel.get(idx)
            var tmp = { stepDir: a.stepDir, stepDist: a.stepDist, stepSpeed: a.stepSpeed, stepHover: a.stepHover, stepStatus: a.stepStatus }
            _3dModel.setProperty(idx - 1, "stepDir",    b.stepDir)
            _3dModel.setProperty(idx - 1, "stepDist",   b.stepDist)
            _3dModel.setProperty(idx - 1, "stepSpeed",  b.stepSpeed)
            _3dModel.setProperty(idx - 1, "stepHover",  b.stepHover)
            _3dModel.setProperty(idx - 1, "stepStatus", b.stepStatus)
            _3dModel.setProperty(idx,     "stepDir",    tmp.stepDir)
            _3dModel.setProperty(idx,     "stepDist",   tmp.stepDist)
            _3dModel.setProperty(idx,     "stepSpeed",  tmp.stepSpeed)
            _3dModel.setProperty(idx,     "stepHover",  tmp.stepHover)
            _3dModel.setProperty(idx,     "stepStatus", tmp.stepStatus)
            _3dSelStep = idx - 1
            _3dCalcSummary()
        }

        // NEW: Move step down
        function _3dMoveDown(idx) {
            if (idx >= _3dModel.count - 1) return
            var a = _3dModel.get(idx)
            var b = _3dModel.get(idx + 1)
            var tmp = { stepDir: b.stepDir, stepDist: b.stepDist, stepSpeed: b.stepSpeed, stepHover: b.stepHover, stepStatus: b.stepStatus }
            _3dModel.setProperty(idx + 1, "stepDir",    a.stepDir)
            _3dModel.setProperty(idx + 1, "stepDist",   a.stepDist)
            _3dModel.setProperty(idx + 1, "stepSpeed",  a.stepSpeed)
            _3dModel.setProperty(idx + 1, "stepHover",  a.stepHover)
            _3dModel.setProperty(idx + 1, "stepStatus", a.stepStatus)
            _3dModel.setProperty(idx,     "stepDir",    tmp.stepDir)
            _3dModel.setProperty(idx,     "stepDist",   tmp.stepDist)
            _3dModel.setProperty(idx,     "stepSpeed",  tmp.stepSpeed)
            _3dModel.setProperty(idx,     "stepHover",  tmp.stepHover)
            _3dModel.setProperty(idx,     "stepStatus", tmp.stepStatus)
            _3dSelStep = idx + 1
            _3dCalcSummary()
        }

        // NEW: Duplicate step
        function _3dDuplicate(idx) {
            if (idx < 0 || idx >= _3dModel.count) return
            var s = _3dModel.get(idx)
            _3dModel.insert(idx + 1, { stepDir: s.stepDir, stepDist: s.stepDist, stepSpeed: s.stepSpeed, stepHover: s.stepHover, stepStatus: "pending" })
            _3dSelStep = idx + 1
            _3dCalcSummary()
        }

        // ── Presets (extended with more shapes) ───────────────────
        function _3dPreset(name) {
            _3dModel.clear(); _3dSelStep = -1
            var i, steps
            if (name === "StairClimb") {
                steps = [["N",5,0.5,1],["UP",3,0.4,2],["N",5,0.5,1],["UP",3,0.4,2],["N",5,0.5,1],["UP",3,0.4,2]]
            } else if (name === "Pyramid") {
                steps = [["N",5,0.5,1],["E",5,0.5,1],["S",5,0.5,1],["W",5,0.5,1],["UP",4,0.4,2],["N",3,0.5,1],["E",3,0.5,1],["S",3,0.5,1],["W",3,0.5,1]]
            } else if (name === "AltPatrol") {
                steps = [["N",5,0.5,2],["UP",3,0.4,2],["S",5,0.5,2],["UP",3,0.4,2],["N",5,0.5,2],["DOWN",6,0.4,2]]
            } else if (name === "VertScan") {
                steps = [["UP",2,0.4,1],["N",3,0.5,1],["UP",2,0.4,1],["S",3,0.5,1],["UP",2,0.4,1],["DOWN",6,0.4,2]]
            } else if (name === "Square") {
                // Square route: N → E → S → W back to start
                steps = [["N",5,0.5,1],["E",5,0.5,1],["S",5,0.5,1],["W",5,0.5,1]]
            } else if (name === "Triangle") {
                // Equilateral-ish triangle using cardinal + diagonal
                steps = [["N",5,0.5,1],["SE",5,0.5,1],["W",4,0.5,1]]
            } else if (name === "ZigZag") {
                // Zig-zag pattern: alternating NE / NW
                steps = [["NE",4,0.5,0],["NW",4,0.5,0],["NE",4,0.5,0],["NW",4,0.5,0],["NE",4,0.5,0]]
            } else if (name === "MultiLevel") {
                // Multi-level patrol: North patrol at 3 altitudes
                steps = [["N",6,0.5,2],["S",6,0.5,0],["UP",3,0.4,1],["N",6,0.5,2],["S",6,0.5,0],["UP",3,0.4,1],["N",6,0.5,2],["DOWN",6,0.4,2]]
            } else {
                steps = []
            }
            for (i = 0; i < steps.length; i++)
                _3dModel.append({ stepDir:steps[i][0], stepDist:steps[i][1],
                                  stepSpeed:steps[i][2], stepHover:steps[i][3], stepStatus:"pending" })
            _3dCalcSummary()
        }

        // ── Execution engine (unchanged) ──────────────────────────
        function _3dRun(idx) {
            if (idx < 0 || idx >= _3dExec.length) { _3dComplete(); return }
            _3dCurStep = idx
            _3dModel.setProperty(idx, "stepStatus", "active")
            var s  = _3dExec[idx]
            var sx = _3dInvert ? -1 : 1
            var sy = _3dInvert ? -1 : 1
            _3dVx = 0; _3dVy = 0; _3dVz = 0
            // v22: record step start time for MSNPROG calculation
            missionPlanner3D._3dStepStartMs = Date.now()
            missionPlanner3D._3dHoverStartMs = 0

            // Raw body-frame velocity from direction + speed
            var bx = 0, by = 0
            if (s.stepDist > 0) {
                switch (s.stepDir) {
                    case "N":    bx =  sx * s.stepSpeed;                                              break
                    case "NE":   bx =  sx * s.stepSpeed * 0.707; by =  sy * s.stepSpeed * 0.707; break
                    case "E":                                     by =  sy * s.stepSpeed;          break
                    case "SE":   bx = -sx * s.stepSpeed * 0.707; by =  sy * s.stepSpeed * 0.707; break
                    case "S":    bx = -sx * s.stepSpeed;                                              break
                    case "SW":   bx = -sx * s.stepSpeed * 0.707; by = -sy * s.stepSpeed * 0.707; break
                    case "W":                                     by = -sy * s.stepSpeed;          break
                    case "NW":   bx =  sx * s.stepSpeed * 0.707; by = -sy * s.stepSpeed * 0.707; break
                    case "UP":   _3dVz = -s.stepSpeed;                                                break
                    case "DOWN": _3dVz =  s.stepSpeed;                                                break
                    default:     bx =  sx * s.stepSpeed;                                              break
                }

                // ── Heading rotation for NoGPS body-frame alignment ──
                // If the drone's forward face isn't pointing North, rotate the
                // horizontal velocity vector by _3dHeading degrees so "N" in
                // the step list means "drone forward", not compass North.
                if (_3dHeading !== 0 && (bx !== 0 || by !== 0)) {
                    var rad = _3dHeading * Math.PI / 180
                    var cos = Math.cos(rad)
                    var sin = Math.sin(rad)
                    // NED: x=North, y=East  →  rotate CCW by heading
                    _3dVx = bx * cos - by * sin
                    _3dVy = bx * sin + by * cos
                } else {
                    _3dVx = bx
                    _3dVy = by
                }
            }

            console.log("3D run idx=" + idx + " dir=" + s.stepDir + " vx=" + _3dVx + " vy=" + _3dVy + " vz=" + _3dVz)
            _3dStatus = "Step " + (idx+1) + "/" + _3dExec.length + " · " + s.stepDir + " " + s.stepDist + "m"

            // ── Move duration ────────────────────────────────────────
            // GPS mode:   add 800ms padding so position hold catches up
            // NoGPS mode: no padding — drone won't hold anyway, extra time = drift
            var padding = _3dNoGPS ? 0 : 800
            var dur = s.stepDist > 0 ? (s.stepDist / s.stepSpeed) * 1000 + padding : 200
            missionPlanner3D._3dMoveDurationMs = dur   // v22: used by _3dStateTimer for MSNPROG
            _3dPhase = "move"
            _3dStepTimer.interval = dur
            _3dStepTimer.start()
            _3dMoveTimer.stop()
            _3dMoveTimer.start()
        }

        function _3dNext() {
            if (!_3dRunning) return
            var s = _3dExec[_3dCurStep]
            if (_3dPhase === "move") {
                _3dVx = 0; _3dVy = 0; _3dVz = 0
                if (s.stepHover > 0) {
                    _3dPhase = "hover"
                    _3dStatus = "Hovering " + s.stepHover + "s"
                    // v22: record hover start time for MSNHOVMS calculation
                    missionPlanner3D._3dHoverStartMs = Date.now()
                    _3dStepTimer.interval = s.stepHover * 1000
                    _3dStepTimer.start()
                    // NoGPS: keep streaming attitude commands every 100ms so the
                    // FC stays in Guided_NoGPS attitude-hold. vx/vy/vz are all
                    // 0 here, so _3dSendAttitude() sends pitch=0, roll=0,
                    // thrust=0.5 — that is the correct neutral hover command.
                    // GPS: stop streaming — position hold handles it.
                    if (_3dNoGPS) {
                        _3dMoveTimer.stop()
                        _3dMoveTimer.start()   // vx=vy=vz=0 → attitude hover hold
                    } else {
                        _3dMoveTimer.stop()
                    }
                } else {
                    _3dModel.setProperty(_3dCurStep, "stepStatus", "complete")
                    _3dRun(_3dCurStep + 1)
                }
            } else {
                _3dModel.setProperty(_3dCurStep, "stepStatus", "complete")
                _3dRun(_3dCurStep + 1)
            }
        }

        function _3dComplete() {
            _3dMoveTimer.stop(); _3dStepTimer.stop(); _3dStateTimer.stop()
            _3dVx = 0; _3dVy = 0; _3dVz = 0
            _3dRunning = false; _3dCurStep = -1
            _3dStatus = "Complete ✓"
            var v = QGroundControl.multiVehicleManager.activeVehicle
            if (v) {
                // v22: write MSNSTATE=3 so Lua's ST_WATCH sees QGC finished cleanly
                missionPlanner3D._3dWriteOneFact(v, "MSNSTATE", 3)
                if (_3dNoGPS) {
                    // NoGPS: send neutral attitude (hover) to stop movement
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                } else {
                    v.guidedModeSetVelocityNED(0,0,0)
                    v.guidedModeSetVelocityNED(0,0,0)
                    v.guidedModeSetVelocityNED(0,0,0)
                }
            }
        }

        function _3dAbort() {
            _3dMoveTimer.stop(); _3dStepTimer.stop(); _3dGuidedWaitTimer.stop(); _3dStateTimer.stop()
            _3dVx = 0; _3dVy = 0; _3dVz = 0
            _3dRunning = false; _3dCurStep = -1; _3dGuidedRetries = 0
            var i
            for (i = 0; i < _3dModel.count; i++) _3dModel.setProperty(i, "stepStatus", "pending")
            _3dStatus = "Aborted"
            var v = QGroundControl.multiVehicleManager.activeVehicle
            if (v) {
                // v22: write MSNSTATE=0 so Lua's ST_WATCH sees QGC aborted cleanly
                missionPlanner3D._3dWriteOneFact(v, "MSNSTATE", 0)
                if (_3dNoGPS) {
                    // NoGPS: send neutral attitude (hover hold) to stop movement
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                    v.virtualTabletJoystickValue(0.0, 0.0, 0.0, 0.5)
                } else {
                    v.guidedModeSetVelocityNED(0,0,0)
                    v.guidedModeSetVelocityNED(0,0,0)
                    v.guidedModeSetVelocityNED(0,0,0)
                }
            }
        }

        function _3dStart() {
            if (_3dModel.count === 0 || _3dRunning) {
                console.log("3D: blocked count=" + _3dModel.count + " running=" + _3dRunning); return
            }
            var v = QGroundControl.multiVehicleManager.activeVehicle
            if (!v) { console.log("3D: no vehicle"); return }

            console.log("=== 3D START ===")
            console.log("  mode    = " + v.flightMode)
            console.log("  guided  = " + v.guidedMode)
            console.log("  flying  = " + v.flying)
            console.log("  alt     = " + v.altitudeRelative.rawValue.toFixed(2) + "m")
            console.log("  noGPS   = " + _3dNoGPS)
            console.log("  steps   = " + _3dModel.count)

            // Bug 2 fix: altitude check BEFORE changing any state.
            // If the check was after _3dRunning=true/_3dOpen=false the panel
            // would close and the user would not see the failure message.
            var currentAlt = 0
            try { currentAlt = v.altitudeRelative.rawValue } catch(e) {}
            if (currentAlt < _3dMinStartAlt) {
                _3dStatus = "Too low (" + currentAlt.toFixed(1) + "m) — hover first"
                console.log("3D: aborted — alt=" + currentAlt.toFixed(2) + " below min=" + _3dMinStartAlt)
                return   // panel stays OPEN so user can see the error
            }

            // Bug 7 fix: block START if ARM LUA is still pending (both systems
            // would simultaneously command the drone if allowed to overlap).
            if (missionPlanner3D._3dLuaPendingCount > 0) {
                _3dStatus = "ARM LUA is pending — flip RC6 or wait"
                return
            }

            var i
            for (i = 0; i < _3dModel.count; i++) _3dModel.setProperty(i, "stepStatus", "pending")
            _3dExec = []
            for (i = 0; i < _3dModel.count; i++) {
                var s = _3dModel.get(i)
                _3dExec.push({ stepDir:s.stepDir, stepDist:s.stepDist, stepSpeed:s.stepSpeed, stepHover:s.stepHover })
            }

            _3dRunning = true
            _3dOpen    = false

            // v22: initialize takeover tracking state
            missionPlanner3D._3dSeqCounter       = 0
            missionPlanner3D._3dStepStartMs      = 0
            missionPlanner3D._3dHoverStartMs     = 0
            missionPlanner3D._3dMoveDurationMs   = 0
            missionPlanner3D._3dTotalStepsForLua = _3dExec.length
            missionPlanner3D._3dLuaTakeoverActive = false

            // v22: write initial params (MSNSTATE=1, all others=0, MSNTOTAL) before
            // streaming starts, so Lua can begin watching from the first tick.
            {
                var vInit = QGroundControl.multiVehicleManager.activeVehicle
                if (vInit) {
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNSTATE",  1)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNSTEP",   1)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNPHASE",  0)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNPROG",   0)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNHOVMS",  0)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNSEQ",    0)
                    missionPlanner3D._3dWriteOneFact(vInit, "MSNTOTAL",  _3dExec.length)
                }
            }

            // ── Switch to Guided and run ───────────────────────────────────
            var mode     = v.flightMode
            var inGuided = v.guidedMode || mode.indexOf("Guided") !== -1

            if (inGuided) {
                console.log("3D: already in Guided, starting immediately")
                _3dStatus = "Running..."
                _3dRun(0)
                // v22: start state timer AFTER _3dRun(0) sets _3dCurStep=0,
                // so first tick never writes MSNSTEP=0 (which Lua rejects).
                _3dStateTimer.stop()
                _3dStateTimer.start()
            } else {
                console.log("3D: switching to Guided from (" + mode + ")")
                _3dStatus = "Switching to Guided..."
                _3dGuidedRetries = 0
                v.setFlightMode("Guided")
                _3dGuidedWaitTimer.start()
                // v22: start state timer now — _3dRun(0) will be called by
                // _3dGuidedWaitTimer when Guided is confirmed; the curStep<0
                // guard in the timer prevents writing invalid MSNSTEP until then.
                _3dStateTimer.stop()
                _3dStateTimer.start()
            }
        }

        // ── ARM LUA ──────────────────────────────────────────────────────────
        // Writes MSNCFG + MSNS1..MSNS20, then after 1s writes MSNCOUNT (GO).
        //
        // ROOT CAUSE OF COMPLEXITY:
        //   QGC v5 Daily connects to SITL within 0.5s of boot. ArduPilot's Lua
        //   scheduler runs its first cycle ~2s later — registering MSNCFG etc.
        //   QGC's initial param list snapshot has no Lua params.
        //   refreshAllParameters() re-requests the list, but QGC's reception
        //   pipeline uses the old PARAM_COUNT from connection time and discards
        //   any params that appear beyond that count. So Lua params are
        //   permanently invisible to getParameter() for that session.
        //
        // THREE-PATH STRATEGY:
        //   FAST  (most presses after first): MSNCFG already in cache → write now.
        //   SLOW  (rare): refreshAllParameters → poll parametersReady → write.
        //   RECONNECT (SITL first press): params not in cache even after refresh →
        //     disconnect QGC → QGC auto-reconnects → Lua params now in initial list
        //     → poll parametersReady → write.
        //
        // On real hardware the FAST path is always taken (FC boots slower than QGC).
        // SITL may need the RECONNECT path on the very first ARM LUA press.

        // ── ARM LUA state ────────────────────────────────────────────────────
        property int  _3dLuaPendingCount:  0
        property var  _3dLuaVehicle:       null
        property var  _3dLuaPackedCfg:     0
        property var  _3dLuaPackedSteps:   []    // array of {name, val}
        property int  _3dLuaCachedCid:     -99
        property bool _3dSeenNotReady:     false
        property bool _3dReconnectDone:    false  // true after one auto-reconnect

        // ── v22: Automatic Link-Loss Takeover state ───────────────────────────
        property int  _3dSeqCounter:       0      // MSNSEQ heartbeat, incremented each _3dStateTimer tick
        property real _3dStepStartMs:      0      // Date.now() when _3dRun(idx) was called for current step
        property real _3dHoverStartMs:     0      // Date.now() when hover phase began (0 = not yet)
        property int  _3dTotalStepsForLua: 0      // MSNTOTAL written once at START
        property bool _3dLuaTakeoverActive: false // true when Lua has taken ownership (MSNSTATE==2)
        property real _3dMoveDurationMs:   0      // duration of current move step in ms (for MSNPROG)

        // ── Write one param via direct MAVLink PARAM_SET ──────────────────
        // Uses Vehicle::sendParamSet() — Q_INVOKABLE added to Vehicle.h/.cc.
        // Bypasses parameterManager cache entirely. Works even when getParameter()
        // returns null for Lua custom params (which it always does in QGC Daily).
        // componentId=1 = MAV_COMP_ID_AUTOPILOT1, accepted by ArduPilot always.
        function _3dWriteOneFact(v, name, val) {
            try {
                v.sendParamSet(1, name, val)
                return true
            } catch(e) {
                console.log("3D: sendParamSet FAILED " + name + ": " + e)
                _3dLuaStatus = "FAILED: sendParamSet — rebuild QGC with Vehicle.cc patch"
                return false
            }
        }

        // ── Phase B: 1s delay before sending MSNCOUNT GO signal ──────────────
        Timer {
            id:       _3dLuaCountTimer
            interval: 1000
            repeat:   false
            onTriggered: {
                var v = missionPlanner3D._3dLuaVehicle
                var n = missionPlanner3D._3dLuaPendingCount
                if (!v || n <= 0) { missionPlanner3D._3dLuaStatus = "ERROR: vehicle lost"; return }
                var ok = missionPlanner3D._3dWriteOneFact(v, "MSNCOUNT", n)
                missionPlanner3D._3dLuaStatus = ok
                    ? "✅ " + n + " step(s) armed — flip RC6 HIGH"
                    : "FAILED: MSNCOUNT write failed — retry ARM LUA"
                missionPlanner3D._3dLuaVehicle      = null
                missionPlanner3D._3dLuaPendingCount = 0
            }
        }

        // ── Write MSNCFG + all step params, then start GO delay ──────────────
        function _3dDoWrite() {
            var v = _3dLuaVehicle
            if (!v) { _3dLuaStatus = "ERROR: vehicle lost during write"; return }
            _3dWriteOneFact(v, "MSNCFG", _3dLuaPackedCfg)
            var steps = _3dLuaPackedSteps
            for (var i = 0; i < steps.length; i++) _3dWriteOneFact(v, steps[i].name, steps[i].val)
            _3dLuaStatus = "⏳ Params written — sending GO in 1s…"
            _3dLuaCountTimer.stop()
            _3dLuaCountTimer.start()
        }

        // ── Entry point: pack mission, choose path ────────────────────────────
        function _3dArmLua() {
            _3dLuaStatus = "⏳ Loading…"
            if (_3dModel.count === 0) { _3dLuaStatus = "No steps — add steps first"; return }
            var v = QGroundControl.multiVehicleManager.activeVehicle
            if (!v) { _3dLuaStatus = "No vehicle connected"; return }

            var maxSteps = 20
            var n = Math.min(_3dModel.count, maxSteps)

            // Pack config
            var invert_bit = _3dInvert ? 1 : 0
            var nogps_bit  = _3dNoGPS  ? 2 : 0
            var hdg_bits   = Math.floor(Math.max(0, Math.min(511, _3dHeading)))
            var spd_bits   = Math.floor(Math.max(0, Math.min(127, _3dMaxSpeed * 10)))
            var cfg = invert_bit + nogps_bit + hdg_bits * 4 + spd_bits * 4096 + 15 * 524288

            // Pack steps
            var dirCode = {"N":0,"NE":1,"E":2,"SE":3,"S":4,"SW":5,"W":6,"NW":7,"UP":8,"DOWN":9}
            var steps = []
            for (var i = 0; i < maxSteps; i++) {
                var pname = "MSNS" + (i + 1)
                if (i < n) {
                    var s      = _3dModel.get(i)
                    var dc2    = (dirCode[s.stepDir] !== undefined) ? dirCode[s.stepDir] : 0
                    var dist10 = Math.floor(Math.max(0, Math.min(255, s.stepDist  * 10)))
                    var spd20  = Math.floor(Math.max(0, Math.min(255, s.stepSpeed * 20)))
                    var hov10  = Math.floor(Math.max(0, Math.min(255, s.stepHover * 10)))
                    steps.push({name: pname, val: dc2*16777216 + dist10*65536 + spd20*256 + hov10})
                } else {
                    steps.push({name: pname, val: 0})
                }
            }

            _3dLuaVehicle      = v
            _3dLuaPendingCount = n
            _3dLuaPackedCfg    = cfg
            _3dLuaPackedSteps  = steps
            _3dLuaCachedCid    = -99
            _3dSeenNotReady    = false
            _3dReconnectDone   = false

            // v22: zero-write all 7 takeover params BEFORE writing MSNCOUNT.
            // This resets the ownership token regardless of any prior state
            // (e.g. MSNSTATE==3 from a previous QGC-START session that ended in
            // takeover), guaranteeing no cross-workflow interference.
            missionPlanner3D._3dWriteOneFact(v, "MSNSTATE",  0)
            missionPlanner3D._3dWriteOneFact(v, "MSNSTEP",   0)
            missionPlanner3D._3dWriteOneFact(v, "MSNPHASE",  0)
            missionPlanner3D._3dWriteOneFact(v, "MSNPROG",   0)
            missionPlanner3D._3dWriteOneFact(v, "MSNHOVMS",  0)
            missionPlanner3D._3dWriteOneFact(v, "MSNSEQ",    0)
            missionPlanner3D._3dWriteOneFact(v, "MSNTOTAL",  0)

            // Direct MAVLink write — no cache lookup or refresh needed
            console.log("3D ARM: sending " + n + " steps via sendParamSet")
            _3dLuaStatus = "⏳ Writing params…"
            _3dDoWrite()
        }

        // ── Toggle Button ─────────────────────────────────────────
        Rectangle {
            id:             _3dBtn
            anchors.left:   parent.left
            anchors.bottom: parent.bottom
            width:          ScreenTools.defaultFontPixelWidth * 22
            height:         ScreenTools.defaultFontPixelHeight * 2.4
            radius:         ScreenTools.defaultFontPixelHeight * 1.2
            color:          "#CC0E0000"
            border.color:   "#CC2222"
            border.width:   1
            Row {
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    color: missionPlanner3D._3dRunning ? "#FF8800" : "#FF4444"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "▲ 3D Mission"
                    color:          "#FF4444"
                    font.bold:      true
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 0.88
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: missionPlanner3D._3dTotalSteps > 0
                    width:   _3dBtnBadge.implicitWidth + 10
                    height:  18; radius: 9
                    color: "#1A0000"; border.color: "#551111"; border.width: 1
                    Text {
                        id:               _3dBtnBadge
                        anchors.centerIn: parent
                        text:             missionPlanner3D._3dTotalSteps + " steps"
                        color:            "#AA3333"
                        font.pixelSize:   ScreenTools.defaultFontPixelSize * 0.68
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked:    missionPlanner3D._3dOpen = !missionPlanner3D._3dOpen
            }
        }

        // ── Panel ─────────────────────────────────────────────────
        Rectangle {
            id:                   _3dPanel
            visible:              missionPlanner3D._3dOpen
            anchors.left:         parent.left
            anchors.bottom:       _3dBtn.top
            anchors.bottomMargin: 6
            width:                parent.width
            height:               _3dPanelFlick.height + ScreenTools.defaultFontPixelWidth
            radius:               10
            color:                "#EE050A14"
            border.color:         "#AA1111"
            border.width:         1

            // Flickable so ARM LUA button + status line are always reachable on small screens.
            // The panel grows upward; without this wrapper the bottom items overflow on phones/tablets.
            Flickable {
                id:                 _3dPanelFlick
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                anchors.margins:    4
                height:             Math.min(_3dPanelCol.implicitHeight + ScreenTools.defaultFontPixelWidth * 2,
                                             _root.height * 0.85)
                contentHeight:      _3dPanelCol.implicitHeight + ScreenTools.defaultFontPixelWidth * 2
                clip:               true
                flickableDirection: Flickable.VerticalFlick

                Column {
                id:              _3dPanelCol
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                spacing:         8

                // ── Header ────────────────────────────────────────
                Item {
                    width:  parent.width
                    height: ScreenTools.defaultFontPixelHeight * 2
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: 16; radius: 2; color: "#FF4444"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "3D MISSION PLANNER"; color: "#CC3333"
                            font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.72
                        }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22; radius: 11
                        color: "#1A0000"; border.color: "#331111"; border.width: 1
                        Text { anchors.centerIn: parent; text: "✕"; color: "#553333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.76 }
                        MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dOpen = false }
                    }
                }

                // ── Status bar ────────────────────────────────────
                Rectangle {
                    width: parent.width; height: ScreenTools.defaultFontPixelHeight * 1.8
                    radius: 4; color: "#0A0A0F"; border.color: "#1A1122"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text:  missionPlanner3D._3dStatus
                        color: missionPlanner3D._3dRunning ? "#FF6644" : "#AA3333"
                        font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.76
                    }
                }

                // ── Summary cards (4: steps, dist, time, vert) ───
                Row {
                    width: parent.width; spacing: 4
                    Repeater {
                        model: 4
                        Rectangle {
                            width:  (parent.width - 12) / 4
                            height: ScreenTools.defaultFontPixelHeight * 2.8
                            radius: 6; color: "#07060E"; border.color: "#1A0808"; border.width: 1
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:  index === 0 ? "STEPS" : index === 1 ? "DIST" : index === 2 ? "TIME" : "VERT"
                                    color: "#442222"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.56; font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: index === 0 ? missionPlanner3D._3dTotalSteps
                                        : index === 1 ? missionPlanner3D._3dTotalDist + "m"
                                        : index === 2 ? missionPlanner3D._3dTotalTime + "s"
                                        :               missionPlanner3D._3dTotalVert + "m"
                                    color: index === 3 ? "#33AACC" : "#FF5533"
                                    font.pixelSize: ScreenTools.defaultFontPixelSize * 0.95; font.bold: true
                                }
                            }
                        }
                    }
                }

                // ── Takeoff alt ───────────────────────────────────
                Rectangle {
                    width: parent.width; height: ScreenTools.defaultFontPixelHeight * 2.8
                    radius: 6; color: "#06060C"; border.color: "#180808"; border.width: 1
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Takeoff Alt"; color: "#BB7777"
                            font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 4
                            Repeater {
                                model: [3, 5, 10]
                                Rectangle {
                                    width: ScreenTools.defaultFontPixelWidth * 5.5; height: ScreenTools.defaultFontPixelHeight * 1.7; radius: 4
                                    color:        missionPlanner3D._3dTakeoffAlt === modelData ? "#2A0A0A" : "#05050C"
                                    border.color: missionPlanner3D._3dTakeoffAlt === modelData ? "#AA1111" : "#1A0808"
                                    border.width: missionPlanner3D._3dTakeoffAlt === modelData ? 2 : 1
                                    Text {
                                        anchors.centerIn: parent; text: modelData + "m"
                                        color: missionPlanner3D._3dTakeoffAlt === modelData ? "#FF5533" : "#775555"
                                        font.bold: missionPlanner3D._3dTakeoffAlt === modelData
                                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.8
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dTakeoffAlt = modelData }
                                }
                            }
                        }
                    }
                }

                // ── Steps section label ───────────────────────────
                Item {
                    width: parent.width; height: 14
                    Text {
                        id: _3dStepsLbl
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: "3D MISSION STEPS"; color: "#551111"
                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60; font.bold: true
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: _3dStepsLbl.left
                        anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        height: 1; color: "#220A0A"
                    }
                }

                // ── Step list ─────────────────────────────────────
                Flickable {
                    width:         parent.width
                    height:        Math.min(contentHeight, ScreenTools.defaultFontPixelHeight * 16)
                    contentHeight: _3dListCol.implicitHeight
                    clip:          true

                    Column {
                        id:      _3dListCol
                        width:   parent.width
                        spacing: 5

                        // Empty state
                        Rectangle {
                            visible: _3dModel.count === 0
                            width: parent.width; height: ScreenTools.defaultFontPixelHeight * 4
                            radius: 6; color: "#04040A"; border.color: "#180808"; border.width: 1
                            Column {
                                anchors.centerIn: parent; spacing: 4
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No steps yet"; color: "#AA3333"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Add a step or load a preset below"; color: "#553333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.72 }
                            }
                        }

                        Repeater {
                            model: _3dModel

                            Rectangle {
                                id:     _3dCard
                                width:  _3dListCol.width
                                height: _3dCardBody.implicitHeight + 12
                                radius: 7

                                property int    myIdx:    index
                                property string myDir:    model.stepDir
                                property real   myDist:   model.stepDist
                                property real   myHover:  model.stepHover
                                property real   mySpeed:  model.stepSpeed
                                property string myStatus: model.stepStatus
                                property bool   myOpen:   missionPlanner3D._3dSelStep === index
                                property bool   isVert:   model.stepDir === "UP" || model.stepDir === "DOWN"

                                color: myStatus === "active"   ? "#0F0700"
                                     : myStatus === "complete" ? "#080F00"
                                     : myOpen                  ? "#1A0505" : "#05050C"
                                border.color: myStatus === "active"   ? "#FF6600"
                                            : myStatus === "complete" ? "#33AA44"
                                            : myOpen                  ? "#AA1111" : "#1A0808"
                                border.width: (myStatus === "active" || myOpen) ? 2 : 1

                                Column {
                                    id:              _3dCardBody
                                    anchors.left:    parent.left
                                    anchors.right:   parent.right
                                    anchors.top:     parent.top
                                    anchors.margins: 6
                                    spacing:         6

                                    // ── Step header row ───────────────────────────
                                    Item {
                                        width: parent.width; height: 28

                                        Row {
                                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            // Step number badge
                                            Rectangle {
                                                width: 22; height: 22; radius: 11
                                                color: _3dCard.myStatus === "active" ? "#1A0800"
                                                     : _3dCard.isVert               ? "#001A18" : "#1A0505"
                                                border.color: _3dCard.myStatus === "active" ? "#FF6600"
                                                            : _3dCard.isVert               ? "#00CCAA" : "#AA2222"
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text:  _3dCard.myIdx + 1
                                                    color: _3dCard.myStatus === "active" ? "#FF8844"
                                                         : _3dCard.isVert               ? "#00DDBB" : "#CC3333"
                                                    font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70
                                                }
                                            }

                                            // Direction badge
                                            Rectangle {
                                                width: 38; height: 22; radius: 4
                                                color: _3dCard.isVert ? "#001A18" : "#1A0505"
                                                border.color: _3dCard.isVert ? "#00AACC" : "#AA2222"; border.width: 1
                                                Text {
                                                    anchors.centerIn: parent; text: _3dCard.myDir
                                                    color: _3dCard.myDir === "UP" ? "#00DDBB"
                                                         : _3dCard.myDir === "DOWN" ? "#FFAA33" : "#FF5533"
                                                    font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78
                                                }
                                            }

                                            // Distance
                                            Rectangle {
                                                width: ScreenTools.defaultFontPixelWidth * 4.2; height: 22; radius: 4
                                                color: "#05050C"; border.color: "#1A0808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: _3dCard.myDist + "m"; color: "#CC5533"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74 }
                                            }

                                            // Hover badge
                                            Rectangle {
                                                visible: _3dCard.myHover > 0
                                                width: ScreenTools.defaultFontPixelWidth * 4.5; height: 22; radius: 4
                                                color: "#0E0800"; border.color: "#1A1000"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "⏱" + _3dCard.myHover + "s"; color: "#BBAA44"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70 }
                                            }

                                            // Speed badge
                                            Rectangle {
                                                width: ScreenTools.defaultFontPixelWidth * 4.8; height: 22; radius: 4
                                                color: "#04080A"; border.color: "#081408"; border.width: 1
                                                Text { anchors.centerIn: parent; text: _3dCard.mySpeed + "m/s"; color: "#449966"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.66 }
                                            }
                                        }

                                        // Right-side action buttons
                                        Row {
                                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3

                                            // Live indicator
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text:  _3dCard.myStatus === "active" ? "●" : _3dCard.myStatus === "complete" ? "✓" : "○"
                                                color: _3dCard.myStatus === "active" ? "#FF6644" : _3dCard.myStatus === "complete" ? "#44AA55" : "#442222"
                                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.66; font.bold: true
                                            }

                                            // Move Up
                                            Rectangle {
                                                visible: _3dCard.myIdx > 0 && !missionPlanner3D._3dRunning
                                                width: 20; height: 20; radius: 4
                                                color: "#04040C"; border.color: "#1A2808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "▲"; color: "#336633"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60 }
                                                MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dMoveUp(_3dCard.myIdx) }
                                            }

                                            // Move Down
                                            Rectangle {
                                                visible: _3dCard.myIdx < _3dModel.count - 1 && !missionPlanner3D._3dRunning
                                                width: 20; height: 20; radius: 4
                                                color: "#04040C"; border.color: "#1A1808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "▼"; color: "#334433"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60 }
                                                MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dMoveDown(_3dCard.myIdx) }
                                            }

                                            // Duplicate
                                            Rectangle {
                                                visible: !missionPlanner3D._3dRunning
                                                width: 20; height: 20; radius: 4
                                                color: "#04040C"; border.color: "#0A1A18"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "⧉"; color: "#336655"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.68 }
                                                MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dDuplicate(_3dCard.myIdx) }
                                            }

                                            // Edit toggle
                                            Rectangle {
                                                width: 20; height: 20; radius: 4
                                                color:        _3dCard.myOpen ? "#2A0A0A" : "#04040C"
                                                border.color: _3dCard.myOpen ? "#AA1111" : "#1A0808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "✎"; color: _3dCard.myOpen ? "#FF3333" : "#441111"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70 }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: missionPlanner3D._3dSelStep = (missionPlanner3D._3dSelStep === _3dCard.myIdx ? -1 : _3dCard.myIdx)
                                                }
                                            }

                                            // Delete
                                            Rectangle {
                                                visible: !missionPlanner3D._3dRunning
                                                width: 20; height: 20; radius: 4
                                                color: "#0F0000"; border.color: "#2A0000"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "✕"; color: "#551111"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70 }
                                                MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dRemove(_3dCard.myIdx) }
                                            }
                                        }
                                    }

                                    // ── Inline editor ─────────────────────────────
                                    Column {
                                        visible: _3dCard.myOpen
                                        width:   parent.width
                                        spacing: 6

                                        Rectangle { width: parent.width; height: 1; color: "#220808" }

                                        // Direction grid (8 compass + up/down)
                                        Text { text: "DIRECTION"; color: "#AA3333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62; font.bold: true }

                                        Grid {
                                            columns: 3; spacing: 3
                                            Repeater {
                                                model: ["NW","N","NE","W","·","E","SW","S","SE"]
                                                Rectangle {
                                                    property bool isCenter: modelData === "·"
                                                    width:  ScreenTools.defaultFontPixelWidth * 5.0
                                                    height: ScreenTools.defaultFontPixelHeight * 1.6
                                                    radius: isCenter ? 0 : 4
                                                    color:        isCenter ? "transparent" : _3dCard.myDir === modelData ? "#2A0A0A" : "#04040C"
                                                    border.color: isCenter ? "transparent" : _3dCard.myDir === modelData ? "#AA1111" : "#1A0808"
                                                    border.width: isCenter ? 0 : 1
                                                    Text {
                                                        visible: !parent.isCenter; anchors.centerIn: parent; text: modelData
                                                        color: _3dCard.myDir === modelData ? "#FF5533" : "#553333"
                                                        font.bold: _3dCard.myDir === modelData
                                                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent; enabled: !parent.isCenter
                                                        onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepDir", modelData); missionPlanner3D._3dCalcSummary() }
                                                    }
                                                }
                                            }
                                        }

                                        // UP / DOWN buttons
                                        Row {
                                            spacing: 4
                                            Rectangle {
                                                width: ScreenTools.defaultFontPixelWidth * 8.5; height: ScreenTools.defaultFontPixelHeight * 1.7; radius: 4
                                                color:        _3dCard.myDir === "UP" ? "#001A18" : "#04040C"
                                                border.color: _3dCard.myDir === "UP" ? "#00AACC" : "#1A0808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "▲  UP"; color: _3dCard.myDir === "UP" ? "#00DDBB" : "#336655"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78 }
                                                MouseArea { anchors.fill: parent; onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepDir", "UP"); missionPlanner3D._3dCalcSummary() } }
                                            }
                                            Rectangle {
                                                width: ScreenTools.defaultFontPixelWidth * 8.5; height: ScreenTools.defaultFontPixelHeight * 1.7; radius: 4
                                                color:        _3dCard.myDir === "DOWN" ? "#1A0E00" : "#04040C"
                                                border.color: _3dCard.myDir === "DOWN" ? "#CC6600" : "#1A0808"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "▼  DOWN"; color: _3dCard.myDir === "DOWN" ? "#FFAA33" : "#665533"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78 }
                                                MouseArea { anchors.fill: parent; onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepDir", "DOWN"); missionPlanner3D._3dCalcSummary() } }
                                            }
                                        }

                                        // Distance
                                        Text { text: "DISTANCE (m)"; color: "#AA3333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62; font.bold: true }
                                        Row {
                                            spacing: 4
                                            Repeater {
                                                model: [1, 2, 3, 5, 8, 10]
                                                Rectangle {
                                                    width: ScreenTools.defaultFontPixelWidth * 4.2; height: ScreenTools.defaultFontPixelHeight * 1.6; radius: 4
                                                    color:        _3dCard.myDist === modelData ? "#2A0A0A" : "#04040C"
                                                    border.color: _3dCard.myDist === modelData ? "#AA1111" : "#1A0808"; border.width: 1
                                                    Text { anchors.centerIn: parent; text: modelData; color: _3dCard.myDist === modelData ? "#FF5533" : "#553333"; font.bold: _3dCard.myDist === modelData; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78 }
                                                    MouseArea { anchors.fill: parent; onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepDist", modelData); missionPlanner3D._3dCalcSummary() } }
                                                }
                                            }
                                        }

                                        // Hover time (per-step, 0 = no hover)
                                        Text { text: "HOVER (s)  — per step, 0 = none"; color: "#AA3333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62; font.bold: true }
                                        Row {
                                            spacing: 4
                                            Repeater {
                                                model: [0, 1, 2, 3, 5, 8]
                                                Rectangle {
                                                    width: ScreenTools.defaultFontPixelWidth * 4.2; height: ScreenTools.defaultFontPixelHeight * 1.6; radius: 4
                                                    color:        _3dCard.myHover === modelData ? "#2A0A0A" : "#04040C"
                                                    border.color: _3dCard.myHover === modelData ? "#AA1111" : "#1A0808"; border.width: 1
                                                    Text { anchors.centerIn: parent; text: modelData; color: _3dCard.myHover === modelData ? "#FF5533" : "#553333"; font.bold: _3dCard.myHover === modelData; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78 }
                                                    MouseArea { anchors.fill: parent; onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepHover", modelData); missionPlanner3D._3dCalcSummary() } }
                                                }
                                            }
                                        }

                                        // Speed
                                        Text { text: "SPEED (m/s)"; color: "#AA3333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62; font.bold: true }
                                        Row {
                                            spacing: 4
                                            Repeater {
                                                model: [0.3, 0.5, 0.8, 1.0, 1.5]
                                                Rectangle {
                                                    width: ScreenTools.defaultFontPixelWidth * 5.2; height: ScreenTools.defaultFontPixelHeight * 1.6; radius: 4
                                                    color:        _3dCard.mySpeed === modelData ? "#2A0A0A" : "#04040C"
                                                    border.color: _3dCard.mySpeed === modelData ? "#AA1111" : "#1A0808"; border.width: 1
                                                    Text { anchors.centerIn: parent; text: modelData; color: _3dCard.mySpeed === modelData ? "#FF5533" : "#553333"; font.bold: _3dCard.mySpeed === modelData; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.78 }
                                                    MouseArea { anchors.fill: parent; onClicked: { _3dModel.setProperty(_3dCard.myIdx, "stepSpeed", modelData); missionPlanner3D._3dCalcSummary() } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Add / Presets label ───────────────────────────
                Item {
                    width: parent.width; height: 14
                    Text {
                        id: _3dAddLbl
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: "ADD / PRESETS"; color: "#661111"
                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62; font.bold: true
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: _3dAddLbl.left
                        anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        height: 1; color: "#330A0A"
                    }
                }

                // ── Add step button ───────────────────────────────
                Rectangle {
                    width: parent.width; height: ScreenTools.defaultFontPixelHeight * 2.2
                    radius: 5; color: "#1A0000"; border.color: "#AA1111"; border.width: 1
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "＋"; color: "#FF3333"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.95 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Add Step"; color: "#CC2222"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.82 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dAdd() }
                }

                // ── Preset chips (2 rows) ─────────────────────────
                Flow {
                    width: parent.width; spacing: 4
                    Repeater {
                        model: ["StairClimb","Pyramid","AltPatrol","VertScan","Square","Triangle","ZigZag","MultiLevel"]
                        Rectangle {
                            width:  ScreenTools.defaultFontPixelWidth * 10
                            height: ScreenTools.defaultFontPixelHeight * 1.9
                            radius: 5; color: "#0A0505"; border.color: "#441111"; border.width: 1
                            Text { anchors.centerIn: parent; text: modelData; color: "#AA5533"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.68 }
                            MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dPreset(modelData) }
                        }
                    }
                }

                // ── NoGPS Control Panel ───────────────────────────
                Rectangle {
                    width: parent.width
                    height: _3dNoGPSCol.implicitHeight + 14
                    radius: 6; color: "#06060D"; border.width: 1
                    border.color: missionPlanner3D._3dNoGPS ? "#003355" : "#1A0808"

                    Column {
                        id: _3dNoGPSCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: 7
                        spacing:         6

                        // ── NoGPS mode toggle ─────────────────────
                        Row {
                            width: parent.width; spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "NoGPS Mode"; color: "#BB6666"
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74; font.bold: true
                            }
                            Row {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Rectangle {
                                    width: ScreenTools.defaultFontPixelWidth * 8; height: ScreenTools.defaultFontPixelHeight * 1.7; radius: 4
                                    color:        !missionPlanner3D._3dNoGPS ? "#2A0A0A" : "#05050C"
                                    border.color: !missionPlanner3D._3dNoGPS ? "#AA1111" : "#1A0808"
                                    border.width: !missionPlanner3D._3dNoGPS ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "GPS"; color: !missionPlanner3D._3dNoGPS ? "#FF5533" : "#553333"; font.bold: !missionPlanner3D._3dNoGPS; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74 }
                                    MouseArea { anchors.fill: parent; onClicked: { missionPlanner3D._3dNoGPS = false; missionPlanner3D._3dInvert = false } }
                                }
                                Rectangle {
                                    width: ScreenTools.defaultFontPixelWidth * 8; height: ScreenTools.defaultFontPixelHeight * 1.7; radius: 4
                                    color:        missionPlanner3D._3dNoGPS ? "#001A30" : "#05050C"
                                    border.color: missionPlanner3D._3dNoGPS ? "#0055AA" : "#1A0808"
                                    border.width: missionPlanner3D._3dNoGPS ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "NoGPS"; color: missionPlanner3D._3dNoGPS ? "#3399FF" : "#335566"; font.bold: missionPlanner3D._3dNoGPS; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.74 }
                                    MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dNoGPS = true }
                                }
                            }
                        }

                        // ── Heading reference (only relevant in NoGPS) ─
                        Column {
                            visible: missionPlanner3D._3dNoGPS
                            width: parent.width; spacing: 4

                            Rectangle { width: parent.width; height: 1; color: "#0A1A2A" }

                            Text {
                                text: "DRONE HEADING  (drone nose direction)"
                                color: "#336688"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60; font.bold: true
                            }
                            Text {
                                text: "\"N\" steps will move in this direction"
                                color: "#224455"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.58
                            }

                            Flow {
                                width: parent.width; spacing: 4
                                Repeater {
                                    model: [
                                        { lbl:"↑ N",   val:0   },
                                        { lbl:"↗ NE",  val:45  },
                                        { lbl:"→ E",   val:90  },
                                        { lbl:"↘ SE",  val:135 },
                                        { lbl:"↓ S",   val:180 },
                                        { lbl:"↙ SW",  val:225 },
                                        { lbl:"← W",   val:270 },
                                        { lbl:"↖ NW",  val:315 }
                                    ]
                                    Rectangle {
                                        property bool sel: missionPlanner3D._3dHeading === modelData.val
                                        width:  ScreenTools.defaultFontPixelWidth * 7
                                        height: ScreenTools.defaultFontPixelHeight * 1.7
                                        radius: 4
                                        color:        sel ? "#001A30" : "#04040C"
                                        border.color: sel ? "#0055AA" : "#0A1A1A"; border.width: sel ? 2 : 1
                                        Text { anchors.centerIn: parent; text: modelData.lbl; color: sel ? "#3399FF" : "#336655"; font.bold: sel; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.72 }
                                        MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dHeading = modelData.val }
                                    }
                                }
                            }

                            // ── Axis invert (sub-option of NoGPS) ────────
                            Row {
                                width: parent.width; spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Axis flip"; color: "#776655"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.68 }
                                Rectangle {
                                    width: ScreenTools.defaultFontPixelWidth * 7; height: ScreenTools.defaultFontPixelHeight * 1.6; radius: 4
                                    color:        !missionPlanner3D._3dInvert ? "#2A0A0A" : "#05050C"
                                    border.color: !missionPlanner3D._3dInvert ? "#AA1111" : "#1A0808"; border.width: !missionPlanner3D._3dInvert ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Normal"; color: !missionPlanner3D._3dInvert ? "#FF5533" : "#553333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70 }
                                    MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dInvert = false }
                                }
                                Rectangle {
                                    width: ScreenTools.defaultFontPixelWidth * 7; height: ScreenTools.defaultFontPixelHeight * 1.6; radius: 4
                                    color:        missionPlanner3D._3dInvert ? "#2A0A0A" : "#05050C"
                                    border.color: missionPlanner3D._3dInvert ? "#AA1111" : "#1A0808"; border.width: missionPlanner3D._3dInvert ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Inverted"; color: missionPlanner3D._3dInvert ? "#FF5533" : "#553333"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70 }
                                    MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dInvert = true }
                                }
                            }
                        }
                    }
                }

                // ── Controls label ────────────────────────────────
                Item {
                    width: parent.width; height: 14
                    Text {
                        id: _3dCtrlLbl
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: "CONTROLS"; color: "#551111"
                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60; font.bold: true
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: _3dCtrlLbl.left
                        anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        height: 1; color: "#220A0A"
                    }
                }

                // ── Start / Abort + Clear ─────────────────────────
                Row {
                    width: parent.width; spacing: 6

                    Rectangle {
                        width:  Math.round((parent.width - 6) * 0.62)
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        radius: 6
                        // v22: disabled while Lua takeover is active
                        property bool _takeover: missionPlanner3D._3dLuaTakeoverActive
                        color:        _takeover ? "#0A0A0A" : missionPlanner3D._3dRunning ? "#1A0000" : "#001200"
                        border.color: _takeover ? "#333333" : missionPlanner3D._3dRunning ? "#AA2222" : "#004422"
                        border.width: 2
                        opacity:      _takeover ? 0.45 : 1.0
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:  missionPlanner3D._3dRunning ? "■" : "▶"
                                color: missionPlanner3D._3dLuaTakeoverActive ? "#555555"
                                     : missionPlanner3D._3dRunning ? "#FF4444" : "#00BB44"
                                font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.9
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:  missionPlanner3D._3dRunning ? "ABORT" : "START 3D"
                                color: missionPlanner3D._3dLuaTakeoverActive ? "#555555"
                                     : missionPlanner3D._3dRunning ? "#FF3333" : "#008833"
                                font.bold: true; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.82
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            // v22: START is inert while Lua takeover is active
                            enabled: !missionPlanner3D._3dLuaTakeoverActive
                            onClicked: {
                                if (missionPlanner3D._3dRunning) missionPlanner3D._3dAbort()
                                else missionPlanner3D._3dStart()
                            }
                        }
                    }

                    Rectangle {
                        width:  Math.round((parent.width - 6) * 0.38)
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        radius: 6; color: "#130000"; border.color: "#330000"; border.width: 1
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: "#771111"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.9 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Clear"; color: "#551111"; font.pixelSize: ScreenTools.defaultFontPixelSize * 0.82 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: missionPlanner3D._3dClear() }
                    }
                }

                // ── ARM LUA button ───────────────────────────────────────
                Rectangle {
                    width:  parent.width
                    height: ScreenTools.defaultFontPixelHeight * 2.8
                    radius: 6
                    // Dim button while a send is in progress so user knows it was registered
                    property bool isBusy: missionPlanner3D._3dLuaPendingCount > 0
                    color:        isBusy ? "#001228" : "#000A18"
                    border.color: isBusy ? "#0099FF" : "#005599"
                    border.width: 2
                    opacity:      isBusy ? 0.65 : 1.0
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26; height: 22; radius: 5
                            color: "#001830"; border.color: "#0077CC"; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "Lua"
                                color: "#33AAFF"
                                font.bold: true
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.62
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text:  "ARM LUA  (no-WiFi fly)"
                                color: "#22AAFF"
                                font.bold: true
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.82
                            }
                            Text {
                                text:  "Sends MSNCFG + MSNS1-S20 + MSNCOUNT  then flip RC6 HIGH"
                                color: "#115577"
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.60
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: missionPlanner3D._3dArmLua()
                    }
                }

                // ── ARM LUA status line ───────────────────────────────────
                Rectangle {
                    visible: missionPlanner3D._3dLuaStatus !== ""
                    width:   parent.width
                    height:  ScreenTools.defaultFontPixelHeight * 1.9
                    radius:  4
                    // Green = OK, Blue = loading/sending, Amber = error
                    property bool isOK:      missionPlanner3D._3dLuaStatus.indexOf("OK") === 0
                    property bool isLoading: missionPlanner3D._3dLuaStatus.indexOf("⏳") === 0
                    color:        isOK ? "#001A08" : isLoading ? "#001018" : "#0A0800"
                    border.color: isOK ? "#006622" : isLoading ? "#004477" : "#443300"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text:  missionPlanner3D._3dLuaStatus
                        color: parent.isOK ? "#33CC66" : parent.isLoading ? "#33AAFF" : "#BBAA33"
                        font.bold: true
                        font.pixelSize: ScreenTools.defaultFontPixelSize * 0.70
                        elide: Text.ElideRight
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                    }
                }


                // ── v22: Lua Takeover Banner ─────────────────────────────────
                Rectangle {
                    visible: missionPlanner3D._3dLuaTakeoverActive
                    width:   parent.width
                    height:  ScreenTools.defaultFontPixelHeight * 2.2
                    radius:  4
                    color:        "#120600"
                    border.color: "#FF8800"
                    border.width: 2
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⚡"
                            color: "#FF8800"
                            font.pixelSize: ScreenTools.defaultFontPixelSize * 0.85
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Lua takeover active — waiting for mission complete"
                            color: "#FF8800"
                            font.bold: true
                            font.pixelSize: ScreenTools.defaultFontPixelSize * 0.72
                        }
                    }
                }

                Item { width: 1; height: 4 }
                } // Column _3dPanelCol
            } // Flickable _3dPanelFlick
        }
    }
    // ─────────────────────────────────────────────────────────────


}