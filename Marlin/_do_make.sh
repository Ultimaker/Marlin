#!/bin/bash
#
# Clone of _do_make.bat for linux/osx
#

usage() {
  cat <<-EOF >&2
	Usage: $0 [-t {UMO|HBK|UMOP}][-s Suffix] [-D Define]...
	with
	  -t target : Target firmware, default is UMO
	  -s Suffix : Suffix used for the firmware name, default derived from target
	  -D Define : Additional 'DEFINES' passed to Make 
	              Can be used multiple times, quoting required for strings, no spaces allowed
	Example: UMO+ with version in firmware
	  $0 -t UMOP -D "'VERSION_BASE=\"Ultimaker:_14.12\"'"
	Use ARDUINO_PATH and ARDUINO_VERSION environment variables to set/override your Arduino location and version
EOF
  exit 1
}

# Defaults: we build for UMO, no Suffix in firmware name, no additional defines
Target="UMO"
Suffix=""
Defines=""

# Arduino defaults
# Override this by setting the respective environment variables
: ${ARDUINO_PATH:="/Applications/Arduino-1.0.3.app/Contents/Resources/Java"}
: ${ARDUINO_VERSION:=103}

PATH="${ARDUINO_PATH}/hardware/tools/avr/bin:${PATH}"

# Defaults for UMO:
HARDWARE_MOTHERBOARD=7
TEMP_SENSOR_1=-1

# Parse arguments 
while [ $# -gt 0 ]
do
  case "$1" in
    -t)
      if [ $# -lt 2 ]
      then
        usage
      else
        Target="$2"
        case "${Target}" in
          UMO)
            # Nothing to do, it is our default
            ;;
          HBK)
            # Add define and set Suffix
            Suffix="HBK"
            Defines="${Defines} ULTIMAKER_HBK"
            ;;
          UMOP)
            # Set board, sensor and Suffix
            Suffix="UMOP"
            HARDWARE_MOTHERBOARD=72
            TEMP_SENSOR_1=20
            ;;
          *)
            # Invalid
            usage
            ;;
        esac
        shift; shift
      fi
      ;;
    -s)
      if [ $# -lt 2 ]
      then
        usage
      else
        # Set suffix
        Suffix="$2"
        shift; shift
      fi
      ;;
    -D)
      if [ $# -lt 2 ]
      then
        usage
      else
        # Concatenate defines
        Defines="${Defines} $2"
        shift; shift
      fi
      ;;
    *)
      usage
      ;;
  esac
done

cat <<-EOF
	$0: Build summary
	  Building for    : ${Target}
	  Build suffix    : ${Suffix}
	  Motherboard     : ${HARDWARE_MOTHERBOARD}
	  Temp sensor     : ${TEMP_SENSOR_1}
	  Defines         : ${Defines}
	  Arduino path    : ${ARDUINO_PATH}
	  Arduino version : ${ARDUINO_VERSION}	
EOF

BASE_PARAMS="HARDWARE_MOTHERBOARD=${HARDWARE_MOTHERBOARD} ARDUINO_INSTALL_DIR=${ARDUINO_PATH} ARDUINO_VERSION=${ARDUINO_VERSION}"

make ${BASE_PARAMS} BUILD_DIR=_UltimakerMarlin${Suffix:+_$Suffix}_250000 \
  DEFINES="'VERSION_PROFILE=\"250000_single\"' BAUDRATE=250000 TEMP_SENSOR_1=0 EXTRUDERS=1 ${Defines}"
make ${BASE_PARAMS} BUILD_DIR=_UltimakerMarlin${Suffix:+_$Suffix}_115200 \
  DEFINES="'VERSION_PROFILE=\"115200_single\"' BAUDRATE=115200 TEMP_SENSOR_1=0 EXTRUDERS=1 ${Defines}"
make ${BASE_PARAMS} BUILD_DIR=_UltimakerMarlin${Suffix:+_$Suffix}_Dual_250000 \
  DEFINES="'VERSION_PROFILE=\"250000_dual\"' BAUDRATE=250000 TEMP_SENSOR_1=${TEMP_SENSOR_1} EXTRUDERS=2 ${Defines}"
make ${BASE_PARAMS} BUILD_DIR=_UltimakerMarlin${Suffix:+_$Suffix}_Dual_115200 \
  DEFINES="'VERSION_PROFILE=\"115200_dual\"' BAUDRATE=115200 TEMP_SENSOR_1=${TEMP_SENSOR_1} EXTRUDERS=2 ${Defines}"

cp _UltimakerMarlin${Suffix:+_$Suffix}_250000/Marlin.hex MarlinUltimaker${Suffix:+-$Suffix}-250000.hex
cp _UltimakerMarlin${Suffix:+_$Suffix}_115200/Marlin.hex MarlinUltimaker${Suffix:+-$Suffix}-115200.hex
cp _UltimakerMarlin${Suffix:+_$Suffix}_Dual_250000/Marlin.hex MarlinUltimaker${Suffix:+-$Suffix}-250000-dual.hex
cp _UltimakerMarlin${Suffix:+_$Suffix}_Dual_115200/Marlin.hex MarlinUltimaker${Suffix:+-$Suffix}-115200-dual.hex
