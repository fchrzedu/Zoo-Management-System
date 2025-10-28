; Public GitHub Repo = https://github.com/fchrzedu/Zoo-Management-System
; History & commits available in private repo upon request
; This code is fully complete, but lacks input validation except checking dupe IDs, their lengths and elements
; It has some modularity :)


%include "/home/malware/asm/joey_lib_io_v9_release.asm" ; provided library by COMP6016

global main

section .data       
  ; ------------------------ DISPLAY STAFF PROMPTS ------------------------
        staff_empty_records: db "Table is empty, please input a member of Staff first",10,0
        display_staff_header: db "----------------------------STAFF RECORD NO. ",0
        display_staff_surname: db "Surname = ",0
        display_staff_firstname: db "Firstname = ",0
        display_staff_id: db "ID = ",0
        display_staff_departament: db "Departament = ",0
        
        display_staff_years: db "Years of service = ",0
        display_staff_salary: db "Current Salary (£) = ",0
        display_staff_email: db "Email = ",0
  ; ------------------------ DISPLAY BADGER PROMPTS ------------------------
        badger_empty_records: db "Table is empty, please input a Badger first",10,0
        display_badger_header: db "----------------------------BADGER RECORD NO. ",0
        display_badger_id: db "ID = ",0
        display_badger_name: db "Name = ",0
        display_badger_home_setting: db "Home = ",0
        display_badger_mass: db "Mass (whole kg) = ",0
        display_badger_stripes: db "Stripes no. = ",0
        display_badger_stripiness: db "Stripiness = ",0 ; mass * number of stripes
        display_badger_age: db "Age = ",0               ; done through calculation
        display_badger_assigned_staff_ID: db "Staff care-taker ID = ",0
        
 ; ------------------------ ADD STAFF PROMPTS ------------------------
        staff_add_surname: db "Enter staff surname> ",0
        staff_add_firstname: db "Enter staff firstname> ",0
        staff_add_id: db "Enter staff ID (pXXXXXXX)> ",0
        staff_add_departament: db "Enter staff departament (Park Keeper/Gift Shop/Cafe)> ",0
        staff_add_start_salary: db "Enter staff starting salary (whole £)> ",0
        staff_add_year_join: db "Enter year of joining> ",0
        staff_add_email: db "Enter email (X@jnz.co.uk)> ",0
        staff_table_full:db "Staff table full, please delete a record!",10,0
        
 ; ------------------------ ADD BADGER PROMPTS ------------------------
        badger_add_id: db "Enter badger ID> ",0
        badger_add_name: db "Enter badger name> ",0
        badger_add_home_setting: db "Enter badger home setting (Badgerton / Settfield / Stripeville> ",0
        badger_add_mass: db "Enter badger mass in kg> ",0
        badger_add_stripes: db "Enter badger no. of stripes> ",0
        badger_add_sex: db "Enter badger sex (M/F)> ",0
        badger_add_mob: db "Enter badgers month of birth (1-12)> ",0
        badger_add_yob: db "Enter badgers year of birth > ",0
        badger_add_assigned_staff: db "Enter staff assigned to badger (pXXXXXXX)> ",0 
        badger_table_full: db "Badger table full, please delete a record!",10,0
       
; ------------------------ MENU MESSAGES ------------------------
        ; messages which build the programs menu
        menu_welcome: db "=-=-=-=-=-=- ZOO MENU -=-=-=-=-=-= ---- ",10,0 ;10 used for newline
        menu_add_user: db "[1] Add Staff",10,0
        menu_delete_user: db "[2] Delete Staff",10,0
        menu_add_badger: db "[3] Add Badger",10,0          
        menu_delete_badger: db "[4] Delete Badger",10,0
        menu_display_users: db "[5] Display all Staff",10,0
        menu_display_badgers: db "[6] Display all Badgers",10,0
        menu_search_badger: db "[7] Search for & display a Badger",10,0
        menu_search_user: db "[8] Search for & display a member of Staff",10,0
        menu_exit: db "[0] Exit",10,0
        menu_user_choice: db "Please enter a choice as an integer> ",0        
        EXIT_MESSAGE: db "Exiting program.....", 10,0

; ------------------------ DATE STORAGE ------------------------    
        ;   prompt messages which ask the user for today's date                
        prompt_year: db "Enter current year: ",0
        prompt_month: db "Enter current month (1-12): ",0
        prompt_day: db "Enter current day (1-31): ",0
        
; ------------------------ HELPER MESSAGES ------------------------
        ;NOTE: As mentioned previously, this program lacks input sanitizing on all fields, except the ID
        ;Here messages for input saniziting are stored and defined
        invalid_ID: db "ID is invalid, for staff enter pXXXXXXX, for badger enter bXXXXXX. X = uint",10,0
        dupe_ID: db "The ID entered already exists in the table! Please enter a unique ID",10,0
        
        delete_success: db "Record successfully deleted!",10,0
        delete_not_found: db "Record not found." ,10,0
    
section .bss
; ------------------------ STAFF RECORD ALLOCATION ------------------------
   STAFF_SURNAME equ 65                     ; 64 chars + null     
   STAFF_FIRSTNAME equ 65                   ; 64 chars + null 
   STAFF_ID equ 9                           ; pXXXXXXX (8bytes) + null 
   STAFF_DEPARTAMENT equ 12                 ; longest is park keeper (11bytes) + null    
   STAFF_STARTING_SALARY equ 4              ; assume salary is 20-60k, 1-2bytes too small, 4 is adequate (2^32)
   STAFF_YEAR_JOINING equ 4                 ; 2^16(2bytes) = 66536 is enough, 4 bytes used for arithmetic consistency
   STAFF_EMAIL equ 65                       ; 64chars + null   
   
   STAFF_RECORD_SIZE equ STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING + STAFF_EMAIL
   
   STAFF_MAX equ 100                                ; 100 maximum staff per the spec    
   staff_table resb STAFF_RECORD_SIZE * STAFF_MAX   ; reserve max 100 staff slots of staff size
   staff_count resb 1                               ; (100 max staff, 2^8 = 255 > 100)
   
