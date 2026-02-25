import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    property int layoutRevision: 0
    property var draftBarLayout: ({})

    readonly property var barWidgetDefinitions: [
        { key: "leftSidebarButton", icon: "left_panel_open", name: Translation.tr("Left sidebar button") },
        { key: "activeWindow", icon: "web_asset", name: Translation.tr("Active window") },
        { key: "resources", icon: "monitoring", name: Translation.tr("Resources") },
        { key: "media", icon: "music_note", name: Translation.tr("Media") },
        { key: "workspaces", icon: "workspaces", name: Translation.tr("Workspaces") },
        { key: "clock", icon: "schedule", name: Translation.tr("Clock") },
        { key: "utilButtons", icon: "widgets", name: Translation.tr("Utility buttons") },
        { key: "battery", icon: "battery_android_full", name: Translation.tr("Battery") },
        { key: "rightSidebarButton", icon: "right_panel_open", name: Translation.tr("Right sidebar button") },
        { key: "sysTray", icon: "shelf_auto_hide", name: Translation.tr("System tray") },
        { key: "weather", icon: "cloud", name: Translation.tr("Weather") }
    ]

    readonly property var sectionDefinitions: [
        { key: "left", title: Translation.tr("Left") },
        { key: "centerLeft", title: Translation.tr("Center Left") },
        { key: "center", title: Translation.tr("Center") },
        { key: "centerRight", title: Translation.tr("Center Right") },
        { key: "right", title: Translation.tr("Right") }
    ]

    readonly property var defaultBarLayout: ({
            left: ["leftSidebarButton", "activeWindow"],
            centerLeft: ["resources", "media"],
            center: ["workspaces"],
            centerRight: ["clock", "utilButtons", "battery"],
            right: ["rightSidebarButton", "sysTray", "weather"]
        })

    function widgetName(key) {
        for (let i = 0; i < barWidgetDefinitions.length; ++i) {
            if (barWidgetDefinitions[i].key === key)
                return barWidgetDefinitions[i].name;
        }
        return key;
    }

    function widgetIcon(key) {
        for (let i = 0; i < barWidgetDefinitions.length; ++i) {
            if (barWidgetDefinitions[i].key === key)
                return barWidgetDefinitions[i].icon;
        }
        return "widgets";
    }

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

    function listIncludes(values, target) {
        for (let i = 0; i < values.length; ++i) {
            if (values[i] === target)
                return true;
        }
        return false;
    }

    function getLayoutSection(sectionKey) {
        const configured = Config?.options?.bar?.layout?.[sectionKey];
        if (configured !== null && configured !== undefined) {
            const configuredList = listToArray(configured);
            if (configuredList.length > 0 || (typeof configured.length === "number" && configured.length === 0))
                return configuredList;
        }
        const fallback = defaultBarLayout[sectionKey] ?? [];
        return listToArray(fallback);
    }

    function currentLayoutSnapshot() {
        return {
            left: getLayoutSection("left"),
            centerLeft: getLayoutSection("centerLeft"),
            center: getLayoutSection("center"),
            centerRight: getLayoutSection("centerRight"),
            right: getLayoutSection("right")
        };
    }

    function initializeDraftLayout() {
        draftBarLayout = currentLayoutSnapshot();
        layoutRevision += 1;
    }

    function resetDraftToDefaults() {
        draftBarLayout = {
            left: listToArray(defaultBarLayout.left),
            centerLeft: listToArray(defaultBarLayout.centerLeft),
            center: listToArray(defaultBarLayout.center),
            centerRight: listToArray(defaultBarLayout.centerRight),
            right: listToArray(defaultBarLayout.right)
        };
        layoutRevision += 1;
    }

    function getDraftSection(sectionKey) {
        layoutRevision;
        const section = draftBarLayout?.[sectionKey];
        return Array.isArray(section) ? section.slice() : [];
    }

    function setDraftSection(sectionKey, values) {
        const nextLayout = currentLayoutSnapshot();
        const existingLayout = draftBarLayout;
        for (let i = 0; i < sectionDefinitions.length; ++i) {
            const key = sectionDefinitions[i].key;
            const existingSection = existingLayout?.[key];
            if (Array.isArray(existingSection)) {
                nextLayout[key] = existingSection.slice();
            }
        }
        nextLayout[sectionKey] = Array.isArray(values) ? values.slice() : [];
        draftBarLayout = nextLayout;
        layoutRevision += 1;
    }

    function allAssignedWidgets() {
        const assigned = [];
        for (let i = 0; i < sectionDefinitions.length; ++i) {
            const sectionValues = getDraftSection(sectionDefinitions[i].key);
            for (let j = 0; j < sectionValues.length; ++j) {
                assigned.push(sectionValues[j]);
            }
        }
        return assigned;
    }

    function availableWidgets(sectionKey) {
        const current = getDraftSection(sectionKey);
        const assigned = allAssignedWidgets();
        const result = [];
        for (let i = 0; i < barWidgetDefinitions.length; ++i) {
            const item = barWidgetDefinitions[i];
            if (listIncludes(current, item.key) || !listIncludes(assigned, item.key)) {
                result.push(item);
            }
        }
        return result;
    }

    function addWidgetToSection(sectionKey, widgetKey) {
        const assigned = allAssignedWidgets();
        if (listIncludes(assigned, widgetKey)) {
            return;
        }
        const section = getDraftSection(sectionKey);
        section.push(widgetKey);
        setDraftSection(sectionKey, section);
    }

    function removeWidgetFromSection(sectionKey, widgetKey) {
        const section = getDraftSection(sectionKey).filter(key => key !== widgetKey);
        setDraftSection(sectionKey, section);
    }

    function moveWidget(sectionKey, fromIndex, toIndex) {
        const section = getDraftSection(sectionKey);
        if (fromIndex < 0 || toIndex < 0 || fromIndex >= section.length || toIndex >= section.length || fromIndex === toIndex) {
            return;
        }
        const [moved] = section.splice(fromIndex, 1);
        section.splice(toIndex, 0, moved);
        setDraftSection(sectionKey, section);
    }

    function indexInSection(sectionKey, widgetKey) {
        const section = getDraftSection(sectionKey);
        for (let i = 0; i < section.length; ++i) {
            if (section[i] === widgetKey)
                return i;
        }
        return -1;
    }

    function moveWidgetByKey(sectionKey, widgetKey, delta) {
        const currentIndex = indexInSection(sectionKey, widgetKey);
        if (currentIndex < 0)
            return;
        const nextIndex = currentIndex + delta;
        moveWidget(sectionKey, currentIndex, nextIndex);
    }

    function applyDraftLayout() {
        const left = getDraftSection("left");
        const centerLeft = getDraftSection("centerLeft");
        const center = getDraftSection("center");
        const centerRight = getDraftSection("centerRight");
        const right = getDraftSection("right");

        Config.options.bar.layout.left = left;
        Config.options.bar.layout.centerLeft = centerLeft;
        Config.options.bar.layout.center = center;
        Config.options.bar.layout.centerRight = centerRight;
        Config.options.bar.layout.right = right;

        Config.setNestedValue("bar.layout.left", left);
        Config.setNestedValue("bar.layout.centerLeft", centerLeft);
        Config.setNestedValue("bar.layout.center", center);
        Config.setNestedValue("bar.layout.centerRight", centerRight);
        Config.setNestedValue("bar.layout.right", right);

        initializeDraftLayout();
    }

    function hasDraftChanges() {
        const current = currentLayoutSnapshot();
        const draft = {
            left: getDraftSection("left"),
            centerLeft: getDraftSection("centerLeft"),
            center: getDraftSection("center"),
            centerRight: getDraftSection("centerRight"),
            right: getDraftSection("right")
        };
        return JSON.stringify(current) !== JSON.stringify(draft);
    }

    function sectionModel(sectionKey) {
        return getDraftSection(sectionKey);
    }

    function sectionAvailableModel(sectionKey) {
        const current = getDraftSection(sectionKey);
        const available = availableWidgets(sectionKey);
        const result = [];
        for (let i = 0; i < available.length; ++i) {
            if (!listIncludes(current, available[i].key)) {
                result.push(available[i]);
            }
        }
        return result;
    }

    Component.onCompleted: initializeDraftLayout()

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "dashboard_customize"
        title: Translation.tr("Layout")

        Repeater {
            model: sectionDefinitions

            delegate: ContentSubsection {
                required property var modelData
                readonly property string sectionId: modelData.key
                property bool addPickerOpen: false

                title: modelData.title
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Drag to reorder. Widgets are unique across all sections.")
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: sectionColumn.implicitHeight + 10
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant

                        Column {
                            id: sectionColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 5
                            }
                            spacing: 4

                            Repeater {
                                model: sectionModel(sectionId)

                                delegate: Rectangle {
                                    id: widgetItem
                                    required property string modelData
                                    readonly property string widgetKey: modelData
                                    readonly property string sectionKey: sectionId

                                    width: sectionColumn.width
                                    implicitHeight: 36
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer1
                                    border.width: 1
                                    border.color: Appearance.colors.colOutlineVariant

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 6
                                        spacing: 8

                                        MaterialSymbol {
                                            text: widgetIcon(widgetItem.widgetKey)
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: widgetName(widgetItem.widgetKey)
                                            color: Appearance.colors.colOnLayer1
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            elide: Text.ElideRight
                                        }

                                        MaterialSymbol {
                                            text: "widgets"
                                            iconSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                        }

                                        RippleButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            buttonRadius: Appearance.rounding.full
                                            enabled: indexInSection(widgetItem.sectionKey, widgetItem.widgetKey) > 0
                                            onClicked: moveWidgetByKey(widgetItem.sectionKey, widgetItem.widgetKey, -1)

                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "arrow_upward"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: Appearance.colors.colOnLayer1
                                            }
                                        }

                                        RippleButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            buttonRadius: Appearance.rounding.full
                                            enabled: {
                                                const idx = indexInSection(widgetItem.sectionKey, widgetItem.widgetKey);
                                                const len = sectionModel(sectionId).length;
                                                return idx >= 0 && idx < len - 1;
                                            }
                                            onClicked: moveWidgetByKey(widgetItem.sectionKey, widgetItem.widgetKey, 1)

                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "arrow_downward"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: Appearance.colors.colOnLayer1
                                            }
                                        }

                                        RippleButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            buttonRadius: Appearance.rounding.full
                                            colBackground: ColorUtils.transparentize(Appearance.colors.colErrorContainer, 1)
                                            colBackgroundHover: Appearance.colors.colErrorContainerHover
                                            colRipple: Appearance.colors.colErrorContainerActive
                                            onClicked: removeWidgetFromSection(widgetItem.sectionKey, widgetItem.widgetKey)

                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "close"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: Appearance.m3colors.m3onErrorContainer
                                            }
                                        }
                                    }
                                }
                            }

                            StyledText {
                                visible: sectionModel(sectionId).length === 0
                                width: sectionColumn.width
                                text: Translation.tr("No widgets in this section")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        RippleButtonWithIcon {
                            materialIcon: "add"
                            mainText: Translation.tr("Add widget")
                            onClicked: addPickerOpen = !addPickerOpen
                        }

                        StyledComboBox {
                            id: addWidgetCombo
                            visible: addPickerOpen
                            implicitWidth: 260
                            model: sectionAvailableModel(sectionId)
                            textRole: "name"
                            buttonIcon: currentIndex >= 0 && currentIndex < model.length ? model[currentIndex].icon : "widgets"
                            currentIndex: model.length > 0 ? 0 : -1
                        }

                        RippleButtonWithIcon {
                            visible: addPickerOpen
                            materialIcon: "check"
                            mainText: Translation.tr("Add")
                            enabled: addWidgetCombo.currentIndex >= 0 && addWidgetCombo.currentIndex < addWidgetCombo.model.length
                            onClicked: {
                                const picked = addWidgetCombo.model[addWidgetCombo.currentIndex];
                                if (!picked)
                                    return;
                                addWidgetToSection(sectionId, picked.key);
                                addPickerOpen = false;
                            }
                        }
                    }
                }
            }
        }

        ConfigRow {
            Layout.topMargin: 6
            uniform: true

            RippleButtonWithIcon {
                materialIcon: "restore"
                mainText: Translation.tr("Reset to defaults")
                onClicked: resetDraftToDefaults()
            }

            RippleButtonWithIcon {
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset draft")
                onClicked: initializeDraftLayout()
            }

            RippleButtonWithIcon {
                materialIcon: "done_all"
                mainText: Translation.tr("Apply")
                enabled: hasDraftChanges()
                onClicked: applyDraftLayout()
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
