### A simple class for ternary search trie implemented in JavaScript.

[![Build Status](https://travis-ci.org/jakwings/node-ternary-search-trie.svg)](https://travis-ci.org/jakwings/node-ternary-search-trie)
[![NPM version](https://badge.fury.io/js/node-ternary-search-trie.svg)](https://badge.fury.io/js/node-ternary-search-trie)

It is unstable and *not for production use*. ;)

You can install it via `npm install node-ternary-search-trie`, or just
include the script `lib/trie.js` in your web pages.

```javascript
var Trie = Trie || require('node-ternary-search-trie');

var trie = new Trie();
```

Public methods (with simple Unicode support):

*   `set(key, value) -> this`

    Insert one key-value pair into the trie. This will overwrite the existed
    key-value pair. `value` should not be `null` or `undefined`.

*   `get(key, toSplay = false) -> value`: 

    Fetch the stored value of the given key.

    `get` and `set` methods may be greatly affected after each splaying operation. Splay with caution.

*   `del(key) -> this`

    Delete the key-value pair for the given key.

*   `size() -> size`

    Return the total number of nodes in the trie.

*   `keys() -> [keys...]`

    Sort and return all keys stored in the trie.

*   `keysWithPrefix(prefix) -> [keys...]`

    Sort and return all keys started with the given prefix.

*   `keysWithCommonPrefix(key) -> [keys...]`

    Sort and return all keys that are prefixes of the given key.

*   `keysWithinHammingDistance(key, distance) -> [keys...]`

    Sort and return all keys within a Hamming distance of the given key.

*   `keysWithinLevenshteinDistance(key, distance) -> [keys...]`

    Sort and return all keys within a Levenshtein distance of the given key.

*   `keysWithinDamerauLevenshteinDistance(key, distance) -> [keys...]`

    Sort and return all keys within a Damerau-Levenshtein distance of the given key.

*   `searchWithPrefix(prefix, callback: (key, value) -> void) -> this`

    Just like `keysWithPrefix`.

*   `searchWithCommonPrefix(key, callback: (key, value) -> void) -> this`

    Just like `keysWithCommonPrefix`.

*   `searchWithinHammingDistance(key, distance, callback: (key, value, distance) -> void) -> this`

    Just like `keysWithinHammingDistance`.

*   `searchWithinLevenshteinDistance(key, distance, callback: (key, value, distance) -> void) -> this`

    Just like `keysWithinLevenshteinDistance`.

*   `searchWithinDamerauLevenshteinDistance(key, distance, callback: (key, value, distance) -> void) -> this`

    Just like `keysWithinDamerauLevenshteinDistance`.

*   `traverse(callback: (key, value) -> void) -> this`

    Traverse in in-order. (sorted)

*   `traversal() -> iterator`

    Return an iterator for in-order traversal. `iterator.next()` will return
    `{value: undefined | {key, value}, done: Boolean}`.
