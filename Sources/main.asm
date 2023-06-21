format ELF64
public main ; Entry-point

extrn printf
extrn system
extrn mount
extrn umount
extrn snprintf

;================ПОВІДОМЛЕННЯ ДЛЯ ВВЕДЕННЯ================
section '.input_messages' writeable
    message_fs_format db "Виберіть файлову систему для пристрою (vfat, ext4, xfs, btrfs) >_ ", 0
    message_fs_format_len = $-message_fs_format

    message_shell_input db 0x0A, "Введіть команду >_ ", 0
    message_shell_input_len = $-message_shell_input

    message_enter_device db "Введіть пристрій >_ ", 0
    message_enter_device_len = $-message_enter_device

    message_enter_directory db "Введіть каталог >_ ", 0
    message_enter_directory_len = $-message_enter_directory

    message_enter_iso_path db "Введіть шлях до ISO-файлу >_ ", 0
    message_enter_iso_path_len = $-message_enter_iso_path

    
;================ІНФОРМАЦІЙНІ ПОВІДОМЛЕННЯ================
section '.info_messages' writeable
    message_operations_list db 0x0A, "=========================СПИСОК ОПЕРАЦІЙ НАД ПРИСТРОЯМИ=========================", 0x0A, "Довідка: (>_ help)", 0x0A, "Показати список дискових пристроїв: (>_ lst)", 0x0A, "Примонтувати пристрій: (>_ mnt dev)", 0x0A, "Відмонтувати пристрій: (>_ umnt dev)", 0x0A, "Безпечно вийняти пристрій: (>_ dtch dev)", 0x0A, "Створити завантажувальний пристрій: (>_ create boot)", 0x0A, "Форматувати пристрій: (>_ fmt dev)", 0x0A, "Вихід з програми: (>_ exit)", 0x0A, "=========================СПИСОК ОПЕРАЦІЙ НАД ПРИСТРОЯМИ=========================", 0x0A, 0
    message_operations_list_len = $-message_operations_list

    list_devices db "Список дискових пристроїв: ", 0x0A, 0
    list_devices_len = $-list_devices

    success_mount db "Пристрій успішно примонтовано!", 0x0A, 0x0A, 0
    success_mount_len = $ - success_mount
    error_mount db "Не вдалося примонтувати пристрій! Перевірте правильність введеної назви пристрою або каталогу.", 0x0A, 0x0A, 0
    error_mount_len = $ - error_mount

    success_unmount db "Пристрій успішно розмонтовано!", 0x0A, 0x0A, 0
    success_unmount_len = $ - success_unmount
    error_unmount db "Не вдалося розмонтувати пристрій! Перевірте правильність введеної назви каталогу.", 0x0A, 0x0A, 0
    error_unmount_len = $ - error_unmount

    success_detach db "Пристрій успішно відключено!", 0x0A, 0x0A, 0
    success_detach_len = $-success_detach
    error_detach db "Не вдалося відключити пристрій! Перевірте правильність введеної назви пристрою.", 0x0A, 0x0A, 0
    error_detach_len = $-error_detach

    creating_boot_started db "Створення завантажувального пристрою розпочато. Це може зайняти деякий час, наберіться терпіння.", 0x0A, 0
    creating_boot_started_len = $ - creating_boot_started
    success_creating_boot db "Завантажувальний пристрій успішно створено!", 0x0A, 0x0A, 0
    success_creating_boot_len = $-success_creating_boot
    error_creating_boot db "Не вдалося створити завантажувальний пристрій! Перевірте правильність введеної назви пристрою або шляху до ISO-файлу.", 0x0A, 0x0A, 0
    error_creating_boot_len = $-error_creating_boot

    formatting_started db "Форматування у вибрану ФС розпочато...", 0x0A, 0
    formatting_started_len = $-formatting_started
    success_format db "Пристрій успішно відформатовано!", 0x0A, 0x0A, 0
    success_format_len = $-success_format
    error_format db "Не вдалося відформатувати пристрій! Перевірте правильність введеної назви пристрою або файлової системи.", 0x0A, 0x0A, 0
    error_format_len = $-error_format

    exit_the_program db "Завершення програми...", 0x0A, 0
    exit_the_program_len = $-exit_the_program


;=========================КОМАНДИ=========================
section '.commands' writeable
    help_command db "help", 0
    list_command db "lst", 0
    mount_command db "mnt dev", 0
    unmount_command db "umnt dev", 0
    detach_command db "dtch dev", 0
    create_boot_command db "create boot", 0
    format_command db "fmt dev", 0
    exit_command db "exit", 0


