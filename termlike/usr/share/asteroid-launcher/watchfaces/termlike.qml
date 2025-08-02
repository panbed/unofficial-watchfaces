/*
 * Copyright (C) 2018 - Timo Könnecke <el-t-mo@arcor.de>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
 *               2012 - Vasiliy Sorokin <sorokin.vasiliy@gmail.com>
 *                      Aleksey Mikhailichenko <a.v.mich@gmail.com>
 *                      Arto Jalkanen <ajalkane@gmail.com>
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtGraphicalEffects 1.12
import QtSensors 5.11
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Configuration 1.0
import Nemo.Mce 1.0

Item {
    property string fontName: "Terminus (TTF)"

    // Foreground colors
    property string fgMain: "#ffffff"
    property string fgAlt: "#a0a0a0"

    // Color scheme
    property string fg1: "#ffa7da"
    property string fg2: "#b58858"
    property string fg3: "#efbd8b"
    property string fg4: "#a3d572"
    property string fg5: "#98cbfe"
    property string fg6: "#e5b0ff"

    // Text shadow
    layer.enabled: true
    layer.effect: DropShadow {
        verticalOffset: 3
        horizontalOffset: 2
        color: Qt.rgba(0, 0, 0, .95)
        radius: 2
        samples: 2
    }

    // Font object, will be reused
    QtObject {
        id: theme
        property font wfFont: Qt.font({
            family: fontName,
            italic: false,
            pixelSize: Math.round(parent.height * 0.07),
        })
    }

    // "Main" area in which the "terminal" will reside in
    Rectangle {
        z: 1
        id: termArea
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color: Qt.rgba(0, 0, 0, 0.0)
        width: parent.width * 0.65
        height: parent.height * 0.5
    }

    // Prompt (e.g. like "user@hostname")
    Text {
        z: 2
        id: promptText
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgMain

        property string username: "usr"
        property string hostname: "astr"

        property string usernameString: `<strong><font color="${fg5}">${username}</font></strong>`
        property string hostnameString: `<strong><font color="${fg4}">${hostname}</font></strong>`
        property string promptString: `[${usernameString}@${hostnameString} ~]$ now`

        text: promptString
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
        }
    }

    // Time
    Text {
        z: 3
        id: timeText
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgAlt

        property string timeFormat: if (use12H.value) {
                                        wallClock.time.toLocaleString(Qt.locale(), "hh ap").slice(0, 2) + wallClock.time.toLocaleString(Qt.locale(), `:mm${!displayAmbient ? ":ss" : ""} AP`)
                                    }
                                    else {
                                        wallClock.time.toLocaleString(Qt.locale(), "HH") + wallClock.time.toLocaleString(Qt.locale(), `:mm${!displayAmbient ? ":ss" : ""}`)
                                    }
        property string timeString: `<font color="${fg3}">${timeFormat}</font>`

        text: `[TIME] <strong>${timeString}</strong>`
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
            topMargin: promptText.height
        }
    }

    // Date
    Text {
        z: 4
        id: dateText
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgAlt

        property string dateFormat: Qt.formatDate(wallClock.time, "ddd d MMM").toUpperCase()
        property string dateString: `<font color="${fg2}">${dateFormat}</font>`

        text: `[DATE] <strong>${dateString}</strong>`
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
            topMargin: promptText.height + timeText.height
        }
    }

    // Battery
    Text {
        z: 5
        id: battText
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgAlt

        // Create battery bar, e.g.: [##....] 27%
        property int battBarLength: 6
        function createBattBar(battBarNum) {
            var battBar = ""
            for (var i = 0; i < battBarLength; i++) {
                if (i < battBarNum) {
                    battBar += "#"
                }
                else {
                    battBar += "."
                }
            }

            return battBar
        }

        property int battPercent: batteryChargePercentage.percent
        property int battBarNum: Math.round(battPercent * (battBarLength/100))
        property string battFormat: createBattBar(battBarNum)
        property string battString: `[<font color="${fg4}">${battFormat}</font>] <font color="${fg4}">${battPercent}%</font>`

        text: `[BATT] <strong>${battString}</strong>`
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
            topMargin: promptText.height + timeText.height + dateText.height
        }
    }

    // Weather(?)
    Text {
        z: 5
        id: weatherText
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgAlt

        ConfigurationValue {
            id: timestampDay0
            key: "/org/asteroidos/weather/timestamp-day0"
            defaultValue: 0
        }

        ConfigurationValue {
            id: useFahrenheit
            key: "/org/asteroidos/settings/use-fahrenheit"
            defaultValue: false
        }

        ConfigurationValue {
            id: owmId
            key: "/org/asteroidos/weather/day0/id"
            defaultValue: 0
        }

        ConfigurationValue {
            id: maxTemp
            key: "/org/asteroidos/weather/day0/max-temp"
            defaultValue: 0
        }

        ConfigurationValue {
            id: minTemp
            key: "/org/asteroidos/weather/day0/min-temp"
            defaultValue: 0
        }

        visible: (displayAmbient || maxTemp.value == 0) ? false : true

        function kelvinToTemperatureString(kelvin) {
            var celsius = (kelvin - 273);
            if (!useFahrenheit.value)
                return celsius + "°C";
            else
                return Math.round(((celsius)*9/5) + 32) + "°F";
        }

        property bool weatherSynced: maxTemp.value != 0

        property string wthrFormat: `${kelvinToTemperatureString(minTemp.value)} <font color="${fgAlt}">/</font> ${kelvinToTemperatureString(maxTemp.value)}`
        property string wthrString: `<font color="${fg5}">${wthrFormat}</font>`

        text: `[WTHR] <strong>${wthrString}</strong>`
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
            topMargin: promptText.height + timeText.height + dateText.height + battText.height
        }
    }

    // Prompt (copy)
    Text {
        z: 2
        id: prompt2Text
        renderType: Text.NativeRendering
        font: theme.wfFont
        color: fgMain
        visible: !displayAmbient

        property string username: "usr"
        property string hostname: "astr"

        property string usernameString: `<strong><font color="${fg5}">${username}</font></strong>`
        property string hostnameString: `<strong><font color="${fg4}">${hostname}</font></strong>`
        property string promptString: `[${usernameString}@${hostnameString} ~]$ |`

        text: promptString
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignLeft
        anchors {
            top: termArea.top
            left: termArea.left
            topMargin: promptText.height + timeText.height + dateText.height + battText.height + weatherText.height
        }
    }
}
