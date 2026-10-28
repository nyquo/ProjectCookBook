#pragma once

#include "RowListModel.hpp"
#include "core/Recipe.hpp"
#include "core/RecipeStore.hpp"
#include "core/SettingStore.hpp"
#include "core/TagStore.hpp"
#include "core/unitSystem.hpp"

#include <QAbstractItemModel>
#include <QCollator>
#include <QObject>
#include <QUrl>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

#include <optional>

class PhotoStore;

// Created by QML for the recipe screen: one recipe, every text it shows built
// for the user's locale and settings, its ingredients and steps as list
// models, and the actions on it. Follows the app's RecipeStore, its TagStore
// and the unit system setting. Once the recipe is deleted, it keeps showing it
// as it was, for the screen's closing transition.
class RecipeModel
  : public QObject
  , private core::RecipeObserver
  , private core::TagObserver
  , private core::SettingObserver
{
  Q_OBJECT
  QML_ELEMENT

  // Set once, when created
  Q_PROPERTY(QString recipeId READ recipeId WRITE setRecipeId NOTIFY
               recipeIdChanged FINAL)
  Q_PROPERTY(QString title READ title NOTIFY fieldsChanged FINAL)
  Q_PROPERTY(QString description READ description NOTIFY fieldsChanged FINAL)
  // Empty without a photo
  Q_PROPERTY(QUrl photo READ photo NOTIFY fieldsChanged FINAL)
  // The title's first letter, shown without a photo
  Q_PROPERTY(QString initial READ initial NOTIFY fieldsChanged FINAL)
  // The live tags, by name: [{ name, colorKey }], colorKey a tag family's key
  Q_PROPERTY(QVariantList tags READ tags NOTIFY tagsChanged FINAL)
  Q_PROPERTY(bool favorite READ favorite NOTIFY favoriteChanged FINAL)
  // What the amounts are shown for, from 1 to maxServings: the base servings
  // when the recipe opens, never saved
  Q_PROPERTY(
    int servings READ servings WRITE setServings NOTIFY servingsChanged FINAL)
  Q_PROPERTY(int maxServings READ maxServings CONSTANT FINAL)
  // "40 min", "1 h", "1 h 05"; "" when unknown
  Q_PROPERTY(QString prepTime READ prepTime NOTIFY fieldsChanged FINAL)
  Q_PROPERTY(QString cookTime READ cookTime NOTIFY fieldsChanged FINAL)
  // The cost over the base servings, in euros: "€1.42"; "" when unknown
  Q_PROPERTY(
    QString costPerServing READ costPerServing NOTIFY fieldsChanged FINAL)
  // "4×", or "Never"
  Q_PROPERTY(
    QString cookedCount READ cookedCount NOTIFY cookingHistoryChanged FINAL)
  // "5 mo ago"; "" when never cooked
  Q_PROPERTY(
    QString lastCooked READ lastCooked NOTIFY cookingHistoryChanged FINAL)
  Q_PROPERTY(QString notes READ notes NOTIFY fieldsChanged FINAL)
  // As typed
  Q_PROPERTY(QString source READ source NOTIFY fieldsChanged FINAL)
  // The source if it's an http(s) link, else empty; its host without "www."
  Q_PROPERTY(QUrl sourceUrl READ sourceUrl NOTIFY fieldsChanged FINAL)
  Q_PROPERTY(QString sourceHost READ sourceHost NOTIFY fieldsChanged FINAL)
  // The main ingredients. Roles: quantity ("" for "To taste"), name,
  // optional, note, alternatives (["or 20 cl crème fraîche"])
  Q_PROPERTY(QAbstractItemModel* ingredients READ ingredients CONSTANT FINAL)
  // Roles: number ("2"), segments ([{ text, ingredient }], ingredient true
  // for a mention's words), amounts ([{ quantity, name }])
  Q_PROPERTY(QAbstractItemModel* steps READ steps CONSTANT FINAL)

public:
  enum class Error
  {
    NoError,
    StorageFailed,
    // Deleted recipe, nothing to undo: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit RecipeModel(QObject* parent = nullptr);
  RecipeModel(core::RecipeStore& recipes,
              core::TagStore& tags,
              core::SettingStore& settings,
              const PhotoStore& photos,
              QObject* parent = nullptr);
  ~RecipeModel() override;

  QString recipeId() const;
  void setRecipeId(const QString& recipeId);
  QString title() const;
  QString description() const;
  QUrl photo() const;
  QString initial() const;
  QVariantList tags() const { return m_tags; }
  bool favorite() const { return m_recipe.favorite; }
  int servings() const { return m_servings; }
  void setServings(int servings);
  int maxServings() const { return 99; }
  QString prepTime() const;
  QString cookTime() const;
  QString costPerServing() const;
  QString cookedCount() const;
  QString lastCooked() const;
  QString notes() const;
  QString source() const;
  QUrl sourceUrl() const;
  QString sourceHost() const;
  QAbstractItemModel* ingredients() { return &m_ingredientRows; }
  QAbstractItemModel* steps() { return &m_stepRows; }

  Q_INVOKABLE Error setFavorite(bool favorite);
  // One more time cooked, today
  Q_INVOKABLE Error markCooked();
  // Puts back the history the last markCooked() replaced
  Q_INVOKABLE Error undoCooked();
  // Soft delete; RecipeListModel::restore() undoes it
  Q_INVOKABLE Error remove();

signals:
  void recipeIdChanged();
  void fieldsChanged();
  void tagsChanged();
  void favoriteChanged();
  void servingsChanged();
  void cookingHistoryChanged();

private:
  void recipeAboutToChange(const core::RecipeChange& change) noexcept override;
  void recipeChanged(const core::RecipeChange& change) noexcept override;
  void tagAboutToChange(const core::TagChange& change) noexcept override;
  void tagChanged(const core::TagChange& change) noexcept override;
  void settingAboutToChange(std::string_view key) noexcept override;
  void settingChanged(std::string_view key) noexcept override;

  QVariantList computeTags() const;
  // The ingredient and step rows, for the servings and the unit system
  void updateRows();

  core::RecipeStore& m_recipes;
  core::TagStore& m_tagStore;
  core::SettingStore& m_settings;
  const PhotoStore& m_photos;
  QCollator m_collator;
  // A copy, which stays once the recipe is deleted
  core::Recipe m_recipe;
  QVariantList m_tags;
  int m_servings = 1;
  core::UnitSystem m_unitSystem;
  // What the last markCooked() replaced
  std::optional<core::CookingHistory> m_cookedBefore;
  RowListModel m_ingredientRows;
  RowListModel m_stepRows;
};
