#ifndef _SUFFIX_ARRAY_H
#define _SUFFIX_ARRAY_H

typedef void* SuffixArray;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Build suffix array for given string
 * \return new suffix-array or 0 if out of memory.
 */
SuffixArray buildSuffixArray(const char* str, const int length);

/**
 * Destroy matrix previously allocated by matrixNew(), matrixScale(),
 * matrixAdd() or matrixMul().
 */
Range findAllEntries(SuffixArray a, const char* needle, const int length);


#ifdef __cplusplus
}
#endif
#endif
