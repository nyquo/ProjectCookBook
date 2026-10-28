#include "collation.hpp"

#include <QString>

QCollator app::nameCollator()
{
  QCollator collator;
  collator.setCaseSensitivity(Qt::CaseInsensitive);
  collator.setNumericMode(true);
  return collator;
}

core::NameLess app::nameLess(const QCollator& collator)
{
  return [&collator](std::string_view a, std::string_view b) {
    return collator.compare(
             QString::fromUtf8(a.data(), static_cast<qsizetype>(a.size())),
             QString::fromUtf8(b.data(), static_cast<qsizetype>(b.size()))) < 0;
  };
}
