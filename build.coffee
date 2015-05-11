#!/usr/bin/env coffee

fs    = require 'fs'
exec  = require('child_process').exec
chalk = require('chalk')

# repos are
# https://github.com/ttscoff/ubersicht-widgets.git
# https://github.com/Pe8er/uWidgets-Distribution.git
# https://github.com/dalemanthei/uebersicht-widgets.git
# https://github.com/mortensieker/ubersicht.git

repos = ['uebersicht-widgets', 'ttscoff-uebersicht-widgets',
        'Pe8er-uebersicht-widgets', 'dalemanthei-uebersicht-widgets',
        'mortensieker-uebersicht-widgets']

noUpdate = process.argv[2] == "-q"

build = ->
  widgetJSON = ["{\"widgets\":["]
  done = ->
    file = fs.createWriteStream('widgets.json')
    file.write chunk for chunk in widgetJSON
    file.end "]}"
    console.log chalk.green 'done'

  fromRepoIdx = (idx) ->
    console.log 'getting widgets from', repos[idx]
    gatherWidgesFromRepo repos[idx], widgetJSON, ->
      return done() if idx == repos.length-1
      widgetJSON.push ","
      fromRepoIdx idx+1

  fromRepoIdx 0

gatherWidgesFromRepo = (repo, widgetJSON, callback) ->
  pullChanges repo, ->
    getTree 'master', cwd: repo, (tree) ->
      getAndWriteWidgets tree, repo, widgetJSON, callback


getAndWriteWidgets = (dirTree, repo, widgetJSON, callback) ->
  written = 0

  writeAndNext = (idx, next) -> (w) ->
    return next(idx+1) unless w

    writeWidget widgetJSON, w, (if written > 0 then ',' else ''), ->
      console.log chalk.green "ok"
      written++
      next idx+1

  parseDirEntry = (idx) ->
    return callback() unless (entry = dirTree[idx])?
    buildWidget entry, repo, writeAndNext(idx, parseDirEntry)

  parseDirEntry(0)

buildWidget = (entry, repo, callback) ->
  manifest = null
  modDate  = null
  repoInfo = null
  widgetId = entry.path

  root = path = sha = null
  isSubmodule = false
  # submodule
  if entry.mask == '160000'
    root = repo+'/'+entry.path
    path = '.'
    sha  = 'master'
    isSubmodule = true
  # subfolder
  else if entry.type == 'tree'
    sha  = entry.sha
    root = repo
    path = entry.path
  else
    return callback()

  process.stdout.write chalk.blue(" » ") + widgetId + ' .. '

  bail = (reason) ->
    console.log chalk.red "fail"
    console.log chalk.red "   " + reason
    callback()

  combineData = ->
    return unless manifest and modDate and repoInfo

    callback
      id            : widgetId
      name          : manifest.name
      author        : manifest.author
      user          : repoInfo.user
      repo          : repoInfo.name
      description   : manifest.description
      screenshotUrl : repoInfo.screenshotUrl
      downloadUrl   : repoInfo.downloadUrl
      repoUrl       : if isSubmodule then repoInfo.repoUrl else ghFolderUrl(repoInfo.repoUrl, path)
      modifiedAt    : modDate

  getTree sha, cwd: root, (widgetDir) ->
    return bail "could not read widget dir" unless widgetDir
    paths = parseWidgetDir widgetDir

    return bail "could not find screenshot" unless paths.screenshotPath
    return bail "could not find manifest"   unless paths.manifestPath
    return bail "could not find zip file"   unless paths.zipPath

    getUserRepo cwd: root, (user, repo) ->
      return bail "could not retrieve repo info" unless user and repo
      repoInfo =
        user         : user
        name         : repo
        downloadUrl  : ghRawUrl user, repo, "#{path}/#{paths.zipPath}"
        screenshotUrl: ghRawUrl user, repo, "#{path}/#{paths.screenshotPath}"
        repoUrl      : ghUrl user, repo
      combineData()

    getModDate "#{path}/#{paths.zipPath}", cwd: root, (date) ->
      return bail "could not get last mod date" unless date
      modDate = date
      combineData()

    getManifest "#{path}/#{paths.manifestPath}", cwd: root, (man) ->
      return bail "could not read manifest" unless man
      manifest = man
      combineData()

parseWidgetDir = (dirTree, dirPath) ->
  paths = {}

  for entry in dirTree
    if entry.path.indexOf('widget.json') > -1
      paths.manifestPath = entry.path
    else if /screenshot/i.test(entry.path)
      paths.screenshotPath = entry.path
    else if entry.path.indexOf('widget.zip') > -1
      paths.zipPath  = entry.path

  paths

getManifest = (path, options, callback) ->
  fs.readFile "#{options.cwd}/#{path}", (err, contents) ->
    bail(err) if err
    callback JSON.parse(contents ? 'null')

  # saveExec "git show master:#{path}", options, (contents) ->
  #   callback JSON.parse(contents ? 'null')

getModDate = (path, options, callback) ->
  saveExec "git log -1 --format=\"%ad\" master -- #{path}", options, (stdout) ->
    return callback() unless stdout
    callback new Date(stdout).getTime()

getUserRepo = (options, callback) ->
  saveExec "git remote -v | tail -n 1", options, (stdout) ->
    return callback() unless stdout

    [junk, userAndRepo] = stdout.split(/\s/)[1].split('github.com')
    userAndRepo  = userAndRepo[1..]
    [user, repo] = userAndRepo.split('/') if userAndRepo
    repo = repo.replace(/\.git$/g, '') if repo
    callback user, repo

writeWidget = (widgetJSON, widget, sep, callback) ->
  widgetJSON.push sep+JSON.stringify(widget)
  callback()

pullChanges = (repo, callback) ->
  return callback() if noUpdate
  cmd = "git pull --recurse-submodules && \
         git submodule update --init --remote --merge --recursive"

  exec cmd, cwd: repo, (err, stdout, stderr) ->
    if err
      console.log 'ERROR:', err
    else
      console.log stdout or stderr
      callback()

getTree = (treeish, options, callback) ->
  saveExec "git ls-tree #{treeish}", options, (output) ->
    callback() unless output
    lines = output.split '\n'

    entries = (for line in lines when line
      [mask, type, sha, path] = line.split(/\s+/)
      mask: mask, type: type, sha: sha, path: path
    )

    callback entries

ghFolderUrl = (repo, path) ->
  "#{repo}/tree/master/#{path}"

ghRawUrl = (user, repo, path) ->
  "https://raw.githubusercontent.com/#{user}/#{repo}/master/#{path}"

ghUrl = (user, repo) ->
  "https://github.com/#{user}/#{repo}"

saveExec = (cmd, options, callback) ->
  exec cmd, options, (err, output, stderr) ->
    if err or stderr
      console.log(err ? stderr)
      callback()
    else
      callback(output)

build()
