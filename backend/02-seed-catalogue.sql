-- NN ElectroLab Store — initial four-project catalogue seed.
-- Run AFTER 01-schema.sql. Safe to re-run: upserts by product slug and variant SKU.
-- Price values are in paise (₹1 = 100 paise).

insert into public.products
(slug,title,short_description,description,category,categories,difficulty,tags,specs,bom,icon,is_published,sort_order)
values
(
 'solar-iot-telemetry-node',
 'Solar IoT Telemetry & Sensor Node',
 'Ultra-low-power ESP32-S3 + LoRa 433MHz environmental and water-level telemetry node with MPPT solar charging for remote deployments.',
 'Designed for off-grid farms, weather stations and flood monitoring where Wi-Fi is unavailable. Includes low-power telemetry, waterproof ultrasonic sensing and solar charging.',
 'IoT & Telemetry', array['IoT & Telemetry','Open Source'], 'Intermediate',
 array['ESP32-S3','SX1278 LoRa','MPPT Solar','IP65'],
 '[["MCU","ESP32-S3-WROOM-1 (Wi-Fi / BLE)"],["Radio Link","SX1278 LoRa 433 MHz (+20 dBm)"],["Deep Sleep Draw","26 µA @ 3.3V"],["Solar Charger","CN3791 1S MPPT"],["Sensor Interfaces","I2C, UART/Ultrasonic, ADC"]]'::jsonb,
 '[["ESP32-S3-WROOM-1","8MB Flash Module",1,340],["Ra-02 SX1278 LoRa","433 MHz SPI + IPEX",1,380],["JSN-SR04T Probe","Waterproof Ultrasonic",1,420],["BME280 Breakout","Temp/Humidity/Pressure",1,220],["CN3791 MPPT Board","1S Solar Charge IC",1,190],["Custom 2-Layer PCB","68x54mm ENIG",1,250]]'::jsonb,
 '☀', true, 10
),
(
 'edge-ai-smart-camera',
 'Edge AI Smart Camera Module',
 'Offline computer-vision camera HAT for Raspberry Pi with 850nm IR night-vision ring, PWM fan driver and Python ONNX/YOLO pipeline.',
 'Run real-time object detection, security alerts or industrial part counting offline. The carrier HAT adds IR illumination, thermal cooling and protected power delivery.',
 'Edge AI & Cameras', array['Edge AI & Cameras','IoT & Telemetry'], 'Intermediate',
 array['Raspberry Pi','ONNX / YOLO','850nm IR','Python'],
 '[["Compatible SBC","Raspberry Pi Zero 2 W / Pi 4 / Pi 5"],["Inference Engine","Python + OpenCV + ONNX Runtime"],["Night Illumination","6x 850nm IR LEDs"],["Cooling","30mm 5V PWM Fan"],["Alert Outputs","MQTT JSON, Telegram Bot, Relay GPIO"]]'::jsonb,
 '[["Vision Carrier HAT PCB","65x30mm 40-pin GPIO",1,220],["AO3400A MOSFET","30V 5.7A SOT-23",2,30],["850nm IR LEDs","5mm 60°",6,90],["30x30mm 5V Fan","Brushless low-noise",1,160],["SMBJ5.0A TVS","5V surge clamp",1,25],["PETG Enclosure","Tripod mount",1,350]]'::jsonb,
 '◉', true, 20
),
(
 'multi-voltage-lifepo4-bms',
 'Multi-Voltage LiFePO4 Power Bank & BMS',
 '4S 12.8V 30A LiFePO4 smart power station PCB with 2oz copper, INA219 telemetry, USB-C PD 65W and regulated outputs.',
 'For field robotics, portable soldering stations and solar backup rigs. Includes pack protection, current sensing and regulated rails for embedded systems.',
 'Power & BMS', array['Power & BMS','Open Source'], 'Advanced',
 array['4S LiFePO4','2oz Copper','30A BMS','INA219 I2C'],
 '[["Pack Config","4S LiFePO4 (12.8V nominal / 14.6V charge)"],["Continuous Load","30A main XT60"],["Regulated Rails","USB-C PD 65W + 5V/3A + 3.3V/1A"],["Telemetry","INA219 I2C"],["Safety Suite","OVP, UVP, OCP, short-circuit & NTC"]]'::jsonb,
 '[["4S BMS Front-End IC","LiFePO4 3.65V/cell OVP",1,260],["HYG025N04 MOSFET","40V low RDS(on)",6,360],["INA219AIDCNR","I2C current/power sensor",1,180],["2 mΩ Shunt","2512 3W 1%",1,65],["TPS54302 Buck IC","28V 3A step-down",1,110],["XT60PW Connectors","Right-angle PCB mount",3,150]]'::jsonb,
 '▣', true, 30
),
(
 'autonomous-rover-rov-controller',
 'Autonomous Rover / ROV Controller',
 'STM32F411 dual 15A H-bridge and 6-channel ESC thruster controller with IMU, encoders, CAN bus and ROS 2 bridge.',
 'Motion-control platform for 4WD ground rovers and underwater ROVs. Provides closed-loop control and interfaces for Raspberry Pi, Jetson, MAVLink and ROS 2 stacks.',
 'Robotics & Drones', array['Robotics & Drones','Power & BMS'], 'Advanced',
 array['STM32F411','Dual 15A','CAN / ROS 2','IMU + Encoders'],
 '[["Main MCU","STM32F411CEU6 (100 MHz Cortex-M4)"],["Drive Outputs","2x 15A brushed H-bridge + 6x PWM ESC"],["Supply Range","7V–28V DC"],["Onboard Sensors","MPU-6500 IMU + quadrature encoders"],["Comms Bus","USB-C CDC, UART, CAN bus"]]'::jsonb,
 '[["STM32F411CEU6","UFQFPN-48 MCU",1,320],["DRV8701E Driver","Full-bridge gate driver",2,340],["CSD18532 MOSFET","60V power N-MOSFET",8,480],["MPU-6500 IMU","SPI 6-axis gyro/accel",1,140],["TJA1050 CAN IC","High-speed CAN transceiver",1,60],["20A Terminal Blocks","5.08mm pitch screw",3,90]]'::jsonb,
 '⌁', true, 40
)
on conflict (slug) do update set
 title=excluded.title,
 short_description=excluded.short_description,
 description=excluded.description,
 category=excluded.category,
 categories=excluded.categories,
 difficulty=excluded.difficulty,
 tags=excluded.tags,
 specs=excluded.specs,
 bom=excluded.bom,
 icon=excluded.icon,
 is_published=excluded.is_published,
 sort_order=excluded.sort_order,
 updated_at=now();

