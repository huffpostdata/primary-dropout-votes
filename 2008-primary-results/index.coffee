fs = require('fs')

cheerio = require('cheerio')
request = require('sync-request')

STATES = 'AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY'.split(' ')
PARTIES = { R: 'GOP', D: 'Dem' }
MONTHS = {
  January: '01',
  February: '02',
  March: '03',
  April: '04',
  May: '05',
  June: '06',
  July: '07',
  August: '08',
  September: '09',
  October: '10',
  November: '11',
  December: '12'
}
HEADERS = 'PopularVote,Floor Vote,PopularVote(Supporters),CountyConventionDelegatesElected,StateConventionDelegatesSelected,StateDelegates,CaucusPopularVote,CountyDelegates,PercentageVote'.split(',')

get_html = (year, state, party) ->
  filename = "cache/#{year}-#{state}-#{party}.html"
  try
    fs.readFileSync(filename, 'utf-8')
  catch e
    throw e if e.code != 'ENOENT'

    year_code = year == '2000' && 'CC' || year[2..4]
    ext = year == '2000' && 'html' || 'phtml'

    url = "http://www.thegreenpapers.com/P#{year_code}/#{state}-#{party}.#{ext}"
    console.log("GET #{url}")
    res = request('GET', url)
    fs.writeFileSync(filename, res.getBody(), 'utf-8')
    fs.readFileSync(filename, 'utf-8')

parse_date_phtml = (ugly_text) ->
  arr = ugly_text.split(/:\s*/)[1].split(/\s/)
  yyyy = arr[arr.length - 1][0...4]
  mm = MONTHS[arr[2]]
  throw new Error("Invalid month #{arr[2]} in ugly date #{ugly_text}") if !mm?
  dd = (100 + parseInt(arr[1], 10)).toString().slice(1)
  "#{yyyy}-#{mm}-#{dd}"

parse_date_html = (ugly_text) ->
  arr = ugly_text.split(/:\s*/)[1].split(/\s/)
  yyyy = arr[arr.length - 1][0...4]
  mm = MONTHS[arr[1]]
  throw new Error("Invalid month #{arr[2]} in ugly date #{ugly_text}") if !mm?
  dd = (100 + parseInt(arr[2], 10)).toString().slice(1)
  "#{yyyy}-#{mm}-#{dd}"

parse_n_votes = (ugly_text) ->
  if /^\s*$/.test(ugly_text)
    0
  else
    m = /\s*([\d,]+).*/.exec(ugly_text)
    throw new Error("Invalid vote count #{ugly_text}") if !m?
    parseInt(m[1].replace(/,/g, ''), 10)

parse_candidate = (ugly_text) ->
  m = /\s*(.*?)(?:,.*)?$/.exec(ugly_text)
  throw new Error("Invalid candidate #{ugly_text}") if !m?
  m[1].toLowerCase().replace(/[^-a-z0-9]+/g, '-')

dump_data = (year, state, party, html) ->
  if year == '2000'
    dump_data_html(year, state, party, html)
  else
    dump_data_phtml(year, state, party, html)

dump_data_html = (year, state, party, html) ->
  id = "#{year}-#{state}-#{party}"

  $ = cheerio.load(html)

  b = $('thead font[size=2] b').eq(0)
  throw new Error("Could not find <b> in HTML for #{id}") if !b?
  date = parse_date_html(b.text())

  total = $('tr.total td#w000 b').eq(0)
  throw new Error("Could not find totals for #{id}") if !total?
  total = parse_n_votes(total.text())

  if total == 0
    # don't print anything
  else
    trs = $('tbody tr.data')
    for tr in trs
      th = $(tr).find('th').eq(0)
      candidate_text = th.text()
      td = $(tr).find('td#w000').eq(0)
      n_votes_text = td.text()
      candidate = parse_candidate(candidate_text)
      n_votes = parse_n_votes(n_votes_text)

      console.log([ year, PARTIES[party], state, date, candidate, n_votes, total ].join(','))

dump_data_phtml = (year, state, party, html) ->
  id = "#{year}-#{state}-#{party}"
  return if id == '2004-CT-R' # cancelled
  return if id == '2004-FL-R' # cancelled
  return if id == '2004-MS-R' # cancelled
  return if id == '2004-SD-R' # cancelled

  $ = cheerio.load(html)

  evtmaj = $('#evtmaj').eq(0)
  throw new Error("Could not find evtmaj in HTML for #{id}") if evtmaj.length == 0
  date = parse_date_phtml(evtmaj.text())

  tdnb = $('#tdnb').eq(0)
  throw new Error("Could not find totals for #{year}-#{state}-#{party}") if !tdnb?
  total = parse_n_votes(tdnb.next().text())

  if total == 0
    # don't print anything
  else
    trs = tdnb.parent().siblings() # Cheerio returns these in arbitrary order
    for tr in trs
      $children = $(tr).children()
      continue if $children.eq(0).attr('id') != 'tdnn' # Skip header rows
      candidate_text = $children.eq(0).text()
      n_votes_text = $children.eq(1).text()
      candidate = parse_candidate(candidate_text)
      n_votes = parse_n_votes(n_votes_text)

      console.log([ year, PARTIES[party], state, date, candidate, n_votes, total ].join(','))

for year in [ '2000', '2004', '2008' ]
  for state in STATES
    for party in Object.keys(PARTIES)
      html = get_html(year, state, party)
      dump_data(year, state, party, html)
