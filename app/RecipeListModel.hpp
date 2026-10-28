#pragma once

#include "core/RecipeStore.hpp"

#include <QAbstractListModel>
#include <QCollator>
#include <QtQml/qqmlregistration.h>

#include <vector>

// Created by QML, one per screen: the live recipes, by title in the user's
// locale. Follows the app's RecipeStore.
class RecipeListModel
  : public QAbstractListModel
  , private core::RecipeObserver
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)

public:
  enum Role
  {
    RecipeIdRole = Qt::UserRole + 1,
    TitleRole
  };

  enum class Error
  {
    NoError,
    StorageFailed,
    // Stale id: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit RecipeListModel(QObject* parent = nullptr);
  explicit RecipeListModel(core::RecipeStore& store, QObject* parent = nullptr);
  ~RecipeListModel() override;

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  // Undoes RecipeModel::remove()
  Q_INVOKABLE Error restore(const QString& recipeId);

signals:
  void countChanged();

private:
  // What a row shows, kept so that a change emits only the roles that differ
  struct Row
  {
    QString recipeId;
    QString title;
  };

  void recipeAboutToChange(const core::RecipeChange& change) noexcept override;
  void recipeChanged(const core::RecipeChange& change) noexcept override;

  std::vector<Row> computeRows() const;
  // Brings the rows up to date with single-row inserts, removals, moves and
  // dataChanged, never a reset
  void refresh();

  core::RecipeStore& m_store;
  QCollator m_collator;
  std::vector<Row> m_rows;
};
