#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/ioctl.h>
#include <linux/kdev_t.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>

#include "dsc-driver.h"

#define DSC_CORE_S00_AXI_SLV_BASE_ADDR 0x43C00000

#define DSC_CORE_S00_AXI_SLV_REG0_OFFSET 0
#define DSC_CORE_S00_AXI_SLV_REG1_OFFSET 4
#define DSC_CORE_S00_AXI_SLV_REG2_OFFSET 8
#define DSC_CORE_S00_AXI_SLV_REG3_OFFSET 12
#define DSC_CORE_S00_AXI_SLV_REG4_OFFSET 16
#define DSC_CORE_S00_AXI_SLV_REG5_OFFSET 20
#define DSC_CORE_S00_AXI_SLV_REG6_OFFSET 24

#define DSC_CORE_S00_AXI_SLV_REG_SIZE 1U

dev_t dev = 0;
static struct class *dev_class;
static struct cdev dsc_cdev;

static void __iomem *r0;
static void __iomem *r1;
static void __iomem *r2;
static void __iomem *r3;
static void __iomem *r4;
static void __iomem *r5;
static void __iomem *r6;

static int __init dsc_driver_init(void);
static void __exit dsc_driver_exit(void);

static int dsc_open(struct inode *inode, struct file *file);
static int dsc_release(struct inode *inode, struct file *file);

static ssize_t dsc_read(struct file *filp, char __user *buf, size_t len, loff_t *off);
static ssize_t dsc_write(struct file *filp, const char *buf, size_t len, loff_t *off);

static long int dsc_ioctl(struct file *file, unsigned cmd, unsigned long arg);

static u32 dsc_read_data_from_core(void);
static void dsc_write_data_to_core(u32 value);
static void dsc_configure_core(struct Configuration_t *configuration);
static void dsc_restart_core(struct Restart_t *restart);

static struct file_operations fops = {
	.owner = THIS_MODULE,
	.read = dsc_read,
	.write = dsc_write,
	.open = dsc_open,
	.release = dsc_release,
	.unlocked_ioctl = dsc_ioctl,
};

static int dsc_open(struct inode *inode, struct file *file)
{
	return 0;
}

static int dsc_release(struct inode *inode, struct file *file)
{
	return 0;
}

static ssize_t dsc_read(struct file *filp, char __user *buf, size_t len, loff_t *off)
{
	char str[8];
	size_t str_len = 0;
	if (0 == *off)
	{
		u32 data = dsc_read_data_from_core();
		sprintf(str, "%d\n", data);
		str_len = strlen(str);
		if (copy_to_user(buf, str, str_len))
		{
			return -EFAULT;
		}
		*off += str_len;
		return str_len;
	}
	return 0;
}

static ssize_t dsc_write(struct file *filp, const char __user *buf, size_t len, loff_t *off)
{
	u32 value = 0;
	char str[32];
	if (copy_from_user(str, buf, len))
	{
		return -EFAULT;
	}
	sscanf(str, "%d", &value);
	dsc_write_data_to_core(value);
	return len;
}

static int __init dsc_driver_init(void)
{
	if ((alloc_chrdev_region(&dev, 0, 1, "dsc")) < 0)
	{
		pr_err("Cannot allocate major number\n");
		return -1;
	}
	pr_info("Major = %d Minor = %d \n", MAJOR(dev), MINOR(dev));

	cdev_init(&dsc_cdev, &fops);

	if ((cdev_add(&dsc_cdev, dev, 1)) < 0)
	{
		pr_err("Cannot add the device to the system\n");
		goto r_class;
	}

	if (IS_ERR(dev_class = class_create(THIS_MODULE, "dsc_class")))
	{
		pr_err("Cannot create the struct class\n");
		goto r_class;
	}

	if (IS_ERR(device_create(dev_class, NULL, dev, NULL, "dsc_device")))
	{
		pr_err("Cannot create the Device 1\n");
		goto r_device;
	}
	pr_info("starting dsc IPCORE.\n");
	r0 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG0_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r1 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG1_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r2 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG2_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r3 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG3_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r4 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG4_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r5 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG5_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	r6 = ioremap(DSC_CORE_S00_AXI_SLV_BASE_ADDR + DSC_CORE_S00_AXI_SLV_REG6_OFFSET, DSC_CORE_S00_AXI_SLV_REG_SIZE);
	iowrite32(0b00000000000000110000011100000011, r2);
	iowrite32(0x00000040, r3);
	iowrite32(0x9000a000, r4);
	iowrite32(0x00000000, r5);
	wmb();
	iowrite32(0b00000000000000000000000000000001, r0);
	return 0;

r_device:
	class_destroy(dev_class);
r_class:
	unregister_chrdev_region(dev, 1);
	return -1;
}

