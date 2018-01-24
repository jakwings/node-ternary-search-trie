'use strict'

# punnycode.ucs2.decode from https://github.com/bestiejs/punycode.js
toCodePoints = (str) ->
  str = String str
  result = []
  counter = 0
  length = str.length
  if str.codePointAt?
    while counter < length
      codepoint = str.codePointAt counter
      if codepoint?
        result.push codepoint
        counter += if codepoint > 0xffff then 2 else 1
      else
        return result
    return result
  while counter < length
    value = str.charCodeAt counter++
    if counter < length and 0xD800 <= value <= 0xDBFF
      extra = str.charCodeAt counter++
      if (extra & 0xFC00) == 0xDC00  # low surrogate
        result.push ((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000
      else
        result.push value
        counter--
    else
      result.push value
  return result

# punnycode.ucs2.encode from https://github.com/bestiejs/punycode.js
fromCodePoint = String.fromCodePoint or (codepoints...) ->
  fromCharCode = String.fromCharCode
  str = ''
  for value in codepoints
    return str if !isFinite(value) or value < 0
    if value > 0xFFFF
      value -= 0x10000
      str += fromCharCode value >>> 10 & 0x3FF | 0xD800
      value = 0xDC00 | value & 0x3FF
    str += fromCharCode value
  return str

calcHammingDistance = (a, b) ->
  return Infinity if a.length != b.length
  d = 0
  d += 1 for i in [0...a.length] by 1 when a[i] != b[i]
  return d

calcLevenshteinDistance = (a, b) ->
  return a.length if b.length == 0
  return b.length if a.length == 0
  vx = (i for i in [0..b.length] by 1)
  vy = new Array(b.length + 1)
  for i in [0...a.length] by 1
    vy[0] = i + 1  # deletion in a
    for j in [0...b.length] by 1
      delta = if a[i] == b[j] then 0 else 1
      # deletion in a, deletion in b, deletion in both
      vy[j+1] = Math.min vy[j] + 1, vx[j+1] + 1, vx[j] + delta
    temp = vx
    vx = vy
    vy = temp
  return vx[b.length]

# The restricted Damerau-Levenshtein distance is better than the true version?
calcDamerauLevenshteinDistance = (a, b) ->
  return a.length if b.length == 0
  return b.length if a.length == 0
  vx = (i for i in [0..b.length] by 1)
  vy = new Array(b.length + 1)
  vz = new Array(b.length + 1)
  for i in [0...a.length] by 1
    vy[0] = i + 1  # deletion in a
    for j in [0...b.length] by 1
      cost = if a[i] == b[j] then 0 else 1
      # deletion in a, deletion in b, deletion in both, transposition
      vy[j+1] = Math.min vy[j] + 1, vx[j+1] + 1, vx[j] + cost,
          if cost != 0 and i > 0 and j > 0 and a[i-1] == b[j] and a[i] == b[j-1]
            vz[j-1] + 1
          else
            Infinity
    temp = vx
    vx = vy
    vy = vz
    vz = temp
  return vx[b.length]

mkTrie = (codepoint = null, value = null, parent = null,
    middle = null, left = null, right = null) ->
  return c: codepoint, v: value, p: parent, m: middle, l: left, r: right

erase = (parent, node) ->
  return if !(parent? and node?)
  node.p = null
  switch node
    when parent.l then parent.l = null
    when parent.r then parent.r = null
    when parent.m then parent.m = null
  return

replace = (parent, oldNode, newNode) ->
  return if !(parent? and oldNode?)
  oldNode.p = null
  newNode.p = parent if newNode?
  switch oldNode
    when parent.l then parent.l = newNode
    when parent.r then parent.r = newNode
    when parent.m then parent.m = newNode
  return


class TernarySearchTrie

  constructor: ->
    @root_ = null
    @size_ = 0

  set: (key, value) ->
    return this if !(key? and value?)
    codepoints = toCodePoints key
    @root_ ?= mkTrie codepoints[0]
    @insert_ @root_, codepoints, value
    return this

  insert_: (root, codepoints, value) ->
    index = 0
    while root? and index < codepoints.length
      c = codepoints[index]
      branch = switch
        when c < root.c then 'l'
        when c > root.c then 'r'
        else 'm'
      isEqual = branch == 'm'
      index += 1 if isEqual
      if isEqual and index == codepoints.length
        @size_ += 1 if !root.v?
        root.v = value
        break
      if root[branch]?
        root = root[branch]
      else
        root = root[branch] = mkTrie codepoints[index], null, root
        index += 1
        while index < codepoints.length
          root = root.m = mkTrie codepoints[index], null, root
          index += 1
        @size_ += 1
        root.v = value
        break
    return

  get: (key, splay = false) ->
    return null if !key?
    codepoints = toCodePoints key
    node = if splay
      @findAndSplay_ @root_, codepoints
    else
      @find_ @root_, codepoints
    return if node?.v? then node.v else null

  find_: (root, codepoints) ->
    index = 0
    while root? and index < codepoints.length
      c = codepoints[index]
      branch = switch
        when c < root.c then 'l'
        when c > root.c then 'r'
        else 'm'
      isEqual = branch == 'm'
      return root if isEqual and index + 1 == codepoints.length
      root = root[branch]
      index += 1 if isEqual
    return null

  del: (key) ->
    return this if !key?
    codepoints = toCodePoints key
    node = @find_ @root_, codepoints
    @delete_ node
    return this

  delete_: (node) ->
    return if !node?
    if node.v?
      node.v = null
      @size_ -= 1
    until node.m? or node.v?
      return if node.l? and node.r?
      parent = node.p
      if node.l? or node.r?
        child = node.r or node.l
        if parent?
          replace parent, node, child
          node = if child.m? or child.v? then parent else child
        else
          @root_ = child
          @root_.p = null
          node = @root_
      else
        if parent?
          erase parent, node
          node = parent
        else
          @root_ = null
          return
    return

  # TODO: http://www.bcs.org/upload/pdf/oommen.pdf
  findAndSplay_: (root, codepoints) ->
    index = 0
    while root? and index < codepoints.length
      c = codepoints[index]
      branch = switch
        when c < root.c then 'l'
        when c > root.c then 'r'
        else 'm'
      isEqual = branch == 'm'
      if isEqual and index + 1 == codepoints.length
        @splay_ root if root?.v?
        return root
      root = root[branch]
      index += 1 if isEqual
    return null

  splay_: (node) ->
    return if !node?
    while node.p?
      if node == node.p.m
        node = node.p
        continue
      if !node.p.p? or node.p.p.m == node.p
        #  ?     ?
        #  b --> a
        # a       b
        @rotate_ node.p, node
      else
        if ((node == node.p.l and node.p == node.p.p.l) or
            (node == node.p.r and node.p == node.p.p.r))
          #   c              a
          #  b  --->  b  -->  b
          # a        a c       c
          @rotate_ node.p.p, node.p
          @rotate_ node.p, node
        else
          #  c        c
          # b  --->  a  -->  a
          #  a      b       b c
          @rotate_ node.p, node
          @rotate_ node.p, node
    return

  rotate_: (parent, node) ->
    return if !(parent? and node?)
    if node == parent.l or node == parent.r
      grandparent = parent.p
      if grandparent?
        branch = switch parent
          when grandparent.l then 'l'
          when grandparent.r then 'r'
          else 'm'
        grandparent[branch] = node
        node.p = grandparent
      else
        @root_ = node
        @root_.p = null
      if node == parent.l
        parent.l = node.r
        parent.l.p = parent if parent.l?
        node.r = parent
      else
        parent.r = node.l
        parent.r.p = parent if parent.r?
        node.l = parent
      parent.p = node
    else
      throw new Error('unknown errors')
    return

  size: -> @size_

  keys: ->
    items = []
    @traverse_ @root_, (key) -> items.push key
    return items

  keysWithPrefix: (prefix) ->
    items = []
    @searchWithPrefix prefix, (key) -> items.push key
    return items

  searchWithPrefix: (prefix, callback) ->
    return if prefix.length < 1
    codepoints = toCodePoints prefix
    root = @find_ @root_, codepoints
    return if !root?
    callback prefix, root if root.v?
    @traverse_ root.m, (key, node) -> callback prefix + key, node.v
    return this

  keysWithCommonPrefix: (key) ->
    items = []
    @searchWithCommonPrefix key, (key) -> items.push key
    return items

  searchWithCommonPrefix: (key, callback) ->
    return if key.length < 1 or !@root_?
    prefix = ''
    @walk_ @root_, toCodePoints(key), (node) ->
      prefix += fromCodePoint node.c
      callback prefix, node.v if node.v?
    return this

  keysWithinHammingDistance: (query, distance) ->
    items = []
    @searchWithinHammingDistance query, distance, (key) -> items.push key
    return items

  keysWithinLevenshteinDistance: (query, distance) ->
    items = []
    @searchWithinLevenshteinDistance query, distance, (key) -> items.push key
    return items

  keysWithinDamerauLevenshteinDistance: (query, distance) ->
    items = []
    @searchWithinDamerauLevenshteinDistance query, distance, (key) -> items.push key
    return items

  searchWithinHammingDistance: (query, distance, callback) ->
    a = toCodePoints query
    @traverse_ @root_, (key, value) ->
      b = toCodePoints key
      return if a.length != b.length
      callback key, value if calcHammingDistance(a, b) <= distance
      return
    return this

  searchWithinLevenshteinDistance: (query, distance, callback) ->
    a = toCodePoints query
    @traverse_ @root_, (key, value) ->
      b = toCodePoints key
      return if Math.abs(a.length - b.length) > distance
      callback key, value if calcLevenshteinDistance(a, b) <= distance
      return
    return this

  searchWithinDamerauLevenshteinDistance: (query, distance, callback) ->
    a = toCodePoints query
    @traverse_ @root_, (key, value) ->
      b = toCodePoints key
      return if Math.abs(a.length - b.length) > distance
      callback key, value if calcDamerauLevenshteinDistance(a, b) <= distance
      return
    return this

  traverse: (callback) -> @traverse_ @root_, callback

  traverse_: (root = @root_, callback) ->
    t = @traversal_ root
    callback r.value.key, r.value.value while !(r = t.next()).done
    return this

  traversal: -> @traversal_ @root_

  # in-order
  traversal_: (root = @root_, callback = null) -> # iterator
    done = false
    prefix = ''
    ns = []
    ps = []
    return next: ->
      result = value: undefined, done: true
      return result if done
      while root? or ns.length > 0
        if root?
          ns.push root
          ps.push prefix
          root = root.l
        else
          break if ns.length == 0
          root = ns.pop()
          prefix = ps.pop()
          if ns.length > 0 and ns[ns.length-1] == -1
            ns.pop()
            root = root.r
          else
            ns.push -1
            ns.push root
            ps.push prefix
            prefix += fromCodePoint root.c
            if root.v?
              if callback?
                result.value = {key: prefix, node: root}
                result = callback result
              else
                result.value = {key: prefix, value: root.v}
              root = root.m
              result.done = false
              return result
            else
              root = root.m
      done = true
      return result

  walk_: (root, codepoints, callback) ->
    index = 0
    while root? and index < codepoints.length
      c = codepoints[index]
      branch = switch
        when c < root.c then 'l'
        when c > root.c then 'r'
        else 'm'
      isEqual = branch == 'm'
      index += 1 if isEqual
      next = if index < codepoints.length then root[branch] else null
      callback root if isEqual and callback?
      return root if index == codepoints.length
      root = next
    return null


if module?.exports?
  module.exports = TernarySearchTrie
else if typeof define == 'function' and define.amd
  define [], -> TernarySearchTrie
else
  this.TernarySearchTrie = TernarySearchTrie
