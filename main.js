
var PARSE_LINE = basic.parse.bind(basic);

state.print = function(s) {
    $("#output").append(s);
}

state.input = function(vars) {
    resume = function () {
        var val = $("#input").val();
        var vals = val.split(",");
        var idx;
        for (idx=0;idx<vars.length;idx++) {
            this.vars[vars[idx](state)] = vals[idx];
        }
        this.running = true;
        while (this.running) {
            this.step();
        }
    }
    this.running = false;
    $("#return").one("click", resume.bind(this));
}


$(function (){
    $.get("dnd.basic")
    .done(start);
});


function start(t) {
    console.log(t);
    $("#output").append("foo!");

    function bind_f(f) {
        var new_f = function (state) {
            return f(state);
        }
        return new_f;
    }

    var prog_text = t.split("\n");
    var program = prog_text.map(PARSE_LINE);

    state.run(program);
}
