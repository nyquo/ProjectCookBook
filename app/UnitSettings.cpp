#include "UnitSettings.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <stdexcept>

UnitSettings::UnitSettings(QObject* parent)
  : UnitSettings(app::backend().settings(), parent)
{
}

UnitSettings::UnitSettings(core::SettingStore& settings, QObject* parent)
  : QObject(parent)
  , m_settings(settings)
  , m_system(core::unitSystem(settings))
{
  m_settings.addObserver(*this);
}

UnitSettings::~UnitSettings()
{
  m_settings.removeObserver(*this);
}

UnitSettings::System UnitSettings::system() const
{
  return static_cast<System>(m_system);
}

void UnitSettings::setSystem(System system)
{
  // Also spares the store a write from a binding that follows the setting,
  // which would otherwise come during the store's notification
  if (system == this->system()) {
    return;
  }
  try {
    core::setUnitSystem(m_settings, static_cast<core::UnitSystem>(system));
  } catch (const core::DatabaseError& error) {
    qCritical("Saving the unit system failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("UnitSettings: %s", error.what());
  }
}

QStringList UnitSettings::unitChoices() const
{
  QStringList codes;
  for (const core::Unit unit : core::unitChoices(m_system)) {
    const std::string_view code = core::unitCode(unit);
    codes.append(
      QString::fromUtf8(code.data(), static_cast<qsizetype>(code.size())));
  }
  return codes;
}

void UnitSettings::settingAboutToChange(std::string_view) noexcept {}

void UnitSettings::settingChanged(std::string_view) noexcept
{
  const core::UnitSystem system = core::unitSystem(m_settings);
  if (system != m_system) {
    m_system = system;
    emit systemChanged();
  }
}
