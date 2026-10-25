#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QString>
#include <QtQml/qqmlregistration.h>

// For --capture: saves what a window shows, popups and sheets included, which
// Item.grabToImage() can't
class WindowCapture : public QObject
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit WindowCapture(QObject* parent = nullptr);

  // Saves `window` as a PNG file at `path`; false if it couldn't
  Q_INVOKABLE bool save(QQuickWindow* window, const QString& path) const;
};
