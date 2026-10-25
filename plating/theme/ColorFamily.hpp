#pragma once

#include <QColor>
#include <QObject>
#include <QtQml/qqmlregistration.h>

// colorFamily: a fill and the ink drawn on it, already resolved for the current
// theme. Tags, aisles and swatches take one. QML builds it from an object
// literal: ({ fill: theme.tagMint, ink: theme.tagMintInk }).
struct ColorFamily
{
  Q_GADGET
  QML_VALUE_TYPE(colorFamily)
  QML_STRUCTURED_VALUE
  Q_PROPERTY(QColor fill MEMBER fill FINAL)
  Q_PROPERTY(QColor ink MEMBER ink FINAL)

public:
  QColor fill;
  QColor ink;

  bool operator==(const ColorFamily&) const = default;
};
