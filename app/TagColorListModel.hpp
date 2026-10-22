#pragma once

#include "core/TagColorStore.hpp"

#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>

// Created by QML: the app's tag colors, for pickers. The store doesn't change
// yet, so there's nothing to follow.
class TagColorListModel : public QAbstractListModel
{
  Q_OBJECT
  QML_ELEMENT

public:
  enum Role
  {
    NameRole = Qt::UserRole + 1,
    // QML picks the pair with UiTheme.dark
    FillRole,
    InkRole,
    DarkFillRole,
    DarkInkRole
  };

  explicit TagColorListModel(QObject* parent = nullptr);
  explicit TagColorListModel(const core::TagColorStore& store,
                             QObject* parent = nullptr);

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

private:
  const core::TagColorStore& m_store;
};
