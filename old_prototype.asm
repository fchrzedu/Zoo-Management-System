; Code for COMP6016 Malware Analysis S1 - Zoo management system
; For memory management, smallest possible bit sizes are used and compensated with movXY
; Public git repo: https://github.com/fchrzedu/COMP6016-Malware-Analysis-Semester-1/

; NEW BRANCH TO DISPLAY ALL USER RECORDS
; WILL HELP FIX BUG IN DELETE USERS
%include "/home/malware/asm/joey_lib_io_v9_release.asm"

global main


section .data    

   ; ------------------------ MENU MESSAGES ------------------------
       menu_welcome: db "---- Jamie's Menu ---- ",10,0 ;10 used for newline
       menu_add_user: db "[1] Add User",10,0
       menu_delete_user: db "[2] Delete User",10,0
       menu_add_badger: db "[3] Add Badger",10,0   
       
       
       menu_delete_badger: db "[4] Delete Badger",10,0
       menu_display_users: db "[5] Display all Users",10,0
       menu_display_badgers: db "[6] Display all Badgers",10,0
       menu_search_badger: db "[7] Search for & display a Badger",10,0
       menu_search_user: db "[8] Search for & display a User",10,0
       menu_exit: db "[0] Exit",10,0
       menu_user_choice: db "Please enter a choice as an integer> ",0        
       EXIT_MESSAGE: db "Exiting program.....", 0
       
   ; ------------------------ ADD STAFF PROMPTS ------------------------
       staff_add_surname: db "Enter staff surname> ",0
       staff_add_firstname: db "Enter staff firstname> ",0
       staff_add_id: db "Enter staff ID (pXXXXXXX)> ",0
       staff_add_departament: db "Enter staff departament (Park Keeper/Gift Shop/Cafe)> ",0
       staff_add_start_salary: db "Enter staff starting salary (whole £)> ",0
       staff_add_year_join: db "Enter year of joining> ",0
       staff_add_email: db "Enter email (X@jnz.co.uk)> ",0
       
   ; ------------------------ ADD BADGER PROMPTS ------------------------    
       add_badger_id: db "Enter badger ID> ",0
       add_badger_name: db "Enter badger name> ",0
       add_badger_home_setting: db "Enter badger home setting (Badgerton / Settfield / Stripeville> ",0
       add_badger_mass: db "Enter badger mass in kg> ",0
       add_badger_stripes: db "Enter badger no. of stripes> ",0
       add_badger_sex: db "Enter badger sex (M/F)> ",0
       add_badger_mob: db "Enter badgers month of birth (1-12)> ",0
       add_badger_yob: db "Enter badgers year of birth > ",0
       add_badger_assigned_staff: db "Enter staff assigned to badger (pXXXXXXX)> ",0  
       
   ; ------------------------ DELETE STAFF PROMPTS ------------------------    
      staff_delete_id: db "Enter ID of staff to delete (pXXXXXXX)> ",0
      staff_delete_success: db "Staff entry deleted succesfully!",0
      staff_delete_not_found: db "Staff member not found!",0
      
   ; ------------------------ DISPLAY STAFF RECORDS ------------------------   
      staff_record_header: db "--STAFF RECORD--",10,0 ; header used for display_Staff 
      staff_record_empty: db "No Staff in records",10,0
       
    ; ------------------------ DISPLAY BADGER RECORDS ------------------------   

       badger_record_header: db "--BADGER RECORD--",10,0
       badger_record_empty: db "No badgers in records",10,0

      

section .bss

; ------------------------ STATIC MEM-ALLOC FOR BADGER RECORDS ------------------------

   BADGER_ID equ 8 ; b123456 (7bytes) + null
   BADGER_NAME equ 65 ; 64chars (64bytes) + null 
   BADGER_HOME_SETTING equ 12 ; stripeville (11bytes) + null = 12 bytes    
   BADGER_MASS equ 4 ; 2^32 overkill, however kept to 4 bytes purely for arithmetic purpouses and stack alignments
   BADGER_NUM_STRIPES equ 1 ;badgers do not have more than 255 stripes! Will use lower registers to accommodate
   BADGER_SEX equ 1 ; either M or F (0 or 1)
   BADGER_MOB equ 1 ; 1 byte needed for range of 0-11 nums
   BADGER_YOB equ 2; 2^16 = 65536 > YEAR. 2^8 = 255 < YEAR
   BADGER_ASSIGNED_STAFF_ID equ 9; p1234567 (8bytes) + null. ONLY USED AS A REFERENCE, NOT A PTR!!
   
   ; Better than equ 105. Any badger field changes are accounted for - Shows what makes the size, rather than an arbitary byte assignment
   BADGER_RECORD_SIZE equ BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB + BADGER_YOB + BADGER_ASSIGNED_STAFF_ID
   BADGER_MAX equ 500 ; 500 maximum badgers (as per the specification)        
   badger_table resb BADGER_RECORD_SIZE * BADGER_MAX ; reserve max 500 badger slots of badger size
   badger_count resw 1; 2bytes plenty (65535 > 500)    
   
