"""
"""

STM32FamilyInfo = provider("", fields = {
    'family_name': "",
    'arm_cpu_version': "",
    'cpu': "",
    'fpu': "",
})

def stm32_family_info(
        family_name,
        arm_cpu_version,
        cpu,
        fpu = None
    ):
    return STM32FamilyInfo(
        family_name = family_name,
        arm_cpu_version = arm_cpu_version,
        cpu = cpu,
        fpu = fpu,
    )

def stm32_family_info_from_dict(stm32_family_info_dict):
    fpu = None
    if "fpu" in stm32_family_info_dict:
        fpu = stm32_family_info_dict["fpu"]
    return STM32FamilyInfo(
        family_name = stm32_family_info_dict["family_name"],
        arm_cpu_version = stm32_family_info_dict["arm_cpu_version"],
        cpu = stm32_family_info_dict["cpu"],
        fpu = fpu,
    )

# ARM Cortex-M0
STM32F0 = stm32_family_info(
    family_name = "STM32F0",
    arm_cpu_version = "armv6-m",
    cpu = "-mcpu=cortex-m0",
)

# ARM Cortex-M3
STM32F1 = stm32_family_info(
    family_name = "STM32F1",
    arm_cpu_version = "armv7-m",
    cpu = "-mcpu=cortex-m3"
)

# ARM Cortex-M3
STM32F2 = stm32_family_info(
    family_name = "STM32F2",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
)

# ARM Cortex-M4 with FPU
STM32F3 = stm32_family_info(
    family_name = "STM32F3",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
)

# ARM Cortex-M4 with FPU
STM32F4 = stm32_family_info(
    family_name = "STM32F4",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m4",
    fpu = "-mfpu=fpv4-sp-d16",
)

# ARM Cortex-M4 with FPU
STM32F7 = stm32_family_info(
    family_name = "STM32F7",
    arm_cpu_version = "armv7e-mf",
    cpu = "-mcpu=cortex-m7",
    fpu = "-mfpu=fpv4-sp-d16",
)

# ARM Cortex-M4 with FPU
STM32H5 = stm32_family_info(
    family_name = "STM32H5",
    arm_cpu_version = "armv8-m",
    cpu = "-mcpu=cortex-m33",
    fpu = "-mfpu=fpv4-sp-d16",
)

# ARM Cortex-M7 with FPU + ARM Cortex-M4 with FPU
# STM32H7 = stm32_toolchain(
#     family_name = "STM32H7",
#     arm_cpu_version = "F7: armv7e-mf; F4: armv7e-mf",
#     cpu = "-mcpu=cortex-m4",
#     fpu = "-mfpu=fpv4-sp-d16",
# )

def stm32_families_lut(stm32_families):
    """Generate an lookup table for STM32 mcu's families

    Args:
        stm32_families: The list of family
    Returns:
        The stm32's families lookup table
    """
    lut = {}
    for family in stm32_families:
        lut[family.family_name.upper()] = family
    return lut

STM32_FAMILIES_LUT = stm32_families_lut([
    STM32F0,
    STM32F1,
    # STM32F2,
    STM32F3,
    STM32F4,
    STM32F7,
    STM32H5,
    # STM32H7,
])

