pragma Singleton

import QtQuick

// What to tell the user when a model refuses a change; "" when there's nothing
// to say, e.g. for a request that went stale
QtObject {
    function aisle(error: int): string {
        switch (error) {
        case AisleListModel.Error.EmptyName:
            return qsTr("An aisle needs a name.")
        case AisleListModel.Error.DuplicateName:
            return qsTr("An aisle with this name already exists.")
        case AisleListModel.Error.InUse:
            return qsTr("This aisle still holds items.")
        case AisleListModel.Error.StorageFailed:
            return qsTr("Couldn't save the change.")
        default:
            return ""
        }
    }

    function catalog(error: int): string {
        switch (error) {
        case CatalogListModel.Error.EmptyName:
            return qsTr("An item needs a name.")
        case CatalogListModel.Error.DuplicateName:
            return qsTr("Already in the catalog.")
        case CatalogListModel.Error.NameTaken:
            return qsTr("Another ingredient already has this name.")
        case CatalogListModel.Error.AisleDeleted:
            return qsTr("Its aisle was deleted.")
        case CatalogListModel.Error.StorageFailed:
            return qsTr("Couldn't save the change.")
        default:
            return ""
        }
    }
}
