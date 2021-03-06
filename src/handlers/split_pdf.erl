%%% @doc Module handling pdf spliting
%%% @end

-module(split_pdf).
-include_lib("fyler_worker/include/fyler.hrl").
-include("../../include/log.hrl").

-export([run/1,run/2,category/0]).

category() ->
  document.

-define(COMMAND(In, Split, Out), "pdftk \"" ++ In ++ "\" cat " ++ Split ++ " output \"" ++ Out ++ "\"").

run(File) -> run(File, []).

run(#file{tmp_path = Path, name = Name, dir = Dir},Opts) ->
  Start = ulitos:timestamp(),
  case proplists:get_value(split,Opts) of
    undefined -> ?D(split_options_undefined),
                 {ok,#job_stats{time_spent = 0, result_path = [list_to_binary(Path)]}};
    Split ->  PDF = filename:join(Dir,Name ++ "_split.pdf"),
              ?D({"command",?COMMAND(Path,binary_to_list(Split),PDF)}),
              Data = exec_command:run(?COMMAND(Path, binary_to_list(Split), PDF)),
              case  filelib:is_file(PDF) of
                    true -> {ok,#job_stats{time_spent = ulitos:timestamp() - Start, result_path = [list_to_binary(Name ++ "_split.pdf")]}};
                    _ -> {error, {pdf_split_failed, PDF, Data}}
              end
  end.