; ------------------------ STATIC MEM-ALLOC FOR STAFF RECORDS ------------------------

   STAFF_SURNAME equ 65    ;64 chars (64bytes) + null
   STAFF_FIRSTNAME equ 65  ;64chars + null
   STAFF_ID equ 9; p1234567 (8bytes) + null ;currently placeholders
   STAFF_DEPARTAMENT equ 11 ; park keeper (10bytes) + null    
   STAFF_STARTING_SALARY equ 4; assume salary is 20-60k, 1-2bytes too small, 4 is adequate (2^32)
   STAFF_YEAR_JOINING equ 4; 2^16(2bytes) = 66536 is enough, 4 bytes used for arithmetic consistency
   STAFF_EMAIL equ 65; 64chars + null
   
   STAFF_RECORD_SIZE equ STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING + STAFF_EMAIL
   STAFF_MAX equ 100; 100 maximum staff per the specification    
   staff_table resb STAFF_RECORD_SIZE * STAFF_MAX ; reserve max 100 staff slots of staff size
   staff_count resb 1; (100 max staff, 2^8 = 255 > 100)
   
   TEMP_STAFF_ID_BUFFER resb 9; used for inputting a staff ID for either delete or search

section .text  

   ;safe_string_input: ; helper function used for input sanitisng
   ; will be used by checking whether 0x00 is longer than string
       

   add_badger_record:
       ; Function used to generate a new badger record
       ; movzx compensates for varying register sizes
       ; uint_new calls require additional code to ensure integer stored in RAX is correctly stored, unlike string_new
       
       ;stack management
       push rbx
       push r9
       push rdi
       
       movzx rbx, word [badger_count]
       imul rbx, BADGER_RECORD_SIZE
       lea r9, [badger_table + rbx]
       
       ; -- badger ID --
       mov rdi, add_badger_id
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9]
       call copy_string        
       
       ; -- badger name -- 
       mov rdi, add_badger_name
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + BADGER_ID]
       call copy_string
       
       
       ; -- badger home setting --
       mov rdi, add_badger_home_setting
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + BADGER_ID + BADGER_NAME]
       call copy_string
       
       ; -- badger mass --
       mov rdi, add_badger_mass
       call print_string_new
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING]

       call read_uint_new        

       mov dword [rdi], eax ; badger mass is 4 bytes

       ; -- badger num stripes --
       mov rdi, add_badger_stripes
       call print_string_new
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS]
       call read_uint_new
       mov byte [rdi], al ; stripes are 1 byte

       ; -- bader sex --
       mov rdi, add_badger_sex        
       call print_string_new
        call read_string_new ; More intuitive to store M or F
        mov rsi, rax
        call read_char_new ; More intuitive to store M or F (only 1char needed)        
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS+  BADGER_NUM_STRIPES]
        call copy_string
        mov BYTE [rdi], al
        
        
               
       ; -- badger mob --
       mov rdi, add_badger_mob     
       call print_string_new
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING +BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX]
       call read_uint_new        
       mov byte [rdi], al ; MOB is 1 byte
       
       ; -- badger yob --
       mov rdi, add_badger_yob
       call print_string_new
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB]
       call read_uint_new
       mov word [rdi], ax; YOB is 2 bytes
       
        ; -- badger assigned staff ID --
        ; -- badger assigned staff ID --         
       mov rdi, add_badger_assigned_staff
        call print_string_new
       call read_string_new
       mov rsi, rax
        call print_string_new
       lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB +  BADGER_YOB]
                
        call copy_string       
       
       inc word [badger_count]
       
       ;stack management
       pop rdi     
       
       pop r9
       pop rbx
       
       ret
   
   add_staff_record:
       ; Function used to generate a new staff record
       ; R9 : pointer to the next staff record
       ; RBX useage has been taken into cosideration as follows:
       ; (1)EAX is large enough to be used as a register(65536-bits) and RBX is not neccesarily required
       ; (2)RBX provides much easier arithmetic logic, is safer and reduces potential bugs hence MOVZX :)
       
       ; stack management (incase)
       push rbx
       push r9
       push rdi
       push rax
       
       movzx rbx, byte [staff_count] ;zero extend 8bit->64bit register (negates leftover 'junk')       
       imul rbx, STAFF_RECORD_SIZE ; stores offset of records. used to identify next record location
       lea r9, [staff_table + rbx]; r9 now points to where next record should be stored
   
       ;---- input surname ----        
       
       
       mov rdi, staff_add_surname
       call print_string_new
       call read_string_new    ; RAX now points to temp buffer where user input is
       mov rsi, rax ; mov RAX into RSI for copy_string
       lea rdi, [r9] ; R9 points to start of mem for current record
       call copy_string ; copies str from RSI to RDI
       
       
       ;----  input firstname ---- 
       mov rdi, staff_add_firstname
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + STAFF_SURNAME] ; r9 now points to mem space to enter staff ID and so on
       call copy_string
       
       ;----  input ID ----
       mov rdi, staff_add_id
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME]
       call copy_string
       

       ;----  input departament ---- 
       mov rdi, staff_add_departament
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID]
       call copy_string
       
       ;----  input starting salary ---- 
       mov rdi, staff_add_start_salary
       call print_string_new
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT]
       call read_uint_new ; read integer input
       mov dword [rdi], eax ; move 4 byte salary into RDI (red_uint_new doesn't store like read_string_new does and requires extra declaration)
       ;ensures field next over doesn't get overwritten
       
       ;---- input year of joining ---- 
       mov rdi, staff_add_year_join
       call print_string_new
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY]
       call read_uint_new
       mov dword [rdi], eax ; move 4byte year into RDI
       
       ;----  input email ---- 
       mov rdi, staff_add_email
       call print_string_new
       call read_string_new
       mov rsi, rax
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING]
       call copy_string
       
       ;increment record of overall staff records stored by 1
       inc byte [staff_count]    
       
       ; stack management (incase)
       pop rax
       pop rdi
       pop r9
       pop rbx    
       ret

   delete_staff_record:    
       ; Function deletes a staff from record table         
       ; RCX = Total number of staff_records - caller-saved(no push needed)
       push rbx ; RBX = index in staff_table i.e. staff_table[0]
       push rdi  ; RDI = Dest. ptr (where we overwrite memory)
       push rsi ; RSI = Source ptr (record after deleted one)
       push r8   ; R8 = Num of bytes to move table by
       push r9 ; R9 = Temp register used for offset calculations
       
       
        ; -- read staff ID to delete through prompt --      
       mov rdi, staff_delete_id
       call print_string_new
       lea rdi, [TEMP_STAFF_ID_BUFFER]
       call read_string_new        
      
       ; -- PREPARE INDEX USED FOR LOOP --
       xor rbx, rbx ; xor RBX to make zero. RBX = staff_table[index] i.e. staff_table[1]
       movzx rcx, BYTE [staff_count] ; RCX = staff_count (0-100). Zero extend rcx to store only 8bits
       
     .staff_search_loop:
       cmp rbx, rcx ; staff_table[indx] =>staff_count
       jae .delete_staff_not_found; is yes, staff hasn't been found, end loop
       
       ; -- set pointer to current staff record -- 
       mov rdx, rbx ; temporary copy of indx
       imul rdx, STAFF_RECORD_SIZE ; RDX creates offset in bytes to current record: indx * record_Size
       lea rsi, [staff_table+rdx+STAFF_SURNAME+STAFF_FIRSTNAME] ; RSI points to mem of staff_table[indx]
       ;calc starting mem addy of current record.
       
       ; -- COMPARE STAFF IDs -- 
       lea rdi, [TEMP_STAFF_ID_BUFFER] ; pointer that has input ID
       call strings_are_equal ; RAX = 1 if equal, RAX = 0 if not
       cmp rax, 1
       jne .delete_next_staff_record ; if not equal, look at next record
       
       ; -- DELETE STAFF RECORD --      
       mov rdx, rbx ; RDX = indx of record for deletion
       inc rdx ; RDX = record of next record        
       cmp rdx, rcx ; do any records exist after deleted one?
       jae .decrement_staff_count ; if deleted = staff_record count, decrement by 1
       
       ; -- SHIFT RECORDS --
       mov r8, rcx ; r8 = tot num of staff count
       sub r8, rdx ; r8 = staff count - deleted record (being indx)
       ;i.e. staff_count = 5, deleting at indx 2: r8 = 5-2=3 (3 records left)
       
       imul r8, STAFF_RECORD_SIZE; tot num of bytes to be copied left
       mov r9, rdx
       imul r9, STAFF_RECORD_SIZE
       lea rsi, [staff_table + r9] ; RSI = record after the one we delete
       mov r9, rbx
       imul r9, STAFF_RECORD_SIZE
       lea rdi, [staff_table + r9] ; RDI = where we overwrite record
       mov rcx, r8
       rep movsb ; copy byte from RSI->RDI , inc both ptrs, dec RCX until RCX = 0
       
     .decrement_staff_count:
       dec BYTE [staff_count] ; reduce staff count by 1 (which is byte)
       mov rdi, staff_delete_success
       call print_string_new
       call print_nl_new
       jmp .delete_staff_exit
     .delete_next_staff_record:
       inc rbx ; increment next staff indx
       jmp .staff_search_loop
     .delete_staff_not_found:
       mov rdi, staff_delete_not_found
       call print_string_new
       call print_nl_new
     .delete_staff_exit:
             
       pop r9
       pop r8
       pop rsi
       pop rdi
       pop rbx
       ret
       
               
  
    show_all_badgers:
        ;FUNCTION DISPLAYS ALL BADGERS IN TABLE SEQUENTIALLY
        movzx ecx, WORD [badger_count] ; 2^16 bits (word)
        cmp cx, 0 ; are there badgers in the table?
        je .badger_record_empty        
        xor rbx, rbx
        
      .output_following_badger_record:
        cmp rbx, rcx
        jae .finish_badger_show_iteration
        
        mov rdx, rbx
        imul rbx, BADGER_RECORD_SIZE
        lea r9, [badger_table + rbx]
        
        ; -- PRINT HEADER --
        call print_nl_new
        mov rdi, badger_record_header
        call print_string_new
        call print_nl_new
        
        ; -- BADGER ID --
        mov rdi, r9
        call print_string_new
        call print_nl_new
        
        ; -- BADGER NAME -- 
        lea rdi, [r9 + BADGER_ID]
        call print_string_new
        call print_nl_new
        
        ; -- BADGER HOME SETTINGS --
        lea rdi, [r9 + BADGER_ID + BADGER_NAME]
        call print_string_new
        call print_nl_new
        
        ; -- BADGER MASS --
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING]
        mov eax, [rdi]
        mov rdi, rax
        call print_uint_new
        call print_nl_new
        
        ; -- BADGER NO. STRIPES --
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS]
        movzx eax, BYTE [rdi]
        mov rdi, rax
        call print_uint_new
        call print_nl_new
        
        ; -- BADGER SEX --
        movzx rdi, byte [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES]
       
        call print_char_new
        call print_nl_new
        
        ; -- BADGER MOB --
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX]
        movzx eax, BYTE [rdi]
        mov rdi, rax
        call print_uint_new
        call print_nl_new
     
        ; -- BADGER YOB -- 
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB]
        movzx eax, WORD [rdi]
        mov rdi, rax
        call print_uint_new
        call print_nl_new
       
        ; -- BADGER ASSIGNED STAFFID -- 
        lea rdi, [r9 + BADGER_ID + BADGER_NAME + BADGER_HOME_SETTING + BADGER_MASS + BADGER_NUM_STRIPES + BADGER_SEX + BADGER_MOB + BADGER_YOB]
        call print_string_new
        call print_nl_new
       
        inc rbx
        jmp .output_following_badger_record 
       
      .badger_record_empty:
        mov rdi, badger_record_empty
        call print_string_new
        jmp .finish_badger_show_iteration
         
    
      .finish_badger_show_iteration:
       ret
    
    
        
   show_all_staff:
       ; Displays all staff records one by one, rather than in a table
       ; RCX = Stores num of staff (staff_count)
       ; RBX = index iterating through STAFF_TABLE
       
       push rbx
       push rcx
       push r9
       push rdi
       push rdx
       
       movzx rcx, BYTE [staff_count] ; move no. staff into bottom 8bits of RCX
       cmp rcx, 0 ; is there no staff members?
       je .staff_table_empty
       
       xor rbx, rbx ; clear RBX
       
      .output_following_record:
      .output_following_staff_record:
       cmp rbx, rcx        
        jae .finish_iteration
        jae .finish_staff_show_iteration
       
       mov rdx, rbx
       
       imul rbx, STAFF_RECORD_SIZE ; creates offset, where offset = staff_count[indx] * STAFF_RECORD_SIZE
       lea r9, [staff_table + rbx] ; R9 ptr to current staff record
       
       ; -- PRINT HEADER -- 
       call print_nl_new
       mov rdi, staff_record_header
       call print_string_new
       
       ; -- DISPLAY SURNAME --
       mov rdi, r9
       call print_string_new 
       call print_nl_new
       
       ; -- DISPLAY FIRSTNAME -- 
       lea rdi, [r9 + STAFF_SURNAME] ; move into mem location where firstname for record exists
       call print_string_new
       call print_nl_new
       
       ; -- DISPLAY ID --
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME]
       call print_string_new
       call print_nl_new
       
       ; -- DISPLAY DEPARTAMENT --
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID]
       call print_string_new
       call print_nl_new
       
       ;-- DISPLAY STARTING SALARY --
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT]
       mov eax, [rdi]
       mov rdi, rax
       call print_uint_new
       call print_nl_new
       
       ; -- DISPLAY YEAR JOINING --
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY]
       mov eax, [rdi]
       mov rdi, rax
       call print_uint_new
       call print_nl_new
       
       ; -- DISPLAY EMAIL
       lea rdi, [r9 + STAFF_SURNAME + STAFF_FIRSTNAME + STAFF_ID + STAFF_DEPARTAMENT + STAFF_STARTING_SALARY + STAFF_YEAR_JOINING]
       call print_string_new
       call print_nl_new
       
       ; -- INCREMENT INDX TO NEXT RECORD --
       
       inc rbx
        jmp .output_following_record      
        jmp .output_following_staff_record      
       
       
     .staff_table_empty:
       mov rdi, staff_record_empty
       call print_string_new
        jmp .finish_iteration
        jmp .finish_staff_show_iteration
     
      .finish_iteration:            
      .finish_staff_show_iteration:            
       pop rdx
       pop rdi
       pop r9
       pop rcx
       pop rbx
       
       ret
       

   main:
       ;stack prologue
       push rbp
       mov rbp, rsp
       sub rsp, 32              
       
     .main_menu_loop:
       ; ---- MAIN MENU FOR SYSTEM ----
     ; loads all messages in .data with menu_ prefix, and prints to terminal
     ; loop due to being the main function, calling others within
     
       ;used for debug to print staff records
       mov eax, [staff_count] ; move 32-bit value into EAX
       mov rdi, rax          ; zero-extend to 64-bit into RDI
       call print_uint_new
       call print_nl_new
       
       
       mov rdi, menu_welcome
        call print_string_new 
        
        call print_string_new         
       mov rdi, menu_add_user
        
        call print_string_new        
       mov rdi, menu_delete_user
        
        call print_string_new        
       mov rdi, menu_add_badger ; ! handle user input choices !
        
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
       ; ---- READ USER INPUT ----
       ;RAX stores choice 
       call read_uint_new                
       
       mov eax, eax ; ensures lower-bits are in eax (32bit) opposed to rax (64bits)
       
       ; ---- 'SWITCH CASE' FOR USER INPUT (CALLS APPROPRIATE FUNCTION) ----
       cmp eax, 0 ;terminate program
       je .exit_program
       
       cmp eax, 1 ;add staff entry to record table
       je .create_staff_record
       
       cmp eax, 2
       je .delete_staff_record
      
        
       
       cmp eax, 3 ; add badger to record table
       je .create_badger_record 
       
       cmp eax, 5 ; display all users
       je .show_all_staff
       
        cmp eax, 6 ; display all badgers
        je .show_all_badgers
        
       ;currently placeholders
      
       ;cmp eax, 4 ; delete badger record
      
       
      
       
       
        ;cmp eax, 6 ; display all badgers
        
       
       
       ;cmp eax, 7 ; search for a badger & display
       
       
       ;cmp eax, 8 ; search for staff & display
      
       
       
       ;jump back to menu after functions
       jmp .main_menu_loop
       
     .create_staff_record:
       call add_staff_record
       jmp .main_menu_loop
     .delete_staff_record:
       call delete_staff_record
       jmp .main_menu_loop
     .create_badger_record:
       call add_badger_record
       jmp .main_menu_loop
     .show_all_staff:
       call show_all_staff
       jmp .main_menu_loop
      .show_all_badgers:
        call show_all_badgers
        jmp .main_menu_loop
       
       
       
     .exit_program:        
       mov rdi, EXIT_MESSAGE
       call print_string_new
       call print_nl_new
       
       ;stack epilogue
       add rsp, 32
       pop rbp
       
       ;syscall to exit (prevents return to main after entering EXIT choice in menu loop)
       mov rax, 60 ; 60 syscall for exit
       xor rdi, rdi ; clear rdi
       syscall
           

