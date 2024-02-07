; Configures an ADJI joystick handler for FireTrack in SRAM (thus only works with Enhanced version on Master)
ORG &1900
CPU 1 ; 65C02 only aka Master

; OS Routines and Locations
KEYCODE=&EC
PAGEDROM=&F4
OSWORD=&FFF1
OSWRCH=&FFEE
OSBYTE=&FFF4
OSARGS=&FFDA
ACCCON=&FE34
ROMSEL=&FE30

; FireTrack
FTSRAM=7 ; so long as this is empty (no ROM), it is what FireTrack will use on a Master
FTSRAM_CONFIG_BASE=&B100 ; see https://www.level7.org.uk/miscellany/firetrack-disassembly.txt

; ADJI
ADJI_BASE=&FCC0

; Various ADJI handler locations in SRAM
adjihandler_sram_config=FTSRAM_CONFIG_BASE
adjihandler_sram=FTSRAM_CONFIG_BASE+&100

; Vars
testMode=&70 ; 1 byte
adjiKey=&71  ; 1 byte
cmdLine=&72  ; OSARGS output

.start
.exec
      JSR init                      ; look for command line args and adjust ADJI base address in handler (before copying to SRAM)
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
      STA adjihandler_sram,X        ; write code block to SRAM
      LDA #0                        ; clear source location to ensure no false positives when testing SRAM copy in test mode
      STA adjihandler_config,X      ; clear source location to ensure no false positives when testing SRAM copy in test mode
      STA adjihandler,X             ; clear source location to ensure no false positives when testing SRAM copy in test mode
      INX                           ; next byte to copy
      CPX #0                        ; done?
      BNE sram_copy_loop            ; loop back if not
.check_testMode
      LDA testMode                  ; test mode enabled?
      BEQ exit                      ; otherwise we are done
      JSR adjihandler_test          ; test handler without running FireTrack
.exit
      PLA                           ; pop current paged rom
      STA ROMSEL                    ; set current paged rom
      STA PAGEDROM                  ; set current paged rom
      RTS

.init
      LDA #0                        
      STA testMode                  ; test modd off by default
      STA adjiKey                   ; default to ADJI FCC0 
      LDA #1                        ; obtain command line args 
      LDX #cmdLine                  ; address for params buffer address
      LDY #0
      JSR OSARGS
      LDY #0                        ; parse command line args
.init_arg_loop
      LDA (cmdLine),Y               ; arg character
      CMP #&0D                      ; end of args?
      BEQ init_continue             ; done
      LDX #4                        ; check if its one of the 5 allowed
.init_parseOption
      CMP init_validOptions,X       ; valid arg character?
      BEQ init_validOption          ; process it
      DEX                           ; keep checking for others
      BNE init_parseOption          ; until all checked
      JMP init_next_arg             ; checked all and nothing, try next char
.init_validOption
      CMP #'T'                      ; test mode special char?
      BNE init_validOption_isKey    ; if not its going to be one of the key numbers
      LDA #255                      ; enable test mode
      STA testMode                  ; store for later ref
      JMP init_next_arg             ; keep looking for more params
.init_validOption_isKey
      SEC                           ; sec carry
      SBC #'1'                      ; obtain key index via simple subsctraction from ascii base
      STA adjiKey                   ; store for later ref
.init_next_arg
      INY
      JMP init_arg_loop
.init_continue                      ; following makes some adjustments to the handler code before relocation to SRAM
      LDX adjiKey                   ; index into ADJI addressing table
      LDA init_validOffets,X        ; read applicable offet address based on key given
      STA adjihandler_read_adji+1   ; patch the handler read ADJI low byte
      LDA #HI(adjihandler_sram)     ; high byte of sram code
      STA adjihandler_read_masks+2  ; patch the handler read ADJI masks high byte
      RTS
.init_validOptions
      EQUS "1234T"
.init_validOffets
      EQUB $C0,$D0,$E0,$F0          ; see ADJI repo README for dip switch settings that determine these

.adjihandler_test
      LDA #&13                      ; v-sync delay between sampling
      JSR OSBYTE                    ; v-sync delay between sampling
      LDY #0                        ; action index
.adjihandler_test_buttons
      TYA                           ; action index goes in A
      JSR adjihandler_sram          ; test the adji handler (from its SRAM location)
      BPL adjiHandler_test_next     ; test next action
      LDA adjihandler_test_act,Y    ; confirm action detected with applicable action ASCII char
      JSR OSWRCH                    ; print character in A
.adjiHandler_test_next
      INY                           ; increment next action to test
      CPY #5                        ; done testing all actions?
      BNE adjihandler_test_buttons  ; test another action
      LDA KEYCODE                   ; any key exits the test
      BEQ adjihandler_test          ; any key exits the test
      RTS
.adjihandler_test_act
      EQUS "LRDUF"

      ALIGN &100                    ; copied to &B100 by above - configuration must reside at this address
.adjihandler_config 
      EQUS "** FireTrack ** by Orlando.(C) Aardvark Software 1987." ; magic string at &B100 is required
      EQUB 0,0,0,0,0,0,0,0,0,0      ; not used 
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
      EQUB LO(adjihandler_sram)     ; LOW ADDR of sram entry point for the .adjihandler 
      EQUB HI(adjihandler_sram)     ; HIGH ADDR of sram entry point for the .adjihandler 
      EQUB 0                        ; LEFT movement parameter value passed in A to .adjhandler
      EQUB 1                        ; RIGHT movement parameter value passed in A to .adjhandler
      EQUB 2                        ; DOWN movement parameter value passed in A to .adjhandler
      EQUB 3                        ; UP movement parameter value passed in A to .adjhandler
      EQUB 4                        ; FIRE movement parameter value passed in A to .adjhandler

      ALIGN &100                    ; be aware this is copied to &B200 and executed from this location, relocatable code only
.adjihandler                        ; this code must respect inputs and outputs per "check_joystick" (see FireTrack disassemble link above)
      PHX                           ; store entry X
      PHA                           ; push action index
      LDA ACCCON                    ; read ACCCON
      PHA                           ; store current value on stack
      LDA #&20                      ; set bit 5
      TSB ACCCON                    ; set bit 5 of ACCON
.adjihandler_read_adji              
      LDA ADJI_BASE                 ; read joystick value (low byte base address adjusted before copying to SRAM, see init routine above)
      PLX                           ; pull prior ACCCON value into X
      STX ACCCON                    ; restore ACCCON back to its prior value
      PLX                           ; restore action index into
.adjihandler_read_masks
      AND adjihandler_masks, X      ; mask joystick value according to action index (absolute address patched in init routine before relocate)
      BNE adjihandler_detected      ; action detected?
      PLX                           ; restore entry X
      LDA #0                        ; no action detected
      RTS
.adjihandler_detected  
      PLX                           ; restore entry X
      LDA #&FF                      ; action detected
      RTS
.adjihandler_masks
      EQUB 4,8,2,1,16               ; bitmasks used by ADJI joystick value LEFT, RIGHT, DOWN, UP and FIRE
.end
 
PUTFILE "dev/firetrack-adji/!BOOT", "!BOOT", &0000
PUTFILE "dev/firetrack-adji/!FTLoad", "!FTLoad", &1F00
PUTFILE "dev/firetrack-adji/!FTrack", "!FTrack", &1A00, &1A00
PUTFILE "dev/firetrack-adji/FireTra", "FireTra", &1900, &802B
SAVE "!FTADJI", start, end, exec 