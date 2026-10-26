#pragma once

#include "core/AisleStore.hpp"
#include "core/IngredientStore.hpp"

#include <QAbstractListModel>
#include <QCollator>
#include <QColor>
#include <QtQml/qqmlregistration.h>

#include <vector>

// Created by QML, one per screen: the catalog items as the catalog screen shows
// them, grouped by aisle (aisle order, "Other" last), sorted by name in the
// user's locale within a group, filtered by searchText and aisleFilter. Each
// row also carries its group's aisle, size and ends, so a view can draw the
// groups. Follows the app's AisleStore and IngredientStore.
class CatalogListModel
  : public QAbstractListModel
  , private core::AisleObserver
  , private core::IngredientObserver
{
  Q_OBJECT
  QML_ELEMENT

  // Matched against the items' names, ignoring case and accents
  Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY
               searchTextChanged FINAL)
  // An aisle's id, or "" for all; back to "" when that aisle is deleted
  Q_PROPERTY(QString aisleFilter READ aisleFilter WRITE setAisleFilter NOTIFY
               aisleFilterChanged FINAL)
  Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)

public:
  enum Role
  {
    IngredientIdRole = Qt::UserRole + 1,
    NameRole,
    // An icon key, or "" for the default icon
    IconRole,
    // The one-tap amount: quantity, unit code, and as the user reads it
    QuantityRole,
    UnitRole,
    AmountTextRole,
    // "" for "Other", and the colors invalid
    AisleIdRole,
    AisleNameRole,
    // QML picks the pair with UiTheme.dark
    FillRole,
    InkRole,
    DarkFillRole,
    DarkInkRole,
    // Rows in the row's group, and whether the row starts or ends it
    GroupCountRole,
    FirstInGroupRole,
    LastInGroupRole
  };

  enum class Error
  {
    NoError,
    EmptyName,
    // A catalog item has this name
    DuplicateName,
    // Renaming: an ingredient outside the catalog has this name
    NameTaken,
    // restoreToCatalog(): its aisle was deleted meanwhile
    AisleDeleted,
    StorageFailed,
    // Stale id, unknown unit, deleted aisle...: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit CatalogListModel(QObject* parent = nullptr);
  CatalogListModel(core::AisleStore& aisles,
                   core::IngredientStore& ingredients,
                   QObject* parent = nullptr);
  ~CatalogListModel() override;

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  QString searchText() const { return m_searchText; }
  void setSearchText(const QString& text);
  QString aisleFilter() const { return m_aisleFilter; }
  void setAisleFilter(const QString& aisleId);

  // What add(), or update() of the item `ingredientId`, would say of the name
  Q_INVOKABLE Error checkName(const QString& name,
                              const QString& ingredientId = {}) const;
  // `icon` "" for none; `unit` a unit code ("kg")
  Q_INVOKABLE Error add(const QString& name,
                        const QString& aisleId,
                        const QString& icon,
                        double quantity,
                        const QString& unit);
  Q_INVOKABLE Error update(const QString& ingredientId,
                           const QString& name,
                           const QString& aisleId,
                           const QString& icon,
                           double quantity,
                           const QString& unit);
  Q_INVOKABLE Error removeFromCatalog(const QString& ingredientId);
  Q_INVOKABLE Error restoreToCatalog(const QString& ingredientId);

signals:
  void searchTextChanged();
  void aisleFilterChanged();
  void countChanged();

private:
  // What a row shows, kept so that a change emits only the roles that differ
  struct Row
  {
    QString ingredientId;
    QString name;
    QString icon;
    double quantity = 0;
    QString unit;
    QString amountText;
    QString aisleId;
    QString aisleName;
    QColor fill;
    QColor ink;
    QColor darkFill;
    QColor darkInk;
    int groupCount = 0;
    bool firstInGroup = false;
    bool lastInGroup = false;
  };

  void aisleAboutToChange(const core::AisleChange& change) noexcept override;
  void aisleChanged(const core::AisleChange& change) noexcept override;
  void ingredientAboutToChange(
    const core::IngredientChange& change) noexcept override;
  void ingredientChanged(
    const core::IngredientChange& change) noexcept override;

  std::vector<Row> computeRows() const;
  // Brings the rows up to date with single-row inserts, removals, moves and
  // dataChanged, never a reset
  void refresh();

  core::AisleStore& m_aisles;
  core::IngredientStore& m_ingredients;
  QString m_searchText;
  QString m_aisleFilter;
  QCollator m_collator;
  std::vector<Row> m_rows;
};
