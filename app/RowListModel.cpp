#include "RowListModel.hpp"

#include <algorithm>
#include <iterator>
#include <utility>

RowListModel::RowListModel(QList<QByteArray> roleNames, QObject* parent)
  : QAbstractListModel(parent)
  , m_roleNames(std::move(roleNames))
{
}

int RowListModel::rowCount(const QModelIndex& parent) const
{
  return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QVariant RowListModel::data(const QModelIndex& index, int role) const
{
  const int column = role - Qt::UserRole;
  if (!checkIndex(index,
                  CheckIndexOption::IndexIsValid |
                    CheckIndexOption::ParentIsInvalid) ||
      column < 0 || column >= m_roleNames.size()) {
    return {};
  }
  return m_rows[index.row()].value(column);
}

QHash<int, QByteArray> RowListModel::roleNames() const
{
  QHash<int, QByteArray> names;
  for (int column = 0; column < m_roleNames.size(); ++column) {
    names.insert(Qt::UserRole + column, m_roleNames[column]);
  }
  return names;
}

void RowListModel::setRows(std::vector<QVariantList> rows)
{
  const int kept = std::min(rowCount(), static_cast<int>(rows.size()));
  for (int row = 0; row < kept; ++row) {
    QList<int> roles;
    for (int column = 0; column < m_roleNames.size(); ++column) {
      if (m_rows[row].value(column) != rows[row].value(column)) {
        roles.append(Qt::UserRole + column);
      }
    }
    if (!roles.isEmpty()) {
      m_rows[row] = std::move(rows[row]);
      emit dataChanged(index(row), index(row), roles);
    }
  }

  const int count = static_cast<int>(rows.size());
  if (count > rowCount()) {
    beginInsertRows({}, rowCount(), count - 1);
    m_rows.insert(m_rows.end(),
                  std::make_move_iterator(rows.begin() + kept),
                  std::make_move_iterator(rows.end()));
    endInsertRows();
  } else if (count < rowCount()) {
    beginRemoveRows({}, count, rowCount() - 1);
    m_rows.resize(rows.size());
    endRemoveRows();
  }
}
