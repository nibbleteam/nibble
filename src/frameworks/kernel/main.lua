-- Kernel Lua do Nibble

-- Para acessar as funções do kernel cpp
local hw = require('frameworks.kernel.hw')

-- Utilitários
local audio = require('frameworks.kernel.audio')
local input = require('frameworks.kernel.input')
local lang = require('frameworks.kernel.lang')
local gpu = require('frameworks.kernel.gpu')
local pprint = require('frameworks.kernel.pprint')

-- Moonscript
package.loaded.moonscript = require("frameworks.kernel.moonscript")

local moon_parse = require("moonscript.parse")
local moon_compile = require("moonscript.compile")

local processes = {}
local pid_counter = 0
local executing_process = nil

local global_time = 0

--
-- Pontos de entrada a partir do cpp
--

function init()
    processes[0] = make_process('apps/system/init.nib', {})
end

function update(dt)
    global_time += dt

    exec_processes(dt)

    audio_tick()
end

function audio_tick()
    for p, proc in pairs(processes) do
        if proc.priv.running then
            exec_audio_tick(proc)
        end
    end
end

function menu()
    if not get_running_process('apps/system/menu.nib') then
        pid_counter += 1

        processes[pid_counter] = make_process('apps/system/menu.nib', {
            pid = pid_counter,
            app = {
                env = executing_process.pub.env,
                pid = executing_process.priv.pid,
            },
            running = get_running_pids()
        })
    end
end

--
-- Gerenciamento de processos
--

function get_running_pids()
    local pids = {}

    for _, proc in pairs(processes) do
        if proc.priv.running then
            table.insert(pids, proc.priv.pid)
        end
    end

    return pids
end

function get_running_process(entrypoint)
    for _, proc in pairs(processes) do
        if proc.priv.entrypoint == entrypoint and proc.priv.running then
            return proc
        end
    end

    return nil
end

function nib_open_asset(entrypoint, asset, kind)
    local path = entrypoint..'/'..asset:gsub("%.", "/")..'.'..kind:gsub("%.", "")

    print('loading', asset, '('..kind..')')
    print('at', path)

    return io.open(path, "r+")
end

-- Cria um processo, composto de um conjunto de infromações acessíveis apenas ao
-- kernel e um conjunto de informações públicas ao código do processo
function make_process(entrypoint, env, group)
    local proc = {}

    local sheet = entrypoint..'/assets/sheet.png'

    local sheet_ptr, sheet_w, sheet_h = hw.load_spritesheet(sheet)

    local ex, ey, ew, eh

    if executing_process then
        ex, ey, ew, eh = executing_process.priv.x, executing_process.priv.y,
                         executing_process.priv.width, executing_process.priv.height
    else
        ex, ey, ew, eh = 0, 0, 400, 240
    end

    local x = math.max(env.x or 0, ex)
    local y = math.max(env.y or 0, ey)
    local w = math.min(env.width or 400, ex+ew-ex)
    local h = math.min(env.height or 240, ey+eh-ey)

    proc.priv = {
        spritesheet = {
            ptr = sheet_ptr,
            w = sheet_w,
            h = sheet_h
        },
        external_spritesheets = {},
        width = w, height = h,
        x = x, y = y,
        message_queue = {},
        pid = pid_counter,
        parent = executing_process,
        entrypoint = entrypoint,
        children = {},
        group = group or {},
    }

    table.insert(proc.priv.group, pid_counter)

    if executing_process then
        table.insert(executing_process.priv.children, proc)
    end

    -- Define o tamanho da tela
    env.width = w
    env.height = h
    env.x = x
    env.y = y

    local parent_process = executing_process
    executing_process = proc

    proc.pub = nib_api(entrypoint, proc, env)
    proc.pub.env = env
    proc.pub.env.pid = proc.priv.pid

    proc.priv.ok, err = exec(entrypoint..'/main', proc.pub)
    proc.priv.running = true

    if not proc.priv.ok then
        print(err)
    end

    -- Põe as funções que vamos chamar em sandboxes
    sandbox_fn(proc.pub.init, proc.pub)
    sandbox_fn(proc.pub.draw, proc.pub)
    sandbox_fn(proc.pub.update, proc.pub)

    executing_process = parent_process

    return proc
end