;==========================БУФЕРИ=========================
section '.buffers' writeable
    buffer_command db 100 DUP(?)
    buffer_command_len = 100
    final_detach_command db 100 DUP(?)
    final_detach_command_len = 100
    final_create_boot_command db 100 DUP(?)
    final_create_boot_command_len = 100
    final_format_command db 100 DUP(?)
    final_format_command_len = 100
    final_devices_list_command db "ls /sys/block", 0
    device rb 20
    device_len = 20
    directory rb 100
    directory_len = 100
    filesystem rb 20
    filesystem_len = 20
    isofile rb 100
    isofile_len = 100

    
;===================ШАБЛОНИ І КОНСТАНТИ===================
section '.templates_and_constants' writeable
    template_detach_command db "eject %s", 0
    template_create_boot_command db "dd if=%s of=%s > /dev/null", 0
    template_format_command db "sudo dd if=/dev/zero of=%s bs=1M count=1 &>/dev/null && mkfs -t %s %s &>/dev/null", 0
    ext4_filesystem db "ext4", 0
    vfat_filesystem db "vfat", 0
    xfs_filesystem db "xfs", 0
    btrfs_filesystem db "btrfs", 0


;=========================================================
;=====================ГОЛОВНА ПРОГРАМА====================
;=========================================================
section '.text' writeable
main:
    call output_help_operation
    .main_loop:
        ; Виводимо shell input
        mov rax, 1
        mov rdi, 1
        mov rsi, message_shell_input
        mov rdx, message_shell_input_len
        syscall

        ; Зчитуємо команду
        mov rax, 0
        mov rdi, 0
        mov rsi, buffer_command
        mov rdx, buffer_command_len
        syscall

        ; перевірка команди виведення довідки
        mov rsi, buffer_command
        mov rcx, 4
        mov rdi, help_command
        repe cmpsb
        jz .output_help_operation
        ; перевірка команди виведення списку дискових пристроїв
        mov rsi, buffer_command
        mov rcx, 3
        mov rdi, list_command
        repe cmpsb
        jz .devices_list_operation
        ; перевірка команди монтування пристрою
        mov rsi, buffer_command
        mov rcx, 7
        mov rdi, mount_command
        repe cmpsb
        jz .device_mount_operation
        ; перевірка команди розмонтування пристрою
        mov rsi, buffer_command
        mov rcx, 8
        mov rdi, unmount_command
        repe cmpsb
        jz .device_unmount_operation
        ; перевірка команди відключення пристрою
        mov rsi, buffer_command
        mov rcx, 8
        mov rdi, detach_command
        repe cmpsb
        jz .device_detach_operation
        ; перевірка команди створення завантажувального пристрою
        mov rsi, buffer_command
        mov rcx, 11
        mov rdi, create_boot_command
        repe cmpsb
        jz .create_boot_operation
        ; перевірка команди форматування пристрою
        mov rsi, buffer_command
        mov rcx, 7
        mov rdi, format_command
        repe cmpsb
        jz .device_format_operation
        ; перевірка команди виходу з програми
        mov rsi, buffer_command
        mov rcx, 4
        mov rdi, exit_command
        repe cmpsb
        jz .exit
        jnz .main_loop

        .output_help_operation:
            call output_help_operation
            jmp .main_loop
        .devices_list_operation:
            call devices_list_operation
            jmp .main_loop
        .device_mount_operation:
            call device_mount_operation
            jmp .main_loop
        .device_unmount_operation:
            call device_unmount_operation
            jmp .main_loop
        .device_detach_operation:
            call device_detach_operation
            jmp .main_loop
        .create_boot_operation:
            call create_boot_operation
            jmp .main_loop
        .device_format_operation:
            call device_format_operation
            jmp .main_loop
    .exit:
        mov rax, 1
        mov rdi, 1
        mov rsi, exit_the_program
        mov rdx, exit_the_program_len
        syscall
        xor rax, rax
        ret


;=========================================================
;================ВИВЕДЕННЯ СПИСКУ ОПЕРАЦІЙ================
;=========================================================
section '.text' writeable
output_help_operation:
    ; Виводимо меню операцій
    mov rax, 1
    mov rdi, 1
    mov rsi, message_operations_list
    mov rdx, message_operations_list_len
    syscall
    ret

