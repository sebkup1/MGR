#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define extern            // Keil: Line added for modular project management

#include "easyweb.h"

#include "EMAC.h"         // Keil: *.c -> *.h    // ethernet packet driver
#include "tcpip.h"        // Keil: *.c -> *.h    // easyWEB TCP/IP stack
#include <LPC23xx.h>      // Keil: Register definition file for LPC2378

#include "webpage.h"      // webside for our HTTP server (HTML)

#include "type.h"
#include "irq.h"
#include "target.h"

#include "fio.h"
#include "Pico.h"

/*----------------------------------------------------------------------------
  Main Program
 *----------------------------------------------------------------------------*/
int main (void) {
	DWORD REG;	
	BOOL set=0;
	TCPRxDataCount =0;
	PicoLCDReceiveDataCounter=0;
	PicoSendViaTCPReady=0;
	PicoData=0x0;
	
			SCS |= GPIOM;	
	(*(volatile unsigned long *)(HS_PORT_DIR_BASE 
			+ 0 * HS_PORT_DIR_INDEX)) = 0x00000a00;
	
	// LCD Pico out data set
	(*(volatile unsigned long *)(HS_PORT_DIR_BASE 
			+ 0 * HS_PORT_DIR_INDEX)) |= 0x38010000;
	
	(*(volatile unsigned long *)(HS_PORT_DIR_BASE 
		 + 1 * HS_PORT_DIR_INDEX)) = 0xffffffff;    //0x00000000 wejscia
	
	// Configure PicoBlazes Port
	(*(volatile unsigned long *)(HS_PORT_DIR_BASE 
			+ 2 * HS_PORT_DIR_INDEX)) = 0x00000400;

				
	FIO2PIN |= ReadyReadFromPico;

	
	REG = FIO0PIN | 0xfffffe7f;
	while(REG == 0xffffffff)
	{
		FIO1SET2 = 0x08;//czerwony
		REG = FIO0PIN | 0xfffffe7f;
	}
	
	
	FIO1SET2 = 0x20;//niebieska
	FIO1CLR2 = 0x08;//czerwony
	
																	
	
	TCPLowLevelInit();
	
		//PINSEL3 |= 0xC0000000; 						// Enable ad0[5] converter
																			// so it could read value from P1.31 potentiometer 
	
	//HTTPStatus = 0;                                 // clear HTTP-server's flag register

	FIO1CLR = 0xFFFFFFFF;	
	FIO1SET |= 0x0040000;
	FIO0CLR = ToPicoDataValid;
	
    TCPLocalPort = 50001;
  //TCPLocalPort = TCP_PORT_HTTP;

	TCPRemotePort = 50000;

  while (1)                                       // repeat forever
  {

			
    //if (!(SocketStatus & SOCK_ACTIVE)) TCPPassiveOpen();  // listen for incoming TCP-connection
    DoNetworkStuff();                                       // handle network and easyWEB-stack
															// events
		
	  
//	  if (!(TCPFlags & IP_ADDR_RESOLVED)) 
//		TCPActiveOpen();
		
		
		
	if (!(TCPFlags & IP_ADDR_RESOLVED)){
		
		if(set<1)
		{
			TCPStartRetryTimer();
			PrepareARP_REQUEST();                        // ask for MAC by sending a broadcast
			LastFrameSent = ARP_REQUEST;
		}
			
		if ((TCPStateMachine == CLOSED) || (TCPStateMachine == LISTENING))
		{
			TCPFlags |= TCP_ACTIVE_OPEN;                 // let's do an active open!
			TCPFlags &= ~IP_ADDR_RESOLVED;               // we haven't opponents MAC yet
			SocketStatus = SOCK_ACTIVE;                  // reset, socket now active    
			set=1;
		}
	}
	else{set=0;}
		
		

		
		
//		if ((SocketStatus & SOCK_DATA_AVAILABLE)){
//			
//			SocketStatus &= ~SOCK_DATA_AVAILABLE;
//			MAC_RXCONSUMEINDEX = 0;
//			MAC_RXPRODUCEINDEX = 0;
//			//TCPTransmitTxBuffer();
//		}
		
		

		//HTTPServer();
//		while(1)
//	{
//		SendToPico(118);
//	}
    ProcessData();
		SendEcho();
		PicoBlazesThread();
		 

  }
}

void PicoBlazesThread(){
	if(FIO2PIN & PicoDataValid)
	{
		(*(volatile unsigned long *)(HS_PORT_DIR_BASE 
		+ 2 * HS_PORT_DIR_INDEX)) &= PicoDataOutMask;
		
		PicoData = (FIO2PIN>>2);
		PicoDataBuffer[PicoLCDReceiveDataCounter]=PicoData;
		PicoLCDReceiveDataCounter++;
		if(PicoData ==35)PicoSendViaTCPReady=1;
		
		FIO2PIN &= NotReadyReadFromPico;
		
		while(!(FIO2PIN | PicoDataNotValid))
			{
				FIO2PIN &= NotReadyReadFromPico;
			}
	}
	FIO2PIN |= ReadyReadFromPico;
	SendFromPico();
}

