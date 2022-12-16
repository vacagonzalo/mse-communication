#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include "dsc-driver.h"

int fd = NULL;
const char *dev_name = "/dev/dsc_device";

struct WriteData_t wdata = {.value = 0};
struct ReadData_t rdata = {.value = 0};

int main(int argc, char **argv)
{
    printf("Testing dsc-driver!\n");
    system("modprobe dsc-driver");

    /* Time for the module to create the device */
    sleep(1);

    fd = open(dev_name, O_RDONLY);
    if (-1 == fd)
    {
        printf("could not open %s\n", dev_name);
        return fd;
    }

    while (rdata.value < 0xfe)
    {
        ioctl(fd, WRITE_DATA, &wdata);
        ioctl(fd, READ_DATA, &rdata);
        ++wdata.value;
        printf("%d", rdata.value);
    }

    close(fd);
    return 0;
}
