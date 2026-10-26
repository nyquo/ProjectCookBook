#include "RecipeFieldSettings.hpp"

#include "appBackend.hpp"
#include "core/Backend.hpp"
#include "core/Database.hpp"

#include <stdexcept>
#include <utility>

RecipeFieldSettings::RecipeFieldSettings(QObject* parent)
  : RecipeFieldSettings(app::backend().settings(), parent)
{
}

RecipeFieldSettings::RecipeFieldSettings(core::SettingStore& settings,
                                         QObject* parent)
  : QObject(parent)
  , m_settings(settings)
  , m_shown(readFields())
{
  m_settings.addObserver(*this);
}

RecipeFieldSettings::~RecipeFieldSettings()
{
  m_settings.removeObserver(*this);
}

bool RecipeFieldSettings::shown(core::RecipeField field) const
{
  return m_shown[std::to_underlying(field)];
}

void RecipeFieldSettings::setShown(core::RecipeField field, bool on)
{
  // Also spares the store a write from a binding that follows the setting,
  // which would otherwise come during the store's notification
  if (on == shown(field)) {
    return;
  }
  try {
    core::setRecipeFieldShown(m_settings, field, on);
  } catch (const core::DatabaseError& error) {
    qCritical("Saving a recipe field failed: %s", error.what());
  } catch (const std::logic_error& error) {
    qWarning("RecipeFieldSettings: %s", error.what());
  }
}

std::array<bool, RecipeFieldSettings::fieldCount>
RecipeFieldSettings::readFields() const
{
  static_assert(
    static_cast<std::size_t>(std::to_underlying(core::RecipeField::Notes)) +
      1 ==
    fieldCount);
  std::array<bool, fieldCount> result{};
  for (std::size_t i = 0; i < fieldCount; ++i) {
    result[i] =
      core::recipeFieldShown(m_settings, static_cast<core::RecipeField>(i));
  }
  return result;
}

void RecipeFieldSettings::settingAboutToChange(std::string_view) noexcept {}

void RecipeFieldSettings::settingChanged(std::string_view) noexcept
{
  const std::array<bool, fieldCount> shown = readFields();
  if (shown != m_shown) {
    m_shown = shown;
    emit fieldsChanged();
  }
}
