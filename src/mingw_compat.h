// MinGW lacks the GNU `uint` and BSD `u_intN_t` typedefs that rapidsnark and ffiasm use.
// This header patches those types to their windows equivalent.
#ifndef RAPIDSNARK_MINGW_COMPAT_H
#define RAPIDSNARK_MINGW_COMPAT_H

#include <stdint.h>

typedef unsigned int uint;
typedef uint32_t     u_int32_t;
typedef uint64_t     u_int64_t;

#endif
