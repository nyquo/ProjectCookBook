#include "core/UuidV7Generator.hpp"

#include <format>

namespace core {

UuidV7Generator::UuidV7Generator()
{
  std::random_device device;
  std::seed_seq seed{ device(), device(), device(), device() };
  m_random.seed(seed);
}

UuidV7Generator::UuidV7Generator(std::uint64_t seed)
  : m_random(seed)
{
}

std::string UuidV7Generator::next(Timestamp time)
{
  const auto millis = static_cast<std::uint64_t>(toMillis(time));
  const std::uint64_t randomA = m_random();
  const std::uint64_t randomB = m_random();

  // high: unix_ts_ms (48 bits) | version 7 (4) | rand_a (12)
  // low:  variant 0b10 (2) | rand_b (62)
  const std::uint64_t high =
    (millis << 16) | (0x7ull << 12) | (randomA & 0xfff);
  const std::uint64_t low =
    (0b10ull << 62) | (randomB & 0x3fff'ffff'ffff'ffffull);

  return std::format("{:08x}-{:04x}-{:04x}-{:04x}-{:012x}",
                     high >> 32,
                     (high >> 16) & 0xffff,
                     high & 0xffff,
                     low >> 48,
                     low & 0xffff'ffff'ffffull);
}

}
