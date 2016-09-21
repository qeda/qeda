#!/usr/bin/env node

'use strict';

if (process.platform == 'linux') {
  var sys = require('util');
  var exec = require('child_process').exec;
  var child;

  child = exec("cp scripts/qeda /etc/bash_completion.d/qeda", function (error, stdout, stderr) {
    if (error !== null) {
      console.log('Warning: ' + stderr);
    } else {
      console.log('stdout: ' + stdout);
    }
  });
}
