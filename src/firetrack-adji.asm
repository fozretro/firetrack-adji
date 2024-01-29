\ Configures the ADJI joystick handler for FireTrack (requires sideways RAM)

ORG &1900

.start
.exec
      LDA &F4
      PHA
      LDA #7
      STA &FE30
      STA &F4

      LDX #0
.loop 
      LDA config,X
      STA &B100,X
      INX
      CPX #0
      BNE loop

      PLA
      STA &FE30
      STA &F4
      RTS

      ALIGN &100
.config 
      EQUS "** FireTrack ** by Orlando.(C) Aardvark Software 1987."
      EQUB 0,0,0,0,0,0,0,0,0,0
      EQUB 255
      EQUS "KEYS"
      EQUB -97
      EQUB -17
      EQUB -87
      EQUB -56
      EQUB -72
.end
 
PUTFILE "dev/firetrack-adji/!BOOT", "!BOOT", &0000
PUTFILE "dev/firetrack-adji/!FTLoad", "!FTLoad", &1F00
PUTFILE "dev/firetrack-adji/!FTrack", "!FTrack", &1A00, &1A00
PUTFILE "dev/firetrack-adji/FireTra", "FireTra", &1900, &802B
SAVE "!FTADJI", start, end, exec 