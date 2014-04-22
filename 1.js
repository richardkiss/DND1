var parser = require("./basic").parser;

function exec (input) {
    return parser.parse(input);
}

function bind_f(f) {
    var new_f = function (state) {
        return f(state);
    }
    return new_f;
}


var state = {
    line_index: 0,
    running: 1,
    vars: {},
    array_vars: {},
    print: function(s) {
        console.log(s);
    },
    goto: function(line_number) {
        this.line_index = this.line_lookup[line_number];
    },
    load: function(program) {
        this.program = program;
        this.line_index = 0;
        this.line_lookup = {};
        var idx;
        for (idx=0;idx<program.length;idx++) {
            var statement = program[idx];
            this.line_lookup[statement.line_number] = idx
        }
    },
    step: function() {
        if (this.program.length <= state.line_index) {
            this.running = 0;
            return;
        }
        statement = this.program[this.line_index];
        this.line_index++;
        statement.f(this);
    },
    run: function(program) {
        if (program) {
            this.load(program);
        }
        while (this.running) {
            this.step();
        }
    }
}

function compile_line(line) {
    return parser.parse(line);
}

var prog_text = ["10 LET A = 1", "20 PRINT A", "30 A = A + 1", "40 IF A < 100 THEN 20", "50 STOP"];

var program = prog_text.map(compile_line);

console.log("program=");
console.log(program);

var v = state.run(program);
console.log("state=");
console.log(state);
