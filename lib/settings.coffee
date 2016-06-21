Q       = require 'q'
_       = require 'underscore'
cookie  = require 'tiny-cookie'
merge   = require 'deepmerge'

###

  Input on of those
  * data          object
  * selectorId    string | script tag id without #
  * cookieKey     string | key of the cookie entry

  Optional:
  * defaults      object            default: {}
  * base64        true|false        default: false
  * removeAfterParse true|false     default: true

###
module.exports = class Settings

  options:  null
  settings: null

  constructor: (options = {}) ->
    if !@_isValidDataObj(options.data) && !@_isValidString(options.selectorId) &&
       !@_isValidString(options.cookieKey)
      throw('Settings needs one data, cookieKey or selectorId option.')

    @options  = merge @_getDefaultOptions(), options
    @settings = {}

    @_loadData()

  parse: ->
    @settings = if _.isString(@settings) then @_handleString(@settings) else (@settings || {})
    @settings = merge (@options.defaults || {}), @settings

    @_clearContent() if @options.removeAfterParse == true

    Q()

  get: (key) ->
    v = @settings[key]
    return v if v?

    @_getForDotNotation(@settings, key)


  # ---------------------------------------------
  # private

  # @nodoc
  _isValidDataObj: (data) ->
    return true if @_isValidString(data)

    _.isObject(data)

  # @nodoc
  _isValidString: (string) ->
    return false unless _.isString(string)

    string.length > 0 && string != ' '


  # @nodoc
  _getDefaultOptions: ->
    defaults:         {}
    base64:           false
    removeAfterParse: true

  # @nodoc
  _loadData: ->
    if @options.data
      @settings = @options.data
    else if @options.cookieKey
      @settings = cookie.get(@options.cookieKey) || {}
      @settings = {} if @settings == 'null'
    else if @options.selectorId
      @settings = document.getElementById(@options.selectorId).textContent

  # @nodoc
  _handleString: (str) ->
    str = str.replace(/\s|\n/g, '')

    try
      str = JSON.parse(str)
    catch e
      str = atob(str)
      str = JSON.parse(str)

    str

  # @nodoc
  _clearContent: ->
    @_clearCookieContent()
    @_clearDomContent()

  # @nodoc
  _clearCookieContent: ->
    return unless _.isString(@options.cookieKey)

    cookie.set(@options.cookieKey, null)

  # @nodoc
  _clearDomContent: ->
    return unless _.isString(@options.selectorId)

    document.getElementById(@options.selectorId).textContent = ''

  # @nodoc
  _getForDotNotation: (obj, key) ->
    return null unless _.isString(key)
    return null unless key.length > 0

    keyArr  = key.split('.')
    key     = keyArr.shift()
    obj     = obj[key]

    return obj if !_.any(keyArr) && obj?
    return null unless _.isObject(obj)

    @_getForDotNotation(obj, keyArr.join('.'))
