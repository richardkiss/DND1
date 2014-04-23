/* BASIC interpreter to run D&D#1 */

/* lexical grammar */
%lex

%%
\"[^\"]*\"            return "STR_CONSTANT";
\s+                   /* skip whitespace */
[0-9]+                return 'INTEGER';
[0-9]+("."[0-9]*)     return 'REAL';
"*"                   return '*';
"/"                   return '/';
"-"                   return '-';
"+"                   return '+';
"^"                   return '^';
"<>"                  return 'NE';
"<="                  return 'LE';
"<"                   return 'LT';
">="                  return 'GE';
">"                   return 'GT';
"!="                  return 'NE';
"("                   return '(';
")"                   return ')';
";" return "SEMICOLON";
"," return ",";
\n return "NL";
"=" return "EQ";
"IF" return "IF";
"THEN" return "THEN";
"PRINT" return "PRINT";
"STOP" return "STOP";
"LET" return "LET";
"BASE" return "BASE";
"DIM" return "DIM";
"INPUT" return "INPUT";
"FOR" return "FOR";
"NEXT" return "NEXT";
"READ" return "READ";
"REM" return "REM";


"INT" return "INT";
"RND" return "RND";
"CLK" return "CLK";

"TO" return "TO";

[A-Z][A-Z0-9]?\$       return 'STR_VARIABLE'
[A-Z][A-Z0-9]?         return 'NUM_VARIABLE'
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
| PRINT print_exp SEMICOLON
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
| REM COMMENT_TEXT
| DIM dim_exp
{
}
| FOR NUM_VARIABLE EQ num_exp TO num_exp
{
    $$ = bind_f(function (state) {
        state.for_state[$2] = { v: $2, m: $6(state), step:1, p: state.line_index };
        state.vars[$2] = $4(state);
    });
}
| NEXT NUM_VARIABLE
{
    $$ = bind_f(function(state) {
            for_state = state.for_state[$2];
            if (state.vars[$2] < for_state.m) {
                state.vars[$2] += for_state.step;
                state.line_index = for_state.p;
            } else {
                // remove for_item
                state.for_state[$2] = undefined;
            }
        })
}
| READ variable
{
}
| INPUT variable
{
}
| STOP
{ $$ = function(state) {
        state.running = 0;
    }
}
| BASE num_exp
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
| str_exp '+' str_exp
    { $$ = bind_f(function(state) { return $1(state) + $3(state); }); }
| str_exp EQ str_exp
    { $$ = bind_f(function(state) { return $1(state) == $3(state); }); }
| str_exp LE str_exp
    { $$ = bind_f(function(state) { return $1(state) <= $3(state); }); }
| str_exp GE str_exp
    { $$ = bind_f(function(state) { return $1(state) >= $3(state); }); }
| str_exp GT str_exp
    { $$ = bind_f(function(state) { return $1(state) > $3(state); }); }
| str_exp LT str_exp
    { $$ = bind_f(function(state) { return $1(state) < $3(state); }); }
| str_exp NE str_exp
    { $$ = bind_f(function(state) { return $1(state) != $3(state); }); }
| '(' num_exp ')'
    { $$ = $2;}
| INT '(' num_exp ')'
    { $$ = bind_f(function(state) { return int($1(state)); })}
| RND '(' num_exp ')'
    { $$ = bind_f(function(state) { return rnd($1(state)); })}
| CLK '(' num_exp ')'
    { $$ = bind_f(function(state) { return clk($1(state)); })}
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
{
    $$ = bind_f(function(state) { return $1 });
}
| STR_VARIABLE
{
    $$ = bind_f(function(state) { return state.vars[$1]; })
}
;

variable
: NUM_VARIABLE
{ $$ = "n_" + $1; }
| STR_VARIABLE
{ $$ = "s_" + $1; }
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

dim_exp
: dim_entry "," dim_exp
| dim_entry
;

dim_entry
: NUM_VARIABLE "(" index_list ")"
{
    $$ = bind_f(function(state) {
        state.array_vars[$1] = make_num_array($3);
        });
}
| STR_VARIABLE "(" index_list ")"
{
}
;

index_list
: INTEGER
{
    $$ = [$1];
}
| INTEGER "," index_list
{
    $$ = [$1].concat($3);
}
;

%%

function bind_f(f) {
    var new_f = function (state) {
        return f(state);
    }
    return new_f;
}

function make_num_array(index_list) {
    console.log("make num array: " + index_list);
}

function int(v) {
    return Math.floor(v);
}

function rnd(v) {
    return 0.5;
}

function clk(v) {
    return 0.5;
}