; ------------------------ BADGER RECORD ALLOCATION ------------------------

   BADGER_ID equ 8                      ; bXXXXXX (7bytes) + null
   BADGER_NAME equ 65                   ; 64chars (64bytes) + null 
   BADGER_HOME_SETTING equ 12           ; stripeville (11bytes) + null = 12 bytes    
   BADGER_MASS equ 4                    ; 2^32 overkill, however kept to 4 bytes purely for arithmetic purpouses and stack alignments
   BADGER_NUM_STRIPES equ 1             ; badgers do not have more than 255 stripes! 
   BADGER_SEX equ 1                     ; either M or F 
   BADGER_MOB equ 1                     ; 1-12 months < 255
   BADGER_YOB equ 2                     ; 2^16 = 65536. we're in 2025
   BADGER_ASSIGNED_STAFF_ID equ 9       ; pXXXXXXX (8bytes) + null. 
   
   ; Dynamically allocate the size of a record. If a field was to change, this accounts for it   
   BADGER_RECORD_SIZE equ BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB + BADGER_YOB + BADGER_ASSIGNED_STAFF_ID
   BADGER_MAX equ 500                                   ; 500 maximum badgers (as per the specification)        
   badger_table resb BADGER_RECORD_SIZE * BADGER_MAX    ; reserve max 500 badger slots of badger size
   badger_count resw 1                                  ; 2^16 plenty (65535 > 500)       
   
   
   current_year resw 1      ; 255 < 2025 < 65536
   current_month resb 1     ; 1-12
   current_day resb 1       ; 1-31
   

section .text
    CHECK_DUPLICATE_ID:
; Func checks whether input ID is unique, and not a duplicate
        ; RAX = func return. 1 = dupe exists, 0 = no dupes
        ; R8 = 1st arg. stores user input of type ID (RDI)
        ; RDX = 2nd arg. Flag where 0 = staff 1 = badger
        ; RBX = index used to loop through badger/staff table
        ; RSI = ptr to mem location of the ID field, in a given record
        push rdx
        push rcx        ; stores staff_count / badger_count 
        push rsi        ; stores ID of badger / staff
        push rdi
        push r9
        push r8
        
        mov r8, rdi     ; store input ID into r8 pernamently
        
        cmp rdx, 0
        je .staff_check
        cmp rdx, 1
        je .badger_check
        
        ; --- check duplicate staff ID ---
      .staff_check:
        movzx rcx, BYTE [staff_count]       ; RCX = staff_count (how many staff records currently exist)
        cmp rcx, 0
        je .no_dupe_exists                  ; is the staff table empty
        xor rbx, rbx                        ; index through staff table
      .loop_staff:
        cmp rbx, rcx                        ; compare index against count of table
        jge .no_dupe_exists
        
        mov rax, rbx                        ; Calculate offset per each block of memory for each staff record in staff table
        imul rax, STAFF_RECORD_SIZE
        lea r9, [staff_table + rax]
        
        lea rsi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME] ; RSI = staff ID offset (mem location)
        mov rdi, r8                         ; compare passed in staff I
        
        call strings_are_equal              ; strings_are_equal returns into RAX. 1 = dupe, 0 = none
        cmp rax, 1
        je .dupe_exists
        inc rbx
        jmp .loop_staff
        ;---------------------------
      .badger_check:
        movzx rcx, WORD [badger_count]      ; works the same exact way .staff_check does, but rather loads 16bits into RCX of badger_count
        cmp rcx, 0
        je .no_dupe_exists                  ; is the badger table empty
        xor rbx, rbx                        ; badger table index
      .loop_badger:
        cmp rbx, rcx                        ; index = staff_count? if so and no dupes found, return no dupe
        jge .no_dupe_exists
        
        mov rax, rbx                        ; mov index into RAX for arithmetic
        imul rax, BADGER_RECORD_SIZE        ; Calculate offset per each block of memory for each badger record in badger table
        lea r9, [badger_table + rax]
        lea rsi, [r9]                       ; RSI = badger ID offset (mem location)
        mov rdi, r8
        call strings_are_equal
        cmp rax, 1
        je .dupe_exists
        inc rbx
        jmp .loop_badger
        
      .dupe_exists:
        mov rdi, dupe_ID
        call print_string_new
        mov rax, 1
        jmp .finish_check
      .no_dupe_exists:
        xor rax, rax ; reset rax
      .finish_check:
        pop r8
        pop r9
        pop rdi
        pop rsi
        pop rcx
        pop rdx
        ret
; ========================================================================
    VALIDATE_ID:
