# FIXME: gulpfile.coffee is currently not auto-compiled into JS. Do this
#        manually with coffee -c gulpfile.coffee
gulp = require 'gulp'
gutil = require 'gulp-util'

coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
sass = require 'gulp-sass'

connect = require 'connect'
http = require 'http'
path = require 'path'

# Starts the webserver (http://localhost:3000)
gulp.task 'webserver', ->
    port = 3000
    hostname = null # allow to connect from anywhere
    base = path.resolve './dist'
    directory = path.resolve './dist'

    app = connect()
        .use(connect.static base)
        .use(connect.directory directory)

    http.createServer(app).listen port, hostname

# Compiles CoffeeScript files into js file
# and reloads the page
gulp.task 'scripts', ->
    gulp.src('app/**/*.coffee')
        .pipe(concat 'app.coffee')
        .pipe(do coffee)
        .pipe(gulp.dest 'dist')

# Compiles Sass files into css file
# and reloads the styles
gulp.task 'styles', ->
    gulp.src('app/app.scss')
        .pipe(sass includePaths: ['app'])
        .pipe(concat 'app.css')
        .pipe(gulp.dest 'dist')

# The default task
gulp.task 'default', ->
    gulp.run 'webserver', 'scripts', 'styles'

    # Watches files for changes
    gulp.watch 'app/**/*.coffee', ->
        gulp.run 'scripts'

    gulp.watch 'app/**/*.scss', ->
        gulp.run 'styles'
