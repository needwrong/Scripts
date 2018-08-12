// ver 1.0
// author: NearEast 2018-07-27, modified from https://gist.github.com/bang590/8f3e9704f1c2661836cd
// usage: node linkmap.js filepath -hlp
// Desc: resolve linkmap file, to find out how heavy each part takes in your binary

var readline = require('readline'),
    fs = require('fs');

var LinkMap = function(filePath) {
	this.files = [];
	this.filePath = filePath;
	this.sum = 0.0;
}

LinkMap.prototype = {
	start: function(cb) {
		var self = this;
		var rl = readline.createInterface({
		    input: fs.createReadStream(self.filePath),
		    output: process.stdout,
		    terminal: false
		});
		var currParser = "";
		rl.on('line', function(line) {
			if (line[0] == '#') {
				if (line.indexOf('Object files') > -1) {
					currParser = "_parseFiles";
				} else if (line.indexOf('Sections') > -1) {
					currParser = "_parseSection";
				} else if (line.indexOf('Symbols') > -1) {
					currParser = "_parseSymbols";
				}
				return;
			}
			if (self[currParser]) {
				self[currParser](line);
			}
		});


		rl.on('close', function(line) {
			cb(self);
		});
	},

	_parseFiles: function(line) {
		var arr = line.split(']');
		if (arr.length > 1) {
			var idx = Number(arr[0].replace('[',''));
			var file = arr[1].split('/').pop().trim();
			this.files[idx] = {
				name: file,
				size: 0,
				percentage: ''
			};
		}
	},

	_parseSection: function(line) {
	},

	_parseSymbols: function(line) {
		var arr = line.split('\t');
		if (arr.length > 2) {
			var size = parseInt(arr[1], 16);
			var idx = Number(arr[2].split(']')[0].replace('[', ''));

			if (idx && this.files[idx]) {
				this.sum += size;
				this.files[idx].size += size;
			}
		}
	},

	_formatSize: function(size) {
		if (size > 1024 * 1024) return (size/(1024*1024)).toFixed(2) + "MB";
		if (size > 1024) return (size/1024).toFixed(2) + "KB";
		return size + "B";
	},

	statLibs: function(h, p) {
		var libs = {};
		var files = this.files;
		var self = this;
		for (var i in files) {
			var file = files[i];
			var libName;
			if (file.name.indexOf('.o)') > -1) {//libQRCode.a(QRCode.o)
				libName = file.name.split('(')[0];
			} else {//BaiduWallet_Portal;//GPUImageSharpenFilter.o
				libName = file.name;
			}
			if (!libs[libName]) {
				libs[libName] = 0;
			}
			libs[libName] += file.size;
		}
		var i = 0, sortLibs = [];
		for (var name in libs) {
			sortLibs[i++] = {
				name: name,
				size: libs[name],
				percentage: ''
			}
		}
		return this.sortAndFormat(sortLibs, h, p);
	},

	statFiles: function(h, p) {
		return this.sortAndFormat(this.files, h, p);
	},

	sortAndFormat:function(data, h, p) {
		var self = this;
		data.sort(function(a,b) {
			return a.size > b.size ? -1 : 1;
		})

		if (h || p) {
			data.map(function(o) {
				if (self.sum && p) {
					o.percentage = (100 * o.size / self.sum).toFixed(3) + "%";
				}
				if (h) {
					o.size = self._formatSize(o.size);
				}
			})
		}
		return data;
	}
}

if (!process.argv[2]) {
	console.log('usage: node linkmap.js filepath -hlp');
	console.log('-h: format size');
	console.log('-l: stat libs');
	console.log('-p: print percentage');
	return;
}
var isStatLib, isFomatSize, showPercentage;
var opts = process.argv[3];
if (opts && opts[0] == '-') {
	if (opts.indexOf('h') > -1) isFomatSize = true;
	if (opts.indexOf('l') > -1) isStatLib = true;
	if (opts.indexOf('p') > -1) showPercentage = true;
}

var linkmap = new LinkMap(process.argv[2]);
linkmap.start(function(){
	var ret = isStatLib ? linkmap.statLibs(isFomatSize, showPercentage) 
	                    : linkmap.statFiles(isFomatSize, showPercentage);
	console.log('Total stat binary size: ' + linkmap._formatSize(linkmap.sum) + '\n');
	for (var i in ret) {
		var text = ret[i].name + '\t' + ret[i].size;
		if (showPercentage) {
			text += ('\t' + ret[i].percentage);
		}
		console.log(text);
	}
})