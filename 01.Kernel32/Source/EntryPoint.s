[ORG 0x00]
[BITS 16]

SECTION .txt

START:
    mov ax, 0x1000  ; 보호 모드 엔트리 포인트의 시작 어드레스(0x10000)를 세그먼트 레지스터 값으로 변환
    mov ds, ax
    mov es, ax

    cli         ; 인터럽트가 발생하지 못하도록 설정
    lgdt [GDTR] ; GDTR 자료구조를 프로세서에 설정하여 GDT 테이블을 로드

    ; 보호 모드로 진입
    ; Disable Paging, Disable Cache, Internal FPU, Disable Align Check, Enable ProtectedMode
    mov eax, 0x4000003B ;PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax    ; CR0 컨트롤 레지스터에 위에서 저장한 플래그를 설정하여 보호모드로 전환

    ; 커널 코드 세그먼트를 0x00을 기준으로 하는 것으로 교체하고 EIP의 값을 0x00을 기준으로 재설정
    ; CS 세그먼트 셀렉터 : EIP
    jmp dword 0x08: (PROTECTEDMODE - $$ + 0x10000)

; 보호 모드로 진입
[BITS 32]
PROTECTEDMODE:
    mov ax, 0x10    ; 보호 모드 커널용 데이터 세그먼트 디스크립터를 AX 레지스터에 저장
    mov ds, ax      ; DS 세그먼트 셀렉터에 설정
    mov es, ax      ; ES 세그먼트 셀렉터에 설정
    mov fs, ax      ; FS 세그먼트 셀렉터에 설정
    mov gs, ax      ; GS 세그먼트 셀렉터에 설정

    ; 스택을 0x00000000 ~ 0x0000FFFF 영역에 64KB 크기로 생성
    mov ss, ax      ; SS 세그먼트 셀렉터에 설정
    mov esp, 0xFFFE ; ESP 레지스터 어드레스를 0xFFFE 로 설정
    mov ebp, 0xFFFE ; EBP 레지스터의 어드레스를 0xFFFE 로 설정

    ; 화면에 보호 모드로 전환되었다는 메시지를 출력한다.
    push (SWITCHSUCCESSMESSAGE - $$ + 0x10000)  ; 출력할 메시지의 어드레스를 스택에 삽입
    push 2  ; 화면 Y 좌표 (2) 스택에 삽입
    push 0  ; 화면 X 좌료 (0) 스택에 삽입
    call PRINTMESSAGE
    add esp, 12 ; 삽입한 파라미터 제거

    jmp $

PRINTMESSAGE:
    push ebp    ; 베이스 포인터 레지스터 (BP) 를 스택에 삽입
    mov ebp, esp    ; 베이스 포인터 레지스터(BP)에 스택 포인터 레지스터(SP)의 값을 설정
    push esi    ; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서 스택에 삽입된 값을 꺼내 원래 값으로 복원
    push edi
    push eax
    push ecx
    push edx

    mov eax, dword[ebp + 12]   ; 파라미터 2(화면 좌표 Y) 를 EAX 레지스터에 설정
    mov esi, 160                ; 한 라인의 바이트 수 (2 * 80) 를 ESI 레지스터에 저장
    mul esi                     ; EAX 레지스터와 ESI 레지스터를 곱하여 화면 Y 어드레스 계산
    mov edi, eax                ; 계산된 화면 Y 어드레스를 EDI 레지스터에 설정

    mov eax, dword[ebp + 8]    ; 파라미터 1(화면 좌표 X) 를 EAX 레지스터에 설정
    mov esi, 2                  ; 한 문자를를 나타내는 바이트 수 (2) 를 ESI 레지스터에 저장
    mul esi                     ; EAX 레지스터와 ESI 레지스터를 곱하여 화면 X 어드레스 계산
    add edi, eax                ; 계산된 화면 Y 어드레스를 EDI 레지스터에 설정

    ; 출력할 문자열 어드레스
    mov esi, dword[ebp + 16]    ; 파라미터 3(출력할 문자열 어드레스

.MESSAGELOOP:
    mov cl, byte[esi]   ; ESI 레지스터가 가리키는 문자열 위치에서 한 문자를 CL 레지스터에 복사
                        ; CL 레지스터는 ECX 레지스터의 하위 1바이트를 의미
                        ; 문자열은 1바이트로 충분하므로 ECX 레지스터의 하위 1바이트만 사용

    cmp cl, 0
    je .MESSAGEEND

    mov byte[edi + 0xB8000], cl    ; 0이 아니라면 비디오 메모리 어드레스 0xB8000 + EDI 에 문자를 출력

    add esi, 1  ; ESI 레지스터에 1을 더하여 다음 문자열로 이동
    add edi, 2  ; EDI 레지스터에 2를 더하여 비디오 메모리의 다음 문자 위치로 이동
                ; 비디오 메모리는 (문자, 속성)의 쌍으로 구성되므로 문자만 출력하려면 2를 더해야 함.
    jmp .MESSAGELOOP

.MESSAGEEND:
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret

; 데이터 영역
; 아래의 데이터들을 8바이트에 맞춰 정렬하기 위해서 추가
align 8, db 0

;GDTR 의 끝을 8byte 로 정렬하기 위해 추가
dw 0x0000
; GDTR 자료구조 정의
GDTR:
    dw GDTEND - GDT - 1  ; 아래에 위치하는 GDT 테이블의 전체 크기
    dd (GDT - $$ + 0x10000) ; 아래에 위치하는 GDT 테이블의 시작 어드레스

; GDT 테이블 정의
GDT:
    ; 널 디스크립터, 반드시 0으로 초기화해야 함
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    CODEDESCRIPTOR:
        dw 0xFFFF   ; Limit [15:0]
        dw 0x0000   ; Base [15:0]
        db 0x00     ; Base [23:16]
        db 0x9A     ; P=1, DPL=0, Code Segment, Execute/Read
        db 0xCF     ; G=1, D=1, L=0, Limit[19:16]
        db 0x00     ; Base [31, 24]

    ; 보호 모드 커널용 데이터 세그먼트 디스크립터
    DATADESCRIPTOR:
        dw 0xFFFF   ; Limit [15:0]
        dw 0x0000   ; Base [15:0]
        db 0x00     ; Base [23:16]
        db 0x92     ; P=1, DPL=0, Data Segment, Read/Write
        db 0xCF     ; G=1, D=1, L=0, Limit[19:16]
        db 0x00     ; Base [31, 24]
GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success.', 0

times 512 - ($ - $$) db 0x00