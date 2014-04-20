var prog = ["10 let a = 1", "20 print a", "30 a = a + 1", "40 if a < 100 then 10", "50 stop"];

/*
statement:
    line_number
    f(state)
*/

function SyntaxError(message) {
    this.message = message;
};

function step(compiled, state) {
    var i;
    if (compiled.length <= state.line_index) {
        state.running = 0;
        return;
    }
    statement = compiled[state.line_index];
    statement.f(state);
    state.line_index++;
}

function eval_expression(tokens, state) {
    if (tokens.length == 1) {
        var n = Number(tokens[0]);
        console.log("N=" + n);
        return n;
    }
    console.log("*** eval expression");
    console.log(tokens);
    console.log("*** end eval expression");
}

function do_let(tokens, state) {
    console.log("** let");
    console.log(tokens);
    var the_var = tokens.shift();
    if (tokens.shift() !== '=') {
        throw "= token expected; got " + tokens[1];
    }
    var the_val = eval_expression(tokens, state);
    state.vars[the_var] = the_val;
}

function do_print(tokens, state) {
    console.log("print " + tokens);
}

function do_if(tokens, state) {
    console.log("if " + tokens);
}

function do_stop(tokens, state) {
    console.log("if " + tokens);
}

function do_goto(tokens, state) {
    console.log("goto " + tokens);
}

function do_go(tokens, state) {
    console.log("go " + tokens);
}

TOKEN_LOOKUP = {
    'let' : do_let,
    'print' : do_print,
    'if' : do_if,
    'stop' : do_stop,
    'goto' : do_goto,
    'go' : do_go,
}

function compile_line(tokens) {
    if (TOKEN_LOOKUP[tokens[0]] === undefined) {
        tokens.unshift("let");
    }
    var verb = tokens.shift();
    var f = TOKEN_LOOKUP[verb];
    return function (state) {
        console.log(tokens);
        f(tokens.slice(), state);
    }
}

function compile(prog) {
    var compiled = [];
    var idx;
    for (idx=0; idx<prog.length; idx++) {
        var line = prog[idx];
        var tokens = line.split(" ");
        var statement = {
            line_number: Number(tokens[0]),
            f: compile_line(tokens.splice(1)),
        }
        compiled.push(statement);
    }
    return compiled;
}

function run(prog) {
    var compiled = compile(prog);
    var state = {
        line_index: 0,
        running: 1,
        vars: {},
        array_vars: {},
    }
    while (state.running) {
        step(compiled, state);
        console.log("state:");
        console.log(state);
    }
}

run(prog);