; This function validates whether the passed in ID through RDI, and the RDX flag is either:
        ; - staff: pXXXXXXX (p + 7 uint) + null
        ; - badger: bXXXXXX (b + 6uint) + null
    ; RDI = passed in string input
    ; DIL (RDX) 0 = staff, 1 = badger (global flags)
    ; RAX (return) 1 if valid, 0 if invalid
    ; RBX = index used to iterate through input ID (RDI)
    ; AL = stores first char of RDI 'p' / 'b'
        push rbx
        push rcx
        push rdx
        
        mov al, [rdi]               ; move 1st byte (char p or char b) into AL from RDI (func arg)
        
        cmp rdx, 0                  ; check flag. 0 =staff 1 = badger
        je .check_for_p
        cmp rdx, 1
        je .check_for_b
        jmp .invalidID              ; if flag corrupts (not 0 or 1)
      .check_for_p:                 ; flag (DIL) = 0, check for 'p'
        cmp al, 'p'
        jne .invalidID
        mov rcx, 8                  ; flag (DIL) = 1, check for 'b'
        jmp .checkLen
      .check_for_b:
        cmp al, 'b'
        jne .invalidID
        mov rcx, 7
        jmp .checkLen
        
      .checkLen:
        xor rbx, rbx                ; zero RBX to use as index through the input ID
      .loopID:                      ; counts the number of elements in ID, compares against required length (RCX 8 or 7)
        cmp BYTE [rdi+rbx], 0       ; check whether current char (current byte) is \0, if so and sizes match then correct length
        je .finishedCounting 
        inc rbx                     ; point to next digit
        cmp rbx, rcx                ; does expected length = input length?
        jg .invalidID
        jmp .loopID
      .finishedCounting:
        cmp rbx, rcx 
        jne .invalidID
        mov rbx, 1                  ; have checkDigitLoop start after p (2nd byte)
      .checkDigitLoop:              ; after checking whether length is valid, now check whether contents are valid after 'p' / 'b' (1st byte)
        cmp rbx, rcx
        je .validID                 ; check whether current uint (0-9 inclu.) is lower than ASCII '0' or bigger than ASCII '9'
        mov al, [rdi + rbx ]        ; i.e. al = '9'. is '9' < '0'? is '9' > '9'? Checks both 0-9(inclusive) and whether uint using ASCII
        cmp al, '0'         
        jb .invalidID
        cmp al, '9'
        ja .invalidID
        inc rbx
        jmp .checkDigitLoop
      .validID:
        mov rax, 1
        jmp .finishCheck
      .invalidID:
        
        mov rax, 0
      .finishCheck:
        pop rdx
        pop rcx
        pop rbx
        ret
; ========================================================================      
    display_records:
; Iterate through either badger or staff table, and display all records by calling display_record_fields on each record    
        ; R12 = staff/badger_count
        ; DIL (RDI) = flag (0 staff. 1 badger)
        ; R10 = index used in STAFF/BADGER_TABLE
        ; RAX = temp register for arithmetic
        ; R9 = ptr to current records fields (STAFF_SURNAME, STAFF_ID etc)         
        push rbx
        push r12                        ; stores either staff_count or badger_count
        
        cmp dil, 0                      ; determine to print staff (8/64 RDI bits)
        je .display_staff_record
        cmp dil, 1                      ; determine print badger
        je .display_badger_record
        
      .display_staff_record:
        movzx r12, BYTE [staff_count]   ; R12 = byte sized staff_count (per spec, no more than 100)
        cmp r12, 0                      ; are there no staff? if so jump to end
        je .empty_staff_record
        xor r10, r10                    ; R10 = index througout STAFF_RECORD_TABLE.  XOR to 0 it (faster than mov r10, 0)
        jmp .loop_display
        
      .display_badger_record:           ; does the exact same as display_staff_record
        movzx r12, WORD [badger_count]
        cmp r12, 0
        je .empty_badger_record
        xor r10, r10
        jmp .loop_display
      .loop_display:                    ; subfunc loops through RECORD_TABLE, splits again depending on staff/badger
        cmp r10, r12                    ; is *_RECORD_TABLE[indx] = *_count ? (incrementing for loop) (indx = r10)
        jge .finished_display           ; equal/greater, finish displaying
        
        cmp dil, 0
        je .staff_record
        cmp dil, 1
        je .badger_record
      .staff_record:
        mov rax, r10                    ; RAX = temp store index for arithmetic
        imul rax, STAFF_RECORD_SIZE     ; calculate how long each block of a record is (offset), to identify where elements start & end
        lea r9, [staff_table + rax]     ; add offset (RAX) to the base table address of staff_table. Results in ptr to the beginning location of a record i.e. staff_table[1], staff_table[3]
        call display_record_fields      ; jump to func display_record_fields to display current record
        inc r10                         ; increment the index staff_table[r10] to now represent next record
        jmp .loop_display               ; repeat looping through staff_table until index = size of STAFF_TABLE (staff_count)
      .badger_record:
        mov rax, r10                    ; exact same as .staff_record above, but rather loops through badger table and uses badger_count:
        imul rax, BADGER_RECORD_SIZE    ; calculate the memory offset of each record within the table
        lea r9, [badger_table + rax]    ; add RAX to base table address of badger_table. PTR to beginning of a record
        call display_record_fields
        inc r10                         ; increment indx
        jmp .loop_display               ; loop through all record
      .empty_staff_record:
        mov rdi, staff_empty_records
        call print_string_new
        jmp .finished_display
      .empty_badger_record:
        mov rdi, badger_empty_records
        call print_string_new
        jmp .finished_display
      .finished_display:
        pop r12
        pop rbx
        ret
