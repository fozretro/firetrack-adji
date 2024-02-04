\ Configures the ADJI joystick handler for FireTrack (requires sideways RAM)

ORG &1900
CPU 1

.start
.exec
      LDA &F4                       ; current paged rom
      PHA                           ; store on stack
      LDA #7                        ; hard coded sram 7 for now - TODO repliace FireTrack selection code
      STA &FE30                     ; set current paged rom
      STA &F4                       ; set current paged rom
      LDX #0                        ; loop to copy config and code to sram
.loop 
      LDA config,X                  ; read config block
      STA &B100,X                   ; write config block
      LDA config+&100,X             ; read code block
      STA &B200,X                   ; write code block
      INX                           ; next byte to copy
      CPX #0                        ; done?
      BNE loop                      ; loop back if not
      ;JSR test
      PLA                           ; pop current paged rom
      STA &FE30                     ; set current paged rom
      STA &F4                       ; set current paged rom
      RTS

.test
      LDY #0                        ; action index
      JSR &FFE0                     ; wait for a key
.testButtons
      TYA                           ; action index goes in A
      JSR &B200                     ; test the adji handler (from SRAM location)
      BPL testNext                  ; test next 
      LDA buttons,Y                 ; action ASCII char
      JSR &FFEE                     ; print character in A
.testNext
      INY
      CPY #5
      BNE testButtons
      JMP test
.buttons
      EQUS "LRDUF"

      ALIGN &100                    ; copied to &B100 by above - configuration must reside at this address
.config 
      EQUS "** FireTrack ** by Orlando.(C) Aardvark Software 1987."     ; magic string at &B100 is required
      EQUB 0,0,0,0,0,0,0,0,0,0                                          ; not used 

      EQUB 255                      ; 255 donates the start of a config value, in this case KEYS
      EQUS "KEYS"                   ; magic string for alternative keys
      EQUB -97                      ; INKEY value for left key
      EQUB -17                      ; INKEY value for right key
      EQUB -87                      ; INKEY value for down key
      EQUB -56                      ; INKEY value for up key
      EQUB -72                      ; INKEY value for fire key
      EQUB 0                        ; not used
      EQUB 0                        ; not used
      EQUB 0                        ; not used
      EQUB 0                        ; not used
      EQUB 0                        ; not used
      EQUB 0                        ; not used

      EQUB 255                      ; 255 donates the start of a config value, in this case DEVICE
      EQUS "DEVICE"                 ; magic string for customer joystick handler
      EQUB &00                      ; LOW ADDR of &B200 aka entry point of the .adjihandler 
      EQUB &B2                      ; HIGH ADDR of &B200 aka entry point of the .adjihandler 
      EQUB 0                        ; LEFT movement parameter value passed in A to .adjhandler
      EQUB 1                        ; RIGHT movement parameter value passed in A to .adjhandler
      EQUB 2                        ; DOWN movement parameter value passed in A to .adjhandler
      EQUB 3                        ; UP movement parameter value passed in A to .adjhandler
      EQUB 4                        ; FIRE movement parameter value passed in A to .adjhandler

      ALIGN &100                    ; copied to &B200 by above
.adjihandler
      PHX                           ; store entry X
      PHA                           ; push action index
      LDA &FE34                     ; read ACCCON
      PHA                           ; store current value on stack
      LDA #&20                      ; set bit 5
      TSB &FE34                     ; set bit 5 of ACCON
      LDA &FCC0                     ; read joystick value
      PLX                           ; pull prior ACCCON value into X
      STX &FE34                     ; restore ACCCON back to its prior value
      PLX                           ; restore action index into X
      AND &B220,X                   ; mask joystick value according to action index
      BNE detected                  ; action detected?
      PLX                           ; restore entry X
      LDA #0                        ; no action detected
      RTS
.detected  
      PLX                           ; restore entry X
      LDA #&FF                      ; action detected
      RTS
.masks
      EQUB 4,8,2,1,16               ; bitmasks used by ADJI joystick value LEFT, RIGHT, DOWN, UP and FIRE
.end
 
PUTFILE "dev/firetrack-adji/!BOOT", "!BOOT", &0000
PUTFILE "dev/firetrack-adji/!FTLoad", "!FTLoad", &1F00
PUTFILE "dev/firetrack-adji/!FTrack", "!FTrack", &1A00, &1A00
PUTFILE "dev/firetrack-adji/FireTra", "FireTra", &1900, &802B
SAVE "!FTADJI", start, end, exec 