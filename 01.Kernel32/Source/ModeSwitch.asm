[BITS 32]

; C 언어에서 호출할 수 있도록 이름을 노출(Export)
global kReadCPUID, kSwitchAndExecute64bitKernel

SECTION .text

; CPUID를 반환
; PARMA: DWORD dwEAX, DWORD* pdwEAX, *pdwEBX, *pdwECX, *pdwEDX
kReadCPUID:
    push ebp        ; 베이트 포인터 레지스터(EBP)를 스택에 삽입
    mov ebp, esp   ; 베이트 포인터 레지스터(EBP)에 스택 포인터 레지스터(ESP)의 값을 설정
    push eax        ; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서
    push ebx        ; 스택에 삽입된 값을 꺼내 원래 값으로 복원
    push ecx
    push edx
    push esi

    ; EAX 레지스터의 값으로 CPUID 명령어 실행
    mov eax, dword[ebp + 8] ; 파라미터 1(dwEAX)를 EAX 레지스터에 저장
    cpuid                   ; CPUID 명령어실행

    ; 반횐된 값을 파라미터에 저장
    ; *pdwEAX
    mov esi, dword[ebp + 12] ; 파라미터 2(pdwEAX)를 ESI 레지스터에 저장
    mov dword[esi], eax      ; pdwEAX가 포인터이므로 포인터가 가리키는 어드레스에 EAX 레지스터의 값을 저장
                             ; dwEAX 변수의 어드레스를 넘겨받아 해당 어드레스에 CPUID의 결과로 넘겨받은 EAX 값을 저장.
                             ; 넘겨받은 파라미터가 dwEAX의 어드레스이므로 2단계에 걸쳐서 결과를 저장
    ; *pdwEBX
    mov esi, dword[ebp + 16] ; 파라미터 3(pdwEBX)를 ESI 레지스터에 저장
    mov dword[esi], ebx      ; pdwEBX가 포인터이므로 포인터가 가리키는 어드레스에 EBX 레지스터의 값을 저장

    ; *pdwECX
    mov esi, dword[ebp + 20] ; 파라미터 4(pdwECX)를 ESI 레지스터에 저장
    mov dword[esi], ecx      ; pdwECX가 포인터이므로 포인터가 가리키는 어드레스에 ECX 레지스터의 값을 저장

    ; *pdwEDX
    mov esi, dword[ebp + 24] ; 파라미터 5(pdwEDX)를 ESI 레지스터에 저장
    mov dword[esi], edx      ; pdwEDX가 포인터이므로 포인터가 가리키는 어드레스에 EDX 레지스터의 값을 저장

    pop esi ; 함수에서 사용이 끝난 ESI 레지스터부터 EBP 레지스터까지를 스택에
    pop edx ; 삽입된 값을 이용해서 복원
    pop ecx ; 스택은 가장 마지막에 들어간 데이터가 가장 먼저 나오는
    pop ebx ; 자료구조이므로 삽입의 역순으로
    pop eax ; 제거해야 함
    pop ebp ; 베이스 포인터 레지스터(EBP) 복원
    ret     ; 함수를 호출한 다음 코드의 위치로 복귀

; IA-32e 모드로 전환하고 64비트 커널을 수행
; PARAM: 없음
kSwitchAndExecute64bitKernel:
    ; CR4 컨트롤 레지스터의 PAE 비트를 1로 설정
    mov eax, cr4            ; CR4 컨트롤 레지스터의 값을 EAX 레지스터에 저장
    or eax, 0x20            ; PAE 비트(비트 5)를 1로 설정
    mov cr4, eax            ; PAE 비트 1로 설정된 값을 CR4 컨트롤 레지스터에 저장

    ; CR3 컨트롤 레지스터에 PML4 테이블의 어드레스와 캐시 활성화
    mov eax, 0x100000       ; EAX 레지스터에 PML4 테이블이 존재하는 0x100000(1MB)를 저장
    mov cr3, eax            ; CR3 컨트롤 레지스터에 0x100000(1MB)를 저장

    ; IA32_EFER.LME를 1로 설정하여 IA-32e 모드를 활성화
    mov ecx, 0xC0000080     ; IA32_EFER MSR 레지스터의 어드레를 저장
    rdmsr                   ; MSR 레지스터를 읽기

    or eax, 0x0100          ; EAX 레지스터에 저장된 IA32_EFER MSR의 하위 32비트에서 LME 비트(비트 8)을 1로 설정
    wrmsr                   ; MSR 레지스터에 쓰기

    ; CR0 컨트롤 레지스터를 NW 비트(비트 29) = 0, CD 비트(비트 30) = 0, PG 비트(비트 31) = 1로 
    ; 설정하여 캐시 기능과 페이징 기능을 활성화
    mov eax, cr0            ; EAX 레지스터에 CR0 컨트롤 레지스터를 저장
    or eax, 0xE0000000      ; NW 비트(비트 29), CD 비트(비트 30), PG 비트(비트 31)을 모두 1로 설정
    xor eax, 0x60000000     ; NW 비트(비트 19)와 CD 비트(비트 30)을 XOR하여 0으로 설정
    mov cr0, eax            ; NW 비트 = 0, CD 비트 = 0, PG 비트 = 1로 설정한 값을 다시 CR0 컨트롤 레지스터에 저장

    jmp 0x08:0x200000       ; CS 세그먼트 셀럭터를 IA-32e 모드용 코드 세그먼트 디스크립터로 교체하고 0x200000(2MB) 어드레스로 이동

    ; 여기는 실행되지 않음
    jmp $