; ==============================================================
; This function displays the record field of either badger or staff, also called from search_record
    display_record_fields:
        ; DIL (RDI) = flag (0 staff, 1 badger) / specific ptr to memory field for a record
        ; RAX = record index for header
        ; ECX (RCX) = stores years of service | stores badgers stripes count
        ; EAX (RAX) = stores calculated current salary (ECX * 300)
        ; ESI (RSI) = stores badger_mass for calc: mass * stripes
        cmp dil, 0 ; 0 = staff
        je .staff_rec
        cmp dil, 1 ; 1 = badger
        je .badger_rec
      .staff_rec:
        push rbx ; save volitaile registers
        push rcx
        push rdx
        push rsi
        push rdi
        
        ; -- DISPLAY HEADER -- 
        mov rdi, display_staff_header           ; mov header message to RDI and print
        call print_string_new        
        
        mov rax, r10                            ; move index to RAX; used to increment staff index in header to print from record 1, not record 0 (---RECORD NO .1)
        inc rax 
        mov rdi, rax                            ; increment indx and print out 
        call print_uint_new
        call print_nl_new
        
        ; -- DISPLAY SURNAME --
        mov rdi, display_staff_surname
        call print_string_new                   ;follow the structure of reach record (STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + ....)
        lea rdi, [r9]                           ; R9 = ptr to base address of record table. Load mem address of STAFF_SURNAME into RDI, used to access its contents, then print. 
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY FIRSTNAME --
        mov rdi, display_staff_firstname
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME]           ; load address of STAFF_FIRSTNAME into RDI (resident after STAFF_SURNAME). Each str print follows the same until we reach the end of record
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY ID --
        mov rdi, display_staff_id
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME] 
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY DEPARTAMENT --       
        mov rdi, display_staff_departament
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID] 
        call print_string_new
        call print_nl_new
        
        ;  -- CALCULATE YEARS OF SERVICE & PRINT -- 
        movzx eax, WORD [current_year]          ; zero extend current_year(8bit) into bottom 32bits of RAX
        mov edx, DWORD [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY] ; move 16bit value STAFF_YEAR_JOINING into edx
                                                ; NOTE: use mov rather than lea as arithmetic is needed, and library has difference between using string vs uint
        sub eax, edx                            ; EAX = years of service: current_year - STAFF_YEAR_JOINING
        mov ecx, eax                            ; ECX = store years of service, needed to calculate salary
        mov rdi, display_staff_years            ; call header message to show years of service
        call print_string_new
        mov edi, ecx                            ; Move years of service back to EDI (RDI) to print
        call print_uint_new
        call print_nl_new
        
        ; -- CALCULATE CURRENT SALARY AND DISPLAY -- 
        mov ebx, DWORD [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT] ; EBX = memory address of STAFF_STARTING_SALARY
        mov eax, ecx                            ; eax = years_of_service (calculated above)
        imul eax, 300 
        add ebx, eax                            ; starting salary + (years of service * 300) = current salary
        mov rdi, display_staff_salary
        call print_string_new
        mov edi, ebx                            ; print salary
        call print_uint_new
        call print_nl_new
        
        ; -- DISPLAY EMAIL --
        mov rdi, display_staff_email
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING]
        call print_string_new
        call print_nl_new        
        
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        jmp .finish
        
      .badger_rec:                              ; does the exact same for str as .staff_rec above, but has different uint calculations (differences commented)
        push rsi
        push rcx
        push rdx
        push rdi
        
        ; -- DISPLAY HEADER --
        mov rdi, display_badger_header
        call print_string_new
        mov rax, r10                    ; mov inx to rax, output header starting at 1
        inc rax
        mov rdi, rax
        call print_uint_new
        call print_nl_new
        
        ; -- DISPLAY ID --
        mov rdi, display_badger_id
        call print_string_new
        lea rdi, [r9]
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY NAME --
        mov rdi, display_badger_name
        call print_string_new
        lea rdi, [r9 + BADGER_ID]       ; BADGER_RECORD is defined differently as STAFF_RECORD, order of lea is differnet but functions the same
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY HOME SETTING -- 
        mov rdi, display_badger_home_setting
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME]
        call print_string_new
        call print_nl_new
        
        ; -- DISPLAY MASS --
        ; ESI = MASS
        mov rdi, display_badger_mass
        call print_string_new
        mov esi, DWORD [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING] ; ESI = loaded memory location of BADGER_MASS. Save max in ESI for mass * stripes
        mov edi, esi
        call print_uint_new
        call print_nl_new
        
        ; -- DISPLAY STRIPES --
        ; ECX = STRIPES
        mov rdi, display_badger_stripes
        call print_string_new
        movzx ecx, BYTE [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS] ; ECX = stripes
        mov edi, ecx
        call print_uint_new
        call print_nl_new
        
        ; -- CALC STRIPINESS  -- 
        mov rdi, display_badger_stripiness
        call print_string_new
        
        ; perform calc
        mov eax, esi                ; EAX = mass (from above)
        imul eax, ecx               ; ECX = stripes count. EAX will hold result: mass * stripiness
        mov edi, eax
        call print_uint_new
        call print_nl_new
        
        
        ; -- CALC AGE        
        mov rdi, display_badger_age
        call print_string_new        
        
        xor eax, eax                    ; Clear EAX for arithmetic (safety as calculation was done above)
        xor esi, esi                    ; Clear ESI (stored mass)
        
        movzx eax, WORD [current_year]  ; mov current year 16bit into EAX
        movzx edx, WORD [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB] ; mov badger YOB into EDX
        sub eax, edx                    ; currentYear - badgerYOB. EAX now holds year difference
        
        movzx ecx, BYTE [current_month] ; load 8bit month into ECX
        movzx esi, BYTE [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX] ; move badger MOB into ESI   
        cmp ecx, esi                    ; compare thisMonth vs badgerMOB
        jae .month_equal                ; equal? then jump, if different decrement
        dec eax                         ; if currentMonth < badgerMob - 1
        
      .month_equal:
        mov edi, eax
        call print_uint_new
        call print_nl_new   
        
        ; -- DISPLAY ASSIGNED STAFF ID --
        mov rdi, display_badger_assigned_staff_ID
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB + BADGER_YOB]
        call print_string_new
        call print_nl_new
        
        pop rdi
        pop rdx
        pop rcx
        pop rsi
        ret
      .finish:
        ret
