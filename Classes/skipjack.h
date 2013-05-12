//
//  skipjack.h
//	
//	a header file for skipjack.c 

typedef unsigned char  byte;
typedef unsigned int  word32;


void makeKey(byte key[10], byte tab[10][256]);
void skip_encrypt(byte tab[10][256], byte in[8], byte out[8]);
void skip_decrypt(byte tab[10][256], byte in[8], byte out[8]);
