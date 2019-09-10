(function() {
  'use strict';
  var TernarySearchTrie, calcDamerauLevenshteinDistance, calcHammingDistance, calcLevenshteinDistance, erase, fromCodePoint, mkTrie, replace, toCodePoints,
    slice = [].slice;

  toCodePoints = function(str) {
    var codepoint, counter, extra, length, result, value;
    str = String(str);
    result = [];
    counter = 0;
    length = str.length;
    if (str.codePointAt != null) {
      while (counter < length) {
        codepoint = str.codePointAt(counter);
        if (codepoint != null) {
          result.push(codepoint);
          counter += codepoint > 0xffff ? 2 : 1;
        } else {
          return result;
        }
      }
      return result;
    }
    while (counter < length) {
      value = str.charCodeAt(counter++);
      if (counter < length && (0xD800 <= value && value <= 0xDBFF)) {
        extra = str.charCodeAt(counter++);
        if ((extra & 0xFC00) === 0xDC00) {
          result.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
        } else {
          result.push(value);
          counter--;
        }
      } else {
        result.push(value);
      }
    }
    return result;
  };

  fromCodePoint = String.fromCodePoint || function() {
    var codepoints, fromCharCode, k, len, str, value;
    codepoints = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    fromCharCode = String.fromCharCode;
    str = '';
    for (k = 0, len = codepoints.length; k < len; k++) {
      value = codepoints[k];
      if (!isFinite(value) || value < 0) {
        return str;
      }
      if (value > 0xFFFF) {
        value -= 0x10000;
        str += fromCharCode(value >>> 10 & 0x3FF | 0xD800);
        value = 0xDC00 | value & 0x3FF;
      }
      str += fromCharCode(value);
    }
    return str;
  };

  calcHammingDistance = function(a, b) {
    var d, i, k, ref;
    if (a.length !== b.length) {
      return 2e308;
    }
    d = 0;
    for (i = k = 0, ref = a.length; k < ref; i = k += 1) {
      if (a[i] !== b[i]) {
        d += 1;
      }
    }
    return d;
  };

  calcLevenshteinDistance = function(a, b) {
    var delta, i, j, k, l, ref, ref1, temp, vx, vy;
    if (b.length === 0) {
      return a.length;
    }
    if (a.length === 0) {
      return b.length;
    }
    vx = (function() {
      var k, ref, results;
      results = [];
      for (i = k = 0, ref = b.length; k <= ref; i = k += 1) {
        results.push(i);
      }
      return results;
    })();
    vy = new Array(b.length + 1);
    for (i = k = 0, ref = a.length; k < ref; i = k += 1) {
      vy[0] = i + 1;
      for (j = l = 0, ref1 = b.length; l < ref1; j = l += 1) {
        delta = a[i] === b[j] ? 0 : 1;
        vy[j + 1] = Math.min(vy[j] + 1, vx[j + 1] + 1, vx[j] + delta);
      }
      temp = vx;
      vx = vy;
      vy = temp;
    }
    return vx[b.length];
  };

  calcDamerauLevenshteinDistance = function(a, b) {
    var cost, i, j, k, l, ref, ref1, temp, vx, vy, vz;
    if (b.length === 0) {
      return a.length;
    }
    if (a.length === 0) {
      return b.length;
    }
    vx = (function() {
      var k, ref, results;
      results = [];
      for (i = k = 0, ref = b.length; k <= ref; i = k += 1) {
        results.push(i);
      }
      return results;
    })();
    vy = new Array(b.length + 1);
    vz = new Array(b.length + 1);
    for (i = k = 0, ref = a.length; k < ref; i = k += 1) {
      vy[0] = i + 1;
      for (j = l = 0, ref1 = b.length; l < ref1; j = l += 1) {
        cost = a[i] === b[j] ? 0 : 1;
        vy[j + 1] = Math.min(vy[j] + 1, vx[j + 1] + 1, vx[j] + cost, cost !== 0 && i > 0 && j > 0 && a[i - 1] === b[j] && a[i] === b[j - 1] ? vz[j - 1] + 1 : 2e308);
      }
      temp = vx;
      vx = vy;
      vy = vz;
      vz = temp;
    }
    return vx[b.length];
  };

  mkTrie = function(codepoint, value, parent, middle, left, right) {
    if (codepoint == null) {
      codepoint = null;
    }
    if (value == null) {
      value = null;
    }
    if (parent == null) {
      parent = null;
    }
    if (middle == null) {
      middle = null;
    }
    if (left == null) {
      left = null;
    }
    if (right == null) {
      right = null;
    }
    return {
      c: codepoint,
      v: value,
      p: parent,
      m: middle,
      l: left,
      r: right
    };
  };

  erase = function(parent, node) {
    if (!((parent != null) && (node != null))) {
      return;
    }
    node.p = null;
    switch (node) {
      case parent.l:
        parent.l = null;
        break;
      case parent.r:
        parent.r = null;
        break;
      case parent.m:
        parent.m = null;
    }
  };

  replace = function(parent, oldNode, newNode) {
    if (!((parent != null) && (oldNode != null))) {
      return;
    }
    oldNode.p = null;
    if (newNode != null) {
      newNode.p = parent;
    }
    switch (oldNode) {
      case parent.l:
        parent.l = newNode;
        break;
      case parent.r:
        parent.r = newNode;
        break;
      case parent.m:
        parent.m = newNode;
    }
  };

  TernarySearchTrie = (function() {
    function TernarySearchTrie() {
      this.root_ = null;
      this.size_ = 0;
    }

    TernarySearchTrie.prototype.set = function(key, value) {
      var codepoints;
      if (!((key != null) && (value != null))) {
        return this;
      }
      codepoints = toCodePoints(key);
      if (this.root_ == null) {
        this.root_ = mkTrie(codepoints[0]);
      }
      this.insert_(this.root_, codepoints, value);
      return this;
    };

    TernarySearchTrie.prototype.insert_ = function(root, codepoints, value) {
      var branch, c, index, isEqual;
      index = 0;
      while ((root != null) && index < codepoints.length) {
        c = codepoints[index];
        branch = (function() {
          switch (false) {
            case !(c < root.c):
              return 'l';
            case !(c > root.c):
              return 'r';
            default:
              return 'm';
          }
        })();
        isEqual = branch === 'm';
        if (isEqual) {
          index += 1;
        }
        if (isEqual && index === codepoints.length) {
          if (root.v == null) {
            this.size_ += 1;
          }
          root.v = value;
          break;
        }
        if (root[branch] != null) {
          root = root[branch];
        } else {
          root = root[branch] = mkTrie(codepoints[index], null, root);
          index += 1;
          while (index < codepoints.length) {
            root = root.m = mkTrie(codepoints[index], null, root);
            index += 1;
          }
          this.size_ += 1;
          root.v = value;
          break;
        }
      }
    };

    TernarySearchTrie.prototype.get = function(key, splay) {
      var codepoints, node;
      if (splay == null) {
        splay = false;
      }
      if (key == null) {
        return null;
      }
      codepoints = toCodePoints(key);
      node = splay ? this.findAndSplay_(this.root_, codepoints) : this.find_(this.root_, codepoints);
      if ((node != null ? node.v : void 0) != null) {
        return node.v;
      } else {
        return null;
      }
    };

    TernarySearchTrie.prototype.find_ = function(root, codepoints) {
      var branch, c, index, isEqual;
      index = 0;
      while ((root != null) && index < codepoints.length) {
        c = codepoints[index];
        branch = (function() {
          switch (false) {
            case !(c < root.c):
              return 'l';
            case !(c > root.c):
              return 'r';
            default:
              return 'm';
          }
        })();
        isEqual = branch === 'm';
        if (isEqual && index + 1 === codepoints.length) {
          return root;
        }
        root = root[branch];
        if (isEqual) {
          index += 1;
        }
      }
      return null;
    };

    TernarySearchTrie.prototype.del = function(key) {
      var codepoints, node;
      if (key == null) {
        return this;
      }
      codepoints = toCodePoints(key);
      node = this.find_(this.root_, codepoints);
      this.delete_(node);
      return this;
    };

    TernarySearchTrie.prototype.delete_ = function(node) {
      var child, parent;
      if (node == null) {
        return;
      }
      if (node.v != null) {
        node.v = null;
        this.size_ -= 1;
      }
      while (!((node.m != null) || (node.v != null))) {
        if ((node.l != null) && (node.r != null)) {
          return;
        }
        parent = node.p;
        if ((node.l != null) || (node.r != null)) {
          child = node.r || node.l;
          if (parent != null) {
            replace(parent, node, child);
            node = (child.m != null) || (child.v != null) ? parent : child;
          } else {
            this.root_ = child;
            this.root_.p = null;
            node = this.root_;
          }
        } else {
          if (parent != null) {
            erase(parent, node);
            node = parent;
          } else {
            this.root_ = null;
            return;
          }
        }
      }
    };

    TernarySearchTrie.prototype.findAndSplay_ = function(root, codepoints) {
      var branch, c, index, isEqual;
      index = 0;
      while ((root != null) && index < codepoints.length) {
        c = codepoints[index];
        branch = (function() {
          switch (false) {
            case !(c < root.c):
              return 'l';
            case !(c > root.c):
              return 'r';
            default:
              return 'm';
          }
        })();
        isEqual = branch === 'm';
        if (isEqual && index + 1 === codepoints.length) {
          if ((root != null ? root.v : void 0) != null) {
            this.splay_(root);
          }
          return root;
        }
        root = root[branch];
        if (isEqual) {
          index += 1;
        }
      }
      return null;
    };

    TernarySearchTrie.prototype.splay_ = function(node) {
      if (node == null) {
        return;
      }
      while (node.p != null) {
        if (node === node.p.m) {
          node = node.p;
          continue;
        }
        if ((node.p.p == null) || node.p.p.m === node.p) {
          this.rotate_(node.p, node);
        } else {
          if ((node === node.p.l && node.p === node.p.p.l) || (node === node.p.r && node.p === node.p.p.r)) {
            this.rotate_(node.p.p, node.p);
            this.rotate_(node.p, node);
          } else {
            this.rotate_(node.p, node);
            this.rotate_(node.p, node);
          }
        }
      }
    };

    TernarySearchTrie.prototype.rotate_ = function(parent, node) {
      var branch, grandparent;
      if (!((parent != null) && (node != null))) {
        return;
      }
      if (node === parent.l || node === parent.r) {
        grandparent = parent.p;
        if (grandparent != null) {
          branch = (function() {
            switch (parent) {
              case grandparent.l:
                return 'l';
              case grandparent.r:
                return 'r';
              default:
                return 'm';
            }
          })();
          grandparent[branch] = node;
          node.p = grandparent;
        } else {
          this.root_ = node;
          this.root_.p = null;
        }
        if (node === parent.l) {
          parent.l = node.r;
          if (parent.l != null) {
            parent.l.p = parent;
          }
          node.r = parent;
        } else {
          parent.r = node.l;
          if (parent.r != null) {
            parent.r.p = parent;
          }
          node.l = parent;
        }
        parent.p = node;
      } else {
        throw new Error('unknown errors');
      }
    };

    TernarySearchTrie.prototype.size = function() {
      return this.size_;
    };

    TernarySearchTrie.prototype.keys = function() {
      var items;
      items = [];
      this.traverse_(this.root_, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.keysWithPrefix = function(prefix) {
      var items;
      items = [];
      this.searchWithPrefix(prefix, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.searchWithPrefix = function(prefix, callback) {
      var codepoints, root;
      if (prefix.length < 1) {
        return this;
      }
      codepoints = toCodePoints(prefix);
      root = this.find_(this.root_, codepoints);
      if (root == null) {
        return this;
      }
      if (root.v != null) {
        callback(prefix, root.v);
      }
      this.traverse_(root.m, function(key, value) {
        return callback(prefix + key, value);
      });
      return this;
    };

    TernarySearchTrie.prototype.keysWithCommonPrefix = function(key) {
      var items;
      items = [];
      this.searchWithCommonPrefix(key, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.searchWithCommonPrefix = function(key, callback) {
      var prefix;
      if (key.length < 1 || (this.root_ == null)) {
        return this;
      }
      prefix = '';
      this.walk_(this.root_, toCodePoints(key), function(node) {
        prefix += fromCodePoint(node.c);
        if (node.v != null) {
          return callback(prefix, node.v);
        }
      });
      return this;
    };

    TernarySearchTrie.prototype.keysWithinHammingDistance = function(query, distance) {
      var items;
      items = [];
      this.searchWithinHammingDistance(query, distance, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.keysWithinLevenshteinDistance = function(query, distance) {
      var items;
      items = [];
      this.searchWithinLevenshteinDistance(query, distance, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.keysWithinDamerauLevenshteinDistance = function(query, distance) {
      var items;
      items = [];
      this.searchWithinDamerauLevenshteinDistance(query, distance, function(key) {
        return items.push(key);
      });
      return items;
    };

    TernarySearchTrie.prototype.searchWithinHammingDistance = function(query, distance, callback) {
      var a;
      a = toCodePoints(query);
      this.traverse_(this.root_, function(key, value) {
        var b, d;
        b = toCodePoints(key);
        if (a.length !== b.length) {
          return;
        }
        d = calcHammingDistance(a, b);
        if (d <= distance) {
          callback(key, value, d);
        }
      });
      return this;
    };

    TernarySearchTrie.prototype.searchWithinLevenshteinDistance = function(query, distance, callback) {
      var a;
      a = toCodePoints(query);
      this.traverse_(this.root_, function(key, value) {
        var b, d;
        b = toCodePoints(key);
        if (Math.abs(a.length - b.length) > distance) {
          return;
        }
        d = calcLevenshteinDistance(a, b);
        if (d <= distance) {
          callback(key, value, d);
        }
      });
      return this;
    };

    TernarySearchTrie.prototype.searchWithinDamerauLevenshteinDistance = function(query, distance, callback) {
      var a;
      a = toCodePoints(query);
      this.traverse_(this.root_, function(key, value) {
        var b, d;
        b = toCodePoints(key);
        if (Math.abs(a.length - b.length) > distance) {
          return;
        }
        d = calcDamerauLevenshteinDistance(a, b);
        if (d <= distance) {
          callback(key, value, d);
        }
      });
      return this;
    };

    TernarySearchTrie.prototype.traverse = function(callback) {
      return this.traverse_(this.root_, callback);
    };

    TernarySearchTrie.prototype.traverse_ = function(root, callback) {
      var r, t;
      if (root == null) {
        root = this.root_;
      }
      t = this.traversal_(root);
      while (!(r = t.next()).done) {
        callback(r.value.key, r.value.value);
      }
      return this;
    };

    TernarySearchTrie.prototype.traversal = function() {
      return this.traversal_(this.root_);
    };

    TernarySearchTrie.prototype.traversal_ = function(root, callback) {
      var done, ns, prefix, ps;
      if (root == null) {
        root = this.root_;
      }
      if (callback == null) {
        callback = null;
      }
      done = false;
      prefix = '';
      ns = [];
      ps = [];
      return {
        next: function() {
          var result;
          result = {
            value: void 0,
            done: true
          };
          if (done) {
            return result;
          }
          while ((root != null) || ns.length > 0) {
            if (root != null) {
              ns.push(root);
              ps.push(prefix);
              root = root.l;
            } else {
              if (ns.length === 0) {
                break;
              }
              root = ns.pop();
              prefix = ps.pop();
              if (ns.length > 0 && ns[ns.length - 1] === -1) {
                ns.pop();
                root = root.r;
              } else {
                ns.push(-1);
                ns.push(root);
                ps.push(prefix);
                prefix += fromCodePoint(root.c);
                if (root.v != null) {
                  result.done = false;
                  if (callback != null) {
                    result.value = {
                      key: prefix,
                      node: root
                    };
                    result = callback(result);
                  } else {
                    result.value = {
                      key: prefix,
                      value: root.v
                    };
                  }
                  root = root.m;
                  return result;
                } else {
                  root = root.m;
                }
              }
            }
          }
          done = true;
          return result;
        }
      };
    };

    TernarySearchTrie.prototype.walk_ = function(root, codepoints, callback) {
      var branch, c, index, isEqual, next;
      index = 0;
      while ((root != null) && index < codepoints.length) {
        c = codepoints[index];
        branch = (function() {
          switch (false) {
            case !(c < root.c):
              return 'l';
            case !(c > root.c):
              return 'r';
            default:
              return 'm';
          }
        })();
        isEqual = branch === 'm';
        if (isEqual) {
          index += 1;
        }
        next = index < codepoints.length ? root[branch] : null;
        if (isEqual && (callback != null)) {
          callback(root);
        }
        if (index === codepoints.length) {
          return root;
        }
        root = next;
      }
      return null;
    };

    return TernarySearchTrie;

  })();

  if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
    module.exports = TernarySearchTrie;
  } else if (typeof define === 'function' && define.amd) {
    define([], function() {
      return TernarySearchTrie;
    });
  } else {
    this.TernarySearchTrie = TernarySearchTrie;
  }

}).call(this);
