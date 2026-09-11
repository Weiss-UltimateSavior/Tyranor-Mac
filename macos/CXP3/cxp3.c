#include "CXP3.h"

#include <zlib.h>

int cxz_uncompress(const unsigned char *src, size_t srcLen, unsigned char *dst, unsigned long *dstLen) {
    return uncompress((Bytef *)dst, (uLongf *)dstLen, (const Bytef *)src, (uLong)srcLen);
}
