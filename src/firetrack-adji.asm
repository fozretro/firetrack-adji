\ Configures the ADJI joystick handler for FireTrack (requires sideways RAM)

ORG &1900

.start
.exec
      LDA #66
      JSR &FFEE
      RTS
.end
 
PUTFILE "dev/firetrack-adji/!BOOT", "!BOOT", &0000
PUTFILE "dev/firetrack-adji/!FTLoad", "!FTLoad", &1F00
PUTFILE "dev/firetrack-adji/!FTrack", "!FTrack", &1A00, &1A00
PUTFILE "dev/firetrack-adji/FireTra", "FireTra", &1900, &802B
SAVE "!FTADJI", start, end, exec 