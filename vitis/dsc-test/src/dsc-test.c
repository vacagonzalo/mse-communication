/* FreeRTOS includes. */
#include "FreeRTOS.h"
#include "task.h"

/* Xilinx includes. */
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"

/* BSP includes */
#include "DSC_core.h"

#define BIT_POS(p) (1U << p)
#define BIT_EN_I BIT_POS(0)
#define BIT_SRST_I BIT_POS(1)
#define BIT_READ_LATCH_I BIT_POS(2)
#define BIT_READ_ACK_I BIT_POS(3)
#define BIT_WRITE_LATCH_I BIT_POS(8)

#define SET_HIGH(reg, pos) reg = (reg | pos)
#define SET_LOW(reg, pos) reg = (reg & ~pos)

#define BASE_ADDRESS 0x43c00000

#define REGISTERS 7
#define REGISTER_CONFIG 0
#define REGISTER_READ_CONTROL 0
#define REGISTER_DATA_IN 1
#define REGISTER_NM1 2
#define REGISTER_DET 3
#define REGISTER_PLL 4
#define REGISTER_SIGMA 5
#define REGISTER_DATA_OUT 6

void DscWriteFreeRtosTask(void *notUsed);
void DscReadFreeRtosTask(void *notUsed);

int main( void )
{
	xil_printf("DST TEST\n\r");

	xil_printf("Configure IP Core\n\r");

	uint32_t reg[REGISTERS];
	uint32_t r;
	for(r = 0; r < REGISTERS; ++r)
	{
		reg[r] = 0;
	}

	reg[REGISTER_NM1] = 0b00000000000000110000011100000011;
	DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG2_OFFSET, reg[REGISTER_NM1]);

	reg[REGISTER_DET] = 0x00000040;
	DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG3_OFFSET, reg[REGISTER_DET]);

	reg[REGISTER_PLL] = 0x9000a000;
	DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG4_OFFSET, reg[REGISTER_PLL]);

	reg[REGISTER_SIGMA] = 0x00000000;
	DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG5_OFFSET, reg[REGISTER_SIGMA]);

	SET_HIGH(reg[REGISTER_CONFIG], BIT_EN_I);
	SET_LOW(reg[REGISTER_CONFIG], BIT_SRST_I);
	DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_CONFIG]);


	BaseType_t res;
	res = xTaskCreate(DscWriteFreeRtosTask, (const char *)"DSC_WRITE", 1024 * 4, NULL,  2, NULL);
	configASSERT( res );
	res = xTaskCreate(DscReadFreeRtosTask, (const char *)"DSC_READ", 1024 * 4, NULL,  2, NULL);
	configASSERT( res );
	xil_printf("Starting scheduler\n\r");
	vTaskStartScheduler();
	for( ;; );
}

void DscWriteFreeRtosTask(void *notUsed)
{
	uint32_t reg[REGISTERS];
	uint32_t r;
	for(r = 0; r < REGISTERS; ++r)
	{
		reg[r] = 0;
	}

	for(uint32_t d = 0; ; ++d)
	{
		reg[REGISTER_DATA_IN] = d & 0x000000ff;

		SET_LOW(reg[REGISTER_DATA_IN], BIT_WRITE_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG1_OFFSET, reg[REGISTER_DATA_IN]);
		vTaskDelay(1);

		SET_HIGH(reg[REGISTER_DATA_IN], BIT_WRITE_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG1_OFFSET, reg[REGISTER_DATA_IN]);
		vTaskDelay(1);

		SET_LOW(reg[REGISTER_DATA_IN], BIT_WRITE_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG1_OFFSET, reg[REGISTER_DATA_IN]);
		vTaskDelay(1);
		xil_printf("counter: %d\n\r", d);
	}
}

void DscReadFreeRtosTask(void *notUsed)
{
	uint32_t reg[REGISTERS];
	uint32_t r;
	for(r = 0; r < REGISTERS; ++r)
	{
		reg[r] = 0;
	}

	for(uint32_t d = 0; ; ++d)
	{
		SET_LOW(reg[REGISTER_READ_CONTROL], BIT_READ_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		SET_HIGH(reg[REGISTER_READ_CONTROL], BIT_READ_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		SET_LOW(reg[REGISTER_READ_CONTROL], BIT_READ_LATCH_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		reg[REGISTER_DATA_OUT] = DSC_CORE_mReadReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG6_OFFSET);
		vTaskDelay(1);

		SET_LOW(reg[REGISTER_READ_CONTROL], BIT_READ_ACK_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		SET_HIGH(reg[REGISTER_READ_CONTROL], BIT_READ_ACK_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		SET_LOW(reg[REGISTER_READ_CONTROL], BIT_READ_ACK_I);
		DSC_CORE_mWriteReg(BASE_ADDRESS, DSC_CORE_S00_AXI_SLV_REG0_OFFSET, reg[REGISTER_READ_CONTROL]);
		vTaskDelay(1);

		xil_printf("Data: %d\n\r", reg[REGISTER_DATA_OUT]);

	}
}