function exec_processes(dt)
    for p, proc in pairs(processes) do
        if proc.priv.running then
            exec_process(proc, dt)
        end
    end
end

function exec_process(process, dt)
    if not process.priv.ok then
        return
    end

    executing_process = process

    -- Usa a spritesheet do processo
    local sheet = process.priv.spritesheet
    hw.use_spritesheet(sheet.ptr, sheet.w, sheet.h)

    -- TODO: Coletar erros das chamadas?
    if process.priv.initialized then
        if process.pub.update then
            xpcall(process.pub.update, function (err)
                process.priv.ok = false
                handle_process_error(err)
            end, dt)
        end

        if process.pub.draw then
            hw.clip(process.priv.x, process.priv.y,
                    process.priv.width, process.priv.height)

            xpcall(process.pub.draw, function (err)
                process.priv.ok = false
                handle_process_error(err)
            end)
        end
    else
        if process.pub.init then
            xpcall(process.pub.init, function (err)
                process.priv.ok = false
                handle_process_error(err)
            end)
        end

        process.priv.initialized = true
    end
end

function exec_audio_tick(process)
    if not process.priv.ok then
        return
    end

    executing_process = process

    -- Usa a spritesheet do processo
    local sheet = process.priv.spritesheet
    hw.use_spritesheet(sheet.ptr, sheet.w, sheet.h)

    if process.priv.initialized then
        if process.pub.audio_tick then
            xpcall(process.pub.audio_tick, function (err)
                process.priv.ok = false
                handle_process_error(err)
            end)
        end
    end
end

function loadmoon(path)
    local moon_file = io.open(path, "rb")

    if moon_file then
        local moon_script = moon_file:read("*all")
        moon_file:close()

        local lua_script = moon_compile.tree(moon_parse.string(moon_script))

        print(lua_script)

        return loadstring(lua_script)
    else
        return nil, "No such file or directory"
    end
end

function exec(path, env, args)
    local fn, msg = loadmoon(path..".moon")

    if not fn then
        fn, msg = loadfile(path..".lua")
    end

    if not fn then
       return nil, msg
    end

    return exec_fn(fn, env, args)
end

function sandbox_fn(fn, env)
    if not fn then
        return
    end

    setfenv(fn, env)
end

function exec_fn(fn, env, args)
    setfenv(fn, env)

    return pcall(fn, args)
end

--
-- Funções customizadas para processos sandboxed
--

function nib_require(entrypoint, module, proc)
    local paths = {
        entrypoint..'/'..module:gsub("%.", "/"),
        'frameworks/'..module:gsub("%.", "/"),
        'frameworks/'..module:gsub("%.", "/").."/main",
    }

    local extensions = { ".lua", ".moon" }

    local errors = {}

    for _, path in ipairs(paths) do
        for _, extension in ipairs(extensions) do
            local fn, err

            if extension == ".lua" then
                fn, err = loadfile(path..extension)
            else
                fn, err = loadmoon(path..extension)
            end

            if not fn then
                table.insert(errors, 'require "'..path..'"): '..tostring(err))
            else
                sandbox_fn(fn, proc.pub)
                return fn()
            end
        end
    end

    print('could not load', module, 'tried:')
    for _, err in ipairs(errors) do
        print(err)
    end
end

function handle_process_error(err)
    print(err)
    print(debug.traceback())

    pause_app(executing_process.priv.pid)

    start_app('apps/system/debug.nib', {
        error = err,
        traceback = debug.traceback(),
    }, true)
end

