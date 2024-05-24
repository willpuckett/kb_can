# Canbus: The Briefest of Introductions

This document provides a conversational and ambling introduction to canbus, as well as several case studies of possible canbus configurations and topologies. More technical information is available in the Klipper documentation, as well as cited throughout this text.

Klipper allows a host process to connect to a printer's mcu. Many printers have a single mcu to which all I/O (steppers, sensors, heaters) are connected.

As one adds more peripherals to a printer, the main mcu may begin to run out of available pins. Or, perhaps one wishes to add a concentration of I/O in an area a little further from the primary mcu (generally located in the *chassis*), and wishes to reduce wiring (cable) clutter back to a larger main board.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/clutter.jpeg"
         alt="A Cluttered Chassis">
    <figcaption>An example of a cluttered chassis. Note the difficulty of accessing lower layers of the board and RPi GPIO due to stacked daughter board.</figcaption>
</figure>

Klipper allows the use of multi-mcu in these cases. These additional mcus can be connected via usb or serial. But many smaller SBCs (**Single Board Computer**: the computers usually used to deploy Klipper, of which Raspberry Pi is probably the most popular example), especially the Zero form factor, only have two usb ports... One for power, and one for a usb device. Whereas a user with several tools which can change during a print may have four or five mcus to connect simultaneously.

## What is Canbus

Canbus is a networking technology. CAN stands for Controller Area Network. We'll use the word canbus throughout this document to refer to CAN—it works better for search results, and disambiguates from the common English word, can. Originating from the early 1980's, canbus grew popular in the automotive industry to connect all the various pieces of a car, and for factory floor automation. Canbus runs on two wires, Can High (can_h), and Can Low (can_l). These two wires carry a differential signal, that is, the same magnitude signal where one is positive and the other negative, i.e. abs(can_l) = abs(can_h). By twisting the wires of this differential pair, greater resilience to interference is created, because the difference between the signals is still the same.

At a high level, canbus helps make I/O *plastic*, by adding a little or a lot just where it's needed. This sort of fluidity can make understanding canbus topology a little more challenging at first because so many different configurations are possible. 

Not every mcu is canbus capable. Many STM32 and SAM mcus implement canbus in hardware. Canbus is implemented in software (in the PIO cores) on RP2040.

An mcu doesn't create the final can signal directly. It communicates with a device called a *CAN transceiver* which creates the differential signal from two pins on the mcu. Some boards have a transceiver built in, but for many older boards, you'll need to solder and wire one yourself. If you're building from the ground up, or shopping for new hardware to implement your canbus designs, it's probably preferable to exclude boards without a transceiver built in.

## Motive, or, Do I Need Can?

If your printer is working great, and you're happy with it, you don't need to add canbus. It won't make your printer better, or faster in and of itself. It's also worth noting that Klipper's canbus bridge mode will NOT be stable with only a single mcu, so switching your single mcu to canbus bridge would actually be a detriment. Canbus is a useful addition for people who need to add I/O to their printer, or who like to have more readily accessible ports for testing and experimenting with hardware. 

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/experimenting.jpeg"
         alt="Canbus enables easy experimentation such as testing this mass dampened piezo on an FLSun SR">
    <figcaption>Canbus enables easy experimentation such as testing this mass dampened piezo probe on an FLSun SR</figcaption>
</figure>

Canbus could simplify (or complicate, depending on how you think about it!) the addition of an accelerometer to a toolhead. Accelerometer data can be used with Klipper's input shaping technology, which reduces printer vibrations for better, often quieter, prints.

Canbus is especially convenient for parts of the printer that might be further away from the primary mcu such as toolheads and multi-material units.

## Wiring/Topology

As mentioned earlier, canbus is two wires: can_h and can_l. These two wires are a shared bus, and connect to each device on the canbus. Many users also route power along with the CAN wires. 

Canbus is *terminated* at both ends by a 120Ω resistor. Proper termination helps ensure stability of the canbus line by reducing ringing.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/plug_types.jpeg"
         alt="A U2C with different plug types labeled">
    <figcaption>A U2C with different plug types labeled</figcaption>
