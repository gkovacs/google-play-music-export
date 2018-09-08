require! {
  yargs
  fs
  path
}

sqlite3 = require 'better-sqlite3'

{exec, mkdir} = require 'shelljs'

main = ->
  argv = yargs
  .option('musicdb', {
    describe: 'the music.db file usually located at /data/data/com.google.android.music/databases/music.db'
    default: '/data/data/com.google.android.music/databases/music.db'
  })
  .option('musicfiles', {
    describe: 'the music folder usually located at /data/data/com.google.android.music/files/music'
    default: '/data/data/com.google.android.music/files/music'
  })
  .option('output', {
    describe: 'the music folder to write tagged mp3 files to'
    default: 'music-export'
  })
  .strict()
  .argv
  if not fs.existsSync(argv.musicdb)
    console.log 'could not find music database at ' + argv.musicdb
    return
  if not fs.existsSync(argv.musicfiles)
    console.log 'could not find music files at ' + argv.musicfiles
    return
  db = new sqlite3(argv.musicdb)
  rows = db.prepare('SELECT * FROM MUSIC').all()
  if not fs.existsSync(argv.output)
    mkdir '-p', argv.output
  for row in rows
    filename = row.LocalCopyPath
    title = row.Title
    artist = row.Artist
    if not filename?
      continue
    if not title?
      title = 'Unknown'
    if not artist?
      artist = 'Unknown'
    filepath = path.join argv.musicfiles, filename
    if not fs.existsSync(filepath)
      console.log 'skipping file which does not exist: ' + filepath
      continue
    outfilename = artist + ' - ' + title + '.mp3'
    outfilepath = path.join argv.output, outfilename
    disambiguation_suffix = 1
    while fs.existsSync outfilepath
      outfilename = artist + ' - ' + title + '_' + disambiguation_suffix + '.mp3'
      outfilepath = path.join argv.output, outfilename
      disambiguation_suffix += 1
    exec "ffmpeg -i '#{filepath}' -acodec copy -vn -metadata title='#{title}' -metadata artist='#{artist}' '#{outfilepath}'"

main()