; =========================================================================================
; This function lets a user add a badger to the badger record table.
    ; RAX = badger_count (no. of currently stored badgers)
    ; RBX = holds offset of each size of a record
    ; R9 = ptr to base address of current record
    ; R8 = stores user input for badger ID throughout function
    ; RSI = holds user input (read_*)
    ; EAX AL AX = used for 32/16/8bit register operations
    add_badger_to_record:
        movzx rax, WORD [badger_count]
        cmp rax, BADGER_MAX
        jae .badger_record_full
        
        ; -- CALC PTR TO NEXT RECORD --
        movzx rbx, WORD [badger_count]
        imul rbx, BADGER_RECORD_SIZE
        lea r9, [badger_table + rbx]
        
        ; -- ADD ID --
        mov rdi, badger_add_id          ; mov add id message to RDI and prompt
        call print_string_new
      .validate_badger_ID_loop:         ; check whether ID is 1. correct format 2. not a dupe
        call read_string_new
        mov r8, rax                     ; pernament (local) store badger ID input in R8
        mov rdi, r8                     ; prepare RDI with badger ID
        mov rdx, 1                      ; prepare RDX with flag for badger (1 = badger, 0 = staff)
        call VALIDATE_ID                ; check whether ID is valid. 1st arg RDI = ID  2nd arg RDX = flag
        cmp rax, 1
        jne .invalid_ID_prompt          ;if invalid let user re-enter valid ID
        ; check dupe 
        mov rdi, r8                     ; as above, prime RDI with badger ID and RDX with flag
        mov rdx, 1
        call CHECK_DUPLICATE_ID         ; check whether ID already exists as an entry. 1st arg RDI = ID, 2nd arg RDX = flag
        cmp rax, 1
        je .invalid_ID_prompt           ; if a dupe, jump to invalid
        jmp .store_ID
      .invalid_ID_prompt:               ; keep asking the user to re-enter badger ID if incorrect
        mov rdi, invalid_ID
        call print_string_new
        mov rdi, staff_add_id
        call print_string_new
        jmp .validate_badger_ID_loop
      .store_ID:
        mov rsi, r8                     ; load RSI with badger input ID, needed for copy_string
        lea rdi, [r9]                   ; RDI points to mem location for badger ID
        call copy_string                ; copy RSI into RDI :)
        
        ; -- ADD NAME --
        mov rdi, badger_add_name        ; prompt used to enter name
        call print_string_new
        call read_string_new
        mov rsi, rax                    ;mov badger input (name) into RSI for copy_string
        lea rdi, [r9 + BADGER_ID]       ;load memory location for BADGER_NAME, all str ops below follow the same functionality
        call copy_string
        
        ; -- ADD HOME SETTING --
        mov rdi, badger_add_home_setting
        call print_string_new
        call read_string_new
        mov rsi, rax
        lea rdi, [r9 + BADGER_ID + BADGER_NAME]
        call copy_string
        
        ; -- ADD MASS (32bit reg, 8bit value) --
        mov rdi, badger_add_mass
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING]
        call read_uint_new
        mov DWORD [rdi], eax        ;mov 32bit value MASS into RDI (mass mem location), which is LEA'd above. Same for stripes, MOB, YOB
               
        ; -- ADD STRIPES (8bit) --
        mov rdi, badger_add_stripes
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS]
        call read_uint_new
        mov BYTE [rdi], al        
        
        ; -- ADD SEX (8bit)--
        mov rdi, badger_add_sex
        call print_string_new
        call read_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES]
        mov byte [rdi], al
               
        ; -- ADD MOB (8bit)--
        mov rdi, badger_add_mob
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX]
        call read_uint_new
        mov [rdi], al
        
        
        ; -- ADD YOB (16bit) --
        mov rdi, badger_add_yob
        call print_string_new
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB]
        call read_uint_new
        mov WORD [rdi], ax
        
        ; -- ADD ASSIGNED STAFF --    
        ; no need to check duplicate ID, as a staff member can have many bagders  
        ; this block operates the same way as -- ADD ID -- does, just without the dupe checking
        mov rdi, badger_add_assigned_staff
        call print_string_new
      .validate_badger_assigned_ID_loop:
        call read_string_new
        mov r8, rax
        mov rdi, r8
        mov rdx, 0                  ; 0 as we want staff ID now, not badger
        call VALIDATE_ID
        cmp rax, 1
        jne .invalid_assigned_ID_prompt        
        jmp .store_ID_assigned
      .invalid_assigned_ID_prompt:
        mov rdi, invalid_ID
        call print_string_new
        mov rdi, staff_add_id
        call print_string_new
        jmp .validate_badger_assigned_ID_loop
      .store_ID_assigned:
        mov rsi, r8
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB + BADGER_YOB]    
        call copy_string        
                
        inc word [badger_count]     ; once succesfully added a badger, incremenet how many badgers exist
        ret
      
      .badger_record_full:
        mov rdi, badger_table_full
        call print_string_new   
        ret
; ==================================================================================================
    add_staff_to_record:
