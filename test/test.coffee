should = require 'should'
prng = require 'random-js'

TernarySearchTrie = require __dirname + '/../lib/trie'
trie = new TernarySearchTrie
words = []
sortedKeys = []
randomIndice = []

describe 'set(key, value)', ->
  it 'is inserting key-value pairs...', (done) ->
    fs = require 'fs'
    readline = require 'readline'
    counter = 0
    rl = readline.createInterface
      input: fs.createReadStream __dirname + '/fixtures/wordlist.txt'
      output: process.stdout
      terminal: false
    rl.on 'line', (line) ->
      if line.length > 0
        words.push line
        trie.set line, line
      return
    rl.on 'close', ->
      done()
      return
    return
  it 'should add the exact number of unique words', ->
    sortedKeys = trie.keys()
    sortedKeys.length.should.equal words.length
    return
  it 'is just making some preparations before the rest tests...', ->
    sortedKeys.reverse()
    words.sort()
    randomIndice = (i for i in [0...words.length] by 1)
    rand = new prng(prng.engines.mt19937().seed 0xDEADBEEF)
    rand.shuffle randomIndice
    return
  return

describe 'get(key)', ->
  it 'should get the proper value for each key #1', ->
    for i in randomIndice
      key = words[i]
      should(trie.get key).equal key
    return
  it 'should get the proper value for each key #2', ->
    for i in randomIndice[-100000..]
      key = words[i]
      should(trie.get key, true).equal key
    return
  it 'should get the proper value for each key #3', ->
    should(trie.get key).equal key for key in words by -1
    return
  it 'should get the proper value for each key #4', ->
    should(trie.get key).equal key for key in words
    return
  return

describe 'size()', ->
  it 'should return the total number of nodes in the trie #1', ->
    trie.size().should.equal words.length
    return
  it 'should return the total number of nodes in the trie #2', ->
    for i in randomIndice
      key = words[i]
      trie.set key, key
      trie.size().should.equal words.length
    return
  return

describe 'keys()', ->
  it 'should return the same unique words added before', ->
    keys = trie.keys()
    keys.length.should.equal words.length
    keys.sort()
    key.should.equal words[i] for key, i in keys
    return
  return

describe 'keysWithPrefix(prefix)', ->
  it 'should return an empty array when prefix is an empty string', ->
    trie.keysWithPrefix('').length.should.equal 0
    return
  it 'should work properly for existent prefixes', ->
    data = [
      '!!!DONT_DELETE_ME_A'
      '!!!DONT_DELETE_ME_AB'
      '!!!DONT_DELETE_ME_ABA'
      '!!!DONT_DELETE_ME_ABC'
      '!!!DONT_DELETE_ME_ABCA'
      '!!!DONT_DELETE_ME_ABCBC'
      '!!!DONT_DELETE_ME_ABCD'
      '!!!DONT_DELETE_ME_ABCDEF'
      '!!!DONT_DELETE_ME_ABCE'
      '!!!DONT_DELETE_ME_ABDE'
      '!!!DONT_DELETE_ME_ABDEF'
    ].sort()
    trie.searchWithPrefix '!!!DONT_DELETE_ME_A', (key, value) ->
      key.should.equal value
    keys = trie.keysWithPrefix '!!!DONT_DELETE_ME_'
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  it 'should work properly for non-existent prefixes', ->
    trie.keysWithPrefix('~!~Nothing~!~').length.should.equal 0
    return
  return

describe 'keysWithCommonPrefix(key)', ->
  it 'should return an empty array if key an empty string', ->
    trie.keysWithCommonPrefix('').length.should.equal 0
    return
  it 'should work properly for existent keys', ->
    data = [
      '!!!DONT_DELETE_ME_A'
      '!!!DONT_DELETE_ME_AB'
      '!!!DONT_DELETE_ME_ABC'
      '!!!DONT_DELETE_ME_ABCD'
    ].sort()
    keys = trie.keysWithCommonPrefix '!!!DONT_DELETE_ME_ABCDE'
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  it 'should work properly for non-existent keys', ->
    data = [
      '?!!DONT_DELETE_ME_A'
    ].sort()
    keys = trie.keysWithCommonPrefix '?!!DONT_DELETE_ME_AZ'
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  return

describe 'fuzzy searching', ->
  it 'keysWithinHammingDistance(key, distance)', ->
    data = [ '中國城', '中國字', '中國海', '中國畫',
             '中國結', '中國話', '中間人' ]
    keys = trie.keysWithinHammingDistance '中國人', 1
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  it 'keysWithinLevenshteinDistance(key, distance)', ->
    data = [ '心意', '心慌意亂', '心滿意足', '心灰意冷',
             '心煩意亂', '心猿意馬', '稱意' ]
    keys = trie.keysWithinLevenshteinDistance '心稱意如', 2
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  it 'keysWithinDamerauLevenshteinDistance(key, distance)', ->
    data = [ '心意', '心慌意亂', '心滿意足', '心灰意冷',
             '心煩意亂', '心猿意馬', '稱心如意', '稱意' ]
    keys = trie.keysWithinDamerauLevenshteinDistance '心稱意如', 2
    keys.length.should.equal data.length
    key.should.equal data[i] for key, i in keys
    return
  return

describe 'traverse(callback: (key, value) -> void) -> this', ->
  it 'should visit every key-value pair only once', ->
    trie.traverse (key, value) ->
      key.should.equal(sortedKeys.pop()).equal(value)
      return
    sortedKeys.length.should.equal 0
    return
  return

describe 'del(key)', ->
  it 'should delete the key without changing other key-value pairs', ->
    n = words.length
    for i in randomIndice
      key = words[i]
      should(trie.get(key)).equal key
      should(trie.del(key).get(key)).be.null
      n -= 1
      trie.size().should.equal n
    trie.keys().length.should.equal 0
    return
  return