</figure>

There isn't a standard can plug type. Some early boards for printers used usb c pd wires to carry the can signal and power. Many end users have strong expectations about how a usb c plug should work, though, and, coupled with the physical instability of the plug some users experienced on a rapidly moving toolhead, the choice proved less than ideal. Other boards might use screw terminals, molex minifit, molex microfit, or break out the data wires to jst-xh. Some devices use an xt30(2+2) plug. You'll probably need to be prepared to crimp cables to set up your canbus capable board, and you may need to spend some time troubleshooting the connection (for instance, rotating the plug 180 degrees to get the signal working on some devices using a coopted usb c cable). 

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/xt30_2_plus_2.jpeg"
         alt="XT30 2+2 Plug">
    <figcaption>XT30 2+2
</figcaption>
</figure>

That said, wiring is where canbus shines. 

## The Canbus Bridge

Klipper's host process runs on an sbc, so for it to talk to can devices, it will need to be attached to the canbus... Somehow... Most sbcs don't have canbus onboard (RK3568, RK3588, and RK3582 based devices do, but they'll need a transceiver), so most users add can connectivity via either SPI or a USB adapter. SPI adapters tend to require a little more work to configure, and, as a result, USB adapters have probably become more popular. 

This has been especially true since Klipper introduced canbus bridge mode. This mode allows capable mcus to be configured to bridge can communications via USB. 

You might have seen devices such as the BTT U2C that operate solely as canbus bridges. These are very useful for working with older mcus that don't have can transceivers on board. They're probably a little easier to configure than soldering your own transceiver. Many STM devices can be configured to output the canbus signal on the USB port, and these devices allow connecting those directly, avoiding searching for available pins and soldering all together.

The U2C bridge does require power, and if you're hoping to power your sbc with it, you'll have to get it from either your mcu's usb port, or so other available power pins. You may need to set a jumper to connect the usb port to the 5v rail, or solder over a diode on the usb VIN line. Consult your mcu's schematic and board drawings as necessary.

## Toolhead Boards

Perhaps the most popular use of canbus in Klipper is the toolhead board. A tool tends to be an I/O dense region, usually incorporating at minimum fans, a heater, an ADC for temperature measurements, a bed probe, and a stepper driver for the extruder. All the I/O from the tool can be wired to the toolhead board, and only the 2 canbus and 2 power wires need be routed back to the primary mcu or U2C (depending on topology). Additionally, most if not all toolhead boards have their own 5v regulator, bringing a little extra breathing room to an often heavily loaded 5v rail on the main mcu, perhaps creating headroom for a few extra leds.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/ebb42_mini_sb.jpeg"
         alt="BTT EBB42 on Mini SB">
    <figcaption>BTT EBB42 on Mini SB</figcaption>
</figure>

Some printers have several tools configured and all available for use during a single print. Toolhead boards ensure the availability of ports and wiring simplicity for these tools.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/tap_changer.jpeg"
         alt="Mendel Max with TapChanger">
    <figcaption>Mendel Max with TapChanger used to switch between 1.75mm Sherpa and 2.85mm Orbiter</figcaption>
</figure>

A canbus cable can also be an easy breakpoint for switching tools manually. For example, a delta printer with magballs and canbus could have an extruder and a laser mounted on separate effector plates that can be switched out by unplugging the single can cable. Or, a MendelMax could be retrofitted with a [TapChanger](https://github.com/viesturz/tapchanger) and switch tools by simply lifting the tool off the shuttle, changing the cable, and toggling the configuration in Klipper. (It's worth noting that canbus cables carrying power are NOT hot-swappable. Power the machine down completely before changing.) Such configurations save both costs and space by allowing sharing and reuse of a kinematic system with different tools. 

## Topologies

Let's get our feet on the ground by examining a few possible canbus topologies. As we do, we'll try to think in terms of routing the golden duo—power and data—together on a single 4 wire cable, to keep runs clean.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/distribution_board.jpeg"
         alt="A CAN Distribution Board with SKR Pico in Bridge Mode">
    <figcaption>A CAN Distribution Board with SKR Pico in Bridge Mode</figcaption>
</figure>

### Scenario 1: The Canbus Distribution Board with SPI Adapter

You probably wouldn't choose to lay out your canbus system like this now, but it's worth covering first as early systems often worked this way.


The distribution board isn't doing any processing or switching of the can signal, it's just connecting the wires physically, and sometimes fusing the power rail to each connected device.


![Distribution Board Block Diagram](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/distribution_diagram.svg)

This topology would demonstrate a retrofit of a printer to have multiple tools and a rotary axis. The primary tool was NOT rewired from the primary mcu, the additional toolheads and rotary stepper were simply added on. It demonstrates that it is not necessary for the primary mcu to also be on canbus, as many older mcus (Arduino Mega, for instance) don't support it.

![An example of a (coopted) USB C canbus distribution board](https://biqu.equipment/cdn/shop/products/1_74578e99-1a9c-45e9-ae57-3d23cb5cf975_1220x1220_crop_center.jpg?v=1702633221)

### Scenario 2: U2C

Building on the idea of a distribution board, and consolidating the host CAN adapter into it, the U2C removed the need to install and configure the SPI bridge.

#### Retrofit Version

![U2C Block Diagram 1](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/u2c_diagram_1.svg)

This layout is topologically similar to the first layout. It would also be possible to connect some primary mcus to the U2C board by configuring them to output a CAN signal on the usb pins. In that case, the configuration would look as follows:

![U2C Block Diagram 2](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/u2c_diagram_2.svg)

#### Clearing the Chassis

Creating ample, unobstructed airflow in a chassis can be a challenge. Coupled with the increased difficulty that maintaining the variety of small, difficult to identify cables that run to a toolhead presents, it made sense for some people to stop using the ports for the primary toolhead on the primary pcb, and just connect them all via canbus.

![U2C Block Diagram 3](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/u2c_diagram_3.svg)

The diagram doesn't really communicate how much more open a chassis feels without the primary tool cabling. It becomes much easier to work in the chassis area without the additional clutter, and reduces the likelihood of accidentally dislodging something. It also means that the printer doesn't have to be fully disconnected and unscrewed and flipped over to make a change to wiring at the toolhead, dramatically simplifying maintenance.

The removal of the primary tool from the primary mcu also has the advantage of putting less heat through the primary board, reducing cooling requirements in some cases. 

While on the subject of thermals, it's worth noting that canbus might not work as well for printers with enclosures that run at very high temps. For instance, the data sheet for STM32F072 states an ambient operating range of -40ºC to 85ºC, but the actual range for an early ebb board and all its components is probably lower. 

### Scenario 3: Canbus Bridge Mode

As interest in canbus grew, parts started to become unavailable during the chip shortage. At this time, it became a lot more valuable to integrate the canbus bridge mode that many mcus support into Klipper. 


#### Low Cost, Readily Available Transceiver

By compiling the mcu code with bridge mode support, many users were able to eliminate the need for a U2C altogether. 

![Bridge Block Diagram 1](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/bridge_1.svg)

However, most primary boards did not have a transceiver on board, meaning that users needed to add one, usually SN65HVD230. Often the transceiver was packaged on a [longer, kind of floppy board](https://www.amazon.com/gp/product/B084M5ZQST)--not ideal for the potentially high vibration of a printer chassis. Sourcing a [more square version](https://www.amazon.com/gp/product/B07ZT7LLSK) with mounting holes proved useful. It could also be difficult to locate appropriate pins on some mcus that were near each other, as well as supply a proper voltage in order to not fry the mcu input pins.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/skr_pico_bridge.jpeg"
         alt="An SKR Pico in Canbus bridge mode">
    <figcaption>An SKR Pico in Canbus bridge mode</figcaption>
</figure>

#### Multitool

The small, loose wires going to the transceivers could also be prone to transients in the chassis. Manufacturers responded by beginning to produce primary mcus with onboard transceivers (Mellow Fly-D5, Mellow E3-V2, BTT SKR3/SKR3EZ for example). These boards served as natural bridges.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/fystec-sb-th.jpeg"
         alt="A fystec sb can th board">
    <figcaption>A fystec sb can th board</figcaption>
</figure>

For users who manually switched tools between prints, bridge mode resulted in an much streamlined layout.

![Bridge Block Diagram 2](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/bridge_2.svg)

In this way, a user could switch tools, and then simply comment out an include to toggle between tools in `printer.cfg`, i.e.:

```cfg
[include tools/extruder.cfg]
# [include tools/laser.cfg]
```

becomes 

```cfg
# [include tools/extruder.cfg]
[include tools/laser.cfg]
```

to change from extruder to laser.
<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/flsun_sr_bridge.jpeg"
         alt="An Flsun SR configured with canbus bridge mode. The delta arms only hold one tool at a time, but tools can be switched at the effector plate">
    <figcaption>An Flsun SR configured with canbus bridge mode. The delta arms only hold one tool at a time, but tools can be switched at the effector plate. Note the U2C is only being used as a transceiver.</figcaption>
</figure>

### A Few Addition Topological Notes

For our topological scenarios, we had only a single canbus connected to the host. However, a host may have multiple canbusses connected. The host may communicate with mcus on different busses all in the context of a single Klipper device.

A host may also run multiple Klipper processes, called instances. Each instance may communicate with mcus on any of the canbusses, however, it often makes sense topologically to have a the primary mcu on each printer configured in canbus bridge mode and have all of its canbus nodes connected to it. Such a topology means that a canbus can be powered down when its instance is idle--without affecting other instances.

A multi-instance canbus topology might look like this:

![A Multi-instance Block Diagram](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/multi_1.svg)

We tended to build our topologies around a star shape, but canbus can be daisy chained as well. It would work perfectly well to do something like

![Daisy Chain Block Diagram 1](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/daisy_chain_1.svg)

However, most boards don't break out ports for daisy chaining, and the cabling could end up being a little awkward. Usually mostly star works well for tools, but if the canbus needed to make a stop off on the way to tools for say a gantry mounted x axis motor and endstop, that would be just fine.

![Daisy Chain Block Diagram 2](https://raw.githubusercontent.com/willpuckett/kb_can/master/diagrams/daisy_chain_2.svg)

It would also be possible to have multiple hosts on the canbus, and configure multiple mcus in canbus bridge mode, however it is not recommendable as the bandwidth of the bus could quickly become saturated during a print.

<figure>
    <img src="https://raw.githubusercontent.com/willpuckett/kb_can/master/images/non-recommended.jpeg"
         alt="A non-recommended/experimental canbus setup. Flsun QQ-S Pro with each stepper on separate mcus">
    <figcaption>A non-recommended/experimental canbus setup. Flsun QQ-S Pro with each stepper on separate mcus</figcaption>
</figure>

## Flashing & Updating

In order to communicate with the host process, Klipper needs to build and install a firmware on each mcu. In order to use an mcu via canbus, this firmware needs to be built to communicate over CAN.

While it is possible to build and install the firmware over usb, it can be difficult to access mcus in remote parts of the printer such as the chassis. It would also be tedious to have to connect a usb cable to an mcu each time you wish to update it.

### Katapult (Formerly CanBoot)

Using canbus means you will have more mcus to install and update software on. If you have a couple of printers, flashing and updating becomes even more cumbersome. 

Luckily, other people have faced these issues as well, and come up with some brilliant solutions.

Katapult is a bootloader that allows the mcu to listen over the canbus interface, go into flashing mode, and accept and flash firmware via canbus.

Katapult needs to be installed via USB on first install, but afterwards the mcu will not need to be connected via USB again.

You can find information on installing Katapult on the [Katapult page](https://github.com/arksine/katapult). You can also often find information on installing to your specific board by googling "Katapult" and your board name.

[Klipper_canbus](https://maz0r.github.io/klipper_canbus/controller/canboot.html) is a fantastic resource for flashing toolboards.

For a more thorough top-to-bottom guide to the  process of installing Katapult and Klipper, [Esoterical Can Bus Guide](https://canbus.esoterical.online) is a great read.

### Automating Updates

With multiple mcus, it becomes especially cumbersome to manually configure menuconfig for each mcu on every update.

You probably used kiauh to set up Klipper, and it does have menus for building an flashing, but those don't include the capability to flash via canbus.

[update_klipper_and_mcus](https://github.com/fbeauKmi/update_klipper_and_mcus) runs updates on mcus configured in its `mcus.ini` file. It only updates Klipper.

[katchup](https://github.com/willpuckett/katchup) is a little script that can update Klipper and Katapult on configured mcus. 

Klipper is moving toward including automated updates over the course of this year, so expect changes over the coming months.

## Naming Canbus interfaces on a Multi-Instance Host with udev

Mosts hosts will automatically name the first canbus bridge "can0," and additional bridges as "can1," "can2," etc, using a system called *udev*. For a general introduction to the *udev system*, you might want to scan [Writing udev Rules](https://www.reactivated.net/writing_udev_rules.html). However, without additional configuration, these names can change depending on the order in which the usb-can bridges are connected, making them inconsistent and therefore unreliable for addressing by different instances, especially if devices are powered on and off automatically. In multi-instance installs, where each instance has its own canbus (aka bridge mode mcu), consistent names become necessary to ensure each instance is connected to the appropriate printer.

These instructions were written on Debian running on *x86_64*, but should be applicable to Armbian systems as well. For rpiOS, you may need to use an `ifconfig` command in step 6's `up` directive in lieu of the `ip` command 🤷🏻‍♂️.

### Consistently Naming Canbus Interfaces with udev Rules

1. Plug your canbus device (probably an mcu in canbus bridge mode or a u2c) into an available usb port. It's easiest to start with a single usb-can device plugged in. The system will most likely autoname this device "can0"—you can check by running `ip link show`.

2. Run `udevadm info -a -p $(udevadm info -q path -p /sys/class/net/can0)| grep serial| head -n 1` 

3. The above command should print something like `ATTRS{serial}=="490033000F50475532323820"`. We'll refer to this value as YOUR_SERIAL in subsequent steps.

4. Open `/etc/udev/rules.d/z21_persistent-local.rules` in your editor of choice

5. Subtitiuting the serial number you found in step 3, add the following line. (Since your system likely automatically assigns names such as "can0," "can1," "can2" etc to canbus devices, use a string such as "canalpha," "canbeta," or "cangamma" for YOUR_CHOSEN_CANBUS_NAME):

```
SUBSYSTEM=="net", ACTION=="add", ATTRS{serial}=="YOUR_SERIAL", NAME="YOUR_CHOSEN_CANBUS_NAME"
```

6. Open `/etc/network/interfaces.d/YOUR_CHOSEN_CANBUS_NAME` in your editor of choice, and insert the following text, substituting the canbus name you created in step 5:

```
allow-hotplug YOUR_CHOSEN_CANBUS_NAME
iface YOUR_CHOSEN_CANBUS_NAME can static
    bitrate 1000000
    up ip link set $IFACE txqueuelen 128
```

7. Run `sudo udevadm control --reload-rules && sudo udevadm trigger --attr-match=subsystem=net` and then unplug and replug your can device

8. Run `ip -details link show YOUR_CHOSEN_CANBUS_NAME` and you should see your device listed under the appropriate interface name, with the correctly configured queue length (qlen) and bitrate.

9. You may repeat the steps 1-8 to add additional busses. It seems to work fine to have multiple lines in the udev rules file created in step 4, or if you prefer, you may split the udev rules into multiple files (all in `/etc/udev/rules.d/`). A reboot isn't strictly necessary, but if you like to by all means do!

### Klipper/ Katapult Config

Once the interface is properly configured as above, you can simply add a  `canbus_interface: YOUR_CHOSEN_CANBUS_NAME` line to your `[mcu]` object in your `printer.cfg` that lists the named interface you just created.

If you use katapult, you'll also need to use the `-i YOUR_CHOSEN_CANBUS_NAME` option when your run `flash_can.py` to set the appropriate interface.

