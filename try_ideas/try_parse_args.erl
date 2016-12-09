
% To run this, run
% erl < try_parse_args.erl -foo bar

{ok, [[Foo]]} = init:get_argument(foo).
Foo.

'make this an atom'.

list_to_atom(Foo).
