#include "AmountFormat.hpp"

#include <QLocale>

#include <optional>
#include <string>
#include <utility>
#include <variant>

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
  return AmountFormat::withUnit(formatNumber(amount.quantity),
                                amount.unit,
                                core::takesPlural(amount.quantity));
}

QString app::formatShownAmount(const core::ShownAmount& amount)
{
  const auto* text =
    amount.unit ? std::get_if<std::string>(&*amount.unit) : nullptr;
  if (!amount.quantity) {
    return text ? QString::fromStdString(*text) : QString();
  }
  const QString number = formatNumber(*amount.quantity);
  if (text) {
    return AmountFormat::tr("%1 %2",
                            "a number, then a unit as the user typed it")
      .arg(number, QString::fromStdString(*text));
  }
  const auto* unit =
    amount.unit ? std::get_if<core::Unit>(&*amount.unit) : nullptr;
  if (!unit || *unit == core::Unit::Pieces) {
    return number;
  }
  return AmountFormat::withUnit(number, *unit, amount.plural);
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
    case core::Unit::Ounces:
      return tr("oz");
    case core::Unit::Pounds:
      return tr("lb");
    case core::Unit::FluidOunces:
      return tr("fl oz");
    case core::Unit::Teaspoons:
      return tr("tsp");
    case core::Unit::Tablespoons:
      return tr("tbsp");
    case core::Unit::Cups:
      return tr("cup");
    case core::Unit::Cloves:
      return tr("clove");
    case core::Unit::Pinches:
      return tr("pinch");
    case core::Unit::Cans:
      return tr("can");
  }
  std::unreachable();
}

// Not Qt's %n plural forms: they take whole counts, and amounts aren't (1,5
// cups). core::takesPlural() decides.
QString AmountFormat::withUnit(const QString& number,
                               core::Unit unit,
                               bool plural)
{
  switch (unit) {
    case core::Unit::Pieces:
      return (plural ? tr("%1 pieces") : tr("%1 piece")).arg(number);
    case core::Unit::Grams:
      return tr("%1 g").arg(number);
    case core::Unit::Kilograms:
      return tr("%1 kg").arg(number);
    case core::Unit::Milliliters:
      return tr("%1 ml").arg(number);
    case core::Unit::Centiliters:
      return tr("%1 cl").arg(number);
    case core::Unit::Liters:
      return tr("%1 l").arg(number);
    case core::Unit::Packs:
      return (plural ? tr("%1 packs") : tr("%1 pack")).arg(number);
    case core::Unit::Bunches:
      return (plural ? tr("%1 bunches") : tr("%1 bunch")).arg(number);
    case core::Unit::Ounces:
      return tr("%1 oz").arg(number);
    case core::Unit::Pounds:
      return tr("%1 lb").arg(number);
    case core::Unit::FluidOunces:
      return tr("%1 fl oz").arg(number);
    case core::Unit::Teaspoons:
      return tr("%1 tsp").arg(number);
    case core::Unit::Tablespoons:
      return tr("%1 tbsp").arg(number);
    case core::Unit::Cups:
      return (plural ? tr("%1 cups") : tr("%1 cup")).arg(number);
    case core::Unit::Cloves:
      return (plural ? tr("%1 cloves") : tr("%1 clove")).arg(number);
    case core::Unit::Pinches:
      return (plural ? tr("%1 pinches") : tr("%1 pinch")).arg(number);
    case core::Unit::Cans:
      return (plural ? tr("%1 cans") : tr("%1 can")).arg(number);
  }
  std::unreachable();
}
