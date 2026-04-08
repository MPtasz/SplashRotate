-- SplashBoot.lua
-- Silent splash rotator - runs once on every radio boot via Special Functions.
-- Radio Settings -> Special Functions -> Startup -> Lua script -> SplashBoot
--
-- Rotates /images/splash.png through the archive on every power-on:
--   1. Archives current splash.png -> splash(highest+1).png
--   2. Promotes splash(lowest).png -> splash.png
--
-- Place in /SCRIPTS/FUNCTIONS/SplashBoot.lua
-- EdgeTX 2.11.5 / Lua Reference 2.11
--
-- Function scripts are called repeatedly by EdgeTX. The 'done' flag
-- ensures the rotation runs exactly once per boot session.

local IMG_DIR = "/images"
local BASE    = "splash"
local EXT     = ".png"
local MAX_N   = 999

local done    = false   -- guard: rotate once per boot, not every frame

-- ---- helpers ---------------------------------------------------------------

local function imgPath(n)
  if n == 0 then
    return IMG_DIR .. "/" .. BASE .. EXT
  end
  return IMG_DIR .. "/" .. BASE .. string.format("%02d", n) .. EXT
end

local function exists(path)
  return fstat(path) ~= nil
end

local function copyFile(src, dst)
  local inF = io.open(src, "r")
  if not inF then return false end
  local outF = io.open(dst, "w")
  if not outF then io.close(inF); return false end
  while true do
    local data = io.read(inF, 256)
    if data == nil or data == "" then break end
    io.write(outF, data)
  end
  io.close(inF)
  io.close(outF)
  return true
end

local function renameFile(src, dst)
  if not copyFile(src, dst) then return false end
  del(src)
  return true
end

-- ---- rotation logic --------------------------------------------------------

local function doRotate()
  local hasBase = exists(imgPath(0))

  -- find lowest numbered splashNN.png
  local lowest = 0
  for n = 1, MAX_N do
    if exists(imgPath(n)) then
      lowest = n
      break
    end
  end

  -- find highest (contiguous scan from lowest)
  local highest = lowest
  if lowest > 0 then
    for n = lowest + 1, MAX_N do
      if exists(imgPath(n)) then
        highest = n
      else
        break
      end
    end
  end

  -- nothing to do
  if not hasBase and lowest == 0 then return end
  if highest >= MAX_N then return end

  -- step 1: archive splash.png -> splash(highest+1).png
  if hasBase then
    renameFile(imgPath(0), imgPath(highest + 1))
    highest = highest + 1
  end

  -- step 2: promote lowest -> splash.png
  if lowest > 0 then
    renameFile(imgPath(lowest), imgPath(0))
  end
end

-- ---- function script entry point -------------------------------------------
-- EdgeTX calls run() on every frame while the Special Function is active.
-- We rotate once (guarded by 'done') then do nothing further.

local function run(event)
  if not done then
    done = true
    pcall(doRotate)
  end
end

return { run = run }
