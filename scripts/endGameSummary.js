'use strict';

// endGameSummary.js
// https://github.com/Loathing-Associates-Scripting-Society/kolmafia-scripts
// https://github.com/docrostov/kol-js-starter

require('https://code.jquery.com/jquery.min.js');
var $ = require("https://code.jquery.com/jquery.min.js");
var kolmafia = require('kolmafia');
var zlib_ash = require('zlib.ash');


/**
 * @file Provides methods for logging colored text.
 */
function error(message) {
    zlib_ash.vprint(message, kolmafia.isDarkMode() ? '#ff0033' : '#cc0033', 1);
}
function warn(message) {
    zlib_ash.vprint(message, kolmafia.isDarkMode() ? '#cc9900' : '#cc6600', 2);
}
function info(message) {
    zlib_ash.vprint(message, kolmafia.isDarkMode() ? '#0099ff' : '3333ff', 3);
}
function success(message) {
    zlib_ash.vprint(message, kolmafia.isDarkMode() ? '#00cc00' : '#008000', 2);
}
function debug(message) {
    zlib_ash.vprint(message, '#808080', 6);
}


/**
 * Check if your character is in Ronin/Hardcore. If so, ask for confirmation to
 * @return Whether Philter should be executed now
 */
function printTurnsSpent(turnsSpent) {
}


function main() {
// 	var aPage = kolmafia.visitUrl("clan_raidlogs.php");
// 	var m = kolmafia.createMatcher("Your clan has defeated <b>([\\d,]*)</b> monster\\\(s\\\) in the ([\\w]+)", aPage);
// 	while (kolmafia.find(m)) {
// 		var killCount = kolmafia.group(m, 1);
// 		var locString = kolmafia.group(m, 2);
// 		kolmafia.print(locString + ": " + killCount);
// 	}
}

exports.main = main;
