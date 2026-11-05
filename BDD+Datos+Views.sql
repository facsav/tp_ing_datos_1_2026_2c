-- ==========================================================================
-- SECCION 01_esquema
-- ==========================================================================
USE master;
GO

IF DB_ID('tpDatos') IS NOT NULL
BEGIN
    ALTER DATABASE tpDatos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE tpDatos;
END
GO

CREATE DATABASE tpDatos;
GO

USE tpDatos;
GO

CREATE TABLE cliente (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre     VARCHAR(30) NOT NULL,
    apellido   VARCHAR(30) NOT NULL,
    telefono   VARCHAR(20) NULL
);

CREATE TABLE vehiculos (
    patente    VARCHAR(7)  PRIMARY KEY,
    marca      VARCHAR(30) NOT NULL,
    modelo     VARCHAR(30) NOT NULL,
    anio       INT NULL,
    id_cliente INT NOT NULL,
    CONSTRAINT FK_vehiculos_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT CK_vehiculos_patente CHECK (
        patente COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]'
        OR patente COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]'),
    CONSTRAINT CK_vehiculos_anio CHECK (anio BETWEEN 1950 AND 2030)
);

CREATE TABLE servicios (
    id_servicio INT IDENTITY(1,1) PRIMARY KEY,
    tipo        VARCHAR(100) NOT NULL,
    precio      INT NOT NULL,
    CONSTRAINT UQ_servicios_tipo UNIQUE (tipo),
    CONSTRAINT CK_servicios_precio CHECK (precio >= 0)
);

CREATE TABLE mecanicos (
    id_mecanico    INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(30) NOT NULL,
    apellido       VARCHAR(30) NOT NULL,
    telefono       VARCHAR(20) NULL,
    salariomensual INT NULL,
    CONSTRAINT CK_mecanicos_salario CHECK (salariomensual > 0)
);

CREATE TABLE proveedores (
    id_proveedor  INT IDENTITY(1,1) PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL,
    telefono      VARCHAR(20) NULL,
    direccion     VARCHAR(150) NULL,
    localidad     VARCHAR(70) NULL,
    tipoproveedor VARCHAR(20) NOT NULL,
    CONSTRAINT UQ_proveedores_nombre UNIQUE (nombre),
    CONSTRAINT CK_proveedores_tipo CHECK (tipoproveedor IN ('Repuestos', 'Servicios', 'Otros'))
);

CREATE TABLE grupos_de_trabajo (
    id_grupo_de_trabajo INT IDENTITY(1,1) PRIMARY KEY,
    nombre              VARCHAR(50) NOT NULL,
    descripcion         VARCHAR(200) NULL,
    CONSTRAINT UQ_grupos_nombre UNIQUE (nombre)
);

CREATE TABLE empleados_grupos (
    id_mecanico         INT NOT NULL,
    id_grupo_de_trabajo INT NOT NULL,
    CONSTRAINT PK_empleados_grupos PRIMARY KEY (id_mecanico, id_grupo_de_trabajo),
    CONSTRAINT FK_eg_mecanico FOREIGN KEY (id_mecanico) REFERENCES mecanicos (id_mecanico),
    CONSTRAINT FK_eg_grupo FOREIGN KEY (id_grupo_de_trabajo) REFERENCES grupos_de_trabajo (id_grupo_de_trabajo)
);

CREATE TABLE repuestos (
    id_repuesto  INT IDENTITY(1,1) PRIMARY KEY,
    descripcion  VARCHAR(50) NOT NULL,
    precio       INT NOT NULL,
    stock        INT NOT NULL CONSTRAINT DF_repuestos_stock DEFAULT 0,
    stock_minimo INT NOT NULL CONSTRAINT DF_repuestos_stock_minimo DEFAULT 5,
    id_proveedor INT NOT NULL,
    CONSTRAINT UQ_repuestos_descripcion UNIQUE (descripcion),
    CONSTRAINT CK_repuestos_precio CHECK (precio >= 0),
    CONSTRAINT CK_repuestos_stock CHECK (stock >= 0),
    CONSTRAINT CK_repuestos_stock_minimo CHECK (stock_minimo >= 0),
    CONSTRAINT FK_repuestos_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedores (id_proveedor)
);

