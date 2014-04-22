/* description: Parses end executes mathematical expressions. */

/*
*/

/* lexical grammar */
%lex

%%
\s+                   /* skip whitespace */
[0-9]+                return 'INTEGER';
[0-9]+("."[0-9]*)     return 'REAL';
"*"                   return '*';
"/"                   return '/';
"-"                   return '-';
"+"                   return '+';
"^"                   return '^';
"<="                  return 'LE';
"<"                   return 'LT';
">="                  return 'GE';
">"                   return 'GT';
"<>"                  return 'NE';
"!="                  return 'NE';
"("                   return '(';
")"                   return ')';
\n return "NL";
"=" return "EQ";
"IF" return "IF";
"THEN" return "THEN";
"PRINT" return "PRINT";
"STOP" return "STOP";
"LET" return "LET";
"[^\"]*" return "STR_CONSTANT";
[A-Z]+\$              return 'STR_VARIABLE'
[A-Z]+                return 'NUM_VARIABLE'
<<EOF>>               return 'EOF';

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%left GT GE LT LE EQ NE
%left UMINUS

%start line

%% /* language grammar */

line
: INTEGER statement EOF
{ return { line_number: Number($1), f: $2}; }
;

statement
: LET NUM_VARIABLE EQ num_exp
{
    $$ = bind_f(function(state) {
            state.vars[$2] = $4(state);
        });
    console.log("LET " + $4); 
}
| LET STR_VARIABLE EQ str_exp
| PRINT print_exp
{
    $$ = bind_f(function(state) {
            $2(state);
            });
    console.log("PARSE: PRINT");
}
| IF num_exp THEN INTEGER
{
    $$ = bind_f(function(state) {
        if ($2(state)) {
            state.goto($4);
        }
    });
}
| STOP
{ $$ = function(state) {
        state.running = 0;
    }
}
| NUM_VARIABLE EQ num_exp
{ $$ = function(state) {
    state.vars[$1] = $3(state);
  }
}
| STR_VARIABLE EQ str_exp
{ $$ = function(state) {
    state.vars[$1] = $3(state);
  };
}
;

num_exp
: '-' num_exp
    { $$ = bind_f(function(state) { return -$1(state)}); }
| num_exp '+' num_exp
    { $$ = bind_f(function(state) { return $1(state) + $3(state); }); }
| num_exp '-' num_exp
    { $$ = bind_f(function(state) { return $1(state) - $3(state); }); }
| num_exp '/' num_exp
    { $$ = bind_f(function(state) { return $1(state) / $3(state); }); }
| num_exp '*' num_exp
    { $$ = bind_f(function(state) { return $1(state) * $3(state); }); }
| num_exp LE num_exp
    { $$ = bind_f(function(state) { return $1(state) <= $3(state); }); }
| num_exp GE num_exp
    { $$ = bind_f(function(state) { return $1(state) >= $3(state); }); }
| num_exp GT num_exp
    { $$ = bind_f(function(state) { return $1(state) > $3(state); }); }
| num_exp LT num_exp
    { $$ = bind_f(function(state) { return $1(state) < $3(state); }); }
| num_exp NE num_exp
    { $$ = bind_f(function(state) { return $1(state) != $3(state); }); }
| '(' num_exp ')'
    { $$ = $2;}
| NUM_VARIABLE
{
    $$ = bind_f(function(state) { return state.vars[$1]; });
}
| NUMBER
    { var N = Number(yytext); $$ = bind_f(function(state) { return N;}); }
| INTEGER
    { var N = Number(yytext); $$ = bind_f(function(state) { return N;}); }
;

str_exp
: STR_CONSTANT
;

print_exp
: num_exp
{
    $$ = function(state) {
        state.print($1(state));
    }
}
| str_exp
{
    $$ = function(state) {
        state.print($1(state));
    }
}
;

%%

function bind_f(f) {
    var new_f = function (state) {
        return f(state);
    }
    return new_f;
}
