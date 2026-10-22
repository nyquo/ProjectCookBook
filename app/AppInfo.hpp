#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

// Read-only facts about the running app, for QML as the AppInfo singleton
class AppInfo : public QObject
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QString name READ name CONSTANT)
  Q_PROPERTY(QString version READ version CONSTANT)
  Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
  Q_PROPERTY(QString platform READ platform CONSTANT)
  Q_PROPERTY(QString cpuArchitecture READ cpuArchitecture CONSTANT)

public:
  explicit AppInfo(QObject* parent = nullptr);

  QString name() const;
  QString version() const;
  QString qtVersion() const;
  QString platform() const;
  QString cpuArchitecture() const;
};
