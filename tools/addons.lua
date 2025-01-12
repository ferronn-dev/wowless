local github = {
  ['ferronn-dev/ferronnizer'] = 'Ferronnizer.zip',
  ['ferronn-dev/olliverrstravels'] = 'OlliverrsTravels.zip',
  ['lethay/talentedclassic'] = 'Talented*.zip',
  ['nevcairiel/bartender4'] = 'Bartender4*.zip',
  ['questie/questie'] = 'Questie*.zip',
}
os.execute((assert(require('pl.template').substitute(
  [[
set -ex
mkdir extracts/addonzips
mkdir -p extracts/addons
> for repo, pattern in pairs(github) do
gh release download -R $(repo) -D extracts/addonzips -p "$(pattern)"
> end
unzip -q -o -d extracts/addons 'extracts/addonzips/*'
rm -rf extracts/addonzips
]],
  { _escape = '>', github = github, pairs = pairs }
))))
