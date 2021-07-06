rockspec_format = '3.0'
package = 'wowless'
version = 'scm-0'
source = {
  url = 'git://github.com/ferronn-dev/wowless',
}
dependencies = {
  'lua = 5.1',
  'bitlib',
  'datafile',
  'lua-path',
  'lua-resty-tsort',
  'serpent',
  'xml2lua',
}
build = {
  type = 'none',
  install = {
    lua = {
      ['wowless.api'] = 'wowless/api.lua',
      ['wowless.env'] = 'wowless/env.lua',
      ['wowless.globalstrings'] = 'wowless/globalstrings.lua',
      ['wowless.loader'] = 'wowless/loader.lua',
      ['wowless.runner'] = 'wowless/runner.lua',
      ['wowless.util'] = 'wowless/util.lua',
      ['wowless.xml'] = 'wowless/xml.lua',
      ['wowless.xmllang'] = 'wowless/xmllang.lua',
    },
  },
  copy_directories = {
    'wowui',
  },
}
