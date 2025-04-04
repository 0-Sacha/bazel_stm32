""

load("@bazel_arm//arm_gcc/registry:registry.bzl", "ARM_GCC_REGISTRY")
load("@bazel_arm//arm_gcc:rules.bzl", "arm_gcc_toolchain", "arm_gcc_archive")
load("@bazel_skylib//lib:sets.bzl", "sets")

load("//mcu:stm32_families.bzl", "STM32_FAMILIES_LUT", "stm32_family_info_from_dict")

def _impl_stm32_rules(rctx):
    is_windows = "False"
    if "windows" in rctx.os.name:
        is_windows = "True"

    extension = ""
    if is_windows == "True":
        extension = ".exe"

    substitutions = {
        "%{rctx_name}": rctx.name,
        "%{rctx_name_split}": rctx.name.split("+")[-1],
        
        "%{toolchain_path}": "external/{}/".format(rctx.name),

        "%{arm_none_eabi_repo_name}": rctx.attr.arm_none_eabi_repo_name,

        "%{is_windows}": is_windows,
        "%{extension}": extension,

        "%{MCU_ID}": rctx.attr.mcu,
        "%{MCU_FAMILY}": rctx.attr.stm32_family,

        "%{exec_compatible_with}": json.encode(rctx.attr.exec_compatible_with),
        "%{target_compatible_with}": json.encode(rctx.attr.target_compatible_with),

        "%{toolchain_mcu_constraint}": json.encode(rctx.attr.toolchain_mcu_constraint),
    }
    rctx.template(
        "BUILD.bazel",
        Label("//templates:BUILD.bazel.tpl"),
        substitutions
    )
    rctx.template(
        "rules.bzl",
        Label("//templates:rules.bzl.tpl"),
        substitutions
    )
    rctx.template(
        "st_tools.bzl",
        Label("//templates:st_tools.bzl.tpl"),
        substitutions
    )
    rctx.template(
        "openocd.bzl",
        Label("//templates:openocd.bzl.tpl"),
        substitutions
    )

_stm32_rules = repository_rule(
    implementation = _impl_stm32_rules,
    attrs = {
        'arm_none_eabi_repo_name': attr.string(mandatory = True),

        'mcu': attr.string(mandatory = True),
        'stm32_family': attr.string(mandatory = True),

        'exec_compatible_with': attr.string_list(default = []),
        'toolchain_mcu_constraint': attr.string_list(default = []),
        'target_compatible_with': attr.string_list(default = []),
    },
)

def stm32_toolchain(
        name,

        mcu,
        device_group,
        custom_stm32_family_info = None,

        extra_mcuopts = [],
        copts = [],
        conlyopts = [],
        cxxopts = [],
        linkopts = [],
        defines = [],
        includedirs = [],
        linkdirs = [],
        linklibs = [],
        # dbg / opt
        dbg_copts = [],
        dbg_linkopts = [],
        opt_copts = [],
        opt_linkopts = [],

        specs = [],

        arm_toolchain_extras_filegroups = [],

        exec_compatible_with = [],
        target_compatible_with = [],
        use_mcu_constraint = True,

        arm_none_eabi_version = "latest",
        arm_registry = ARM_GCC_REGISTRY,
        arm_compiler_archive_package = None,
    ):
    """STM32 toolchain

    This macro create a repository containing all files needed to get an STM32 toolchain using an arm-none-eabi Toolchain

    Args:
        name: Name of the repo that will be created

        mcu: STM32 mcu name
        device_group: device_group
        custom_stm32_family_info: information about the mcu you are using if you don't want to use the provided STM32_FAMILIES_LUT

        extra_mcuopts: extra_mcuopts
        copts: copts
        conlyopts: conlyopts
        cxxopts: cxxopts
        linkopts: linkopts
        defines: defines
        includedirs: includedirs
        linkdirs: linkdirs
        linklibs: linklibs
        # dbg / opt
        dbg_copts: dbg_copts
        dbg_linkopts: dbg_linkopts
        opt_copts: opt_copts
        opt_linkopts: opt_linkopts

        specs: specs for the compiler (nano, nosys, ...)

        arm_toolchain_extras_filegroups: arm_toolchain_extras_filegroups

        exec_compatible_with: The exec_compatible_with list for the toolchain
        target_compatible_with: The target_compatible_with list for the toolchain
        use_mcu_constraint: Add the mcu_constraint list (cpu / stm32 family) to the target_compatible_with

        arm_none_eabi_version: The arm-none-eabi archive version
        arm_registry: The arm registry to use. Default to @bazel_arm//arm_gcc/registry:ARM_GCC_REGISTRY
        arm_compiler_archive_package: The arm archive to use. If none are provided, one will be define automatically with this name: ":arm-none-eabi-" + mcu
    """
    mcu = mcu.upper()
    stm32_family_info = custom_stm32_family_info
    if stm32_family_info == None:
        stm32_family = mcu[:7]
        stm32_family_info = STM32_FAMILIES_LUT[stm32_family]
    mcuopts = [ "-mthumb" ] + extra_mcuopts + [ stm32_family_info.cpu ]
    if hasattr(stm32_family_info, "fpu") and stm32_family_info.fpu != None:
        mcuopts += [ stm32_family_info.fpu ]

    toolchain_mcu_constraint = [
        "@platforms//cpu:{}".format(stm32_family_info.arm_cpu_version),
        # "@bazel_stm32//mcu:{}".format(stm32_family.lower()),
    ]

    if use_mcu_constraint:
        target_compatible_with = target_compatible_with + toolchain_mcu_constraint

    arm_gcc_toolchain(
        name = "arm-none-eabi-" + name,
        toolchain_type = "arm-none-eabi",
        toolchain_version = arm_none_eabi_version,

        exec_compatible_with = exec_compatible_with,
        target_compatible_with = target_compatible_with,

        copts = mcuopts + copts,
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        linkopts = mcuopts + linkopts,
        defines = defines + [ device_group ],
        includedirs = includedirs,
        linkdirs = linkdirs,
        linklibs = linklibs,
        # dbg / opt
        dbg_copts = dbg_copts,
        dbg_linkopts = dbg_linkopts,
        opt_copts = opt_copts,
        opt_linkopts = opt_linkopts,

        specs = specs,

        toolchain_extras_filegroups = arm_toolchain_extras_filegroups,

        registry_json = json.encode(arm_registry),

        compiler_archive_package = arm_compiler_archive_package,
    )

    _stm32_rules(
        name = name,
        arm_none_eabi_repo_name = "arm-none-eabi-" + name,
        mcu = mcu,
        stm32_family = stm32_family,
        toolchain_mcu_constraint = toolchain_mcu_constraint,
        target_compatible_with = target_compatible_with,
    )


