#ifndef _DSC_DRIVER_H_
#define _DSC_DRIVER_H_

#include <stdint.h>

struct Nm1_t
{
    uint8_t bytes;
    uint8_t pre;
    uint8_t sfd;
};

struct Pll_t
{
    uint16_t kp;
    uint16_t ki;
};

struct Configuration_t
{
    struct Nm1_t nm1;
    struct Pll_t pll;
    uint16_t detTh;
    uint16_t sigma;
};

struct Restart_t
{
    uint8_t retries;
};

struct WriteData_t
{
    uint16_t value;
};

struct ReadData_t
{
    uint16_t value;
};

#define SET_CONFIGURATION _IOW('a', 'a', struct Configuration_t)
#define RESTART_CORE _IOW('a', 'b', struct Restart_t)
#define WRITE_DATA _IOW('a', 'c', struct WriteData_t)
#define READ_DATA _IOR('a', 'd', struct ReadData_t)

#endif /* _DSC_DRIVER_H_ */