insert into public.product_variants (product_id,sku,name,description,price_paise,stock_qty,is_active)
select p.id, v.sku, v.name, v.description, v.price_paise, 0, true
from public.products p
join (values
 ('solar-iot-telemetry-node','NNE-SOLAR-DIGITAL','Digital Files: Gerbers + Code + BOM','KiCad 8, Gerber ZIP, firmware & 3D STL enclosure',39900::bigint),
 ('solar-iot-telemetry-node','NNE-SOLAR-DIY','DIY Hardware Kit','Fabricated PCB + components + digital pack',189900::bigint),
 ('solar-iot-telemetry-node','NNE-SOLAR-ASSEMBLED','Assembled & Tested Unit','Soldered, RF-tested and pre-flashed',279900::bigint),
 ('edge-ai-smart-camera','NNE-CAMERA-DIGITAL','Digital Files: Gerbers + Code + BOM','Carrier HAT Gerbers, Python ONNX repo & 3D case',49900::bigint),
 ('edge-ai-smart-camera','NNE-CAMERA-DIY','DIY Hardware Kit','Carrier HAT PCB + IR LEDs + fan + case (No Pi)',129900::bigint),
 ('edge-ai-smart-camera','NNE-CAMERA-ASSEMBLED','Assembled & Tested Unit','Assembled HAT + enclosure',179900::bigint),
 ('multi-voltage-lifepo4-bms','NNE-BMS-DIGITAL','Digital Files: Gerbers + Code + BOM','4-layer Gerbers, KiCad & firmware',59900::bigint),
 ('multi-voltage-lifepo4-bms','NNE-BMS-DIY','DIY Hardware Kit','Bare PCB + MOSFETs + shunt + connectors',169900::bigint),
 ('multi-voltage-lifepo4-bms','NNE-BMS-ASSEMBLED','Assembled & Tested Unit','Load-tested BMS board + telemetry firmware',269900::bigint),
 ('autonomous-rover-rov-controller','NNE-ROV-DIGITAL','Digital Files: Gerbers + Code + BOM','4-layer Gerbers, STM32 firmware & ROS 2 node',49900::bigint),
 ('autonomous-rover-rov-controller','NNE-ROV-DIY','DIY Hardware Kit','SMD pre-soldered PCB + terminals & heatsink',219900::bigint),
 ('autonomous-rover-rov-controller','NNE-ROV-ASSEMBLED','Assembled & Tested Unit','Load-tested controller, pre-flashed',319900::bigint)
) as v(slug,sku,name,description,price_paise) on p.slug=v.slug
on conflict (sku) do update set
 product_id=excluded.product_id,
 name=excluded.name,
 description=excluded.description,
 price_paise=excluded.price_paise,
 is_active=true,
 updated_at=now();
