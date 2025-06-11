; dns_resolver.nasm
; Build: nasm -f elf64 dns_resolver.nasm && ld -o dns_resolver dns_resolver.o

%define SYS_SOCKET      41
%define SYS_SENDTO      44
%define SYS_RECVFROM    45
%define SYS_EXIT        60

%define AF_INET         2
%define SOCK_DGRAM      2
%define IPPROTO_UDP     17

%define PORT_DNS        0x3500     ; Port 53 in big endian (network order)
;%define DNS_IP          0x08080808 ; 8.8.8.8 in reverse byte order for sockaddr_in
%define DNS_IP 0x1A054A67  ; 103.74.5.26

section .data
; DNS query packet for: example.com
dns_query:
    dw 0x1337         ; ID
    dw 0x0100         ; flags: standard query, recursion desired
    dw 0x0001         ; QDCOUNT = 1
    dw 0x0000         ; ANCOUNT = 0
    dw 0x0000         ; NSCOUNT = 0
    dw 0x0000         ; ARCOUNT = 0

    ; QNAME: febri.click
    db 5, 'f','e','b','r','i'
    db 5, 'c','l','i','c','k'
    db 0

    dw 0x0001         ; QTYPE = A
    dw 0x0001         ; QCLASS = IN
dns_query_end:

query_len: equ dns_query_end - dns_query

sockaddr_in:
    dw AF_INET
    dw PORT_DNS
    dd DNS_IP
    times 8 db 0  ; padding (sockaddr_in is 16 bytes)

section .bss
sockfd      resq 1
recv_buf    resb 512

section .text
global _start

_start:
    ; socket(AF_INET, SOCK_DGRAM, 0)
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_DGRAM
    xor rdx, rdx
    syscall
    mov [sockfd], rax

    ; sendto(sockfd, dns_query, query_len, 0, &sockaddr_in, 16)
    mov rax, SYS_SENDTO
    mov rdi, [sockfd]
    mov rsi, dns_query
    mov rdx, query_len
    xor r10, r10
    lea r8, [rel sockaddr_in]
    mov r9, 16
    syscall

    ; recvfrom(sockfd, recv_buf, 512, 0, NULL, NULL)
    mov rax, SYS_RECVFROM
    mov rdi, [sockfd]
    mov rsi, recv_buf
    mov rdx, 512
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall

    ; Write raw response to stdout (for debugging)
    ; write(1, recv_buf, rax)
 ;   mov rdi, 1      ; stdout
 ;   mov rax, 1      ; sys_write
 ;   syscall

; write(1, dns_query, query_len)
mov rax, 1
mov rdi, 1
mov rsi, dns_query
mov rdx, query_len
syscall

; print raw response
mov rdi, 1      ; stdout
mov rax, 1      ; sys_write
; rsi sudah diisi oleh recv_buf dari syscall recvfrom
; rdx = jumlah byte yang diterima, sudah disimpan di rax
syscall

    ; exit(0)
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

