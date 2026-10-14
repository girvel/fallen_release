local cli = {}

cli.parse = function(args)
  local parser = Argparse()
    :name("love")
    :description("Launch the game")

  parser
    :argument(
      "game root path",
      "not required; windows version of LOVE passes the path argument, linux doesn't. This argument"
      .. "makes them compatible")
    :args("?")

  parser:flag(
    "-d --debug",
    "Show FPS; no confirmation on exit, exit through Ctrl+D enabled;"
  )

  parser:flag(
    "-y --youtube",
    "Set window to appear in constant position, raise scale -- to make YT videos"
  )

  parser:flag(
    "-P --playground",
    "Run the playground script"
  )

  parser:option(
    "-s --enable-scenes"
  ):args("+"):default({})

  parser:option(
    "-S --disable-scenes"
  ):args("+"):default({})

  parser:option(
    "-c --checkpoint"
  ):args(1)

  parser:option(
    "-p --profiler",
    "Run the game with profiler; value consists of letters:"
    .."\n  z: group by Zone"
    .."\n  s: group by vm State"
    .."\n  l: group by Line"
    .."\n  i: include the Initial phase -- starting menu & loading"
    .."\n  m: include the Main phase -- the game itself"
  ):args(1)

  parser:flag(
    "-A --disable-ambient",
    "Disables background music"
  )

  parser:option(
    "-r --resolution"
  ):args("?")

  parser:flag(
    "-f --fixed-size",
    "Disable resizing of the window"
  )

  parser:flag(
    "-C --force-color",
    "Color logs forcefully"
  )

  parser:option(
    "-E --seed",
    "Seed in hexadecimal form; between 000000 and FFFFFF"
  ):args(1)

  parser:option(
    "-D --discord-status",
    "Custom discord status"
  ):args(1)

  args[-2] = nil
  args[-1] = nil

  local is_mobdebug_attached = Table.last(args) == "-debug"
  if is_mobdebug_attached then
    table.remove(args)
  end

  local result = parser:parse(args)

  if result.resolution then
    local resolution = result.resolution[1] or "1080p"
    local builtin_resolutions = {
      ["1080p"] = V(1920, 1080),
      ["720p"] = V(1280, 720),
      ["360p"] = V(640, 360),
    }

    if not builtin_resolutions[resolution] and not resolution:find("x") then
      error(("Invalid resolution %q"):format(resolution))
    end

    --- @type vector
    result.resolution = builtin_resolutions[resolution]
      or Vector.own(Fun.iter(resolution / "x"):map(tonumber):totable())
  end

  result.mobdebug = is_mobdebug_attached

  if result.seed then
    --- @diagnostic disable-next-line:param-type-mismatch
    result.seed = tonumber(result.seed, 16)
    if not result.seed then error("Invalid seed "..result.seed) end
    if result.seed < 0 then error("Negative seed "..result.seed) end
    if result.seed > 0xFFFFFF then error("Too large seed "..result.seed) end
  end

  if result.profiler then
    result.profiler = {
      grouping = {
        line = not not result.profiler:match("l"),
        state = not not result.profiler:match("s"),
        zone = not not result.profiler:match("z"),
      },
      include_initial = not not result.profiler:match("i"),
      include_main = not not result.profiler:match("m"),
    }

    assert(
      result.profiler.include_initial or result.profiler.include_main,
      "-p / --profiler option should contain at least either 'i' or 'm' (see help)"
    )
  end

  return result
end

return cli
