/******************************************************************************
 **  Copyright (c) Raoul Hecky. All Rights Reserved.
 **
 **  Calaos is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 3 of the License, or
 **  (at your option) any later version.
 **
 **  Calaos is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with Foobar; if not, write to the Free Software
 **  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 **
 ******************************************************************************/
#ifndef USBMONITOR_LINUX_H
#define USBMONITOR_LINUX_H

#include <QtCore>
#include <libusb.h>
#include <QThread>
#include <QMap>

#include "MPDevice_linux.h"

class UsbMonitor_linux: public QObject
{
    Q_OBJECT
public:
    static UsbMonitor_linux *Instance()
    {
        static UsbMonitor_linux inst;
        return &inst;
    }
    ~UsbMonitor_linux();

    libusb_context *getUsbContext() { return usb_ctx; }
public slots:
    void start();
    void stop();

    void handleEvents();
    void createSocketMonitor(int fd);
    void releaseSocketMonitor(int fd);
signals:
    void usbDeviceAdded();
    void usbDeviceRemoved();

private:
    void attachCallbacks();
    void relaseCallbacks();
    UsbMonitor_linux();

    libusb_context *usb_ctx = nullptr;
    libusb_hotplug_callback_handle cbaddhandle;
    libusb_hotplug_callback_handle cbdelhandle;

    QMap<intptr_t, QSocketNotifier*> m_fdMonitors;

    friend void libusb_fd_add_cb(int fd, short events, void *user_data);
    friend void libusb_fd_del_cb(int fd, void *user_data);
    friend int libusb_device_add_cb(libusb_context *ctx, libusb_device *dev, libusb_hotplug_event event, void *user_data);
    friend int libusb_device_del_cb(libusb_context *ctx, libusb_device *dev, libusb_hotplug_event event, void *user_data);
};

Q_DECLARE_METATYPE(struct libusb_transfer *)

#endif // USBMONITOR_LINUX_H
