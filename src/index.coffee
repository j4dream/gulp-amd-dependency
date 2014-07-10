fs = require 'fs'
path = require 'path'
gutil = require 'gulp-util'
through = require 'through2'

module.exports = (opt = {}) ->
	got = {}
	scanned = {}
	through.obj (file, enc, next) ->
		return @emit 'error', new gutil.PluginError('gulp-amd-dependency', 'File can\'t be null') if file.isNull()
		return @emit 'error', new gutil.PluginError('gulp-amd-dependency', 'Streams not supported') if file.isStream()
		return next() if scanned[file.path]
		if opt.excludeDependent
			got[file.path] = 1
		scanned[file.path] = 1
		deps = []
		content = file.contents.toString 'utf-8'
		depArr = content.match /(?:^|[^.]+?)\bdefine\s*\([^\[\{]*(\[[^\[\]]*\])/m
		depArr = depArr && depArr[1]
		depArr && depArr.replace /(["'])(\.[^"']+?)\1/mg, (full, quote, dep) ->
			dep = path.resolve path.dirname(file.path), dep
			got[dep] || deps.push dep
			got[dep] = 1
		content.replace /(?:^|[^.]+?)\brequire\s*\(\s*(["'])(\.[^"']+?)\1\s*\)/mg, (full, quote, dep) ->
			dep = path.resolve path.dirname(file.path), dep
			got[dep] || deps.push dep
			got[dep] = 1
		deps.forEach (filePath) =>
			if not (/\.tpl\.html$/).test filePath
				if fs.existsSync filePath + '.coffee'
					filePath = filePath + '.coffee'
				else
					filePath = filePath + '.js'
			newFile = new gutil.File
				base: file.base
				cwd: file.cwd
				path: filePath
				contents: fs.readFileSync filePath
			@push newFile
			if not scanned[filePath]
				@write newFile
		next()
