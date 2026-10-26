#pragma once

#include "core/TagStore.hpp"

#include <QAbstractListModel>
#include <QCollator>
#include <QtQml/qqmlregistration.h>

#include <vector>

// Created by QML, one per screen: the live tags, sorted by name in the user's
// locale. Follows the app's TagStore; a rename moves its row.
class TagListModel
  : public QAbstractListModel
  , private core::TagObserver
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)

public:
  enum Role
  {
    TagIdRole = Qt::UserRole + 1,
    NameRole,
    // A tag family's key: "mint", "butter", "sky" or "peach"
    ColorKeyRole,
    // The recipes that carry the tag
    RecipeCountRole
  };

  enum class Error
  {
    NoError,
    EmptyName,
    DuplicateName,
    StorageFailed,
    // Stale id, unknown color key: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit TagListModel(QObject* parent = nullptr);
  explicit TagListModel(core::TagStore& store, QObject* parent = nullptr);
  ~TagListModel() override;

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  // The new tag takes the color least used among the others
  Q_INVOKABLE Error create(const QString& name);
  Q_INVOKABLE Error rename(const QString& tagId, const QString& name);
  // `colorKey` a tag family's key
  Q_INVOKABLE Error setColor(const QString& tagId, const QString& colorKey);
  Q_INVOKABLE Error remove(const QString& tagId);
  Q_INVOKABLE Error restore(const QString& tagId);

signals:
  void countChanged();

private:
  // What a row shows, kept so that a change emits only the roles that differ
  struct Row
  {
    QString tagId;
    QString name;
    QString colorKey;
    int recipeCount = 0;
  };

  void tagAboutToChange(const core::TagChange& change) noexcept override;
  void tagChanged(const core::TagChange& change) noexcept override;

  std::vector<Row> computeRows() const;
  // Brings the rows up to date with single-row inserts, removals, moves and
  // dataChanged, never a reset
  void refresh();

  core::TagStore& m_store;
  QCollator m_collator;
  std::vector<Row> m_rows;
};
