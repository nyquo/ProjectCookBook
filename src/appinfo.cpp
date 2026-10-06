#include "appinfo.h"

#include <QGuiApplication>
#include <QSysInfo>

AppInfo::AppInfo(QObject *parent)
    : QObject(parent)
{
}

QString AppInfo::name() const
{
    return QGuiApplication::applicationDisplayName();
}

QString AppInfo::version() const
{
    return QGuiApplication::applicationVersion();
}

QString AppInfo::qtVersion() const
{
    return QString::fromLatin1(qVersion());
}

QString AppInfo::platform() const
{
    // simplified(): Qt leaves a double space when it doesn't know the OS codename,
    // e.g. "Android  (16.0)".
    return QSysInfo::prettyProductName().simplified();
}

QString AppInfo::cpuArchitecture() const
{
    // The architecture this binary was built for, which tells you which APK is
    // installed (the emulator can also run arm64 builds through translation).
    return QSysInfo::buildCpuArchitecture();
}
