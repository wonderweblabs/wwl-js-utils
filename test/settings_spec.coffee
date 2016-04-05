expect  = require('chai').expect
jsdom   = require('mocha-jsdom')
cookie  = require 'tiny-cookie'

describe 'context/default', ->

  Settings = require('../src/settings')

  # ------------------------------------------------------------------
  describe '#constructor', ->

    it 'should raise error for missing selectorId, cookieKey and data', ->
      expect(-> new Settings()).to.throw()

    it 'should raise error for data not an object', ->
      expect(-> new Settings({ data: 1 })).to.throw()
      expect(-> new Settings({ data: 'test' })).to.not.throw()
      expect(-> new Settings({ data: {} })).to.not.throw()

    it 'should raise error for selectorId not or empty string', ->
      expect(-> new Settings({ selectorId: 1 })).to.throw()
      expect(-> new Settings({ selectorId: {} })).to.throw()
      expect(-> new Settings({ selectorId: '' })).to.throw()
      expect(-> new Settings({ selectorId: ' ' })).to.throw()

    it 'should raise error for cookieKey not or empty string', ->
      expect(-> new Settings({ cookieKey: 1 })).to.throw()
      expect(-> new Settings({ cookieKey: {} })).to.throw()
      expect(-> new Settings({ cookieKey: '' })).to.throw()
      expect(-> new Settings({ cookieKey: ' ' })).to.throw()
      expect(-> new Settings({ cookieKey: 'test' })).to.not.throw()

  # ------------------------------------------------------------------
  describe 'defaults', ->

    it 'should be base64 false', ->
      s = new Settings({ cookieKey: 'test' })
      expect(s.options.base64).to.be.false

    it 'should be removeAfterParse true', ->
      s = new Settings({ cookieKey: 'test' })
      expect(s.options.removeAfterParse).to.be.true

  # ------------------------------------------------------------------
  describe '#parse', ->

    it 'should return promise', ->
      s       = new Settings({ cookieKey: 'test' })

      expect(-> s.parse() ).to.not.throw()

    it 'should decode base64', ->
      str = btoa('{"test":1,"server":"https://example.com"}')
      s   = new Settings({ data: str, base64: true })

      s.parse().then =>
        expect(s.settings).to.be.an('object')
        expect(s.settings.test).to.eql(1)
        expect(s.settings.server).to.eql('https://example.com')

    it 'should decode base64 line separators', ->
      str = "eyJ0ZXN0IjoxLCJzZX
      J2ZXIiOiJodHRwczovL2V
      4YW1wbGUuY29tIn0=

      "
      s   = new Settings({ data: str, base64: true })

      s.parse().then =>
        expect(s.settings).to.be.an('object')
        expect(s.settings.test).to.eql(1)
        expect(s.settings.server).to.eql('https://example.com')

    it 'should merge with defaults', ->
      data      = { a: 1, b: '2', c: true, d: true }
      defaults  = { a: 100, d: false, e: 10000 }
      s         = new Settings({ data: data, defaults: defaults })

      s.parse().then =>
        expect(s.settings.a).to.eql(1)
        expect(s.settings.b).to.eql('2')
        expect(s.settings.c).to.eql(true)
        expect(s.settings.d).to.eql(true)
        expect(s.settings.e).to.eql(10000)

    it 'should deep merge with defaults', ->
      data      = { a: { b: 1, c: { d: '2' }, e: { f: 4, g: false } } }
      defaults  = { a: { e: { f: false, h: false } } }
      s         = new Settings({ data: data, defaults: defaults })

      s.parse().then =>
        expect(s.settings.a).to.be.an('object')
        expect(s.settings.a.b).to.eql(1)
        expect(s.settings.a.c).to.be.an('object')
        expect(s.settings.a.c.d).to.eql('2')
        expect(s.settings.a.e).to.be.an('object')
        expect(s.settings.a.e.f).to.eql(4)
        expect(s.settings.a.e.g).to.eql(false)
        expect(s.settings.a.e.h).to.eql(false)

    describe 'for selectorId', ->

      jsdom({ useEach: true })

      beforeEach ->
        document.head.innerHTML = "
          <script id='my-config'>
            eyJ0ZXN0IjoxLCJzZX
            J2ZXIiOiJodHRwczovL2V
            4YW1wbGUuY29tIn0=
          </script>
        "
      it 'should find dom element and parse the content', ->
        s = new Settings({ selectorId: 'my-config', base64: true })

        s.parse().then =>
          expect(s.settings).to.be.an('object')
          expect(s.settings.test).to.eql(1)
          expect(s.settings.server).to.eql('https://example.com')

      it 'with removeAfterParse:true should remove dom element afterwards', ->
        s = new Settings({ selectorId: 'my-config', base64: true, removeAfterParse: true })

        s.parse().then =>
          l = document.getElementById('my-config').textContent.length
          expect(l).to.eql(0)

    describe 'for cookieKey', ->

      beforeEach ->
        cookie.set 'my-config', '
          eyJ0ZXN0IjoxLCJzZX
          J2ZXIiOiJodHRwczovL2V
          4YW1wbGUuY29tIn0=
        '

      it 'should parse content in cookieKey', ->
        s = new Settings({ cookieKey: 'my-config', base64: true })

        s.parse().then =>
          expect(s.settings).to.be.an('object')
          expect(s.settings.test).to.eql(1)
          expect(s.settings.server).to.eql('https://example.com')

      it 'with removeAfterParse:true should clear cookie key', ->
        s = new Settings({ cookieKey: 'my-config', base64: true, removeAfterParse: true })

        s.parse().then =>
          expect(cookie.get('my-config')).to.eql('null')

  # ------------------------------------------------------------------
  describe '#get', ->

    s = null

    beforeEach (cb) ->
      data  = { a: { b: 1, c: { d: '2' }, e: { f: 4, g: false } } }
      s     = new Settings({ data: data })
      s.parse().then(-> cb())

    it 'should return attributes for root keys', ->
      expect(s.get('a').b).to.eql(1)
      expect(s.get('a').c.d).to.eql('2')
      expect(s.get('a').e.f).to.eql(4)
      expect(s.get('a').e.g).to.eql(false)

    it 'should return nested keys for dot notation', ->
      expect(s.get('a.b')).to.eql(1)
      expect(s.get('a.c.d')).to.eql('2')
      expect(s.get('a.e.f')).to.eql(4)
      expect(s.get('a.e.g')).to.eql(false)

