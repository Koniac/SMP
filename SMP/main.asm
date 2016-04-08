.386
.model flat,stdcall
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
include 	d:\masm32\include\windows.inc
include 	d:\masm32\include\user32.inc
include 	d:\masm32\include\kernel32.inc
include 	d:\masm32\include\comdlg32.inc
include		d:\masm32\include\winmm.inc
includelib 	d:\masm32\lib\user32.lib
includelib 	d:\masm32\lib\kernel32.lib
includelib 	d:\masm32\lib\comdlg32.lib
includelib 	d:\masm32\lib\winmm.lib

.const
IDM_OPEN 	equ 1
IDM_SAVE 	equ 2
IDM_EXIT 	equ 3
ID_PLAY 	equ 4
ID_STOP 	equ 5
MAXSIZE 	equ 260
MEMSIZE 	equ 65535

EditID 		equ 1

.data
ClassName 		db "SMPClass",0
AppName  		db "SMPApp",0
EditClass 		db "edit",0
MenuName 		db "FirstMenu",0
Hello_string 	db "Hello, my friend",0
Song_Name		db "TEST.WAV",0
ofn   OPENFILENAME <>
FilterString 	db "All Files",0,"*.*",0
             	db "Text Files",0,"*.txt",0,0
buffer 			db MAXSIZE dup(0)

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hwndEdit HWND ?
hFile HANDLE ?
hMemory HANDLE ?
pMemory DWORD ?
SizeReadWrite DWORD ?

.code
start:
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov CommandLine,eax
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,NULL
	push  hInst
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_WINDOW+1
	mov   wc.lpszMenuName,OFFSET MenuName
	mov   wc.lpszClassName,OFFSET ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax
	invoke RegisterClassEx, addr wc
	INVOKE CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax
	INVOKE ShowWindow, hwnd,SW_SHOWNORMAL
	INVOKE UpdateWindow, hwnd
	.WHILE TRUE
                INVOKE GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                INVOKE TranslateMessage, ADDR msg
                INVOKE DispatchMessage, ADDR msg
	.ENDW
	mov     eax,msg.wParam
	ret
WinMain endp

WndProc proc uses ebx hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.IF uMsg==WM_CREATE
		INVOKE CreateWindowEx,NULL,ADDR EditClass,NULL,\
                   WS_VISIBLE or WS_CHILD or ES_LEFT or ES_MULTILINE or\
                   ES_AUTOHSCROLL or ES_AUTOVSCROLL,0,\
                   0,0,0,hWnd,EditID,\
                   hInstance,NULL
		mov hwndEdit,eax
		invoke SetFocus,hwndEdit
		mov ofn.lStructSize,SIZEOF ofn
		push hWnd
		pop  ofn.hWndOwner
		push hInstance
		pop  ofn.hInstance
		mov  ofn.lpstrFilter, OFFSET FilterString
		mov  ofn.lpstrFile, OFFSET buffer
		mov  ofn.nMaxFile,MAXSIZE
	.ELSEIF uMsg==WM_SIZE
		mov eax,lParam
		mov edx,eax
		shr edx,16
		and eax,0ffffh
		invoke MoveWindow,hwndEdit,0,0,eax,edx,TRUE
	.ELSEIF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.ELSEIF uMsg==WM_COMMAND
		mov eax,wParam
		.if lParam==0
			.if ax==IDM_OPEN
				mov  ofn.Flags, OFN_FILEMUSTEXIST or \
                                OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
				invoke GetOpenFileName, ADDR ofn
				.if eax==TRUE
					invoke CreateFile,ADDR buffer,\
                                       GENERIC_READ or GENERIC_WRITE ,\
                                       FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                       NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
                                       NULL
					mov hFile,eax
					invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE
					mov  hMemory,eax
					invoke GlobalLock,hMemory
					mov  pMemory,eax
					invoke ReadFile,hFile,pMemory,MEMSIZE-1,ADDR SizeReadWrite,NULL
					invoke SendMessage,hwndEdit,WM_SETTEXT,NULL,pMemory
					invoke CloseHandle,hFile
					invoke GlobalUnlock,pMemory
					invoke GlobalFree,hMemory
				.endif
					invoke SetFocus,hwndEdit
			.elseif ax==IDM_SAVE
				mov ofn.Flags,OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
				invoke GetSaveFileName, ADDR ofn
				.if eax==TRUE
					invoke CreateFile,ADDR buffer,\
                                                GENERIC_READ or GENERIC_WRITE ,\
                                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                                NULL,CREATE_NEW,FILE_ATTRIBUTE_ARCHIVE,\
                                                NULL
					mov hFile,eax
					invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE
					mov  hMemory,eax
					invoke GlobalLock,hMemory
					mov  pMemory,eax
					invoke SendMessage,hwndEdit,WM_GETTEXT,MEMSIZE-1,pMemory
					invoke WriteFile,hFile,pMemory,eax,ADDR SizeReadWrite,NULL
					invoke CloseHandle,hFile
					invoke GlobalUnlock,pMemory
					invoke GlobalFree,hMemory
				.endif
				invoke SetFocus,hwndEdit
			.elseif ax==ID_PLAY
				invoke PlaySound,offset Song_Name,NULL,SND_ASYNC
			.elseif ax==ID_STOP
				invoke PlaySound,NULL,NULL,SND_ASYNC
			.else
				invoke DestroyWindow, hWnd
			.endif
		.endif
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.ENDIF
	xor    eax,eax
	ret
WndProc endp

end start
