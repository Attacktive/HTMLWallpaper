/*
 * Copyright (C) 2020 by Marcel Richter <Richter02@protonmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2
import QtWebEngine 1.7

import org.kde.plasma.plasmoid

WallpaperItem {
    id: root
    property bool loadedOk: false
    property url targetUrl: wallpaper.configuration.DisplayPage

    WebEngineView {
        id: web
        anchors.fill: parent
        url: root.targetUrl
        zoomFactor: wallpaper.configuration.ZoomFactor
        backgroundColor: "black"

        onLoadingChanged: function(loadRequest) {
            const startRetry = () => {
                root.loadedOk = false
                if (!retryTimer.running) {
                    retryTimer.start()
                }
            }

            const stopRetry = () => {
                root.loadedOk = true
                retryTimer.stop()
            }

            switch (loadRequest.status) {
                case WebEngineView.LoadSucceededStatus: {
                    const requestedUrl = loadRequest.url.toString()
                    if (requestedUrl.includes("error://")) {
                        startRetry()
                    } else {
                        stopRetry()
                    }
                }

                break
                case WebEngineView.LoadFailedStatus:
                case WebEngineView.LoadStoppedStatus:
                    startRetry()
                break
            }
        }

        onCertificateError: function (error) {
            if (wallpaper.configuration.InsecureHTTPS) {
                error.acceptCertificate()
            } else {
                error.rejectCertificate()
            }
        }

        settings.playbackRequiresUserGesture: false
    }

    Timer {
        id: retryTimer
        interval: 5000
        repeat: true
        running: false
        onTriggered: {
            if (!root.loadedOk && !web.loading) {
                web.url = root.targetUrl
                web.reload()
            }
        }
    }
}
