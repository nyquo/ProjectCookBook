#include "appBackend.hpp"

#include <QtGlobal>

static core::Backend* s_backend = nullptr;
static PhotoStore* s_photoStore = nullptr;

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

PhotoStore& app::photoStore()
{
  if (!s_photoStore) {
    qFatal("app::photoStore() used before app::setPhotoStore()");
  }
  return *s_photoStore;
}

void app::setPhotoStore(PhotoStore& photos)
{
  s_photoStore = &photos;
}
