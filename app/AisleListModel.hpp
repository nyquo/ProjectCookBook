#pragma once

#include "core/AisleStore.hpp"

#include <QAbstractListModel>
#include <QColor>
#include <QtQml/qqmlregistration.h>

// Created by QML, one per screen; follows the app's AisleStore
class AisleListModel
  : public QAbstractListModel
  , private core::AisleObserver
{
  Q_OBJECT
  QML_ELEMENT

public:
  enum Role
  {
    AisleIdRole = Qt::UserRole + 1,
    NameRole,
    // QML picks the pair with UiTheme.dark
    FillRole,
    InkRole,
    DarkFillRole,
    DarkInkRole
  };

  enum class Error
  {
    NoError,
    EmptyName,
    DuplicateName,
    StorageFailed,
    // Stale row or id, invalid or translucent color...: nothing changed
    InvalidRequest
  };
  Q_ENUM(Error)

  explicit AisleListModel(QObject* parent = nullptr);
  explicit AisleListModel(core::AisleStore& store, QObject* parent = nullptr);
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

private:
  void aisleAboutToChange(const core::AisleChange& change) noexcept override;
  void aisleChanged(const core::AisleChange& change) noexcept override;

  bool isValidRow(int row) const;
  std::string idAt(int row) const;

  core::AisleStore& m_store;
};