CREATE TABLE orden_de_trabajo (
    id_orden_trabajo    INT IDENTITY(1,1) PRIMARY KEY,
    patente             VARCHAR(7) NOT NULL,
    id_grupo_de_trabajo INT NULL,
    estado              VARCHAR(20) NOT NULL CONSTRAINT DF_orden_estado DEFAULT 'Pendiente',
    fecha_ingreso       DATE NOT NULL CONSTRAINT DF_orden_ingreso DEFAULT (CAST(GETDATE() AS DATE)),
    fecha_fin           DATE NULL,
    CONSTRAINT FK_orden_vehiculo FOREIGN KEY (patente) REFERENCES vehiculos (patente),
    CONSTRAINT FK_orden_grupo FOREIGN KEY (id_grupo_de_trabajo) REFERENCES grupos_de_trabajo (id_grupo_de_trabajo),
    CONSTRAINT CK_orden_estado CHECK (estado IN ('Pendiente', 'En progreso', 'Terminado')),
    CONSTRAINT CK_orden_grupo_asignado CHECK (estado = 'Pendiente' OR id_grupo_de_trabajo IS NOT NULL),
    CONSTRAINT CK_orden_fin_terminado CHECK (
        (estado = 'Terminado' AND fecha_fin IS NOT NULL)
        OR (estado <> 'Terminado' AND fecha_fin IS NULL)),
    CONSTRAINT CK_orden_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_ingreso)
);

CREATE TABLE orden_servicio (
    id_orden_trabajo INT NOT NULL,
    id_servicio      INT NOT NULL,
    precio           INT NOT NULL,
    CONSTRAINT PK_orden_servicio PRIMARY KEY (id_orden_trabajo, id_servicio),
    CONSTRAINT FK_os_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_de_trabajo (id_orden_trabajo),
    CONSTRAINT FK_os_servicio FOREIGN KEY (id_servicio) REFERENCES servicios (id_servicio),
    CONSTRAINT CK_os_precio CHECK (precio >= 0)
);

CREATE TABLE orden_repuesto (
    id_orden_trabajo INT NOT NULL,
    id_repuesto      INT NOT NULL,
    cantidad         INT NOT NULL,
    precio           INT NOT NULL,
    CONSTRAINT PK_orden_repuesto PRIMARY KEY (id_orden_trabajo, id_repuesto),
    CONSTRAINT FK_or_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_de_trabajo (id_orden_trabajo),
    CONSTRAINT FK_or_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuestos (id_repuesto),
    CONSTRAINT CK_or_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_or_precio CHECK (precio >= 0)
);

CREATE TABLE cobros (
    id_cobro         INT IDENTITY(1,1) PRIMARY KEY,
    id_orden_trabajo INT NOT NULL,
    monto            INT NOT NULL,
    fecha_cobro      DATE NOT NULL CONSTRAINT DF_cobros_fecha DEFAULT (CAST(GETDATE() AS DATE)),
    metodo_de_cobro  VARCHAR(20) NOT NULL,
    CONSTRAINT FK_cobros_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_de_trabajo (id_orden_trabajo),
    CONSTRAINT CK_cobros_monto CHECK (monto > 0),
    CONSTRAINT CK_cobros_metodo CHECK (metodo_de_cobro IN ('efectivo', 'transferencia', 'cheque', 'otros'))
);

CREATE TABLE pedidos (
    id_pedido     INT IDENTITY(1,1) PRIMARY KEY,
    id_repuesto   INT NOT NULL,
    cantidad      INT NOT NULL,
    precio_unidad INT NOT NULL,
    fecha_pedido  DATE NOT NULL CONSTRAINT DF_pedidos_fecha DEFAULT (CAST(GETDATE() AS DATE)),
    estado        VARCHAR(20) NOT NULL CONSTRAINT DF_pedidos_estado DEFAULT 'Pendiente',
    CONSTRAINT FK_pedidos_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuestos (id_repuesto),
    CONSTRAINT CK_pedidos_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_pedidos_precio CHECK (precio_unidad >= 0),
    CONSTRAINT CK_pedidos_estado CHECK (estado IN ('Pendiente', 'Recibido', 'Cancelado'))
);