static void __exit dsc_driver_exit(void)
{
	device_destroy(dev_class, dev);
	class_destroy(dev_class);
	cdev_del(&dsc_cdev);
	unregister_chrdev_region(dev, 1);
	pr_info("stoping dsc IPCORE\n");
	iounmap(r0);
	iounmap(r1);
	iounmap(r2);
	iounmap(r3);
	iounmap(r4);
	iounmap(r5);
	iounmap(r6);
}

/* IOCTL *********************************************************************/

static struct Configuration_t config;
static struct Restart_t restart;
static struct WriteData_t wdata;
static struct ReadData_t rdata;

static long int dsc_ioctl(struct file *file, unsigned cmd, unsigned long arg)
{
	switch (cmd)
	{
	case SET_CONFIGURATION:
		if (copy_from_user(&config, (struct Configuration_t *)arg, sizeof(struct Configuration_t)))
		{
			return -EFAULT;
		}
		dsc_configure_core(&config);
		break;

	case RESTART_CORE:
		if (copy_from_user(&restart, (struct Restart_t *)arg, sizeof(struct Restart_t)))
		{
			return -EFAULT;
		}
		dsc_restart_core(&restart);
		break;

	case WRITE_DATA:
		if (copy_from_user(&wdata, (struct WriteData_t *)arg, sizeof(struct WriteData_t)))
		{
			return -EFAULT;
		}
		dsc_write_data_to_core((u32)wdata.value);
		break;

	case READ_DATA:
		rdata.value = (u16)dsc_read_data_from_core();
		if (copy_to_user((struct ReadData_t *)arg, &rdata, sizeof(struct ReadData_t)))
		{
			return -EFAULT;
		}
		break;
		break;

	default:
		break;
	}
	return 0;
}
/*****************************************************************************/

/* REGISTERS LOGIC ***********************************************************/
static u32 control = 0x00000001; /* srst = 0, en = 1 */

static u32 dsc_read_data_from_core(void)
{
	u32 data = ioread32(r6);

	/* ACK pulse */
	control = control & ~(1U << 3);
	iowrite32(control, r0);
	wmb();
	control = control | (1U << 3);
	iowrite32(control, r0);
	wmb();
	control = control & ~(1U << 3);
	iowrite32(control, r0);
	wmb();
	return data;
}

static void dsc_write_data_to_core(u32 value)
{
	u32 data = value & 0x000000ff;

	/* Latch pulse and data write */
	data = data & ~(1U << 8);
	iowrite32(data, r1);
	wmb();
	data = data | (1U << 8);
	iowrite32(data, r1);
	wmb();
	data = data & ~(1U << 8);
	iowrite32(data, r1);
	wmb();
}

static void dsc_configure_core(struct Configuration_t *configuration)
{
	/* clang-format off */
	u32 nm1_reg = (configuration->nm1.bytes << 0)
				+ (configuration->nm1.pre   << 8)
				+ (configuration->nm1.sfd   << 16);

	u32 pll_reg = (configuration->pll.kp << 0)
				+ (configuration->pll.ki << 16);

	u32 detTh_reg = configuration->detTh & 0x0000ffff;

	u32 sigma_reg = configuration->sigma & 0x0000ffff;
	/* clang-format on */
	iowrite32(nm1_reg, r2);
	iowrite32(pll_reg, r4);
	iowrite32(detTh_reg, r3);
	iowrite32(sigma_reg, r5);

	control = 0x00000001;
	iowrite32(control, r0);
	wmb();
	control = 0x00000003;
	iowrite32(control, r0);
	wmb();
	control = 0x00000001;
	iowrite32(control, r0);
	wmb();
}

static void dsc_restart_core(struct Restart_t *restart)
{
	control = 0x00000001;
	iowrite32(control, r0);
	control = 0x00000003;
	iowrite32(control, r0);
	control = 0x00000001;
	iowrite32(control, r0);
}
/*****************************************************************************/

/* MODULE MACROS *************************************************************/
module_init(dsc_driver_init);
module_exit(dsc_driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jonathan Cagua - Gonzalo Vaca");
MODULE_DESCRIPTION("dscmodule - module to communicate with dsc IPCORE.");
MODULE_VERSION("1:0.0");
/*****************************************************************************/
