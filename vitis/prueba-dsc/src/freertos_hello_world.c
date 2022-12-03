/* FreeRTOS includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "timers.h"
/* Xilinx includes. */
#include "xil_printf.h"
#include "xparameters.h"

#define SLAVE_BASE_ADDR 0x43c00000
#define SLAVE_REGISTER(r) (SLAVE_BASE_ADDR + (r * 32))

#define SLAVE_REGISTER_ENABLE  (SLAVE_REGISTER(0))
#define SLAVE_REGISTER_RESET   (SLAVE_REGISTER(0))
#define SLAVE_REGISTER_ISDATAI (SLAVE_REGISTER(1))
#define SLAVE_REGISTER_ISDVI   (SLAVE_REGISTER(1))
#define SLAVE_REGISTER_OSDATAO (SLAVE_REGISTER(2))
#define SLAVE_REGISTER_OSDVO   (SLAVE_REGISTER(2))
#define SLAVE_REGISTER_NM1BYTESI (SLAVE_REGISTER(3))
#define SLAVE_REGISTER_NM1PREI (SLAVE_REGISTER(3))
#define SLAVE_REGISTER_NM1SFDI (SLAVE_REGISTER(3))
#define SLAVE_REGISTER_DETTHI  (SLAVE_REGISTER(4))
#define SLAVE_REGISTER_PLLKPI  (SLAVE_REGISTER(5))
#define SLAVE_REGISTER_PLLKII  (SLAVE_REGISTER(5))
#define SLAVE_REGISTER_SIGMAI  (SLAVE_REGISTER(6))
#define SLAVE_REGISTER_OSRFDI  (SLAVE_REGISTER(7))
#define SLAVE_REGISTER_SENDI   (SLAVE_REGISTER(7))
#define SLAVE_REGISTER_ISRFDO  (SLAVE_REGISTER(8))
#define SLAVE_REGISTER_TXRDYO  (SLAVE_REGISTER(8))
#define SLAVE_REGISTER_RXOVFO  (SLAVE_REGISTER(8))

void test_ipcore_task(void *not_used);

int main( void )
{
	BaseType_t res;
	res = xTaskCreate( test_ipcore_task,
				 ( const char * ) "test",
				 configMINIMAL_STACK_SIZE,
				 NULL,
				 tskIDLE_PRIORITY + 1,
				 NULL);

	configASSERT( pdPASS == res );

	vTaskStartScheduler();

	for( ;; );
}

void test_ipcore_task(void *not_used)
{
	u32 reg0 = 0;
	u32 reg1 = 0;
	u32 reg2 = 0;
	u32 reg3 = 0;
	u32 reg4 = 0;
	u32 reg5 = 0;
	u32 reg6 = 0;
	u32 reg7 = 0;
	u32 reg8 = 0;

	//Xil_Out32(Addr, Value)
	//Xil_In32(Addr)

	// enable 0 y reset 1
	reg0 = reg0 | (1u<<0);
	Xil_Out32(SLAVE_REGISTER_RESET, reg0);

	// Ki Kp........
	reg3 = 0x010f03;
	Xil_Out32(SLAVE_REGISTER_NM1BYTESI, reg3);

	reg4 = 0x0040;
	Xil_Out32(SLAVE_REGISTER_DETTHI, reg4);

	reg5 = 0x9000A000;
	Xil_Out32(SLAVE_REGISTER_PLLKPI, reg5);

	reg6 = 0x00000000;
	Xil_Out32(SLAVE_REGISTER_SIGMAI, reg6);

	// reset 0 enable 1
	reg0 = 0x2;
	Xil_Out32(SLAVE_REGISTER_RESET, reg0);

	/* Sistema configurado y listo para recibir datos. */


	// Volcar datos a la fifo de entrada (ojo con el send_i)

	// Leemos la fifo de salida


}
