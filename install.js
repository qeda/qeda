if(process.platform=='linux'){

var sys = require('util');
var exec = require('child_process').exec;
var child;

child = exec("cp src/qeda /etc/bash_completion.d/qeda", function (error, stdout, stderr) {
  console.log('stdout: ' + stdout);
  console.log('stderr: ' + stderr);
  if (error !== null) {
    console.log('exec error: ' + error);
  }
});

}


