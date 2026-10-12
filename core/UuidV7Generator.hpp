#pragma once

#include "core/clock.hpp"

#include <cstdint>
#include <random>
#include <string>

namespace core {

// RFC 9562 UUIDv7: a millisecond timestamp, then random bits. Ids sort by
// creation time, which keeps the primary-key index compact.
class UuidV7Generator
{
public:
  UuidV7Generator();
  explicit UuidV7Generator(std::uint64_t seed);

  std::string next(Timestamp time);

private:
  std::mt19937_64 m_random;
};

}
