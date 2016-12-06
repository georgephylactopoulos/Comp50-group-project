
% To run this, run
% erl < try_parse_args.erl -foo bar

{ok, Foo} = init:get_argument(foo).
Foo.
