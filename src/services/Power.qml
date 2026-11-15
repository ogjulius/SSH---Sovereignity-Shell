pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../utilities/Fmt.js" as Fmt

// Battery and power profiles via UPower / power-profiles-daemon.
Singleton {
    id: p
    readonly property var dev: UPower.displayDevice
    readonly property bool hasBattery: dev !== null && dev.isLaptopBattery && dev.isPresent
    readonly property real level: hasBattery ? dev.percentage : 1   // 0..1
    readonly property bool charging: hasBattery && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: hasBattery && dev.state === UPowerDeviceState.FullyCharged
    readonly property bool onBattery: UPower.onBattery
    readonly property bool low: hasBattery && !charging && level <= 0.15
    readonly property string timeLeft: !hasBattery ? "" : (charging ? Fmt.duration(dev.timeToFull) : Fmt.duration(dev.timeToEmpty))
    readonly property string stateLabel: !hasBattery ? "AC power" : (full ? "Full" : (charging ? "Charging" : (onBattery ? "Discharging" : "Plugged in")))
    readonly property real health: hasBattery && dev.healthSupported ? dev.healthPercentage / 100 : -1

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    function setProfile(pr) { PowerProfiles.profile = pr; }
    readonly property var profiles: hasPerformance ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    function profileName(pr) { return pr === PowerProfile.PowerSaver ? "Saver" : (pr === PowerProfile.Performance ? "Performance" : "Balanced"); }
}
