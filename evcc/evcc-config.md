
Based on https://github.com/GrimmiMeloni/powerwall-backupCtrl 

Adapted for Sonnenbatterie


```

messaging:
  events:
    start:
      title: charging_started
      msg: ${title} started charging in ${mode} mode
    stop:
      title: charging_stopped
      msg: ${title} finished charging with ${chargedEnergy:%.1fk}kWh in ${chargeDuration}
    connect:
      title: vehicle_connected
      msg: Car connected on wallbox ${title}
    disconnect:
      title: vehicle_disconnected
      msg: Car disconnected from ${title} after ${connectedDuration}
    soc:
      title: soc_changed
      msg: ${vehicleSoc}

  services:
  - type: script
    cmdline: /home/mnagel/sonnenBatterie/sb-control.sh
    timeout: 30s

```