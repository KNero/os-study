[ORG 0x00]
[BITS 16]

SECTION .txt

jmp 0x1000:START ;CS 세그먼트 레지스터리에 0x1000을 복사하면서, START 레이블로 이동

SECTORCOUNT: dw 0x0000  ; 현재 실행 중인 섹터 번호를 저장
TOTALSECTORCOUNT equ 1024   ; 가상 OS의 총 섹터 수. 최대 1152 섹터(0x90000 byte)까지 가능

START:
    mov ax, cs
    mov ds, ax  ; 코드를 복사하기 위해서 CS 레지스터의 값을 DS 레지스터에 저장
    mov ax, 0XB800
    mov es, ax

; 각 섹터별로 코드를 생성
%assign i   0           ; i라는 변수를 지정하고 0으로 초기화
%rep TOTALSECTORCOUNT   ; TOTALSECTORCOUNT 에 저장된 값만큼 아래 코드를 반복
    %assign i i + 1     ; i 1증가

    mov ax, 2   ; 한 문자를 나타내는 바이트 수(2)를 ax 레지스터에 설정
    mul word[SECTORCOUNT]   ; AX 레지스터와 섹터수를 곱함
    mov si, ax

    mov byte[es: si + (160 * 2)], '0' + (i % 10)
    add word[SECTORCOUNT], 1

    %if i == TOTALSECTORCOUNT
        jmp $
    %else
        jmp (0x1000 + i * 0x20): 0x0000 ; 다음 섹터 오프셋으로 이동
    %endif

    times (512 - ($ - $$) % 512) db 0x00
%endrep

