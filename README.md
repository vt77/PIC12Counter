## Introduction

This project is a very simple counter with i2c interface designed for low power consumation. Most time counter sleeps and counting ticks in async timer mode. 

## Disclaimer
This is just my try hand at Microchip PIC assembler.
The pic12 in crystal less mode probably worst choice for this project.We have only 10 instructions per I2C tick on even slow 100kHz bus speed. It was real challenge to make this thing work. After all it works quet good on 50kHz.
 
Sure this project not intended to run in production environment. But I used it in my weather station and it runs well capable low consumption and good stability

## Compile 
I used gptools to compile this project in mpasm compability mode. So most probable mpasm will work as well.

## Hardware 

CNT - 16bit Timer 1 counter pin

SDA - External interrupt pin (wakeups microcontroller for communication)

SCL - Any GPIO pin

```
       PIC12F629/75 
        -------          
      -|VCC GND|-         
  CNT -|GP5 GP0|-        
      -|GP4 GP1|- SCL    
      -|GP3 GP2|- SDA     
        -------    
```
## License
MIT. See LICENSE file 
