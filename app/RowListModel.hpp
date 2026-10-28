#pragma once

#include <QAbstractListModel>
#include <QByteArray>
#include <QList>
#include <QVariant>

#include <vector>

// Rows given whole, for a screen's lists that change in place: setRows()
// emits dataChanged with only the roles that differ, and inserts or removes
// rows at the end when the count changes, never a reset
class RowListModel : public QAbstractListModel
{
  Q_OBJECT

public:
  // The roles' names, in the order rows give their values
  explicit RowListModel(QList<QByteArray> roleNames, QObject* parent = nullptr);

  int rowCount(const QModelIndex& parent = {}) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  // One value per role in each row
  void setRows(std::vector<QVariantList> rows);

private:
  QList<QByteArray> m_roleNames;
  std::vector<QVariantList> m_rows;
};
