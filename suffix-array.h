#ifndef _SUFFIX_ARRAY_H
#define _SUFFIX_ARRAY_H

typedef void* SuffixArray;
typedef void* Range;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Build suffix array for given string
 * \return new suffix-array or 0 if out of memory.
 */
//SuffixArray buildSuffixArray(const char* str, int length);
int buildSuffixArray(const char* str, int length);

/**
 * Delete suffix array
 */
void deleteSuffixArray(SuffixArray a);

/**
 * \return length of given instance of SuffixArray object
 */
int length(SuffixArray a);

/**
 * \return value at given position SuffixArray a or 0 if there is no such position
 */
int getPosition(SuffixArray a, int position);

/**
 * \return Range specifying all entries of given needle in suffix array
 */
Range findAllEntries(SuffixArray a, char* needle, int length);


#ifdef __cplusplus
}
#endif
#endif