void SendToPico(short int mes)
{
	FIO0CLR=0x00010000;
	FIO1CLR=0x38000000;
	if(FIO0PIN & ToPicoPicoReady)
	{
		switch(mes)
		{
			case 1:
			{
		FIO0SET=0x00010000;
		FIO1SET=0x00000000;
		FIO0SET = ToPicoDataValid;
		while ((FIO0PIN & ToPicoPicoReady))
		{
			FIO0SET=0x00010000;
			FIO1SET=0x00000000;
			FIO0SET = ToPicoDataValid;
		}
		FIO0CLR = ToPicoDataValid;
		break;
	}
		
		case 2:
		{
		FIO0SET=0x00010000;
		FIO1SET=0x08000000;
		FIO0SET = ToPicoDataValid;
		while ((FIO0PIN & ToPicoPicoReady))
		{
			FIO0SET=0x00010000;
			FIO1SET=0x08000000;
			FIO0SET = ToPicoDataValid;
		}
		FIO0CLR = ToPicoDataValid;
		break;
	}
		
		case 3:
		{
		FIO0SET=0x00010000;
		FIO1SET=0x18000000;
		FIO0SET = ToPicoDataValid;
		while ((FIO0PIN & ToPicoPicoReady))
		{
			FIO0SET=0x00010000;
			FIO1SET=0x18000000;
			FIO0SET = ToPicoDataValid;
		}
		FIO0CLR = ToPicoDataValid;
		}
		break;
		
		case 4:
		{
		FIO0SET=0x00010000;
		FIO1SET=0x38000000;
		FIO0SET = ToPicoDataValid;
		while ((FIO0PIN & ToPicoPicoReady))
		{
			FIO0SET=0x00010000;
			FIO1SET=0x38000000;
			FIO0SET = ToPicoDataValid;
		}
		FIO0CLR = ToPicoDataValid;
		break;
	}
}
	}
}

void SendFromPico(void)
{  
	if(PicoSendViaTCPReady>0){
		if (SocketStatus & SOCK_CONNECTED)             // check if somebody has connected to our TCP
		{
			if (SocketStatus & SOCK_DATA_AVAILABLE)      // check if remote TCP sent data
				TCPReleaseRxBuffer();                      // and throw it away
		
			if (SocketStatus & SOCK_TX_BUF_RELEASED)     // check if buffer is free for TX 
			{
				memcpy(TCP_TX_BUF, PicoDataBuffer, PicoLCDReceiveDataCounter);
				TCPTxDataCount = PicoLCDReceiveDataCounter;
				TCPTransmitTxBuffer();
				PicoLCDReceiveDataCounter=0;
				PicoSendViaTCPReady=0;
			}
		}
	}
}

void SendEcho(void)
{  
	if(TCPRxDataCount>0){
		if (SocketStatus & SOCK_CONNECTED)             // check if somebody has connected to our TCP
		{
			if (SocketStatus & SOCK_DATA_AVAILABLE)      // check if remote TCP sent data
				TCPReleaseRxBuffer();                      // and throw it away
		
			if (SocketStatus & SOCK_TX_BUF_RELEASED)     // check if buffer is free for TX
			{
				//_RxTCPBuffer[4] = 0x41;
				memcpy(TCP_TX_BUF, TCP_RX_BUF, TCPRxDataCount);
				TCPTxDataCount = TCPRxDataCount;
				TCPTransmitTxBuffer();
				TCPRxDataCount=0;
				//SendToPico(3);
			}
		}
	}
}

void ProcessData(void)
{  
	if(TCPRxDataCount>0){
		if (SocketStatus & SOCK_CONNECTED)             // check if somebody has connected to our TCP
		{
			if(_RxTCPBuffer[4] ==0x62)
			{
				FIO1SET2 = 0x20;//niebieska
				SendToPico(1);
			}
			
			if(_RxTCPBuffer[4] ==0x67)
				{
					FIO1SET2 = 0x10;//zielony	
					SendToPico(2);
				}
				
			if(_RxTCPBuffer[4] ==0x72)
				{
					FIO1SET2 = 0x08;//czerwony	
					SendToPico(3);
				}
				if(_RxTCPBuffer[4] ==0x63)
				{
					FIO1CLR2 = 0x38;//clear all	
					SendToPico(4);
				}
		}
	}
}

