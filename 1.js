// mymodule.js
var parser = require("./basic").parser;

function exec (input) {
    return parser.parse(input);
}

//var v = exec("10 LET A = 2 + 10000 + 20");
//var v = exec("20 PRINT 100");
//console.log("v = " + v);

function bind_f(f) {
    var new_f = function (state) {
        return f(state);
    }
    return new_f;
}


function step(compiled, state) {
    var i;
    if (compiled.length <= state.line_index) {
        state.running = 0;
        return;
    }
    statement = compiled[state.line_index];
    state.line_index++;
    statement.f(state);
}

function run(compiled, state) {
    var state = {
        line_index: 0,
        running: 1,
        vars: {},
        array_vars: {},
        print: function(s) {
            console.log(s);
        }
    }
    while (state.running) {
        step(compiled, state);
        console.log("state:");
        console.log(state);
    }
}

//debugger;

var state = {
    line_index: 0,
    running: 1,
    vars: {},
    array_vars: {},
    print: function(s) {
        console.log(s);
    }
}

var compiled = parser.parse("20 LET A = 5+10\r\n");

console.log("compiled=");
console.log(compiled);


var v = run(compiled, state);
console.log("state=");
console.log(state);

//run(prog);
