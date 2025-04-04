"""
"""

def _get_cmd_action_script(ctx):
    scripts_folder = ctx.attr.scripts_folder
    if scripts_folder == None or scripts_folder == "":
        scripts_folder = "{external}external/bazel_stm32+/tools/scripts" # %{rctx_name}

    if len(ctx.files._openocd_executable) == 0:
        openocd_executable = "openocd"
    else:
        openocd_executable = ctx.files._openocd_executable[0].path

    cmd_action = openocd_executable
    cmd_action = cmd_action + " -s \"{}\"".format(scripts_folder)
    for script_file in ctx.attr.script_files:
        cmd_action = cmd_action + " -f \"{}\"".format(script_file)
    cmd_action = cmd_action + " -c \"{cmd}\""

    if %{is_windows} == False:
        direct_call_wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")
    else:
        direct_call_wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
        cmd_action = cmd_action.replace("\"", "\\\"")
        cmd_action = "pwsh -c \"{}\"".format(cmd_action)

    return cmd_action, direct_call_wrapper

def _openocd_direct_call_bin_impl(ctx):
    cmd_action, direct_call_wrapper = _get_cmd_action_script(ctx)

    cmd = ctx.attr.cmd.format(
        binary_path = "$BUILD_WORKSPACE_DIRECTORY/" + ctx.attr.binary[OutputGroupInfo].elf.to_list()[0].path,
        binary_runfile = "$BUILD_WORKSPACE_DIRECTORY/" + ctx.attr.binary[OutputGroupInfo].elf.to_list()[0].basename,
    )

    ctx.actions.write(
        output = direct_call_wrapper,
        is_executable = True,
        content = cmd_action.format(
            external = "$(realpath $BUILD_WORKSPACE_DIRECTORY/bazel-out)/../../../",
            cmd = cmd
        )
    )

    runfiles = ctx.runfiles([direct_call_wrapper, ctx.attr.binary[OutputGroupInfo].elf.to_list()[0]])
    return [
        DefaultInfo(
            executable = direct_call_wrapper,
            default_runfiles = runfiles,
        ),
        OutputGroupInfo(
            elf = ctx.attr.binary[OutputGroupInfo].elf,
        )
    ]

openocd_direct_call_bin = rule(
    implementation = _openocd_direct_call_bin_impl,
    attrs = {
        "_openocd_executable": attr.label(default = Label("@bazel_stm32//tools:openocd_executable")),

        "binary": attr.label(cfg = "target"),

        "cmd": attr.string(mandatory = True),

        "scripts_folder": attr.string(default = ""),
        "script_files": attr.string_list(mandatory = True),
    },
    executable = True,
    provides = [DefaultInfo],
)

def openocd_flash(name, binary, **kwargs):
    openocd_direct_call_bin(
        name = name,
        binary = binary,
        cmd = "program {binary_runfile} reset exit",
        **kwargs,
    )

def openocd_flash_dbg(name, binary, **kwargs):
    openocd_direct_call_bin(
        name = name,
        binary = binary,
        cmd = "program {binary_runfile} reset",
        **kwargs,
    )

def openocd_debug_binary(name, binary, **kwargs):
    openocd_direct_call_bin(
        name = name,
        binary = binary,
        cmd = "",
        **kwargs,
    )

def _openocd_direct_call_impl(ctx):
    cmd_action, direct_call_wrapper = _get_cmd_action_script(ctx)

    ctx.actions.write(
        output = direct_call_wrapper,
        is_executable = True,
        content = cmd_action.format(
            external = "$(realpath $BUILD_WORKSPACE_DIRECTORY/bazel-out)/../../../",
            cmd = ctx.attr.cmd,
        )
    )

    runfiles = ctx.runfiles([direct_call_wrapper])
    return [
        DefaultInfo(
            executable = direct_call_wrapper,
            default_runfiles = runfiles,
        ),
    ]

openocd_direct_call = rule(
    implementation = _openocd_direct_call_impl,
    attrs = {
        "_openocd_executable": attr.label(default = Label("@bazel_stm32//tools:openocd_executable")),
        "_scripts": attr.label(default = Label("@bazel_stm32//tools:scripts")),
        
        "cmd": attr.string(mandatory = True),

        "scripts_folder": attr.string(default = ""),
        "script_files": attr.string_list(mandatory = True),
    },
    executable = True,
    provides = [DefaultInfo],
)

def openocd_debug(name, **kwargs):
    openocd_direct_call(
        name = name,
        cmd = "",
        **kwargs,
    )

def openocd_clear(name, **kwargs):
    openocd_direct_call(
        name = name,
        cmd = "",
        **kwargs,
    )
