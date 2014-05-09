var state = {
    line_index: 0,
    running: 1,
    vars: {},
    for_state: {},
    files: {},
    file_system: {},
    return_positions: [],
    goto: function(line_number) {
        this.line_index = this.line_lookup[line_number];
    },
    read_data: function() {
        var v = this.data.shift();
        return v;
    },
    load: function(program) {
        this.program = program;
        this.line_index = 0;
        this.line_lookup = {};
        var idx;
        this.data = [];
        for (idx=0;idx<program.length;idx++) {
            var statement = program[idx];
            if (statement.data) {
                this.data = this.data.concat(statement.data);
            }
        }
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
    },
    file_num: function(number, name) {
        var data = this.file_system[name];
        if (data === undefined) {
            data = [];
            this.file_system[name] = data;
        }
        this.files[number] = { name: name, data: data };
    },
    read_num: function(number) {
        var v = this.files[number].data.shift();
        return v;
    },
    restore_num: function(number) {
        this.files[number].data = this.file_system[this.files[number].name].slice(0);
    },
    write_num: function(number, l) {
        var idx;
        for (idx=0;idx<l.length;idx++) {
            this.files[number].data.push(l[idx]);
        }
        this.file_system[this.files[number].name] = this.files[number].data;
    },
    print: function(s) {
        console.log(s);
    },
    input: function(vars) {
        resume = function () {
            // fetch values and stick 'em in the vars
            var idx;
            this.running = true;
            for (idx=0;idx<vars.length;idx++) {
                this.vars[vars[idx](state)] = 100 + idx;
                debugger;
            }
            while (this.running) {
                this.step();
            }
        }
        this.running = false;
        setTimeout(resume.bind(this), 3.0);
    }
}


if (typeof require !== 'undefined' && typeof exports !== 'undefined') {
    exports.state = state;
}