import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth
    readonly property var knownWidgetKeys: [
        "leftSidebarButton",
        "activeWindow",
        "resources",
        "media",
        "workspaces",
        "clock",
        "utilButtons",
        "battery",
        "rightSidebarButton",
        "sysTray",
        "weather"
    ]
    readonly property var defaultLayout: ({
            left: ["leftSidebarButton", "activeWindow"],
            centerLeft: ["resources", "media"],
            center: ["workspaces"],
            centerRight: ["clock", "utilButtons", "battery"],
            right: ["rightSidebarButton", "sysTray", "weather"]
        })

    function listToArray(value) {
        const result = [];
        if (Array.isArray(value)) {
            for (let i = 0; i < value.length; ++i)
                result.push(value[i]);
            return result;
        }
        if (value !== null && value !== undefined && typeof value.length === "number") {
            for (let i = 0; i < value.length; ++i)
                result.push(value[i]);
        }
        return result;
    }

    function sectionKeys(sectionName) {
        const configured = Config?.options?.bar?.layout?.[sectionName];
        const source = (configured !== null && configured !== undefined) ? listToArray(configured) : listToArray(defaultLayout[sectionName] ?? []);
        const seen = new Set();
        return source.filter(key => {
            if (!knownWidgetKeys.includes(key) || seen.has(key) || !isWidgetEnabled(key)) {
                return false;
            }
            seen.add(key);
            return true;
        });
    }

    function sectionContains(sectionName, key) {
        return sectionKeys(sectionName).includes(key);
    }

    function loaderFillWidth(key) {
        return key === "activeWindow"
            || key === "media"
            || key === "clock"
            || (key === "resources" && root.useShortenedForm === 2);
    }

    function loaderFillHeight(key) {
        return key === "workspaces" || key === "sysTray";
    }

    function loaderAlignment(key) {
        if (key === "leftSidebarButton")
            return Qt.AlignVCenter;
        if (key === "rightSidebarButton")
            return Qt.AlignRight | Qt.AlignVCenter;
        return Qt.AlignVCenter;
    }

    function loaderLeftMargin(sectionName, key) {
        if (key === "leftSidebarButton")
            return Appearance.rounding.screenRounding;
        if (key === "activeWindow")
            return sectionContains(sectionName, "leftSidebarButton") ? 10 : (10 + Appearance.rounding.screenRounding);
        if (key === "weather")
            return 4;
        return 0;
    }

    function loaderRightMargin(key) {
        if (key === "activeWindow")
            return Appearance.rounding.screenRounding;
        if (key === "rightSidebarButton")
            return Appearance.rounding.screenRounding;
        return 0;
    }

    function isWidgetEnabled(key) {
        switch (key) {
        case "leftSidebarButton":
        case "rightSidebarButton":
        case "resources":
        case "workspaces":
        case "clock":
            return true;
        case "activeWindow":
            return root.useShortenedForm === 0;
        case "media":
            return root.useShortenedForm < 2;
        case "utilButtons":
            return Config.options.bar.verbose && root.useShortenedForm === 0;
        case "battery":
            return root.useShortenedForm < 2 && Battery.available;
        case "sysTray":
            return root.useShortenedForm === 0;
        case "weather":
            return Config.options.bar.weather.enable;
        default:
            return false;
        }
    }

    component LeftSidebarButtonModule: LeftSidebarButton {
        colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    }

    component ActiveWindowModule: ActiveWindow {
    }

    component ResourcesModule: Resources {
        alwaysShowAllResources: root.useShortenedForm === 2
    }

    component MediaModule: Media {
    }

    component WorkspacesModule: Workspaces {
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onPressed: event => {
                if (event.button === Qt.RightButton) {
                    GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                }
            }
        }
    }

    component ClockModule: ClockWidget {
        showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
    }

    component UtilButtonsModule: UtilButtons {
    }

    component BatteryModule: BatteryIndicator {
    }

    component RightSidebarButtonModule: RippleButton {
        id: rightSidebarButton

        implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
        implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

        buttonRadius: Appearance.rounding.full
        colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive
        toggled: GlobalStates.sidebarRightOpen
        property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        RowLayout {
            id: indicatorsRowLayout
            anchors.centerIn: parent
            property real realSpacing: 15
            spacing: 0

            Revealer {
                reveal: Audio.sink?.audio?.muted ?? false
                Layout.fillHeight: true
                Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                Behavior on Layout.rightMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                MaterialSymbol {
                    text: "volume_off"
                    iconSize: Appearance.font.pixelSize.larger
                    color: rightSidebarButton.colText
                }
            }
            Revealer {
                reveal: Audio.source?.audio?.muted ?? false
                Layout.fillHeight: true
                Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                Behavior on Layout.rightMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                MaterialSymbol {
                    text: "mic_off"
                    iconSize: Appearance.font.pixelSize.larger
                    color: rightSidebarButton.colText
                }
            }
            HyprlandXkbIndicator {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: indicatorsRowLayout.realSpacing
                color: rightSidebarButton.colText
            }
            Revealer {
                reveal: Notifications.silent || Notifications.unread > 0
                Layout.fillHeight: true
                Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                Behavior on Layout.rightMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                NotificationUnreadCount {
                    id: notificationUnreadCount
                }
            }
            MaterialSymbol {
                text: Network.materialSymbol
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
            MaterialSymbol {
                Layout.leftMargin: indicatorsRowLayout.realSpacing
                visible: BluetoothStatus.available
                text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
        }
    }

    component SysTrayModule: SysTray {
        invertSide: Config?.options.bar.bottom
    }

    component WeatherModule: BarGroup {
        WeatherBar {}
    }

    component WidgetLoader: Loader {
        required property string key
        required property string sectionName
        Layout.alignment: loaderAlignment(key)
        Layout.fillWidth: loaderFillWidth(key)
        Layout.fillHeight: loaderFillHeight(key)
        Layout.leftMargin: loaderLeftMargin(sectionName, key)
        Layout.rightMargin: loaderRightMargin(key)
        sourceComponent: {
            switch (key) {
            case "leftSidebarButton": return leftSidebarButtonComponent;
            case "activeWindow": return activeWindowComponent;
            case "resources": return resourcesComponent;
            case "media": return mediaComponent;
            case "workspaces": return workspacesComponent;
            case "clock": return clockComponent;
            case "utilButtons": return utilButtonsComponent;
            case "battery": return batteryComponent;
            case "rightSidebarButton": return rightSidebarButtonComponent;
            case "sysTray": return sysTrayComponent;
            case "weather": return weatherComponent;
            default: return null;
            }
        }
    }

    property Component leftSidebarButtonComponent: LeftSidebarButtonModule {}
    property Component activeWindowComponent: ActiveWindowModule {}
    property Component resourcesComponent: ResourcesModule {}
    property Component mediaComponent: MediaModule {}
    property Component workspacesComponent: WorkspacesModule {}
    property Component clockComponent: ClockModule {}
    property Component utilButtonsComponent: UtilButtonsModule {}
    property Component batteryComponent: BatteryModule {}
    property Component rightSidebarButtonComponent: RightSidebarButtonModule {}
    property Component sysTrayComponent: SysTrayModule {}
    property Component weatherComponent: WeatherModule {}

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        // Visual content
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: root.sectionKeys("left")
                delegate: WidgetLoader {
                    required property string modelData
                    sectionName: "left"
                    key: modelData
                }
            }
        }
    }

    Row { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            visible: root.sectionKeys("centerLeft").length > 0
            implicitWidth: root.centerSideModuleWidth

            Repeater {
                model: root.sectionKeys("centerLeft")
                delegate: WidgetLoader {
                    required property string modelData
                    sectionName: "centerLeft"
                    key: modelData
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless && leftCenterGroup.visible && middleCenterGroup.visible
        }

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            visible: root.sectionKeys("center").length > 0

            readonly property int dynamicPadding: sectionContains("center", "workspaces") ? workspacesWidget.widgetPadding : 5
            padding: dynamicPadding

            Workspaces {
                id: workspacesWidget
                visible: false
            }

            Repeater {
                model: root.sectionKeys("center")
                delegate: WidgetLoader {
                    required property string modelData
                    sectionName: "center"
                    key: modelData
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless && middleCenterGroup.visible && rightCenterGroup.visible
        }

        MouseArea {
            id: rightCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            visible: rightCenterGroupContent.visible
            implicitWidth: root.centerSideModuleWidth
            implicitHeight: rightCenterGroupContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent
                visible: root.sectionKeys("centerRight").length > 0

                Repeater {
                    model: root.sectionKeys("centerRight")
                    delegate: WidgetLoader {
                        required property string modelData
                        sectionName: "centerRight"
                        key: modelData
                    }
                }
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        // Visual content
        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            Repeater {
                model: root.sectionKeys("right")
                delegate: WidgetLoader {
                    required property string modelData
                    sectionName: "right"
                    key: modelData
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
