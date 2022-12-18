# Simulación de un sistema de comunicaciones

Autores:

* Jonathan Cagua
* Gonzalo Vaca

Este proyecto es el trabajo final de la asignatura **Sistemas digitales para las comunicaciones** de la **Maestría en Sistemas Embebidos** de la Universidad de Buenos Aires.

Se implementa una cadena de procesamiento que consta de las siguientes etapas:

* Adaptador de entrada: interfaz entre las señales AXI y el registro FIFO de entrada:
* Registro FIFO de entrada: acumula datos y se sincroniza con la siguiente etapa.
* Lógica de disparo: analiza la cantidad de datos en la cadena de procesamiento y envía señales al modulador.
* Modulador: transforma la señal para ser enviada a través del canal.
* Canal: simula los efectos de un medio físico durante la transmisión de la información.
* Demodulador: reconstruye el mensaje original a partir de la señal que llega desde el canal.
* Registro FIFO de salida: acumula los datos procesados y se sincroniza con las etapas aledañas.
* Adaptador de salida: interfaz entre el registro FIFO de salida y las señales AXI.

## Código RTL

En la carpeta `src` se encuentran los archivos provistos por la cátedra y aquellos que fueron realizados durante la confección de este trabajo. Además, se encuentran los archivos necesario para generar un esclavo AXI.

El sistema se verificó con los *testbenchs* de la carpeta `verification`.

## Esclavo AXI

Los siguientes archivos son necesarios para generar un esclavo AXI en la plataforma de Vivado 2022.2:

* `DSC_core_v1_0_S00_AXI.vhd`
* `DSC_core_v1_0.vhd`

## Diagrama en bloques

Con el esclavo AXI creado y su repositorio como parte del entorno de desarrollo de Vivado. Se procedió a generar un diagrama en bloques que conecta el bloque *PS* con nuestro IP Core.
Luego, se exportó un archivo de descripción de hardware *XSA* que se encuentra en la carpeta `hw`.

## Proyecto baremetal

Se realizaron unas pruebas preliminares en baremetal antes de crear un proyecto en petalinux.
El proyecto se encuentra en la carpeta `vitis`.

## Proyecto petalinux

Se realizó un proyecto en petalinux a partir de la descripción de hardware exportada desde Vivado.
En este proyecto se creó un driver y una aplicación que lo utiliza.

## Driver

El driver implementa una tabla de memoria virtual del kernel que apunta a las direcciones físicas del dispositivo.
Además, se generó una clase y char device para finalmente implementar una interfaz ioctl.

## Licencia

[MIT License](LICENSE)