void HTTPServer(void)
{
  if (SocketStatus & SOCK_CONNECTED)             // check if somebody has connected to our TCP
  {
    if (SocketStatus & SOCK_DATA_AVAILABLE)      // check if remote TCP sent data
      TCPReleaseRxBuffer();                      // and throw it away

    if (SocketStatus & SOCK_TX_BUF_RELEASED)     // check if buffer is free for TX
    {
      if (!(HTTPStatus & HTTP_SEND_PAGE))        // init byte-counter and pointer to webside
      {                                          // if called the 1st time
        HTTPBytesToSend = sizeof(WebSide) - 1;   // get HTML length, ignore trailing zero
        PWebSide = (unsigned char *)WebSide;     // pointer to HTML-code
      }

      if (HTTPBytesToSend > MAX_TCP_TX_DATA_SIZE)     // transmit a segment of MAX_SIZE
      {
        if (!(HTTPStatus & HTTP_SEND_PAGE))           // 1st time, include HTTP-header
        {
          memcpy(TCP_TX_BUF, GetResponse, sizeof(GetResponse) - 1);
          memcpy(TCP_TX_BUF + sizeof(GetResponse) - 1, PWebSide, MAX_TCP_TX_DATA_SIZE - sizeof(GetResponse) + 1);
          HTTPBytesToSend -= MAX_TCP_TX_DATA_SIZE - sizeof(GetResponse) + 1;
          PWebSide += MAX_TCP_TX_DATA_SIZE - sizeof(GetResponse) + 1;
        }
        else
        {
          memcpy(TCP_TX_BUF, PWebSide, MAX_TCP_TX_DATA_SIZE);
          HTTPBytesToSend -= MAX_TCP_TX_DATA_SIZE;
          PWebSide += MAX_TCP_TX_DATA_SIZE;
        }
          
        TCPTxDataCount = MAX_TCP_TX_DATA_SIZE;   // bytes to xfer
        InsertDynamicValues();                   // exchange some strings...
        TCPTransmitTxBuffer();                   // xfer buffer
      }
      else if (HTTPBytesToSend)                  // transmit leftover bytes
      {
        memcpy(TCP_TX_BUF, PWebSide, HTTPBytesToSend);
        TCPTxDataCount = HTTPBytesToSend;        // bytes to xfer
        //InsertDynamicValues();                   // exchange some strings...
        TCPTransmitTxBuffer();                   // send last segment
        //TCPClose();                              // and close connection
        HTTPBytesToSend = 0;                     // all data sent
      }

      HTTPStatus |= HTTP_SEND_PAGE;              // ok, 1st loop executed
    }
  }
  else
    HTTPStatus &= ~HTTP_SEND_PAGE;               // reset help-flag if not connected
	
}



// samples and returns the AD-converter value of channel 0

unsigned int GetAD7Val(void)
{
// Keil: function replaced to handle LPC2378 A/D converter.
  unsigned int val;

  AD0CR = 0x01000020 | 0x002E0400;       // Setup A/D: 10-bit AIN0 @ 3MHz
  do {
    val = AD0GDR;                        // Read A/D Data Register
  } while ((val & 0x80000000) == 0);     // Wait for end of A/D Conversion
  AD0CR &= ~0x01000020;                  // Stop A/D Conversion
  val = (val >> 6) & 0x03FF;             // Extract AIN0 Value
  return(val/10);                      // result of A/D process 
}

// samples and returns AD-converter value of channel 1

unsigned int GetTempVal(void)
{
// Keil: function replaced to handle LPC2378 A/D converter.
  unsigned int val;

  AD0CR  = 0x01000002 | 0x002E0400;      // Setup A/D: 10-bit AIN1 @ 3MHz
  do {
    val = AD0GDR;                        // Read A/D Data Register
  } while ((val & 0x80000000) == 0);     // Wait for end of A/D Conversion
  AD0CR &= ~0x01000002;                  // Stop A/D Conversion
  val = (val >> 6) & 0x03FF;             // Extract AIN1 Value
  return(val / 10);                      // result of A/D process 
}

// searches the TX-buffer for special strings and replaces them
// with dynamic values (AD-converter results)

void InsertDynamicValues(void)
{
  unsigned char *Key;
           char NewKey[5];
  unsigned int i;
  
  if (TCPTxDataCount < 4) return;                     // there can't be any special string
  
  Key = TCP_TX_BUF;
  
  for (i = 0; i < (TCPTxDataCount - 3); i++)
  {
    if (*Key == 'A')
     if (*(Key + 1) == 'D')
       if (*(Key + 3) == '%')
         switch (*(Key + 2))
         {
           case '7' :                                 // "AD7%"?
           {
             sprintf(NewKey, "%3u", GetAD7Val());     // insert AD converter value
             memcpy(Key, NewKey, 3);                  // channel 7 (P6.7)
             break;
           }
           case 'A' :                                 // "ADA%"?
           {
             sprintf(NewKey, "%3u", GetTempVal());    // insert AD converter value
             memcpy(Key, NewKey, 3);                  // channel 10 (temp.-diode)
             break;
           }
         }
    Key++;
  }
}