CREATE TABLE pagos (
    id_pago        INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido      INT NOT NULL,
    monto          INT NOT NULL,
    fecha_pago     DATE NOT NULL CONSTRAINT DF_pagos_fecha DEFAULT (CAST(GETDATE() AS DATE)),
    metodo_de_pago VARCHAR(20) NOT NULL,
    CONSTRAINT FK_pagos_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido),
    CONSTRAINT CK_pagos_monto CHECK (monto > 0),
    CONSTRAINT CK_pagos_metodo CHECK (metodo_de_pago IN ('efectivo', 'transferencia', 'cheque'))
);

CREATE TABLE auditoria_precios (
    id_auditoria    INT IDENTITY(1,1) PRIMARY KEY,
    tabla_origen    VARCHAR(20) NOT NULL,
    id_registro     INT NOT NULL,
    precio_anterior INT NOT NULL,
    precio_nuevo    INT NOT NULL,
    usuario         VARCHAR(128) NOT NULL,
    fecha           DATETIME NOT NULL CONSTRAINT DF_auditoria_fecha DEFAULT GETDATE(),
    CONSTRAINT CK_auditoria_tabla CHECK (tabla_origen IN ('servicios', 'repuestos'))
);

CREATE TABLE alertas_stock (
    id_alerta        INT IDENTITY(1,1) PRIMARY KEY,
    id_orden_trabajo INT NOT NULL,
    id_repuesto      INT NOT NULL,
    requerido        INT NOT NULL,
    disponible       INT NOT NULL,
    fecha            DATETIME NOT NULL CONSTRAINT DF_alertas_fecha DEFAULT GETDATE(),
    CONSTRAINT FK_alertas_orden FOREIGN KEY (id_orden_trabajo) REFERENCES orden_de_trabajo (id_orden_trabajo),
    CONSTRAINT FK_alertas_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuestos (id_repuesto)
);
GO

-- ==========================================================================
-- SECCION 02_datos
-- ==========================================================================
USE tpDatos;
GO

INSERT INTO cliente (nombre, apellido, telefono) VALUES
('Martín',   'Gómez',      '11 4523-8812'),
('Lucía',    'Fernández',  '351 612-3344'),
('Carlos',   'Rodríguez',  NULL),
('Valeria',  'Sosa',       '11 5567-9021'),
('Diego',    'Pereyra',    '341 455-7790'),
('Julieta',  'Acosta',     NULL),
('Federico', 'Benítez',    '11 6034-2278'),
('Romina',   'Castro',     '261 530-1148'),
('Hernán',   'Molina',     '11 4872-3350'),
('Natalia',  'Ibáñez',     '221 478-9063');

INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES
('AB123CD', 'Toyota',     'Corolla',   2019, 1),
('AE345KL', 'Renault',    'Sandero',   2018, 1),
('AC456EF', 'Ford',       'Focus',     2017, 2),
('AA789GH', 'Volkswagen', 'Gol Trend', 2015, 3),
('AD012IJ', 'Chevrolet',  'Cruze',     2021, 4),
('AF678MN', 'Peugeot',    '208',       2022, 5),
('AG901OP', 'Fiat',       'Cronos',    2020, 7),
('HJK234',  'Ford',       'Ka',        2009, 8),
('AH567QR', 'Toyota',     'Hilux',     NULL, 9),
('KLM567',  'Renault',    'Clio',      2005, 9);