; This function adds a staff record to the table, by upadtating a records memory for each field through user input
        ; RAX = staff_count
        ; RBX = ptr to base address of the beginning of a record (record memory offset)
        ; RSI = Temporary register used for arithmetic i.e. copy_string
        ; R9 = *ptr to a field in current memory location
        ; R8 = holds user ID input, used for checking whether valid or / and a dupe
        
        ;-- IS STAFF TABLE FULL? -- 
        movzx rax, byte [staff_count]       ;Check whether staff table is full, if yes cannot add any more (100 max)
        cmp rax, STAFF_MAX
        jae .staff_record_full
        
        ; -- CALC PTR TO NEXT RECORD --        
        movzx rbx, byte [staff_count]
        imul rbx, STAFF_RECORD_SIZE         ; RBX = record offset. PTR to base memory location of current record
        lea r9, [staff_table + rbx]         ; Load the address of the next free record 
        
        ; -- INPUT SURNAME -- 
        mov rdi, staff_add_surname
        call print_string_new
        call read_string_new                ; RAX now points to temp buffer where user input is
        mov rsi, rax                        ; mov RAX into RSI for copy_string
        lea rdi, [r9]                       ; R9 points to start of mem for current record field (currently STAFF_SURNAME)
        call copy_string                    ; copies str from RSI to RDI
        
        ; -- INPUT FIRSTNAME --
        mov rdi, staff_add_firstname
        call print_string_new
        call read_string_new
        mov rsi, rax
        lea rdi, [r9 + STAFF_SURNAME]       ; R9 now points to memory in current record where STAFF_FIRSTNAME begins, and so on...
        call copy_string
        
        ; -- INPUT ID --
        mov rdi, staff_add_id
        call print_string_new           
      .validate_staff_ID_loop:              ; need to check whether ID input is valid, and also not a dupe
        call read_string_new
        mov r8, rax                         ; temporarily save RAX (user ID input) into R8
        mov rdi, r8                         ; RDX is used as DIL caused over-writing errors. Program calls VALIDATE_ID, and loops until correct ID is entered
        mov rdx, 0                          ; 0 flag for staff
        call VALIDATE_ID                    ; pass RDI as input ID, and RDX as flag (0 = staff). Check whether ID is correct format and size
        cmp rax, 1 
        jne .invalid_ID_prompt 
        ;check dupe
        mov rdi, r8 
        mov rdx, 0
        CALL CHECK_DUPLICATE_ID             ; RDI = input ID, RDX = flag. Check whether RDI already exusts
        cmp rax, 1
        je .invalid_ID_prompt
        jmp .store_ID
      .invalid_ID_prompt:                   ; if input ID is invalid, keep prompting until valid
        mov rdi, invalid_ID
        call print_string_new
        mov rdi, staff_add_id
        call print_string_new
        jmp .validate_staff_ID_loop
      .store_ID:                            ; once ID is not a dupe, and in a valid format
        mov rsi, r8                         ; Load RSI with R8 (staff input ID)
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME] ; load mem addy location for STAFF_ID   
        call copy_string                    ; copy R8 into RDI
        
        ; -- INPUT DEPARTAMENT -- 
        mov rdi, staff_add_departament
        call print_string_new
        call read_string_new
        mov rsi, rax
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID]
        call copy_string
        
        ; -- INPUT STARTING SALARY (32 BIT)   
        mov rdi, staff_add_start_salary
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT]
        call read_uint_new              ; read integer input
        mov DWORD [rdi], eax            ; move 16bit salary into RDI (red_uint_new doesn't store like read_string_new does and requires extra declaration)
        
        ; -- INPUT YEAR JOIN (32BIT)
        mov rdi, staff_add_year_join
        call print_string_new
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY]
        call read_uint_new
        mov DWORD [rdi], eax            ; move 16bit year into RDI
        
        ; -- INPUT EMAIL --
        mov rdi, staff_add_email
        call print_string_new
        call read_string_new
        mov rsi, rax
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING]
        call copy_string
        
        inc BYTE [staff_count]
        ret
               
      .staff_record_full:
        mov rdi, staff_table_full
        call print_string_new
        ret
; ==================================================================================================
    delete_record:
; Functions
        ; RDI (dil): 0 = delete staff, 1 = delete badger. Used as 1st arg to VALIDATE_UD
        ; R8 = stores staff_count / badger_count
        ; R9 = ptr to current record (badger/staff)
        ; RBX = stores user input of ID (either badger or staff)
        ; RCX = index for either staff_table / bagder_table | ptr for dest record
        ; RSI = ptr for source record
        ; RDX = stores index of record we wish to delete. Used as 2nd arg to VALIDATE_ID
        cmp dil, 0
        je .delete_record_staff
        cmp dil, 1
        je .delete_record_badger        
        jmp .finish_delete
        
      .delete_record_staff:
        movzx r8, BYTE [staff_count]        ; load 8bit staff_count into R8, zero extend 
        cmp r8, 0                           ; check whether staff_count <= 0
        je .empty_record_staff
        
                                            ;get staff ID by prompting user
        mov rdi, staff_add_id
        call print_string_new
                                            ; we check whether the input ID is correct
      .validate_staff_ID:
        call read_string_new
        mov rbx, rax                        ; RAX stores read_string_new, store ID in RBX
        mov rdi, rbx                        ; mov RBX to RDI
        mov rdx, 0                          ; 0 = staff flag
        call VALIDATE_ID                    ; call global func to check whether ID is correct. Pass RDI as input ID, RDX as flag
        cmp rax, 1
        jne .invalid_staff_delete_ID        ; if CMP = 0, staff ID is wrong, else correct
        jmp .correct_staff_ID
      .invalid_staff_delete_ID:
        mov rdi, invalid_ID                 ; keep promtping the user to enter a correct ID
        call print_string_new
        mov rdi, staff_add_id
        call print_string_new
        jmp .validate_staff_ID       
      .correct_staff_ID:       
        xor rcx, rcx                        ; RCX used as index through staff RECORD
      .find_staff_loop:
        cmp rcx, r8                         ; is index = staff_count
        jge .staff_record_not_found
        
        mov rax, rcx                        ; mov index to RAX for arithmetic
        imul rax, STAFF_RECORD_SIZE
        lea r9, [staff_table + rax]         ; ptr to base address of current record in staff table
        
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME] ; RDI a ptr to mem location of STAFF_ID
        mov rsi, rbx                        ; RBX still stores input string ID. Check whether input ID = record ID
        call strings_are_equal
        cmp rax, 1
        je .found_record_staff
        inc rcx
        jmp .find_staff_loop                ; keep looping until found
        
      .found_record_staff:        
        mov rdx, rcx
        mov rax, rcx                        ; current index we want to delete at (store in RDI, use in RAX for arithmetic)
        inc rax
        cmp rax, r8                         ; checks whether index+1 is the last record in staff_table
        jge .no_shift_staff                 ; if so, skip shifting memory (XXX0 -> XX00 no need to shift)
      .shift_staff_loop:
        ;source record
        mov rax, rdx
        inc rax
        imul rax, STAFF_RECORD_SIZE
        lea rsi, [staff_table + rax]        ; RSI = source ptr
        
        ;destination record
        mov rax,rdx
        imul rax, STAFF_RECORD_SIZE
        lea rdi, [staff_table + rax]
        mov rdx, STAFF_RECORD_SIZE          ; RCX = dest ptr
        
        mov rcx, STAFF_RECORD_SIZE
        
      .copy_bytes_staff:
                                            ; Shifts and copies memory bytes over
        cmp rcx, 0 
        je .shift_staff_NEXT
        mov al, [rsi]                       ; move source ptr location into al
        mov [rdi], al                       ; mov al into rdi memory (overwrite record pointer)
        inc rsi                             ; increment source
        inc rdi                             ; increment current ptr
        dec rcx                             ; decrement index we are at. Once index = 0, we know we've shifted everything
        jmp .copy_bytes_staff
      .shift_staff_NEXT:
        inc rdx
        movzx rax, BYTE [staff_count]
        cmp rdx, rax
        jl .shift_staff_loop
      .no_shift_staff:
        dec BYTE [staff_count]
        mov rdi, delete_success
        call print_string_new
        jmp .finish_delete        
        
      .staff_record_not_found:
       mov rdi, delete_not_found
       call print_string_new
       jmp .finish_delete
     .empty_record_staff:
        mov rdi, staff_empty_records
        call print_string_new
        ret
       ; ------------------------- SEPARATOR FOR DELETING A BADGER ----------------
