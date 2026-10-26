#include "AmountFormat.hpp"

#include <QCoreApplication>
#include <QLocale>

#include <cmath>
#include <limits>
#include <optional>
#include <utility>

static std::optional<core::Unit> unitFromCode(const QString& code)
{
  return core::unitFromCode(code.toStdString());
}

QString app::formatNumber(double value)
{
  QLocale locale;
  locale.setNumberOptions(locale.numberOptions() | QLocale::OmitGroupSeparator);
  return locale.toString(value, 'f', QLocale::FloatingPointShortest);
}

QString app::formatAmount(const core::Amount& amount)
{
  const double quantity = amount.quantity;
  // Counted units take a plural form, which needs a whole number
  const bool whole = quantity == std::floor(quantity) &&
                     quantity <= std::numeric_limits<int>::max();
  const int count = whole ? static_cast<int>(quantity) : 0;
  const QString number = formatNumber(quantity);
  switch (amount.unit) {
    case core::Unit::Pieces:
      return whole ? QCoreApplication::translate(
                       "AmountFormat", "%Ln piece(s)", nullptr, count)
                   : QCoreApplication::translate("AmountFormat", "%1 pieces")
                       .arg(number);
    case core::Unit::Packs:
      return whole ? QCoreApplication::translate(
                       "AmountFormat", "%Ln pack(s)", nullptr, count)
                   : QCoreApplication::translate("AmountFormat", "%1 packs")
                       .arg(number);
    case core::Unit::Bunches:
      return whole ? QCoreApplication::translate(
                       "AmountFormat", "%Ln bunch(es)", nullptr, count)
                   : QCoreApplication::translate("AmountFormat", "%1 bunches")
                       .arg(number);
    case core::Unit::Grams:
      return QCoreApplication::translate("AmountFormat", "%1 g").arg(number);
    case core::Unit::Kilograms:
      return QCoreApplication::translate("AmountFormat", "%1 kg").arg(number);
    case core::Unit::Milliliters:
      return QCoreApplication::translate("AmountFormat", "%1 ml").arg(number);
    case core::Unit::Centiliters:
      return QCoreApplication::translate("AmountFormat", "%1 cl").arg(number);
    case core::Unit::Liters:
      return QCoreApplication::translate("AmountFormat", "%1 l").arg(number);
  }
  std::unreachable();
}

AmountFormat::AmountFormat(QObject* parent)
  : QObject(parent)
{
}

QString AmountFormat::number(double value) const
{
  return app::formatNumber(value);
}

QString AmountFormat::amount(double quantity, const QString& unit) const
{
  const std::optional<core::Unit> coreUnit = unitFromCode(unit);
  return coreUnit ? app::formatAmount({ quantity, *coreUnit }) : QString();
}

QString AmountFormat::unitLabel(const QString& unit) const
{
  const std::optional<core::Unit> coreUnit = unitFromCode(unit);
  if (!coreUnit) {
    return {};
  }
  switch (*coreUnit) {
    case core::Unit::Pieces:
      return tr("pcs");
    case core::Unit::Grams:
      return tr("g");
    case core::Unit::Kilograms:
      return tr("kg");
    case core::Unit::Milliliters:
      return tr("ml");
    case core::Unit::Centiliters:
      return tr("cl");
    case core::Unit::Liters:
      return tr("l");
    case core::Unit::Packs:
      return tr("pack");
    case core::Unit::Bunches:
      return tr("bunch");
  }
  std::unreachable();
}