INSERT INTO servicios (tipo, precio) VALUES
('Cambio de aceite y filtro',         85000),
('Alineación y balanceo',             60000),
('Cambio de pastillas de freno',     120000),
('Revisión general pre-VTV',          45000),
('Cambio de correa de distribución', 280000),
('Diagnóstico con scanner',           35000),
('Cambio de batería',                 40000),
('Service de aire acondicionado',     95000),
('Cambio de amortiguadores',         210000),
('Rectificación de motor',           450000),
('Cambio de embrague',               350000),
('Lavado de inyectores',              70000);

INSERT INTO mecanicos (nombre, apellido, telefono, salariomensual) VALUES
('Ricardo',  'Paredes',   '11 4455-2301', 1450000),
('Gustavo',  'Luna',      '11 6120-8845', 1380000),
('Marcelo',  'Quiroga',   NULL,           1620000),
('Pablo',    'Herrera',   '351 702-1190', 1290000),
('Andrés',   'Maldonado', '11 5338-4472', 1510000),
('Leandro',  'Ruiz',      NULL,           NULL),
('Emiliano', 'Torres',    '11 6741-0923', 1340000),
('Walter',   'Sánchez',   '11 4998-3156', 1700000),
('Damián',   'Correa',    '221 566-7802', 1250000),
('Facundo',  'Ledesma',   '11 5812-6039', 1420000);

INSERT INTO proveedores (nombre, telefono, direccion, localidad, tipoproveedor) VALUES
('Repuestos Rivadavia SRL',        '11 4631-2200', 'Av. Rivadavia 8450',   'Flores, CABA',           'Repuestos'),
('Autopartes del Sur',             '11 4208-7715', 'Av. H. Yrigoyen 3120', 'Lomas de Zamora',        'Repuestos'),
('Lubricantes Pampa',              '11 4765-9034', 'Ruta 8 km 32',         'Pilar',                  'Repuestos'),
('Frenos y Embragues Córdoba',     '351 428-5566', 'Av. Colón 1875',       'Córdoba',                'Repuestos'),
('Baterías Tucumán',               '381 431-9920', 'Maipú 640',            'San Miguel de Tucumán',  'Repuestos'),
('Rectificaciones Mendoza SA',     '261 425-3381', NULL,                   'Mendoza',                'Servicios'),
('Neumáticos Belgrano',            '11 4783-1160', 'Av. Cabildo 2290',     'Belgrano, CABA',         'Otros'),
('Distribuidora Nac. Autopartes',  NULL,           'Av. Mitre 1450',       'Avellaneda',             'Repuestos'),
('Servicio de Grúas Rápido',       '11 3345-7788', NULL,                   NULL,                     'Servicios'),
('Insumos Taller Express',         '341 449-2025', 'Bv. Oroño 980',        'Rosario',                'Otros');

INSERT INTO grupos_de_trabajo (nombre, descripcion) VALUES
('Mecánica general',        'Service y mantenimiento de rutina'),
('Frenos y suspensión',     'Frenos, amortiguadores y alineación'),
('Motor',                   'Distribución, rectificación y motor en general'),
('Electricidad y baterías', NULL),
('Transmisión',             'Embragues y cajas'),
('Diagnóstico',             'Scanner y revisiones previas a la VTV'),
('Climatización',           NULL),
('Reserva',                 'Grupo sin integrantes asignados');

INSERT INTO empleados_grupos (id_mecanico, id_grupo_de_trabajo) VALUES
(1, 1), (2, 1),
(3, 2), (4, 2),
(5, 3), (6, 3),
(7, 4), (8, 4),
(9, 5), (10, 5),
(1, 6), (8, 6),
(3, 7);

INSERT INTO repuestos (descripcion, precio, stock, stock_minimo, id_proveedor) VALUES
('Filtro de aceite',              12500, 40, 10, 1),
('Aceite 10W40 sintético 4L',     48000, 25,  5, 3),
('Pastillas de freno delanteras', 38000, 18,  5, 4),
('Kit correa distribución',       95000,  8,  5, 2),
('Batería 12V 65Ah',             118000,  6,  5, 5),
('Amortiguador delantero',        62000, 10,  5, 1),
('Disco de embrague kit',        145000,  4,  5, 4),
('Filtro de aire',                 9800, 32,  5, 8),
('Bujías x4 (juego)',             22000,  0,  5, 2),
('Líquido refrigerante 5L',       14500, 15,  5, 3),
('Inyector nafta',                41000,  3,  5, 8),
('Lámpara H7 halógena',            6500,  2, 10, 10);