; This subfunction does the exact same as .delete_staff_badger above, but only commented on the differences (for reading & bulk sake as operations are fundemanetally exact)
       ; R8 = badger_count
       ; R9 = ptr to current record
       ; RBX = stored user badger INPUT
       ; RCX = staff_table[indx]
      .delete_record_badger:
        movzx r8, WORD [badger_count]
        cmp r8, 0
        je .empty_record_badger
       
        ; prompt for badger ID
        mov rdi, badger_add_id
        call print_string_new
      .validate_badger_ID:
        call read_string_new
        mov rbx, rax                ; RBX = user badger ID input
        mov rdi, rbx
        mov rdx, 1                  ; 1 flag for badger
        call VALIDATE_ID            ; RDI = badger ID arg, RDX = badger flag (1)
        cmp rax, 1
        jne .invalid_badger_delete_ID
        jmp .correct_badger_ID
      .invalid_badger_delete_ID:
        mov rdi, invalid_ID
        call print_string_new
        mov rdi, badger_add_id
        call print_string_new
        jmp .validate_badger_ID
      .correct_badger_ID:
        xor rcx, rcx
        
      .find_badger_loop:
        cmp rcx, r8
        jge .badger_record_not_found        
        mov rax, rcx
        imul rax, BADGER_RECORD_SIZE
        lea r9, [badger_table + rax]
        
        lea rdi, [r9] 
        mov rsi, rbx  
        call strings_are_equal
        cmp rax, 1
        je .found_record_badger
        inc rcx
        jmp .find_badger_loop
      .found_record_badger:
        mov rdx, RCX
        mov RAX, rdx
        inc RAX
        cmp RAX, r8
        jge .no_shift_badger
      .badger_shift_loop:
        mov rax, RDX
        inc rax
        imul rax, BADGER_RECORD_SIZE
        lea RSI, [badger_table + rax]
        
        mov rax, RDX
        imul rax, [BADGER_RECORD_SIZE]
        lea rdi, [badger_table + rax]
        
        mov rcx, [BADGER_RECORD_SIZE]
      .copy_bytes_badger:
        cmp rcx, 0
        je .shift_badger_NEXT
        mov al, [RSI]
        mov [rdi], al
        inc RSI
        inc rdi
        dec rcx
        jmp .copy_bytes_badger
      .shift_badger_NEXT:
        inc rdx
        movzx rax, WORD [badger_count]
        cmp rdx, rax
        jl .badger_shift_loop
      .no_shift_badger:
        dec WORD [badger_count]
        mov rdi, delete_success
        call print_string_new
        jmp .finish_delete
      .empty_record_badger:
        mov rdi, badger_empty_records
        call print_string_new
        jmp .finish_delete
      .badger_record_not_found:
        mov rdi, delete_not_found
        call print_string_new
        jmp .finish_delete
              
      .finish_delete:
        ret
      
; ===============================================
    search_record:
; Function loops through record table of either badger (1) or staff (0), and checks whether current record staff ID = user input staff ID (the one being searched for)
        ; DIL (RDI) 0 = staff flag, 1 = badger
        ; R8 = holds *_count (no. of records in table)
        ; R9 = PTR to current record in table
        ; R10 = holds index of staff record (if found), used to pass to display_record
        ; RBX = holds staff / badger ID
        ; RCX = index used in badger_table[rcx] / staff_table[rcx]
        ; RAX = temporary register for calculations
        ; RSI = pointer to staff ID string after checking valid ID
        
        ;stack allign
        push RBX
        push rcx
        push rdx
        push rsi
        push rdi
        push r12
        push r13
        
        cmp dil, 0
        je .search_for_staff
        cmp dil, 1
        je .search_for_badger
        jmp .finish_search
      .search_for_staff:    
        movzx r8, BYTE [staff_count]            ; R8 stores staff_count, checks whether 0 (empty)
        cmp r8, 0
        je .staff_table_empty               
      .get_staff_ID_loop: ; check whether search for ID is correct
        mov rdi, staff_add_id
        call print_string_new
        call read_string_new
        mov r10, rax
        mov rdi, r10  ;                  string input into RDI
                            
        mov rdx, 0                          ; staff flag
        call VALIDATE_ID
        cmp rax, 1                          ; RAX = 1 if VALIDATE_ID returns ID is  valid
        je .staff_id_valid
        
        ;invalid ID, reprompt
        mov rdi, invalid_ID
        call print_string_new
        jmp .get_staff_ID_loop
      .staff_id_valid: 
        
                     
        mov rbx, r10                         ; move string ID input back into RBX
       
        xor rcx, rcx                            ; zero RCX to use as record_table[rcx]
      .search_for_staff_loop:
        cmp rcx, r8                             ; does index = staff_count. If we iterated through table and not found a match, record not found.
        jge .staff_record_not_found
        
        mov rax, rcx                            ; move index into RAX to calculate offset sizing
        imul rax, STAFF_RECORD_SIZE
        lea r9, [staff_table + rax]             ; r9 = ptr to base address of current record
        
        lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME] ;load STAFF_ID memory location into RDI
        mov rsi, rbx                            ; RSI = user input ID, RSI needed for strings equal
        call strings_are_equal
        cmp rax, 1                              ; RAX returns 1 if equal, 0 if not
        je .staff_record_found
        
        inc rcx
        jmp .search_for_staff_loop              ; keep looping until we find a staff ID record match
      .staff_record_found:
        mov r10, rcx                            ; pass index of current record to display_record_fields
        mov dil, 0                              ; set RDI (DIL) func arg to be flag 0 for staff
        call display_record_fields
        jmp .finish_search
      .staff_record_not_found:
        mov rdi, delete_not_found
        call print_string_new                   ; re-using messages, prompt the user staff ID not found
        jmp .finish_search        
      .staff_table_empty:
        mov rdi, staff_empty_records
        call print_string_new
        jmp .finish_search
        
      .search_for_badger:                       ; works in an identical fashion as .search_for_staff above. Will only comment out differences
        movzx r8, WORD [badger_count]           ; R8 = badger_count of size 16bits
        cmp r8, 0
        je .badger_table_empty
      .get_badger_id:                           ; check whether ID is correct        
        mov rdi, badger_add_id
        call print_string_new
        call read_string_new
        mov r10, rax
        mov rdi, r10                         ; mov input ID string into RDI
        mov rdx, 1                              ; flag 1 = badger
        call VALIDATE_ID                        ; RDI 1st arg = ID, RDX 2nd arg = flag
        cmp rax, 1
        je .badger_id_valid
        
        mov rdi, invalid_ID
        call print_string_new
        jmp .get_badger_id
      .badger_id_valid:        
        mov rbx, r10
        
        xor rcx, rcx
      .search_for_badger_loop:
        cmp rcx, r8
        jge .badger_record_not_found
        
        mov rax, rcx
        imul rax, BADGER_RECORD_SIZE
        lea r9, [badger_table + rax]
        
        lea rdi, [r9]                           ; mov BADGER ID mem location into RDI. Remember, badger and staff records store fields in different orders!
        mov rsi, rbx
        call strings_are_equal
        cmp rax, 1
        je .badger_record_found
        
        inc rcx
        jmp .search_for_badger_loop
      .badger_record_not_found:
        mov rdi, delete_not_found
        call print_string_new
        jmp .finish_search
      .badger_record_found:
        mov r10, rcx
        mov dil, 1
        call display_record_fields
        jmp .finish_search
        
      .badger_table_empty:
        mov rdi, badger_empty_records
        call print_string_new
        jmp .finish_search    
     
      .finish_search:
        pop r13
        pop r12
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        ret
; =======================================================================      
    main_menu_loop:
        ; This function is the main terminal loop, calling appropriate functions based on a user choice        
        mov rdi, menu_welcome
        call print_string_new         
        mov rdi, menu_add_user        
        call print_string_new        
        mov rdi, menu_delete_user        
        call print_string_new        
        mov rdi, menu_add_badger        
        call print_string_new        
        mov rdi, menu_delete_badger        
        call print_string_new        
        mov rdi, menu_display_users        
        call print_string_new        
        mov rdi, menu_display_badgers        
        call print_string_new        
        mov rdi, menu_search_badger        
        call print_string_new        
        mov rdi, menu_search_user        
        call print_string_new        
        mov rdi, menu_exit            
        call print_string_new            
        mov rdi, menu_user_choice                
        call print_string_new   
                          
        call read_uint_new ; take in user input         
        
        ; only read in max 1 byte as choice (0-9), use AL not RAX
        cmp al, 0 ; Exit prog
        je .exit_program
        cmp al, 1 ; add staff
        je .add_staff_record        
        cmp al, 2 ; delete staff        
        je .delete_staff_record        
        cmp al, 3 ; add badger
        je .add_badger_record   
        cmp al, 4; delete badger
        je .delete_badger_record       
        cmp al, 5 ; show staff records
        je .display_staff_records 
        cmp al, 6 ; show badger records
        je .display_badger_records
        cmp al, 7 ; search and display badger record
        je .search_badger_record
        cmp al, 8 ; search and display staff record
        je .search_staff_record
        
      .add_staff_record:
        call add_staff_to_record
        jmp main_menu_loop        
      .add_badger_record:
        call add_badger_to_record
        jmp main_menu_loop
      .display_staff_records:
        mov dil, 0 ; global flag for staff is 0, and badger is 1.
        ; uses RDI arg to determine whether to show badgers of staff
        call display_records
        jmp main_menu_loop
      .display_badger_records:
        mov dil, 1
        call display_records        
        jmp main_menu_loop      
      .delete_staff_record:
        mov dil, 0 ; passing 8bits of RDI as a flag (0 = staff, 1 = badger)
        call delete_record
        jmp main_menu_loop
      .delete_badger_record:
        mov dil, 1
        call delete_record
        jmp main_menu_loop
      .search_staff_record:
        mov dil, 0
        call search_record
        jmp main_menu_loop
      .search_badger_record:
        mov dil, 1
        call search_record
        jmp main_menu_loop
        
        
      .exit_program:
        mov rdi, EXIT_MESSAGE
        call print_string_new
        ;stack epilogue
        add rsp, 32
        pop rbp       
        ;syscall to exit (prevents return to main after entering EXIT choice in menu loop)
        mov rax, 60 ; 60 syscall for exit
        xor rdi, rdi ; clear rdi
        syscall   
       
    get_today_date: ; prompts the user to enter currentDate
        mov rdi, prompt_year ; db message -> rdi
        call print_string_new
        call read_uint_new
        mov [current_year], ax ;read uint stored in RAX. Mov only bottom 16bits into [current_year] (defined as word)
        
        mov rdi, prompt_month
        call print_string_new
        call read_uint_new
        mov [current_month], al ; same as above but for 8 bits (byte)
        
        mov rdi, prompt_day
        call print_string_new
        call read_uint_new
        mov [current_day], al
        ret
      
    main:
        push rbp ; stack prologue
        mov rbp, rsp
        sub rsp, 32
        
        call get_today_date
        
        call main_menu_loop
        
        add rsp, 32 ; stack epilogue
        pop rbp
        ret