function is_privileged(entrypoint)
    -- !! Todos os aplicativos nessa pasta são privilegiados !!
    local privileged_path = "apps/system/"

    return entrypoint:sub(1, #privileged_path) == privileged_path
end

function start_app(app, env, grouped)
    local parent_group = executing_process and executing_process.priv.group

    pid_counter += 1
    processes[pid_counter] = make_process(app, env, grouped and parent_group)

    if processes[pid_counter].priv.ok then
        return pid_counter, ''
    else
        return nil
    end
end

function stop_app(pid, disable_grouping)
    local send_stopped = function(proc)
        if proc and proc.priv.parent then
            local parent = proc.priv.parent

            table.insert(parent.priv.message_queue, 1, { app_stopped = executing_process.priv.pid })

            if parent.priv.waiting == proc.priv.pid then
                resume_app(parent.priv.pid)
            end
        end
    end

    local kill_group = function(process)
        if disable_grouping then
            send_stopped(process)

            if process then
                processes[pid] = nil
            end
        else
            local group = process.priv.group

            for _, pid in ipairs(group) do
                local process = processes[pid]

                send_stopped(process)

                if process then
                    hw.unload_spritesheet(process.priv.spritesheet.ptr)

                    for _, sheet in ipairs(process.priv.external_spritesheets) do
                        hw.unload_spritesheet(sheet.ptr)
                    end

                    processes[pid] = nil
                end
            end
        end
    end

    if pid == 0 then
        kill_group(executing_process)
    else
        local process = processes[pid]

        if process then
            kill_group(process)
        end
    end
end

function resume_app(pid)
    local process = processes[pid]

    if process then
        process.priv.running = true
        hw.write(768, process.priv.screen)
    end
end

function nib_api(entrypoint, proc, env)
    local api = {
        _G = {},
        -- Processos podem usar require limitado,
        require = function(module)
            return nib_require(entrypoint, module, proc)
        end,
        -- Permite escrever para stdout
        terminal_print = print,
        terminal_pretty = pprint,
        -- Energia
        shutdown = hw.shutdown,
        -- Syscalls
        start_app = function(app, env, grouped)
            return start_app(app, env, grouped)
        end,
        stop_app = function(pid, disable_grouping)
            return stop_app(pid, disable_grouping)
        end,
        pause_app = function (pid, wait_pid)
            local process = processes[pid]

            if process then
                process.priv.screen = hw.read(768, 400*240)
                process.priv.running = false

                -- This process can wake us up
                process.priv.waiting = wait_pid
            end
        end,
        resume_app = function (pid)
            resume_app(pid)
        end,
        send_message = function(pid, message)
            if processes[pid] and message then
                table.insert(processes[pid].priv.message_queue, 1, message)
            end
        end,
        receive_message = function()
            return table.remove(executing_process.priv.message_queue)
        end,
        -- Ferramentas para a linguagem
        instanceof = lang.instanceof,
        new = lang.new,
        copy = lang.copy,
        inherit = function(c, x) return lang.new(c, x or {}) end,
        concat = lang.concat,
        zip = lang.zip,
        debug = error,
        load = load,
        pcall = function(fn)
            setfenv(fn, executing_process.pub)

            return pcall(fn)
        end,
        assert = assert,
        _VERSION = _VERSION,
        -- Funções matemática
        math = math,
        string = string,
        -- Funções gerais
        bit = require 'bit',
        time = os.time,
        date = os.date,
        clock = function() return global_time end,
        ipairs = ipairs, next = next, type = type,
        setmetatable = setmetatable, pairs = pairs, rawget = rawget,
        tonumber = tonumber, tostring = tostring,
        join = table.concat,
        push = table.insert,
        pop = table.remove,
        remove = table.remove,
        insert = table.insert,
        shift = function(tbl) return table.remove(tbl, 1) end,
        sort = table.sort,
        unwrap = unpack,
        from_ascii = string.char,
        -- GPU
        clear = hw.clr,
        sprite = hw.spr,
        custom_sprite = hw.pspr,
        fill_rect = hw.rect_fill,
        fill_circ = hw.circle_fill,
        fill_tri = hw.tri_fill,
        fill_quad = hw.quad_fill,
        line = hw.line,
        rect = hw.rect,
        circ = hw.circle,
        tri = hw.tri,
        quad = hw.quad,
        clip = function (x, y, w, h)
            x = math.max(x, proc.priv.x)
            y = math.max(y, proc.priv.y)
            w = math.min(w, proc.priv.x+proc.priv.width-x)
            h = math.min(h, proc.priv.y+proc.priv.height-y)

            hw.clip(x, y, w, h)
        end,
        print = hw.print,
        measure = hw.measure,
        mouse_cursor = hw.set_cursor,
        start_recording = hw.start_capturing,
        stop_recording = hw.stop_capturing,
        get_pixel = gpu.get_pixel,
        put_pixel = gpu.put_pixel,
        get_sheet_pixel = function(x, y)
            local sheet = executing_process.priv.spritesheet
            return gpu.get_sheet_pixel(sheet.ptr, sheet.w, sheet.h, x, y)
        end,
        get_sheet_full = function(sheet, w, h)
            if sheet and w and h then
                return gpu.get_sheet_full(sheet, w, h)
            else
                local sheet = executing_process.priv.spritesheet
                return gpu.get_sheet_full(sheet.ptr, sheet.w, sheet.h)
            end
        end,
        put_sheet_pixel = function(x, y, color)
            local sheet = executing_process.priv.spritesheet
            return gpu.put_sheet_pixel(sheet.ptr, sheet.w, sheet.h, x, y, color)
        end,
        put_sheet_full = function(data, sheet, w, h)
            if sheet and w and h then
                return gpu.put_sheet_full(sheet, w, h, data)
            else
                local sheet = executing_process.priv.spritesheet
                return gpu.put_sheet_full(sheet.ptr, sheet.w, sheet.h, data)
            end
        end,
        get_sheet_size = function()
            local sheet = executing_process.priv.spritesheet

            return sheet.w, sheet.h
        end,
        save_sheet = function(file, sheet, w, h)
            if sheet and w and h then
                hw.save_spritesheet(sheet, w, h, file)
            else
                local sheet = executing_process.priv.spritesheet
                hw.save_spritesheet(sheet.ptr, sheet.w, sheet.h, file)
            end
        end,
        load_sheet = function(file)
            local ptr, w, h = hw.load_spritesheet(file)

            table.insert(executing_process.priv.external_spritesheets, {
                             ptr = ptr, w = w, h = h,
            })

            return ptr, w, h
        end,
        open_asset = function(asset, kind)
            return nib_open_asset(entrypoint, asset, kind)
        end,
        -- Color manipulation
        copy_palette = gpu.copy_palette,
        mask_color = gpu.mask_color,
        swap_colors = gpu.swap_colors,
        swap_screen_colors = gpu.swap_screen_colors,
        rgba_color = hw.rgba_color,
        -- Memory access
        read16 = hw.read16,
        read8 = hw.read8,
        read = hw.read,
        write = hw.write,
        -- Input
        UP = input.UP,
        DOWN = input.DOWN,
        LEFT = input.LEFT,
        RIGHT = input.RIGHT,
        RED = input.RED,
        BLUE = input.BLUE,
        BLACK = input.BLACK,
        WHITE = input.WHITE,
        MOUSE_LEFT = input.MOUSE_LEFT,
        MOUSE_RIGHT = input.MOUSE_RIGHT,
        SHIFT = input.SHIFT,
        CTRL = input.CTRL,
        ALT = input.ALT,
        GUI = input.GUI,
        button_down = input.button_down,
        button_up = input.button_up,
        button_press = input.button_press,
        button_release = input.button_release,
        mouse_button_down = input.mouse_button_down,
        mouse_button_up = input.mouse_button_up,
        mouse_button_press = input.mouse_button_press,
        mouse_button_release = input.mouse_button_release,
        mouse_position = input.mouse_position,
        mouse_scroll = input.mouse_scroll,
        read_keys = input.read_keys,
        read_key_events = input.read_key_events,
        read_midi = input.read_midi,
        -- Audio
        encode = audio.encode,
        channel = audio.channel,
        envelope = audio.envelope,
        freqs = audio.freqs,
        reverb = audio.reverb,
        route = audio.route,
        noteon = audio.noteon,
        noteoff = audio.noteoff,
        OP1 = audio.OP1,
        OP2 = audio.OP2,
        OP3 = audio.OP3,
        OP4 = audio.OP4,
        OUT = audio.OUT,
        CH1 = audio.CH1,
        CH2 = audio.CH2,
        CH3 = audio.CH3,
        CH4 = audio.CH4,
        CH5 = audio.CH5,
        CH6 = audio.CH6,
        CH7 = audio.CH7,
        CH8 = audio.CH8,
    }

    -- Expõe o sistema de arquivos para processos
    -- privilegiados
    --if is_privileged(entrypoint) then
        api.io = io
        api.os = os

        api.list_directory = hw.list
        api.create_directory = hw.create_directory
        api.touch_file = hw.touch_file
        api.create_file = hw.create_file

        api.loadstring = function(str)
            local chunk = loadstring(str)
            setfenv(chunk, executing_process.pub)

            return chunk
        end

        -- print("privileged:", entrypoint)
    --end

    return api
end
