%%% @doc Convert any video to hls with h264 and aac.
%%% @end 

-module(video_to_hls).
-include_lib("fyler_worker/include/fyler.hrl").
-include("../../include/log.hrl").

-export([run/1, run/2, category/0]).

-define(COMMAND(In,Out,Params), 
  "ffmpeg -i "++In++" "++Params++" -hls_time 10 -hls_list_size 0 "++Out
  ).

category() ->
  video.

run(File) -> run(File, []).

run(#file{tmp_path = Path, name = Name, dir = Dir} = File, Opts) ->
  Start = ulitos:timestamp(),
  M3U = filename:join(Dir, Name ++ ".m3u8"),

  Info = video_probe:info(Path),

  Command = ?COMMAND(Path, M3U, video_to_mp4:info_to_params(Info)),

  ?D({"command", Command}),
  Data = exec_command:run(Command, stderr),
  case filelib:wildcard("*.m3u8", Dir) of
    [] -> {error, Data};
    _List ->
      Result = Name ++ ".m3u8",
      IsThumb = proplists:get_value(thumb, Opts, true),
      Thumbs = thumbs(File, Opts, IsThumb),
      {ok, #job_stats{time_spent = ulitos:timestamp() - Start, result_path = [list_to_binary(Result)|Thumbs]}}
  end.

thumbs(_, _, false) ->
  [];

thumbs(#file{tmp_path = MP4, name = Name, dir = Dir}, Opts, true) ->
  case video_thumb:run(#file{tmp_path = MP4, name = Name, dir = Dir}, Opts) of
    {ok,#job_stats{result_path = Thumbs}} ->
      Thumbs;
    _Else ->
      ?E({video_hls_thumbs_failed, _Else}),
      []
  end.