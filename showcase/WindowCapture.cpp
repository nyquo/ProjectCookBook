#include "WindowCapture.hpp"

#include <QImage>

WindowCapture::WindowCapture(QObject* parent)
  : QObject(parent)
{
}

bool WindowCapture::save(QQuickWindow* window, const QString& path) const
{
  if (!window) {
    return false;
  }
  return window->grabWindow().save(path, "PNG");
}
