extern unsigned char PicoLCDStatus;
#define PicoLCDDataPresent                    0x01      // state machine NOT closed

#define SOCK_CONNECTED                 0x02      // user may send & receive data
#define SOCK_DATA_AVAILABLE            0x04      // new data available
#define SOCK_TX_BUF_RELEASED           0x08      // user may fill buffer

#define ReadyReadFromPico 						0x00000400
#define NotReadyReadFromPico 					0xFFFFFBFF			//P2.10
#define PicoDataValid 								0x00001000
#define PicoDataNotValid							0xFFFFeFFF   		//P2.12
#define PicoDataOutMask 							0xfffffc03
#define ToPicoDataValid 							0x00000800			//P0.11
#define ToPicoPicoReady			 					0x00008000			//P0.15

extern unsigned int PicoLCDReceiveDataCounter;
extern unsigned char PicoData;
extern short int PicoSendViaTCPReady;
extern unsigned char PicoDataBuffer[64];
extern int data;
extern int mask;

void PicoBlazesThread(void);
void SendFromPico(void);
void SendToPico(short int mes);
