#pragma once

#include "core/AisleStore.hpp"
#include "core/IngredientStore.hpp"

#include <QAbstractListModel>
#include <QColor>
#include <QtQml/qqmlregistration.h>

#include <map>
#include <string>

// Created by QML, one per screen; follows the app's AisleStore, and the
// IngredientStore for the number of catalog items in each aisle
class AisleListModel
  : public QAbstractListModel
  , private core::AisleObserver
  , private core::IngredientObserver
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)

public:
  enum Role
  {
    AisleIdRole = Qt::UserRole + 1,
    NameRole,
    // QML picks the pair with UiTheme.dark
    FillRole,
    InkRole,
    DarkFillRole,
    DarkInkRole,
    // Catalog items in the aisle
    ItemCountRole
  };

  enum class Error
  {
    NoError,
    EmptyName,
    DuplicateName,
    // remove(): catalog items are in the aisle
    InUse,
    StorageFailed,
    // Stale row or id, invalid or translucent color...: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit AisleListModel(QObject* parent = nullptr);
  AisleListModel(core::AisleStore& store,
                 core::IngredientStore& ingredients,
                 QObject* parent = nullptr);
  ~AisleListModel() override;

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  // The aisle keeps its own copy of the colors, usually a tag color's
  Q_INVOKABLE Error create(const QString& name,
                           const QColor& fill,
                           const QColor& ink,
                           const QColor& darkFill,
                           const QColor& darkInk);
  Q_INVOKABLE Error rename(int row, const QString& name);
  Q_INVOKABLE Error setColors(int row,
                              const QColor& fill,
                              const QColor& ink,
                              const QColor& darkFill,
                              const QColor& darkInk);
  Q_INVOKABLE Error move(int from, int to);
  Q_INVOKABLE Error remove(int row);
  Q_INVOKABLE Error restore(const QString& aisleId);
  // The row of the aisle with this id, or -1
  Q_INVOKABLE int rowOf(const QString& aisleId) const;
  // The id of the aisle at `row`, or "" out of range; create() appends
  Q_INVOKABLE QString aisleIdAt(int row) const;

signals:
  void countChanged();

private:
  void aisleAboutToChange(const core::AisleChange& change) noexcept override;
  void aisleChanged(const core::AisleChange& change) noexcept override;
  void ingredientAboutToChange(
    const core::IngredientChange& change) noexcept override;
  void ingredientChanged(
    const core::IngredientChange& change) noexcept override;

  bool isValidRow(int row) const;
  std::string idAt(int row) const;
  // Catalog items by aisle id
  std::map<std::string, int, std::less<>> countItems() const;

  core::AisleStore& m_store;
  core::IngredientStore& m_ingredients;
  std::map<std::string, int, std::less<>> m_itemCounts;
};
