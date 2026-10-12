#pragma once

#include "core/AisleStore.hpp"

#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>

#include <utility>

// Created by QML, one per screen; follows the app's AisleStore.
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
    ColorRole
  };

  enum class Color
  {
    Mint = std::to_underlying(core::AisleColor::Mint),
    Butter = std::to_underlying(core::AisleColor::Butter),
    Sky = std::to_underlying(core::AisleColor::Sky),
    Peach = std::to_underlying(core::AisleColor::Peach),
  };
  Q_ENUM(Color)

  enum class Error
  {
    NoError,
    EmptyName,
    DuplicateName,
    StorageFailed
  };
  Q_ENUM(Error)

  explicit AisleListModel(QObject* parent = nullptr);
  explicit AisleListModel(core::AisleStore& store, QObject* parent = nullptr);
  ~AisleListModel() override;

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE Error create(const QString& name, Color color);
  Q_INVOKABLE Error rename(int row, const QString& name);
  Q_INVOKABLE Error setColor(int row, Color color);
  Q_INVOKABLE Error move(int from, int to);
  Q_INVOKABLE Error remove(int row);
  Q_INVOKABLE Error restore(const QString& aisleId);

private:
  void aisleAboutToChange(const core::AisleChange& change) override;
  void aisleChanged(const core::AisleChange& change) override;

  bool isValidRow(int row) const;
  std::string idAt(int row) const;

  core::AisleStore& m_store;
};
