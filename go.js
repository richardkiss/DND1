var parser = require("./basic").parser;
var fs = require("fs");
var state = require("./state").state;


var source_path = "simple.basic";
//source_path = "write.basic.txt";

var prog_text = fs.readFileSync(source_path, encoding="utf8").split("\n");


function bind_f(f) {
    var new_f = function (state) {
        return f(state);
    }
    return new_f;
}


function compile_line(line) {
    return parser.parse(line);
}


var program = prog_text.map(compile_line);

console.log("program=");
console.log(program);

var v = state.run(program);
console.log("state=");
console.log(state);