INSERT INTO orden_de_trabajo (patente, id_grupo_de_trabajo, estado, fecha_ingreso, fecha_fin) VALUES
('AB123CD', 1,    'Terminado',   '2026-08-04', '2026-08-05'),
('AC456EF', 2,    'Terminado',   '2026-08-12', '2026-08-13'),
('AA789GH', 3,    'Terminado',   '2026-08-25', '2026-08-27'),
('AD012IJ', 4,    'En progreso', '2026-10-01', NULL),
('AE345KL', NULL, 'Pendiente',   '2026-10-20', NULL),
('AF678MN', 1,    'Terminado',   '2026-09-03', '2026-09-04'),
('AG901OP', 2,    'Terminado',   '2026-09-08', '2026-09-09'),
('HJK234',  4,    'En progreso', '2026-10-08', NULL),
('AH567QR', NULL, 'Pendiente',   '2026-10-25', NULL),
('KLM567',  5,    'Terminado',   '2026-09-16', '2026-09-17'),
('AB123CD', NULL, 'Pendiente',   '2026-10-28', NULL),
('AB123CD', 6,    'Terminado',   '2026-09-28', '2026-10-01');

INSERT INTO orden_servicio (id_orden_trabajo, id_servicio, precio) VALUES
(1,  1,  80000),
(2,  3,  120000),
(3,  5,  280000),
(4,  9,  210000),
(5,  11, 350000),
(6,  2,  60000),
(7,  4,  45000),
(8,  7,  40000),
(9,  6,  35000),
(10, 1,  85000),
(10, 2,  60000),
(11, 12, 70000),
(12, 8,  95000);

INSERT INTO orden_repuesto (id_orden_trabajo, id_repuesto, cantidad, precio) VALUES
(1,  1,  1, 12000),
(1,  2,  1, 48000),
(2,  3,  1, 38000),
(3,  4,  1, 95000),
(3,  10, 2, 14500),
(4,  6,  2, 62000),
(5,  7,  1, 145000),
(8,  5,  1, 118000),
(11, 9,  1, 22000),
(11, 8,  1, 9800),
(12, 10, 1, 14500);

INSERT INTO cobros (id_orden_trabajo, monto, fecha_cobro, metodo_de_cobro) VALUES
(1,  140000, '2026-08-06', 'transferencia'),
(2,  100000, '2026-08-13', 'efectivo'),
(2,   58000, '2026-08-14', 'transferencia'),
(3,  150000, '2026-08-26', 'efectivo'),
(3,  254000, '2026-08-28', 'transferencia'),
(4,  100000, '2026-10-05', 'efectivo'),
(4,   80000, '2026-10-11', 'transferencia'),
(6,   60000, '2026-09-04', 'efectivo'),
(7,   40000, '2026-09-10', 'efectivo'),
(8,  100000, '2026-10-09', 'cheque'),
(10, 145000, '2026-09-18', 'otros'),
(12, 109500, '2026-10-02', 'transferencia');

INSERT INTO pedidos (id_repuesto, cantidad, precio_unidad, fecha_pedido, estado) VALUES
(1,  20, 11000,  '2026-07-28', 'Recibido'),
(2,  10, 45000,  '2026-08-01', 'Recibido'),
(3,   8, 35000,  '2026-08-10', 'Recibido'),
(4,   4, 90000,  '2026-08-20', 'Recibido'),
(5,   3, 110000, '2026-08-28', 'Recibido'),
(6,   6, 58000,  '2026-09-05', 'Recibido'),
(7,   6, 135000, '2026-10-15', 'Pendiente'),
(8,  15, 9000,   '2026-09-12', 'Recibido'),
(9,  10, 20000,  '2026-09-20', 'Recibido'),
(10,  5, 13000,  '2026-09-25', 'Recibido'),
(11,  2, 38000,  '2026-10-20', 'Pendiente'),
(12, 30, 5800,   '2026-10-01', 'Recibido'),
(9,  12, 21000,  '2026-10-22', 'Cancelado');