def _impl_stm32_toolchain_extension(module_ctx):
    toolchain_versions_list = [
        platform.toolchain_version
        for mod in module_ctx.modules 
        for platform in mod.tags.stm32_platform
    ]
    if len(toolchain_versions_list) == 0:
        toolchain_versions_list.append("latest")
    toolchain_versions_list = sets.to_list(sets.make(toolchain_versions_list))
    arm_registry = ARM_GCC_REGISTRY
    for version in toolchain_versions_list:
        arm_gcc_archive(
            name = "archive_arm-none-eabi-" + version,
            toolchain_type = "arm-none-eabi",
            toolchain_version = version,
            registry_json = json.encode(arm_registry),
        )

    for mod in module_ctx.modules:
        for platform in mod.tags.stm32_platform:
            custom_stm32_family_info = None
            if platform.custom_stm32_family_info != {}:
                custom_stm32_family_info = stm32_family_info_from_dict(platform.custom_stm32_family_info)
            stm32_toolchain(
                name = platform.name,

                mcu = platform.mcu,
                device_group = platform.device_group,
                custom_stm32_family_info = custom_stm32_family_info,

                extra_mcuopts = platform.extra_mcuopts,
                copts = platform.copts,
                conlyopts = platform.conlyopts,
                cxxopts = platform.cxxopts,
                linkopts = platform.linkopts,
                defines = platform.defines,
                includedirs = platform.includedirs,
                linkdirs = platform.linkdirs,
                linklibs = platform.linklibs,
                # dbg / opt
                dbg_copts = platform.dbg_copts,
                dbg_linkopts = platform.dbg_linkopts,
                opt_copts = platform.opt_copts,
                opt_linkopts = platform.opt_linkopts,

                specs = platform.specs,

                arm_toolchain_extras_filegroups = platform.arm_toolchain_extras_filegroups,

                exec_compatible_with = platform.exec_compatible_with,
                target_compatible_with = platform.target_compatible_with,
                use_mcu_constraint = platform.use_mcu_constraint,

                arm_compiler_archive_package = "@archive_arm-none-eabi-" + platform.toolchain_version,
            )
    
stm32_toolchain_extension = module_extension(
    implementation = _impl_stm32_toolchain_extension,
    tag_classes = {
        "stm32_platform": tag_class(attrs = {
            'name': attr.string(mandatory = True),

            'toolchain_version': attr.string(default = "latest"),
            
            'mcu': attr.string(mandatory = True),
            'device_group': attr.string(mandatory = True),
            'custom_stm32_family_info': attr.string_dict(default = {}),

            'exec_compatible_with': attr.string_list(default = []),
            'target_compatible_with': attr.string_list(default = []),
            'use_mcu_constraint': attr.bool(default = True),

            'extra_mcuopts': attr.string_list(default = []),
            'copts': attr.string_list(default = []),
            'conlyopts': attr.string_list(default = []),
            'cxxopts': attr.string_list(default = []),
            'linkopts': attr.string_list(default = []),
            'defines': attr.string_list(default = []),
            'includedirs': attr.string_list(default = []),
            'linkdirs': attr.string_list(default = []),
            'linklibs': attr.string_list(default = []),
            # dbg / opt
            'dbg_copts': attr.string_list(default = []),
            'dbg_linkopts': attr.string_list(default = []),
            'opt_copts': attr.string_list(default = []),
            'opt_linkopts': attr.string_list(default = []),

            'specs': attr.string_list(default = []),

            'arm_toolchain_extras_filegroups': attr.label_list(default = []),
        }),
    },
)
