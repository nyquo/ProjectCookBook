#pragma once

#include "core/SettingStore.hpp"
#include "core/recipeFields.hpp"

#include <QObject>
#include <QtQml/qqmlregistration.h>

#include <array>

// Which recipe fields are shown, for QML as the RecipeFieldSettings singleton.
// A change is saved at once. A hidden field disappears from the recipes list,
// the recipe and the editor; its data stays.
class RecipeFieldSettings
  : public QObject
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  // Price of the recipe and per serving
  Q_PROPERTY(bool cost READ cost WRITE setCost NOTIFY fieldsChanged FINAL)
  // Prep and cook times
  Q_PROPERTY(bool times READ times WRITE setTimes NOTIFY fieldsChanged FINAL)
  // The amounts at the bottom of each step
  Q_PROPERTY(bool stepAmounts READ stepAmounts WRITE setStepAmounts NOTIFY
               fieldsChanged FINAL)
  // Times cooked and last cooked date
  Q_PROPERTY(bool cookingHistory READ cookingHistory WRITE setCookingHistory
               NOTIFY fieldsChanged FINAL)
  // Link, book or person
  Q_PROPERTY(bool source READ source WRITE setSource NOTIFY fieldsChanged FINAL)
  Q_PROPERTY(bool notes READ notes WRITE setNotes NOTIFY fieldsChanged FINAL)

public:
  explicit RecipeFieldSettings(QObject* parent = nullptr);
  explicit RecipeFieldSettings(core::SettingStore& settings,
                               QObject* parent = nullptr);
  ~RecipeFieldSettings() override;

  bool cost() const { return shown(core::RecipeField::Cost); }
  void setCost(bool on) { setShown(core::RecipeField::Cost, on); }
  bool times() const { return shown(core::RecipeField::Times); }
  void setTimes(bool on) { setShown(core::RecipeField::Times, on); }
  bool stepAmounts() const { return shown(core::RecipeField::StepAmounts); }
  void setStepAmounts(bool on) { setShown(core::RecipeField::StepAmounts, on); }
  bool cookingHistory() const
  {
    return shown(core::RecipeField::CookingHistory);
  }
  void setCookingHistory(bool on)
  {
    setShown(core::RecipeField::CookingHistory, on);
  }
  bool source() const { return shown(core::RecipeField::Source); }
  void setSource(bool on) { setShown(core::RecipeField::Source, on); }
  bool notes() const { return shown(core::RecipeField::Notes); }
  void setNotes(bool on) { setShown(core::RecipeField::Notes, on); }

signals:
  void fieldsChanged();

private:
  static constexpr std::size_t fieldCount = 6;

  bool shown(core::RecipeField field) const;
  // A failed save keeps the current value
  void setShown(core::RecipeField field, bool on);
  std::array<bool, fieldCount> readFields() const;

  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  core::SettingStore& m_settings;
  // By core::RecipeField
  std::array<bool, fieldCount> m_shown;
};