INSERT INTO pagos (id_pedido, monto, fecha_pago, metodo_de_pago) VALUES
(1,  220000, '2026-08-05', 'transferencia'),
(2,  450000, '2026-08-12', 'cheque'),
(3,  280000, '2026-08-20', 'transferencia'),
(4,  360000, '2026-09-01', 'efectivo'),
(5,  330000, '2026-09-08', 'transferencia'),
(6,  348000, '2026-09-15', 'cheque'),
(8,  135000, '2026-09-22', 'efectivo'),
(9,  100000, '2026-09-29', 'transferencia'),
(9,  100000, '2026-10-06', 'transferencia'),
(10,  65000, '2026-10-03', 'efectivo'),
(11,  30000, '2026-10-21', 'efectivo'),
(12, 174000, '2026-10-08', 'efectivo');
GO


-- ==========================================================================
-- SECCION 03_vistas_funciones
-- ==========================================================================
USE tpDatos;
GO

CREATE FUNCTION dbo.fn_total_orden (@id_orden INT)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total =
          ISNULL((SELECT SUM(precio)
                  FROM orden_servicio
                  WHERE id_orden_trabajo = @id_orden), 0)
        + ISNULL((SELECT SUM(cantidad * precio)
                  FROM orden_repuesto
                  WHERE id_orden_trabajo = @id_orden), 0);

    RETURN @total;
END;
GO

CREATE FUNCTION dbo.fn_saldo_orden (@id_orden INT)
RETURNS INT
AS
BEGIN
    DECLARE @saldo INT;

    SELECT @saldo = dbo.fn_total_orden(@id_orden)
                  - ISNULL((SELECT SUM(monto)
                            FROM cobros
                            WHERE id_orden_trabajo = @id_orden), 0);

    RETURN @saldo;
END;
GO

CREATE VIEW dbo.vw_stock_critico AS
SELECT r.id_repuesto,
       r.descripcion,
       r.stock,
       r.stock_minimo,
       r.stock_minimo - r.stock AS faltante,
       p.nombre                 AS proveedor
FROM repuestos r
INNER JOIN proveedores p ON p.id_proveedor = r.id_proveedor
WHERE r.stock < r.stock_minimo;
GO

CREATE VIEW dbo.vw_saldo_ordenes AS
SELECT o.id_orden_trabajo,
       o.patente,
       o.estado,
       dbo.fn_total_orden(o.id_orden_trabajo)                                  AS total,
       dbo.fn_total_orden(o.id_orden_trabajo) - dbo.fn_saldo_orden(o.id_orden_trabajo) AS cobrado,
       dbo.fn_saldo_orden(o.id_orden_trabajo)                                  AS saldo
FROM orden_de_trabajo o;
GO

CREATE VIEW dbo.vw_saldo_pedidos AS
SELECT p.id_pedido,
       p.id_repuesto,
       p.estado                                         AS estado_pedido,
       p.cantidad * p.precio_unidad                     AS total,
       COUNT(pg.id_pago)                                AS cantidad_pagos,
       ISNULL(SUM(pg.monto), 0)                         AS pagado,
       p.cantidad * p.precio_unidad - ISNULL(SUM(pg.monto), 0) AS saldo,
       CASE
           WHEN p.estado = 'Cancelado' THEN 'Cancelado'
           WHEN ISNULL(SUM(pg.monto), 0) >= p.cantidad * p.precio_unidad THEN 'Pagado'
           ELSE 'Pendiente de pago'
       END                                              AS estado_pago
FROM pedidos p
LEFT JOIN pagos pg ON pg.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.id_repuesto, p.estado, p.cantidad, p.precio_unidad;
GO


