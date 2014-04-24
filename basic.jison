/* BASIC interpreter to run D&D#1 */

/* lexical grammar */
%lex

%%
\"[^\"]*\"            return "STR_CONSTANT";
\s+                   /* skip whitespace */
[0-9]+("."[0-9]+)     return 'REAL';
[0-9]+                return 'INTEGER';
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
"#" return "#";
";" return "SEMICOLON";
"," return ",";
\n return "NL";
"=" return "EQ";
"IF" return "IF";
"THEN" return "THEN";
"GOTO" return "GOTO";
"PRINT" return "PRINT";
"STOP" return "STOP";
"LET" return "LET";
"BASE" return "BASE";
"DIM" return "DIM";
"INPUT" return "INPUT";
"FOR" return "FOR";
"NEXT" return "NEXT";
"GOSUB" return "GOSUB";
"RETURN" return "RETURN";
"READ" return "READ";
"DATA" return "DATA";
"FILE" return "FILE";
"WRITE" return "WRITE";
"RESTORE" return "RESTORE";
"REM" return "REM";
"ASSERT" return "ASSERT";


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
: INTEGER REM
{ return { line_number: Number($1), f: function() {}}; }
| INTEGER statement EOF
{ return { line_number: Number($1), f: $2}; }
;

statement
: LET identifier EQ exp
{
    $$ = bind_f(function(state) {
            state.vars[$2(state)] = $4(state);
        });
}
| PRINT print_exp_list
{
    $$ = bind_f(function(state) {
          var idx;
          var s = '';
          for (idx=0;idx<$2.length;idx++) {
              s += $2[idx](state);
          }
          s += "\n";
          state.print(s);
      });
}
| PRINT print_exp_list SEMICOLON
{
    $$ = bind_f(function(state) {
        var idx;
        var s = '';
        for (idx=0;idx<$2.length;idx++) {
            s += $2[idx](state);
        }
        state.print(s);
      });
}
| ASSERT num_exp
{
    $$ = bind_f(function(state) {
            if (!$2(state)) {
                console.log("state:");
                console.log(state);
                throw "assertion failed in " + state.program[state.line_index-1].line_number;
            }
        });
}
| IF num_exp THEN INTEGER
{
    $$ = bind_f(function(state) {
        if ($2(state)) {
            state.goto($4);
        }
    });
}
| GOTO INTEGER
{
    $$ = bind_f(function(state) {
        state.goto($2);
    });
}
| DIM dim_exp
{
    $$ = function(state) { $2(state); };
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
            var for_state = state.for_state[$2];
            if (state.vars[$2] < for_state.m) {
                state.vars[$2] += for_state.step;
                state.line_index = for_state.p;
            } else {
                // remove for_item
                delete state.for_state[$2];
            }
        })
}
| GOSUB INTEGER
{
    $$ = bind_f(function(state) {
           state.return_positions.push(state.line_index);
           state.line_index = state.line_lookup[$2];
        })
}
| RETURN
{
    $$ = function(state) {
        state.line_index = state.return_positions.pop();
    }
}
| DATA data_exp_list
{
    $$ = function(state) {};
}
| FILE "#" num_exp EQ str_exp
{
    $$ = function(state) {};
}
| WRITE "#" num_exp "," exp
{
    $$ = function(state) {};
}
| RESTORE "#" INTEGER
{
    $$ = function(state) {};
}
| READ identifier_list
{
    $$ = function(state) {};
}
| READ "#" INTEGER "," identifier
{
    $$ = function(state) {};
}
| INPUT identifier
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


identifier
: num_identifier
{
    $$ = $1;
}
| str_identifier
{
    $$ = $1;
}
;

num_identifier
: NUM_VARIABLE
{
    $$ = bind_f(function(state) { return $1 });
}
| NUM_VARIABLE array_addendum
{
    $$ = bind_f(function (state) {
        return $1 + $2(state);
    });
}
;

str_identifier
: STR_VARIABLE
{
    $$ = bind_f(function(state) { return $1 });
}
| STR_VARIABLE array_addendum
{
    $$ = bind_f(function (state) {
        return $1 + $2(state);
    });
}
;

array_addendum
: "(" num_exp_list ")"
{
    $$ = bind_f(function (state) {
        var s = '';
        var idx;
        for (idx=0; idx<$2.length; idx++) {
            s += "_" + $2[idx](state);
        }
        return s;
    });
}
;


identifier_list
: identifier
{
    $$ = [$1];
}
| identifier_list "," identifier
{
    $$ = $1.concat([$3])
}
;

exp
: num_exp
| str_exp
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
| num_exp EQ num_exp
    { $$ = bind_f(function(state) { return $1(state) == $3(state); }); }
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
    { $$ = bind_f(function(state) { return int($3(state)); })}
| RND '(' num_exp ')'
    { $$ = bind_f(function(state) { return rnd($3(state)); })}
| CLK '(' num_exp ')'
    { $$ = bind_f(function(state) { return clk($3(state)); })}
| num_identifier
{
    $$ = bind_f(function(state) { return state.vars[$1(state)]; });
}
| NUMBER
    { var N = Number(yytext); $$ = bind_f(function(state) { return N;}); }
| INTEGER
    { var N = Number(yytext); $$ = bind_f(function(state) { return N;}); }
| REAL
    { var N = Number(yytext); $$ = bind_f(function(state) { return N;}); }
;

str_exp
: STR_CONSTANT
{
    $$ = bind_f(function(state) { return $1.substring(1, $1.length-1); });
}
| STR_VARIABLE
{
    $$ = bind_f(function(state) { return state.vars[$1]; })
}
| str_exp '+' str_exp
    { $$ = bind_f(function(state) { return $1(state) + $3(state); }); }
;

data_exp_list
: data_exp
{ $$ = [$1]; }
| data_exp "," data_exp_list
{ $$ = $1.concat([$2]); }
;

data_exp
: STR_CONSTANT
{
    $$ = $1;
}
| INTEGER
{
    $$ = $1;
}
| REAL
{
    $$ = $1;
}
;

num_array_var
: NUM_VARIABLE "(" num_exp_list ")"
{
    $$ = bind_f(function(state) {
        var indices = $3.map(function(num_exp) { return int(num_exp(state)); });
        var v = $1;
        var idx;
        for (idx=0;idx<indices.length;idx++) {
            v = v + "_" + indices[idx];
        }
        return v;
    });
}
;



print_exp_list
:
{
    $$ = [];
}
| print_exp
{
    $$ = [$1];
}
| print_exp_list SEMICOLON print_exp
{
    $$ = [$1].concat($3);
}
;

print_exp
: num_exp
{
    $$ = $1;
}
| str_exp
{
    $$ = $1;
}
;

dim_exp
: dim_entry "," dim_exp
| dim_entry
;

dim_entry
: NUM_VARIABLE "(" num_exp_list ")"
{
    $$ = bind_f(function(state) {
        dim(state, $1, $3.map(function (v) { return v(state); }));
    });
}
| STR_VARIABLE "(" num_exp_list ")"
{
}
;

num_exp_list
: num_exp
{
    $$ = [$1];
}
| num_exp "," num_exp_list
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

function dim(state, v, index_list) {
    console.log("dim: " + v + " " + index_list);
    console.log(index_list);
    var idx;
    for (idx=0;idx<=index_list[0];idx++) {
        state.vars[v + "_" + idx] = 0;
    }
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
