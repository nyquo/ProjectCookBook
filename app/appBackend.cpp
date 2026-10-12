#include "appBackend.hpp"

#include <QtGlobal>

static core::Backend* s_backend = nullptr;

core::Backend& app::backend()
{
  if (!s_backend) {
    qFatal("app::backend() used before app::setBackend()");
  }
  return *s_backend;
}

void app::setBackend(core::Backend& backend)
{
  s_backend = &backend;
}
