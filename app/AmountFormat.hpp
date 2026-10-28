#pragma once

#include "core/Amount.hpp"
#include "core/ShownAmount.hpp"

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

namespace app {

// In the user's locale, as short as it reads back exactly, without group
// separators: "0,5" in French, "1500"
QString formatNumber(double value);
// A catalog item's one-tap amount: "250 g", "6 pieces", "1 bunch"
QString formatAmount(const core::Amount& amount);
// A recipe's amount: "1,2 kg", "2 cloves", "3" (pieces are a bare number),
// "2 handfuls" (a free-text unit as typed). Without a quantity: the free-text
// unit alone ("a handful"), or "" for "To taste", which QuantityPill shows.
QString formatShownAmount(const core::ShownAmount& amount);

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

  // The number with the unit's label, in its plural form if `plural`
  static QString withUnit(const QString& number, core::Unit unit, bool plural);
};
