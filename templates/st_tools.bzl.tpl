"""
"""

def _st_opt(value, opt_prefix, default_value = ""):
    return "{opt_prefix}{value}".format(opt_prefix = opt_prefix, value = value) if value != default_value else ""

def _st_flash_direct_call_impl(ctx):
    # If not st-flash binary is provided, we use the system default one
    if len(ctx.files._st_flash_folder_script) == 0:
        st_flash_executable = "st-flash"
    else:
        st_flash_executable = ctx.files._st_flash_folder_script[0].path

    binary = ctx.attr.binary[OutputGroupInfo].bin.to_list()[0]
    script_content = "{st_flash} {cmd_with_binary}".format(
        st_flash = st_flash_executable,
        cmd_with_binary = ctx.attr.cmd.format(
            binary_path = "$BUILD_WORKSPACE_DIRECTORY/" + binary.path
            binary_runfile = "$BUILD_WORKSPACE_DIRECTORY/" + binary.path
        )
    )

    script_content += " --debug" if ctx.attr.debug else ""
    script_content += " " + _st_opt(ctx.attr.flash_address, "")
    script_content += " " + _st_opt(ctx.attr.serial, "--serial ")
    script_content += " " + _st_opt(ctx.attr.freq, "--freq=")
    script_content += " --connect-under-reset" if ctx.attr.connect_under_reset else ""
    
    if %{is_windows} == True:
        script_content = "pwsh -c \"{}\"".format(script_content)

    flash_extension = ".sh"
    if %{is_windows} == True:
        flash_extension = ".bat"

    flasher_wrapper = ctx.actions.declare_file(ctx.label.name + flash_extension)
    ctx.actions.write(
        output = flasher_wrapper,
        is_executable = True,
        content = script_content,
    )

    runfiles = ctx.runfiles([flasher_wrapper, binary])
    return [
        DefaultInfo(
            executable = flasher_wrapper,
            default_runfiles = runfiles,
        ),
        OutputGroupInfo(
            binary = ctx.attr.binary[OutputGroupInfo].bin,
        )
    ]

st_flash_direct_call = rule(
    implementation = _st_flash_direct_call_impl,
    attrs = {
        "binary": attr.label(mandatory = True, cfg = "target"),
        "cmd": attr.string(default = ""),

        "flash_address": attr.string(default = ""),
        "serial": attr.string(default = ""),
        "freq": attr.string(default = ""),
        "connect_under_reset": attr.bool(default = False),
        "debug": attr.bool(default = False),

        "_st_flash_folder_script": attr.label(default = Label("@bazel_stm32//st_tools:st_flash_executable")),
    },
    executable = True,
    provides = [DefaultInfo],
)

def st_flash(
        name,
        binary,
        flash_address = "0x08000000",
        **kwargs
    ):
    st_flash_direct_call(
        name = name,
        binary = binary,
        flash_address = flash_address,
        cmd = "write {binary_runfile}",
        **kwargs
    )

def _st_util_direct_call_impl(ctx):
    # If not st-util binary is provided, we use the system default one
    if len(ctx.files._st_util_folder_script) == 0:
        st_util_executable = "st-util"
    else:
        st_util_executable = ctx.files._st_util_folder_script[0].path

    script_content = "{st_util} {cmd}".format(
        st_util = st_util_executable,
        cmd = ctx.attr.cmd,
    )

    script_content += " " + _st_opt(ctx.attr.port, "--listen_port=")
    script_content += " " + _st_opt(ctx.attr.serial, "--serial ")
    script_content += " " + _st_opt(ctx.attr.freq, "--freq=")
    script_content += " --connect-under-reset" if ctx.attr.connect_under_reset  else ""
    script_content += " --no-reset" if ctx.attr.no_reset  else ""
    
    flash_extension = ".sh"
    if ctx.configuration.host_path_separator == ';':
        flash_extension = ".bat"
    elif ctx.configuration.host_path_separator != ':':
        print("Received unknown '{host_path_separator}' as PATH separator; Unix system is assumed".format(host_path_separator = ctx.configuration.host_path_separator))

    flasher_wrapper = ctx.actions.declare_file(ctx.label.name + flash_extension)
    ctx.actions.write(
        output = flasher_wrapper,
        is_executable = True,
        content = script_content,
    )

    runfiles = ctx.runfiles([flasher_wrapper])
    return [
        DefaultInfo(
            executable = flasher_wrapper,
            default_runfiles = runfiles,
        )
    ]

st_util_direct_call = rule(
    implementation = _st_util_direct_call_impl,
    attrs = {
        "cmd": attr.string(default = ""),

        "serial": attr.string(default = ""),
        "freq": attr.string(default = ""),
        "port": attr.string(default = ""),
        "connect_under_reset": attr.bool(default = False),
        "no_reset": attr.bool(default = False),

        "_st_util_folder_script": attr.label(default = Label("@bazel_stm32//st_tools:st_util_executable")),
    },
    executable = True,
    provides = [DefaultInfo],
)

def st_debug(
        name,
        **kwargs
    ):
    st_util_direct_call(
        name = name,
        **kwargs
    )
