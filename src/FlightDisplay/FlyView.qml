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
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// 3D Viewer modules
import Viewer3D

Item {
    id: _root

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }

    function dropMainStatusIndicatorTool() {
        toolbar.dropMainStatusIndicatorTool();
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id:                 mapHolder
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             customOverlay.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                        (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
            visible:                false
        }

        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            guidedValueSlider:     _guidedValueSlider
        }

        //-- Guided value slider (e.g. altitude)
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:            false
        }

        Viewer3D{
            id:                     viewer3DWindow
            anchors.fill:           parent
        }
        
        Item {
            id: rcPopupLayer
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: ScreenTools.defaultFontPixelWidth * 2
            width: ScreenTools.defaultFontPixelWidth * 26
            height: rcToastList.height
            z: 9999

            property var _lastValues: ({})

            function _channelName(i) {
                if (i === 0) return "Roll"
                if (i === 1) return "Pitch"
                if (i === 2) return "Throttle"
                if (i === 3) return "Yaw"
                return "CH" + (i + 1)
            }

            function _addToast(label, val) {
                if (rcToastModel.count > 8) return
                var text = label + "  →  " + val
                for (var i = 0; i < rcToastModel.count; i++) {
                    if (rcToastModel.get(i).lbl === label) {
                        rcToastModel.setProperty(i, "txt", text)
                        return
                    }
                }
                rcToastModel.append({ "lbl": label, "txt": text })
                if (rcToastModel.count > 6)
                    rcToastModel.remove(0)
            }

            ListModel { id: rcToastModel }

            Connections {
                target: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : null

                function onRcChannelsChanged(channelCount, pwmValues) {
                    if (!pwmValues || channelCount <= 0) return
                    for (var i = 0; i < channelCount; i++) {
                        if (i >= pwmValues.length) break
                        var val = pwmValues[i]
                        if (val === undefined || val === null) continue
                        val = parseInt(val)
                        if (isNaN(val) || val <= 0) continue
                        var prev = rcPopupLayer._lastValues[i]
                        if (prev !== undefined && Math.abs(prev - val) < 80) continue
                        rcPopupLayer._lastValues[i] = val
                        rcPopupLayer._addToast(rcPopupLayer._channelName(i), val)
                    }
                }
            }

            ListView {
                id: rcToastList
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.min(contentHeight, 400)
                spacing: 5
                model: rcToastModel
                verticalLayoutDirection: ListView.BottomToTop

                delegate: Item {
                    id: rcDelegate
                    width: rcToastList.width
                    height: rcPill.height + 4
                    opacity: 1.0

                    Behavior on opacity { NumberAnimation { duration: 380 } }

                    Timer {
                        interval: 2500
                        running: true
                        repeat: false
                        onTriggered: rcDelegate.opacity = 0
                    }

                    Timer {
                        interval: 2900
                        running: true
                        repeat: false
                        onTriggered: {
                            if (index >= 0 && index < rcToastModel.count) {
                                rcToastModel.remove(index)
                            }
                        }
                    }

                    Rectangle {
                        id: rcPill
                        width: parent.width
                        height: rcRow.implicitHeight + 14
                        radius: 7
                        color: "#D91C1C2E"
                        border.color: "#5E7BFF"
                        border.width: 1

                        RowLayout {
                            id: rcRow
                            anchors.centerIn: parent
                            spacing: 10

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#6C8CFF"
                            }

                            Text {
                                text: model.txt
                                color: "white"
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.88
                            }
                        }
                    }
                }
            }
        }
    }
}