;=========================================================
;===========ВИВЕДЕННЯ СПИСКУ ДИСКОВИХ ПРИСТРОЇВ===========
;=========================================================
section '.text' writeable
devices_list_operation:
    ; виведення повідомлення про список пристроїв
    mov rax, 1
    mov rdi, 1
    mov rsi, list_devices
    mov rdx, list_devices_len
    syscall
    ; виведення самих пристроїв
    mov rdi, final_devices_list_command
    xor rax, rax
    call system
    ret

;=========================================================
;===================МОНТУВАННЯ ПРИСТРОЮ===================
;=========================================================
section '.text' writeable
device_mount_operation:
    ; повідомлення про введення пристрою
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_device
    mov rdx, message_enter_device_len
    syscall
    ; зчитуємо назву пристрою
    mov rax, 0
    mov rdi, 0
    mov rsi, device
    mov rdx, device_len
    syscall
    mov [rsi+rax-1], byte 0

    ; повідомлення про введення каталогу монтуваня
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_directory
    mov rdx, message_enter_directory_len
    syscall
    ; зчитуємо шлях до каталогу
    mov rax, 0
    mov rdi, 0
    mov rsi, directory
    mov rdx, directory_len
    syscall
    mov [rsi+rax-1], byte 0

    ; ідентифікація ФС і монтування пристрою
    mov rdi, device
    mov rsi, directory
    mov rdx, ext4_filesystem
    mov rcx, 0
    xor rax, rax
    call mount
    cmp rax, 0
    jz success_mount_label
    mov rdi, device
    mov rsi, directory
    mov rdx, vfat_filesystem
    mov rcx, 0
    xor rax, rax
    call mount
    cmp rax, 0
    jz success_mount_label
    mov rdi, device
    mov rsi, directory
    mov rdx, xfs_filesystem
    mov rcx, 0
    xor rax, rax
    call mount
    cmp rax, 0
    jz success_mount_label
    mov rdi, device
    mov rsi, directory
    mov rdx, btrfs_filesystem
    mov rcx, 0
    xor rax, rax
    call mount
    cmp rax, 0
    jz success_mount_label

    ; повідомлення про помилку монтування
    mov rax, 1
    mov rdi, 1
    mov rsi, error_mount
    mov rdx, error_mount_len
    syscall
    jmp success_mount_label_skip
    success_mount_label:
        ; повідомлення про успішне монтування
        mov rax, 1
        mov rdi, 1
        mov rsi, success_mount
        mov rdx, success_mount_len
        syscall
    success_mount_label_skip:

    ret


;=========================================================
;==================РОЗМОНТУВАННЯ ПРИСТРОЮ=================
;=========================================================
section '.text' writeable
device_unmount_operation:
    ; повідомлення про введення каталогу, в який примонтовано пристрій
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_directory
    mov rdx, message_enter_directory_len
    syscall
    ; зчитуємо шлях до каталогу, в який примонтовано пристрій
    mov rax, 0
    mov rdi, 0
    mov rsi, directory
    mov rdx, directory_len
    syscall
    mov [rsi+rax-1], byte 0

    ; розмонтування пристрою
    mov rdi, directory
    xor rax, rax
    call umount

    ; перевірка успішності виконання операції
    cmp rax, 0
    jz success_unmount_label
    ; повідомлення про помилку розмонтування
    mov rax, 1
    mov rdi, 1
    mov rsi, error_unmount
    mov rdx, error_unmount_len
    syscall
    jmp success_unmount_label_skip
    success_unmount_label:
        ; повідомлення про успішне розмонтування
        mov rax, 1
        mov rdi, 1
        mov rsi, success_unmount
        mov rdx, success_unmount_len
        syscall
    success_unmount_label_skip:

    ret


;=========================================================
;===================ВІДКЛЮЧЕННЯ ПРИСТРОЮ==================
;=========================================================
section '.text' writeable
device_detach_operation:
    ; повідомлення про введення пристрою для відключення
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_device
    mov rdx, message_enter_device_len
    syscall
    ; зчитуємо пристрій для відключення
    mov rax, 0
    mov rdi, 0
    mov rsi, device
    mov rdx, device_len
    syscall
    mov [rsi+rax-1], byte 0

    ; формування інструкції для відключення
    mov rdi, final_detach_command
    mov rsi, final_detach_command_len
    mov rdx, template_detach_command
    mov rcx, device
    call snprintf

    ; виконання інструкції відключення
    mov rdi, final_detach_command
    xor rax, rax
    call system

    ; перевірка успішності виконання операції
    cmp rax, 0
    jz success_detach_label
    ; повідомлення про помилку відключення
    mov rax, 1
    mov rdi, 1
    mov rsi, error_detach
    mov rdx, error_detach_len
    syscall
    jmp success_detach_label_skip
    success_detach_label:
        ; повідомлення про успішне відключення
        mov rax, 1
        mov rdi, 1
        mov rsi, success_detach
        mov rdx, success_detach_len
        syscall
    success_detach_label_skip:

    ret


