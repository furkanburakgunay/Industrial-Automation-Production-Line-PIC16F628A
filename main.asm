LIST P=16F628A
    INCLUDE "P16F628A.INC"
    ; MCLRE_ON: RA5 pinini donanımsal reset yapar. Butona basınca işlemci baştan başlar.
    __CONFIG _WDT_OFF & _XT_OSC & _MCLRE_ON & _LVP_OFF & _PWRTE_ON

    CBLOCK 0x20
    KAPASITE
    ERKEK
    BAYAN
    S1, S2      
    ENDC

    ORG 0x00
    GOTO BASLAT

BEKLE
    MOVLW D'255'
    MOVWF S1
D1  MOVLW D'255'
    MOVWF S2
D2  DECFSZ S2,F
    GOTO D2
    DECFSZ S1,F
    GOTO D1
    RETURN

BASLAT
    MOVLW 0x07      
    MOVWF CMCON     ; PortA dijital
    
    BANKSEL TRISA
    MOVLW B'00101111' ; RA0,1,2,3,5 giriş
    MOVWF TRISA 
    CLRF TRISB      ; PORTB çıkış
    
    BANKSEL PORTA
    CLRF PORTB
    CLRF KAPASITE

; --- 1. AŞAMA: Kapasite Ayar ---
KAP_SEC
    BTFSS PORTA, 0  ; RA0'a basıldı mı?
    GOTO BAS_KONTROL
    INCF KAPASITE, F
    CALL BEKLE      ; Buton arkı
BEKLE_RA0
    BTFSC PORTA, 0  ; Parmak çekilmediyse bekle
    GOTO BEKLE_RA0

BAS_KONTROL
    BTFSS PORTA, 1  ; RA1 (Başlat) basıldı mı?
    GOTO KAP_SEC    ; Hayırsa dön

    ; Kapasiteyi sayaçlara yükle
    MOVF KAPASITE, W
    MOVWF BAYAN
    MOVWF ERKEK
    
    BSF PORTB, 0    ; Motorları aç
    BSF PORTB, 1

; --- 2. AŞAMA: Üretim ---
ANA
    ; Bayan Kontrol
    BTFSS PORTB, 0  ; Motor zaten durduysa bakma
    GOTO ERKEK_BAK
    BTFSS PORTA, 2  ; Sensör gördü mü?
    GOTO ERKEK_BAK
    CALL BEKLE
    DECFSZ BAYAN, F ; Sayı bitti mi?
    GOTO ERKEK_BAK
    BCF PORTB, 0    ; BİTTİ, motoru kapat

ERKEK_BAK
    BTFSS PORTB, 1  ; Motor zaten durduysa bakma
    GOTO DURUM_BAK
    BTFSS PORTA, 3  ; Sensör gördü mü?
    GOTO DURUM_BAK
    CALL BEKLE
    DECFSZ ERKEK, F
    GOTO DURUM_BAK
    BCF PORTB, 1    ; BİTTİ, motoru kapat

DURUM_BAK
    ; İki motor da kapandı mı?
    BTFSC PORTB, 0
    GOTO ANA        ; B0 hala açık, devam
    BTFSC PORTB, 1
    GOTO ANA        ; B1 hala açık, devam

; --- 3. AŞAMA: Bitiş ---
SON_DONGU
    ; Buraya geldiğinde motorlar durmuştur.
    ; RA5'e (MCLR) bastığında işlemci donanımsal olarak 
    ; kendini kapatıp 0x00 adresinden (en baştan) açacaktır.
    GOTO SON_DONGU 

    END