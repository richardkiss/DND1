
var PARSE_LINE = basic.parse.bind(basic);
console.log(PARSE_LINE);
var p = PARSE_LINE("10 PRINT 200 + 300");
console.log(p);


$(function (){
    console.log("hello");
    $.get("simple.basic")
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