;=========================================================
;==========СТВОРЕННЯ ЗАВАНТАЖУВАЛЬНОГО ПРИСТРОЮ===========
;=========================================================
section '.text' writeable
create_boot_operation:
    ; повідомлення про введення пристрою для створення завантажувача
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_device
    mov rdx, message_enter_device_len
    syscall
    ; зчитуємо пристрій для створення завантажувача
    mov rax, 0
    mov rdi, 0
    mov rsi, device
    mov rdx, device_len
    syscall
    mov [rsi+rax-1], byte 0

    ; повідомлення про введення шляху до ISO-образу
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_iso_path
    mov rdx, message_enter_iso_path_len
    syscall
    ; зчитуємо шлях до ISO-образу
    mov rax, 0
    mov rdi, 0
    mov rsi, isofile
    mov rdx, isofile_len
    syscall
    mov [rsi+rax-1], byte 0

    ; формування інструкції створення завантажувального пристрою
    mov rdi, final_create_boot_command
    mov rsi, final_create_boot_command_len
    mov rdx, template_create_boot_command
    mov rcx, isofile
    mov r8, device
    call snprintf

    ; повідомлення про початок створення завантажувального пристрою
    mov rax, 1
    mov rdi, 1
    mov rsi, creating_boot_started
    mov rdx, creating_boot_started_len
    syscall
    
    ; процес створення завантажувального пристрою
    mov rdi, final_create_boot_command
    xor rax, rax
    call system

    ; перевірка успішності виконання операції
    cmp rax, 0
    jz success_creating_boot_label
    ; повідомлення про помилку створення завантажувального пристрою
    mov rax, 1
    mov rdi, 1
    mov rsi, error_creating_boot
    mov rdx, error_creating_boot_len
    syscall

    jmp success_creating_boot_label_skip
    success_creating_boot_label:
        ; повідомлення про успішне створення завантажувального пристрою
        mov rax, 1
        mov rdi, 1
        mov rsi, success_creating_boot
        mov rdx, success_creating_boot_len
        syscall
    success_creating_boot_label_skip:

    ret


;=========================================================
;==================ФОРМАТУВАННЯ ПРИСТРОЮ==================
;=========================================================
section '.text' writeable
device_format_operation:
    ; повідомлення про введення пристрою для форматування
    mov rax, 1
    mov rdi, 1
    mov rsi, message_enter_device
    mov rdx, message_enter_device_len
    syscall
    ; зчитуємо пристрій для форматування
    mov rax, 0
    mov rdi, 0
    mov rsi, device
    mov rdx, device_len
    syscall
    mov [rsi+rax-1], byte 0

    ; повідомлення про введення файлової системи
    mov rax, 1
    mov rdi, 1
    mov rsi, message_fs_format
    mov rdx, message_fs_format_len
    syscall
    ; зчитуємо назву файлової системи
    mov rax, 0
    mov rdi, 0
    mov rsi, filesystem
    mov rdx, filesystem_len
    syscall
    mov [rsi+rax-1], byte 0

    ; формування інструкції для форматування
    mov rdi, final_format_command
    mov rsi, final_format_command_len
    mov rdx, template_format_command
    mov rcx, device
    mov r8, filesystem
    mov r9, device
    call snprintf

    ; повідомлення про початок форматування
    mov rax, 1
    mov rdi, 1
    mov rsi, formatting_started
    mov rdx, formatting_started_len
    syscall

    ; форматування у вибрану ФС
    mov rdi, final_format_command
    xor rax, rax
    call system

    ; перевірка успішності виконання операції
    cmp rax, 0
    jz success_format_label
    ; повідомлення про помилку форматування
    mov rax, 1
    mov rdi, 1
    mov rsi, error_format
    mov rdx, error_format_len
    syscall

    jmp success_format_label_skip
    success_format_label:
        ; повідомлення про успішне форматування
        mov rax, 1
        mov rdi, 1
        mov rsi, success_format
        mov rdx, success_format_len
        syscall
    success_format_label_skip:

    ret