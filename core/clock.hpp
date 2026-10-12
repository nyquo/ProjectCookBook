#pragma once

#include <chrono>
#include <cstdint>
#include <functional>

namespace core {

using Timestamp = std::chrono::sys_time<std::chrono::milliseconds>;
using Clock = std::function<Timestamp()>;

inline Timestamp systemNow()
{
  return std::chrono::time_point_cast<std::chrono::milliseconds>(
    std::chrono::system_clock::now());
}

inline std::int64_t toMillis(Timestamp time)
{
  return time.time_since_epoch().count();
}

inline Timestamp fromMillis(std::int64_t millis)
{
  return Timestamp(std::chrono::milliseconds(millis));
}

}
