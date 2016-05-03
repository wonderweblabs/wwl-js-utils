# WWL JS Utils

| Current Version | Master | Develop |
|-----------------|--------|---------|
| [![npm version](https://badge.fury.io/js/wwl-js-utils.svg)](https://badge.fury.io/js/wwl-js-utils) | [![Build Status](https://travis-ci.org/wonderweblabs/wwl-js-utils.svg?branch=master)](https://travis-ci.org/wonderweblabs/wwl-js-utils) | [![Build Status](https://travis-ci.org/wonderweblabs/wwl-js-utils.svg?branch=develop)](https://travis-ci.org/wonderweblabs/wwl-js-utils) |

---


## settings

Loading configurations/settings over cookie or script tag or by passing in the config directly.

### Options

```coffeescript
new (require('wwl-js-utils/lib/settings'))({
  # one of those is required:
  data:         { test: 1 }
  cookieKey:    'id-of-config-cookie-key'
  selectorId:   'id-of-config-script-tag'

  # optional:
  defaults:     { some: 'defaults' }    # default: {}
  base64:       false                   # default: false
  removeAfterParse: true                # default: true
})
```

If you pass in ```data```, ```selectorId``` and ```cookieKey```, ```data``` will be used. If you pass ```selectorId``` and ```cookieKey```, ```cookieKey``` will be used.

### Getting config attributes

```coffeescript
data =
  a:
    b: 1
    c:
      d: '2'
    e:
      f: 4
      g: false

config = new (require('wwl-js-utils/settings'))({ data: data })

config.get('a').b     # 1
config.get('a').c.d   # '2'
config.get('a').e.f   # 4
config.get('a').e.g   # false
config.get('a.b')     # 1
config.get('a.c.d')   # '2'
config.get('a.e.f')   # 4
config.get('a.e.g')   # false

```
