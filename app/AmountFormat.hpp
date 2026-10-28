#pragma once

#include "core/Amount.hpp"

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

namespace app {

// In the user's locale, as short as it reads back exactly, without group
// separators: "0,5" in French, "1500"
QString formatNumber(double value);
// "250 g", "6 pieces", "1 bunch"
QString formatAmount(const core::Amount& amount);

}

// Amounts as the user reads them, for QML as the AmountFormat singleton. Units
// are given by code ("kg").
class AmountFormat : public QObject
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit AmountFormat(QObject* parent = nullptr);

  Q_INVOKABLE QString number(double value) const;
  // "" for an unknown unit
  Q_INVOKABLE QString amount(double quantity, const QString& unit) const;
  // The unit's short label, where the user picks it ("pcs", "kg")
  Q_INVOKABLE QString unitLabel(const QString& unit) const;
};
