local t = require('wowapi.yaml').parseFile('frame0.yaml')
require('wowless.render').render(t, 1280, 720, 'localhost:8080', 'extracts/wow_classic_era', 'frame0.png')
