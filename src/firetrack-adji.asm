\ Configures the ADJI joystick handler for FireTrack (requires sideways RAM)
ORG &1900
CPU 1

; OS Routines and Locations
OSWORD=&FFF1
OSWRCH=&FFEE
OSBYTE=&FFF4
OSARGS=&FFDA
KEYCODE=&EC
ACCCON=&FE34
PAGEDROM=&F4
ROMSEL=&FE30

; FireTrack
FTSRAM=7 ; so long as this is empty (no ROM), it is what FireTrack will use on a Master
FTSRAM_CONFIG_BASE=&B100 ; see https://www.level7.org.uk/miscellany/firetrack-disassembly.txt

; ADJI
ADJI_BASE=&FCC0

; Various ADJI handler locations in SRAM
adjihandler_sram_config=FTSRAM_CONFIG_BASE
adjihandler_sram_code=FTSRAM_CONFIG_BASE+&100
adjihandler_sram_masks=FTSRAM_CONFIG_BASE+&120

.start
.exec
      LDA PAGEDROM                  ; current paged rom
      PHA                           ; store on stack
      LDA #FTSRAM                   ; Firetrack SRAM 
      STA ROMSEL                    ; set current paged rom
      STA PAGEDROM                  ; set current paged rom
      LDX #0                        ; loop to copy config and code to sram
.sram_copy_loop 
      LDA adjihandler_config,X      ; read config block
      STA adjihandler_sram_config,X ; write config block to SRAM
      LDA adjihandler,X             ; read code block
      STA adjihandler_sram_code,X   ; write code block to SRAM
      LDA #0                        ; clear source location to ensure no false positives when testing SRAM copy in test mode
      STA adjihandler_config,X      ; clear source location to ensure no false positives when testing SRAM copy in test mode
      STA adjihandler,X             ; clear source location to ensure no false positives when testing SRAM copy in test mode
      INX                           ; next byte to copy
      CPX #0                        ; done?
      BNE sram_copy_loop            ; loop back if not
      JSR test                      ; development mode - uncomment to test without running FireTrack
      PLA                           ; pop current paged rom
      STA ROMSEL                    ; set current paged rom
      STA PAGEDROM                  ; set current paged rom
      RTS

.test
      LDA #&13                      ; v-sync delay between sampling
      JSR OSBYTE                    ; v-sync delay between sampling
      LDY #0                        ; action index
.testButtons
      TYA                           ; action index goes in A
      JSR adjihandler_sram_code     ; test the adji handler (from its SRAM location)
      BPL testNext                  ; test next action
      LDA actions,Y                 ; confirm action detected with applicable action ASCII char
      JSR OSWRCH                    ; print character in A
.testNext
      INY                           ; increment next action to test
      CPY #5                        ; done testing all actions?
      BNE testButtons               ; test another action
      LDA KEYCODE                   ; any key exits the test
      BEQ test                      ; any key exits the test
.endtest
      RTS
.actions
      EQUS "LRDUF"

      ALIGN &100                    ; copied to &B100 by above - configuration must reside at this address
.adjihandler_config 
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

      ALIGN &100                    ; be aware this is copied to &B200 by above, relocatable code only
.adjihandler                        ; this code must respect inputs and outputs per "check_joystick" (see FireTrack disassemble link above)
      PHX                           ; store entry X
      PHA                           ; push action index
      LDA ACCCON                    ; read ACCCON
      PHA                           ; store current value on stack
      LDA #&20                      ; set bit 5
      TSB ACCCON                    ; set bit 5 of ACCON
.readADJI
      LDA ADJI_BASE                 ; read joystick value (base address adjusted before copying to SRAM, see above)
      PLX                           ; pull prior ACCCON value into X
      STX ACCCON                    ; restore ACCCON back to its prior value
      PLX                           ; restore action index into X
      AND adjihandler_sram_masks,X  ; mask joystick value according to action index
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