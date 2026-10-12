#pragma once

namespace core {
class Backend;
}

namespace app {

// The app's one Backend. main() sets it before creating the QML engine, so
// every model QML creates can reach the stores.
core::Backend& backend();
void setBackend(core::Backend& backend);

}
