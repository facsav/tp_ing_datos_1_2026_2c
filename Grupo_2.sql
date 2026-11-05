/*
Orden de ejecución: 01 Esquema -> 02 Datos -> 03 Vistas y funciones ->
04 Triggers -> 05 Procedimientos -> 06 Cursor -> 07 Seguridad ->
09 Consultas -> 08 Pruebas.
*/

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

-- ==========================================================================
-- SECCION 04_triggers
-- ==========================================================================
USE tpDatos;
GO

CREATE TRIGGER dbo.trg_servicios_auditoria
ON servicios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio)
        INSERT INTO auditoria_precios (tabla_origen, id_registro, precio_anterior, precio_nuevo, usuario, fecha)
        SELECT 'servicios', d.id_servicio, d.precio, i.precio, SUSER_SNAME(), GETDATE()
        FROM deleted d
        INNER JOIN inserted i ON i.id_servicio = d.id_servicio
        WHERE d.precio <> i.precio;
END;
GO

CREATE TRIGGER dbo.trg_repuestos_auditoria
ON repuestos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio)
        INSERT INTO auditoria_precios (tabla_origen, id_registro, precio_anterior, precio_nuevo, usuario, fecha)
        SELECT 'repuestos', d.id_repuesto, d.precio, i.precio, SUSER_SNAME(), GETDATE()
        FROM deleted d
        INNER JOIN inserted i ON i.id_repuesto = d.id_repuesto
        WHERE d.precio <> i.precio;
END;
GO

CREATE TRIGGER dbo.trg_orden_transicion
ON orden_de_trabajo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_orden_trabajo = i.id_orden_trabajo
                   WHERE i.estado <> d.estado
                     AND NOT ((d.estado = 'Pendiente' AND i.estado = 'En progreso')
                           OR (d.estado = 'En progreso' AND i.estado = 'Terminado')))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50030, 'El estado de la orden solo avanza en orden: Pendiente, En progreso, Terminado.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_inicio_descuenta
ON orden_de_trabajo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @necesarios TABLE (id_repuesto INT, cantidad INT);

    IF UPDATE(estado)
    BEGIN
        INSERT INTO @necesarios (id_repuesto, cantidad)
        SELECT orp.id_repuesto, SUM(orp.cantidad)
        FROM orden_repuesto orp
        INNER JOIN inserted i ON i.id_orden_trabajo = orp.id_orden_trabajo
        INNER JOIN deleted d  ON d.id_orden_trabajo = i.id_orden_trabajo
        WHERE i.estado = 'En progreso'
          AND d.estado = 'Pendiente'
        GROUP BY orp.id_repuesto;

        IF EXISTS (SELECT 1
                   FROM @necesarios n
                   INNER JOIN repuestos r ON r.id_repuesto = n.id_repuesto
                   WHERE r.stock < n.cantidad)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50031, 'Stock insuficiente para iniciar la orden.', 1;
        END;

        UPDATE repuestos
        SET stock = stock - (SELECT n.cantidad FROM @necesarios n WHERE n.id_repuesto = repuestos.id_repuesto)
        WHERE id_repuesto IN (SELECT id_repuesto FROM @necesarios);
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_repuesto_descuenta
ON orden_repuesto
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @necesarios TABLE (id_repuesto INT, cantidad INT);

    INSERT INTO @necesarios (id_repuesto, cantidad)
    SELECT i.id_repuesto, SUM(i.cantidad)
    FROM inserted i
    INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = i.id_orden_trabajo
    WHERE o.estado = 'En progreso'
    GROUP BY i.id_repuesto;

    IF EXISTS (SELECT 1
               FROM @necesarios n
               INNER JOIN repuestos r ON r.id_repuesto = n.id_repuesto
               WHERE r.stock < n.cantidad)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50031, 'Stock insuficiente para agregar el repuesto a la orden.', 1;
    END;

    UPDATE repuestos
    SET stock = stock - (SELECT n.cantidad FROM @necesarios n WHERE n.id_repuesto = repuestos.id_repuesto)
    WHERE id_repuesto IN (SELECT id_repuesto FROM @necesarios);
END;
GO

CREATE TRIGGER dbo.trg_orden_repuesto_bloqueo
ON orden_repuesto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.estado = 'Terminado'
                 AND (o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                   OR o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM deleted)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50032, 'Una orden Terminado no admite cambios en sus servicios ni en sus repuestos.', 1;
    END;

    IF EXISTS (SELECT 1
               FROM deleted d
               INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = d.id_orden_trabajo
               WHERE o.estado = 'En progreso')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50036, 'Los repuestos de una orden En progreso ya descontaron stock y no se modifican.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_servicio_bloqueo
ON orden_servicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.estado = 'Terminado'
                 AND (o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                   OR o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM deleted)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50032, 'Una orden Terminado no admite cambios en sus servicios ni en sus repuestos.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_cobros_tope
ON cobros
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                 AND dbo.fn_saldo_orden(o.id_orden_trabajo) < 0)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50033, 'La suma de los cobros no puede superar el total de la orden.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_pagos_tope
ON pagos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN pedidos p ON p.id_pedido = i.id_pedido
               WHERE p.estado = 'Cancelado')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50035, 'Un pedido Cancelado no se puede pagar.', 1;
    END;

    IF EXISTS (SELECT 1
               FROM pedidos p
               WHERE p.id_pedido IN (SELECT id_pedido FROM inserted)
                 AND p.cantidad * p.precio_unidad < (SELECT SUM(pg.monto)
                                                     FROM pagos pg
                                                     WHERE pg.id_pedido = p.id_pedido))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50034, 'La suma de los pagos no puede superar el total del pedido.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_pedidos_transicion
ON pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_pedido = i.id_pedido
                   WHERE d.estado <> 'Pendiente'
                     AND i.estado <> d.estado)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50037, 'Un pedido Recibido o Cancelado no puede cambiar de estado.', 1;
    END;
END;
GO

-- ==========================================================================
-- SECCION 05_procedimientos
-- ==========================================================================
USE tpDatos;
GO

CREATE PROCEDURE dbo.sp_alta_cliente_vehiculo
    @nombre     VARCHAR(100) = NULL,
    @apellido   VARCHAR(100) = NULL,
    @telefono   VARCHAR(50)  = NULL,
    @patente    VARCHAR(20)  = NULL,
    @marca      VARCHAR(100) = NULL,
    @modelo     VARCHAR(100) = NULL,
    @anio       INT          = NULL,
    @id_cliente INT          = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @patente IS NOT NULL
            SET @patente = UPPER(TRIM(@patente));

        IF @id_cliente IS NULL AND (@nombre IS NULL OR @apellido IS NULL)
            THROW 50001, 'Para crear un cliente hacen falta nombre y apellido.', 1;

        IF @id_cliente IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = @id_cliente)
            THROW 50002, 'El cliente indicado no existe.', 1;

        IF @id_cliente IS NOT NULL AND @patente IS NULL
            THROW 50003, 'Falta la patente del vehículo a cargar.', 1;

        IF @patente IS NOT NULL AND (@marca IS NULL OR @modelo IS NULL)
            THROW 50004, 'Para cargar un vehículo hacen falta patente, marca y modelo.', 1;

        IF @patente IS NOT NULL
           AND EXISTS (SELECT 1 FROM vehiculos WHERE patente = @patente)
            THROW 50005, 'Ya existe un vehículo con esa patente.', 1;

        BEGIN TRANSACTION;

        IF @id_cliente IS NULL
        BEGIN
            INSERT INTO cliente (nombre, apellido, telefono)
            VALUES (@nombre, @apellido, @telefono);

            SET @id_cliente = SCOPE_IDENTITY();
        END;

        IF @patente IS NOT NULL
            INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente)
            VALUES (@patente, @marca, @modelo, @anio, @id_cliente);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_abrir_orden
    @patente  VARCHAR(20),
    @id_orden INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @patente IS NULL
            THROW 50010, 'Falta la patente del vehículo.', 1;

        SET @patente = UPPER(TRIM(@patente));

        IF NOT EXISTS (SELECT 1 FROM vehiculos WHERE patente = @patente)
            THROW 50011, 'El vehículo no existe.', 1;

        INSERT INTO orden_de_trabajo (patente)
        VALUES (@patente);

        SET @id_orden = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_agregar_servicio
    @id_orden    INT,
    @id_servicio INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @id_servicio IS NULL
           OR NOT EXISTS (SELECT 1 FROM servicios WHERE id_servicio = @id_servicio)
            THROW 50013, 'El servicio no existe.', 1;

        IF EXISTS (SELECT 1
                   FROM orden_servicio
                   WHERE id_orden_trabajo = @id_orden
                     AND id_servicio = @id_servicio)
            THROW 50014, 'El servicio ya está incluido en la orden.', 1;

        INSERT INTO orden_servicio (id_orden_trabajo, id_servicio, precio)
        SELECT @id_orden, id_servicio, precio
        FROM servicios
        WHERE id_servicio = @id_servicio;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_agregar_repuesto
    @id_orden    INT,
    @id_repuesto INT,
    @cantidad    INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @id_repuesto IS NULL
           OR NOT EXISTS (SELECT 1 FROM repuestos WHERE id_repuesto = @id_repuesto)
            THROW 50015, 'El repuesto no existe.', 1;

        IF @cantidad IS NULL OR @cantidad <= 0
            THROW 50016, 'La cantidad debe ser mayor que cero.', 1;

        IF EXISTS (SELECT 1
                   FROM orden_repuesto
                   WHERE id_orden_trabajo = @id_orden
                     AND id_repuesto = @id_repuesto)
            THROW 50017, 'El repuesto ya está incluido en la orden.', 1;

        INSERT INTO orden_repuesto (id_orden_trabajo, id_repuesto, cantidad, precio)
        SELECT @id_orden, id_repuesto, @cantidad, precio
        FROM repuestos
        WHERE id_repuesto = @id_repuesto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_iniciar_orden
    @id_orden INT,
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM orden_de_trabajo
                       WHERE id_orden_trabajo = @id_orden
                         AND estado = 'Pendiente')
            THROW 50019, 'Solo se puede iniciar una orden Pendiente.', 1;

        IF @id_grupo IS NULL
           OR NOT EXISTS (SELECT 1 FROM grupos_de_trabajo WHERE id_grupo_de_trabajo = @id_grupo)
            THROW 50018, 'El grupo de trabajo no existe.', 1;

        BEGIN TRANSACTION;

        UPDATE orden_de_trabajo
        SET id_grupo_de_trabajo = @id_grupo,
            estado = 'En progreso'
        WHERE id_orden_trabajo = @id_orden;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_cerrar_orden
    @id_orden INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM orden_de_trabajo
                       WHERE id_orden_trabajo = @id_orden
                         AND estado = 'En progreso')
            THROW 50020, 'Solo se puede cerrar una orden En progreso.', 1;

        IF NOT EXISTS (SELECT 1 FROM orden_servicio WHERE id_orden_trabajo = @id_orden)
            THROW 50021, 'No se puede cerrar una orden sin servicios.', 1;

        BEGIN TRANSACTION;

        UPDATE orden_de_trabajo
        SET estado = 'Terminado',
            fecha_fin = CAST(GETDATE() AS DATE)
        WHERE id_orden_trabajo = @id_orden;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_registrar_cobro
    @id_orden INT,
    @monto    INT,
    @metodo   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @monto IS NULL OR @monto <= 0
            THROW 50022, 'El monto debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro)
        VALUES (@id_orden, @monto, @metodo);

        COMMIT TRANSACTION;

        SELECT dbo.fn_saldo_orden(@id_orden) AS saldo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_crear_pedido
    @id_repuesto   INT,
    @cantidad      INT,
    @precio_unidad INT,
    @id_pedido     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_repuesto IS NULL
           OR NOT EXISTS (SELECT 1 FROM repuestos WHERE id_repuesto = @id_repuesto)
            THROW 50015, 'El repuesto no existe.', 1;

        IF @cantidad IS NULL OR @cantidad <= 0
            THROW 50016, 'La cantidad debe ser mayor que cero.', 1;

        IF @precio_unidad IS NULL OR @precio_unidad < 0
            THROW 50025, 'El costo unitario no puede ser negativo.', 1;

        INSERT INTO pedidos (id_repuesto, cantidad, precio_unidad)
        VALUES (@id_repuesto, @cantidad, @precio_unidad);

        SET @id_pedido = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_recibir_pedido
    @id_pedido INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM pedidos
                       WHERE id_pedido = @id_pedido
                         AND estado = 'Pendiente')
            THROW 50027, 'Solo se puede recibir un pedido Pendiente.', 1;

        BEGIN TRANSACTION;

        UPDATE pedidos
        SET estado = 'Recibido'
        WHERE id_pedido = @id_pedido;

        UPDATE repuestos
        SET stock = stock + (SELECT cantidad FROM pedidos WHERE id_pedido = @id_pedido)
        WHERE id_repuesto = (SELECT id_repuesto FROM pedidos WHERE id_pedido = @id_pedido);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_cancelar_pedido
    @id_pedido INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM pedidos
                       WHERE id_pedido = @id_pedido
                         AND estado = 'Pendiente')
            THROW 50027, 'Solo se puede cancelar un pedido Pendiente.', 1;

        IF EXISTS (SELECT 1 FROM pagos WHERE id_pedido = @id_pedido)
            THROW 50029, 'No se puede cancelar un pedido que ya tiene pagos.', 1;

        BEGIN TRANSACTION;

        UPDATE pedidos
        SET estado = 'Cancelado'
        WHERE id_pedido = @id_pedido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_registrar_pago
    @id_pedido INT,
    @monto     INT,
    @metodo    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF @monto IS NULL OR @monto <= 0
            THROW 50022, 'El monto debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        INSERT INTO pagos (id_pedido, monto, metodo_de_pago)
        VALUES (@id_pedido, @monto, @metodo);

        COMMIT TRANSACTION;

        SELECT saldo, estado_pago FROM dbo.vw_saldo_pedidos WHERE id_pedido = @id_pedido;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==========================================================================
-- SECCION 06_cursor_faltantes
-- ==========================================================================
USE tpDatos;
GO

CREATE PROCEDURE dbo.sp_control_faltantes
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_orden INT, @id_repuesto INT, @cantidad INT, @stock INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM alertas_stock;

        DECLARE cur_pendientes CURSOR LOCAL FOR
            SELECT orp.id_orden_trabajo, orp.id_repuesto, orp.cantidad, r.stock
            FROM orden_repuesto orp
            INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = orp.id_orden_trabajo
            INNER JOIN repuestos r        ON r.id_repuesto = orp.id_repuesto
            WHERE o.estado = 'Pendiente';

        OPEN cur_pendientes;
        FETCH NEXT FROM cur_pendientes INTO @id_orden, @id_repuesto, @cantidad, @stock;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @stock < @cantidad
                INSERT INTO alertas_stock (id_orden_trabajo, id_repuesto, requerido, disponible)
                VALUES (@id_orden, @id_repuesto, @cantidad, @stock);

            FETCH NEXT FROM cur_pendientes INTO @id_orden, @id_repuesto, @cantidad, @stock;
        END;

        CLOSE cur_pendientes;
        DEALLOCATE cur_pendientes;

        COMMIT TRANSACTION;

        SELECT id_repuesto, descripcion, stock, stock_minimo, faltante, proveedor
        FROM vw_stock_critico
        ORDER BY faltante DESC;

        SELECT a.id_orden_trabajo, o.patente, r.descripcion AS repuesto, a.requerido, a.disponible
        FROM alertas_stock a
        INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = a.id_orden_trabajo
        INNER JOIN repuestos r        ON r.id_repuesto = a.id_repuesto
        ORDER BY a.id_orden_trabajo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==========================================================================
-- SECCION 07_seguridad
-- ==========================================================================
USE tpDatos;
GO

DROP USER IF EXISTS usr_admin;
DROP USER IF EXISTS usr_recepcion;
DROP USER IF EXISTS usr_compras;
DROP USER IF EXISTS usr_mecanico;
DROP USER IF EXISTS usr_auditor;

DROP ROLE IF EXISTS rol_administrador;
DROP ROLE IF EXISTS rol_recepcion;
DROP ROLE IF EXISTS rol_compras;
DROP ROLE IF EXISTS rol_mecanico;
DROP ROLE IF EXISTS rol_auditor;
GO

USE master;
GO

IF SUSER_ID('lg_admin') IS NOT NULL DROP LOGIN lg_admin;
IF SUSER_ID('lg_recepcion') IS NOT NULL DROP LOGIN lg_recepcion;
IF SUSER_ID('lg_compras') IS NOT NULL DROP LOGIN lg_compras;
IF SUSER_ID('lg_mecanico') IS NOT NULL DROP LOGIN lg_mecanico;
IF SUSER_ID('lg_auditor') IS NOT NULL DROP LOGIN lg_auditor;
GO

CREATE LOGIN lg_admin     WITH PASSWORD = 'Taller#Admin2026';
CREATE LOGIN lg_recepcion WITH PASSWORD = 'Taller#Recep2026';
CREATE LOGIN lg_compras   WITH PASSWORD = 'Taller#Compra2026';
CREATE LOGIN lg_mecanico  WITH PASSWORD = 'Taller#Mecan2026';
CREATE LOGIN lg_auditor   WITH PASSWORD = 'Taller#Audit2026';
GO

USE tpDatos;
GO

CREATE ROLE rol_administrador;
CREATE ROLE rol_recepcion;
CREATE ROLE rol_compras;
CREATE ROLE rol_mecanico;
CREATE ROLE rol_auditor;
GO

CREATE USER usr_admin     FOR LOGIN lg_admin;
CREATE USER usr_recepcion FOR LOGIN lg_recepcion;
CREATE USER usr_compras   FOR LOGIN lg_compras;
CREATE USER usr_mecanico  FOR LOGIN lg_mecanico;
CREATE USER usr_auditor   FOR LOGIN lg_auditor;
GO

ALTER ROLE rol_administrador ADD MEMBER usr_admin;
ALTER ROLE rol_recepcion     ADD MEMBER usr_recepcion;
ALTER ROLE rol_compras       ADD MEMBER usr_compras;
ALTER ROLE rol_mecanico      ADD MEMBER usr_mecanico;
ALTER ROLE rol_auditor       ADD MEMBER usr_auditor;
GO

CREATE VIEW dbo.vw_mecanicos_publico AS
SELECT id_mecanico, nombre, apellido, telefono
FROM mecanicos;
GO

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO rol_administrador;
DENY UPDATE, DELETE ON dbo.auditoria_precios TO rol_administrador;
DENY UPDATE, DELETE ON dbo.alertas_stock TO rol_administrador;
GO

GRANT SELECT ON dbo.cliente            TO rol_recepcion;
GRANT SELECT ON dbo.vehiculos          TO rol_recepcion;
GRANT SELECT ON dbo.servicios          TO rol_recepcion;
GRANT SELECT ON dbo.repuestos          TO rol_recepcion;
GRANT SELECT ON dbo.grupos_de_trabajo  TO rol_recepcion;
GRANT SELECT ON dbo.orden_de_trabajo   TO rol_recepcion;
GRANT SELECT ON dbo.orden_servicio     TO rol_recepcion;
GRANT SELECT ON dbo.orden_repuesto     TO rol_recepcion;
GRANT SELECT ON dbo.cobros             TO rol_recepcion;
GRANT SELECT ON dbo.vw_saldo_ordenes   TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_alta_cliente_vehiculo TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_abrir_orden           TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_agregar_servicio      TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_agregar_repuesto      TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_iniciar_orden         TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_cerrar_orden          TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_registrar_cobro       TO rol_recepcion;
GO

GRANT SELECT ON dbo.repuestos          TO rol_compras;
GRANT SELECT ON dbo.proveedores        TO rol_compras;
GRANT SELECT ON dbo.pedidos            TO rol_compras;
GRANT SELECT ON dbo.pagos              TO rol_compras;
GRANT SELECT ON dbo.alertas_stock      TO rol_compras;
GRANT SELECT ON dbo.vw_stock_critico   TO rol_compras;
GRANT SELECT ON dbo.vw_saldo_pedidos   TO rol_compras;
GRANT EXECUTE ON dbo.sp_crear_pedido      TO rol_compras;
GRANT EXECUTE ON dbo.sp_recibir_pedido    TO rol_compras;
GRANT EXECUTE ON dbo.sp_cancelar_pedido   TO rol_compras;
GRANT EXECUTE ON dbo.sp_registrar_pago    TO rol_compras;
GRANT EXECUTE ON dbo.sp_control_faltantes TO rol_compras;
GO

GRANT SELECT ON dbo.vehiculos          TO rol_mecanico;
GRANT SELECT ON dbo.servicios          TO rol_mecanico;
GRANT SELECT ON dbo.grupos_de_trabajo  TO rol_mecanico;
GRANT SELECT ON dbo.empleados_grupos   TO rol_mecanico;
GRANT SELECT ON dbo.orden_de_trabajo   TO rol_mecanico;
GRANT SELECT ON dbo.orden_servicio     TO rol_mecanico;
GRANT SELECT ON dbo.orden_repuesto     TO rol_mecanico;
GO

GRANT SELECT ON SCHEMA::dbo TO rol_auditor;
GO

GRANT SELECT ON dbo.vw_mecanicos_publico TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
GO

DENY SELECT ON dbo.mecanicos (salariomensual) TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
GO

DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
DENY EXECUTE ON SCHEMA::dbo TO rol_mecanico, rol_auditor;
GO

SELECT dp.name        AS rol,
       pr.permission_name AS permiso,
       pr.state_desc  AS estado,
       pr.class_desc  AS nivel,
       CASE WHEN pr.class_desc = 'SCHEMA' THEN SCHEMA_NAME(pr.major_id)
            ELSE OBJECT_NAME(pr.major_id) END AS objeto
FROM sys.database_permissions pr
INNER JOIN sys.database_principals dp ON dp.principal_id = pr.grantee_principal_id
WHERE dp.name LIKE 'rol[_]%'
ORDER BY dp.name, pr.state_desc, pr.permission_name;
GO

-- ==========================================================================
-- SECCION 08_consultas
-- ==========================================================================
USE tpDatos;
GO

SELECT v.patente,
       v.marca,
       v.modelo,
       v.anio,
       CONCAT(c.nombre, ' ', c.apellido) AS dueno
FROM vehiculos v
INNER JOIN cliente c ON c.id_cliente = v.id_cliente
ORDER BY c.apellido, c.nombre, v.patente;
GO

SELECT c.id_cliente,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       COUNT(v.patente)                  AS vehiculos
FROM cliente c
LEFT JOIN vehiculos v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY vehiculos DESC, c.apellido;
GO

SELECT patente, marca, modelo, anio
FROM vehiculos
WHERE anio < 2018
   OR anio IS NULL
ORDER BY anio;
GO

SELECT o.id_orden_trabajo,
       o.estado,
       o.fecha_ingreso,
       v.patente,
       v.marca,
       v.modelo,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       g.nombre                          AS grupo
FROM orden_de_trabajo o
INNER JOIN vehiculos v          ON v.patente = o.patente
INNER JOIN cliente c            ON c.id_cliente = v.id_cliente
LEFT JOIN grupos_de_trabajo g   ON g.id_grupo_de_trabajo = o.id_grupo_de_trabajo
WHERE o.estado IN ('Pendiente', 'En progreso')
ORDER BY o.fecha_ingreso;
GO

SELECT s.id_orden_trabajo,
       s.patente,
       s.estado,
       s.total,
       s.cobrado,
       s.saldo
FROM vw_saldo_ordenes s
WHERE s.saldo > 0
ORDER BY s.saldo DESC;
GO

SELECT s.tipo,
       COUNT(*)       AS veces,
       SUM(os.precio) AS facturado,
       AVG(os.precio) AS precio_promedio
FROM orden_servicio os
INNER JOIN servicios s ON s.id_servicio = os.id_servicio
GROUP BY s.id_servicio, s.tipo
ORDER BY facturado DESC;
GO

SELECT r.descripcion,
       SUM(orp.cantidad)                AS unidades,
       SUM(orp.cantidad * orp.precio)   AS facturado
FROM orden_repuesto orp
INNER JOIN repuestos r ON r.id_repuesto = orp.id_repuesto
GROUP BY r.id_repuesto, r.descripcion
HAVING SUM(orp.cantidad * orp.precio) >= 100000
ORDER BY facturado DESC;
GO

SELECT metodo_de_cobro,
       COUNT(*)   AS cobros,
       SUM(monto) AS total,
       AVG(monto) AS promedio,
       MIN(monto) AS minimo,
       MAX(monto) AS maximo
FROM cobros
GROUP BY metodo_de_cobro
ORDER BY total DESC;
GO

SELECT YEAR(fecha_cobro)  AS anio,
       MONTH(fecha_cobro) AS mes,
       COUNT(*)           AS cobros,
       SUM(monto)         AS ingresos
FROM cobros
GROUP BY YEAR(fecha_cobro), MONTH(fecha_cobro)
HAVING SUM(monto) > 300000
ORDER BY anio, mes;
GO

SELECT c.id_cliente,
       CONCAT(c.nombre, ' ', c.apellido)              AS cliente,
       COUNT(o.id_orden_trabajo)                      AS ordenes,
       SUM(dbo.fn_total_orden(o.id_orden_trabajo))    AS total_facturado
FROM cliente c
INNER JOIN vehiculos v        ON v.id_cliente = c.id_cliente
INNER JOIN orden_de_trabajo o ON o.patente = v.patente
GROUP BY c.id_cliente, c.nombre, c.apellido
HAVING SUM(dbo.fn_total_orden(o.id_orden_trabajo)) > 170000
ORDER BY total_facturado DESC;
GO

SELECT g.nombre                  AS grupo,
       COUNT(eg.id_mecanico)     AS integrantes
FROM grupos_de_trabajo g
LEFT JOIN empleados_grupos eg ON eg.id_grupo_de_trabajo = g.id_grupo_de_trabajo
GROUP BY g.id_grupo_de_trabajo, g.nombre
ORDER BY integrantes DESC, g.nombre;
GO

SELECT g.nombre                                                                AS grupo,
       COUNT(*)                                                                AS terminadas,
       AVG(CAST(DATEDIFF(DAY, o.fecha_ingreso, o.fecha_fin) AS DECIMAL(10,2))) AS dias_promedio,
       MAX(DATEDIFF(DAY, o.fecha_ingreso, o.fecha_fin))                        AS dias_maximo
FROM orden_de_trabajo o
INNER JOIN grupos_de_trabajo g ON g.id_grupo_de_trabajo = o.id_grupo_de_trabajo
WHERE o.estado = 'Terminado'
GROUP BY g.id_grupo_de_trabajo, g.nombre
ORDER BY dias_promedio DESC, g.nombre;
GO

SELECT os.id_orden_trabajo,
       s.tipo,
       os.precio            AS precio_cobrado,
       s.precio             AS precio_lista,
       s.precio - os.precio AS diferencia
FROM orden_servicio os
INNER JOIN servicios s ON s.id_servicio = os.id_servicio
WHERE os.precio <> s.precio
ORDER BY os.id_orden_trabajo;
GO

SELECT id_repuesto,
       descripcion,
       stock,
       stock_minimo,
       faltante,
       proveedor
FROM vw_stock_critico
ORDER BY faltante DESC;
GO

SELECT pr.nombre   AS proveedor,
       COUNT(*)    AS pedidos_impagos,
       SUM(sp.saldo) AS deuda
FROM vw_saldo_pedidos sp
INNER JOIN repuestos r     ON r.id_repuesto = sp.id_repuesto
INNER JOIN proveedores pr  ON pr.id_proveedor = r.id_proveedor
WHERE sp.estado_pago = 'Pendiente de pago'
GROUP BY pr.id_proveedor, pr.nombre
HAVING SUM(sp.saldo) > 0
ORDER BY deuda DESC;
GO

SELECT tipo, precio
FROM servicios
WHERE precio > (SELECT AVG(CAST(precio AS DECIMAL(12,2)))
                FROM servicios)
ORDER BY precio DESC;
GO

SELECT r.id_repuesto, r.descripcion, r.stock, r.precio
FROM repuestos r
WHERE r.id_repuesto NOT IN (SELECT orp.id_repuesto
                            FROM orden_repuesto orp)
ORDER BY r.descripcion;
GO

SELECT c.id_cliente, c.nombre, c.apellido, c.telefono
FROM cliente c
WHERE NOT EXISTS (SELECT 1
                  FROM vehiculos v
                  INNER JOIN orden_de_trabajo o ON o.patente = v.patente
                  WHERE v.id_cliente = c.id_cliente)
ORDER BY c.apellido;
GO

SELECT p.id_proveedor, p.nombre, p.telefono, p.localidad
FROM proveedores p
WHERE p.id_proveedor IN (SELECT r.id_proveedor
                         FROM repuestos r
                         WHERE r.stock < r.stock_minimo)
ORDER BY p.nombre;
GO

SELECT p.nombre AS proveedor, r.descripcion, r.precio
FROM repuestos r
INNER JOIN proveedores p ON p.id_proveedor = r.id_proveedor
WHERE r.precio = (SELECT MAX(r2.precio)
                  FROM repuestos r2
                  WHERE r2.id_proveedor = r.id_proveedor)
ORDER BY p.nombre;
GO

SELECT o.id_orden_trabajo,
       o.patente,
       o.estado,
       dbo.fn_total_orden(o.id_orden_trabajo) AS total
FROM orden_de_trabajo o
WHERE dbo.fn_total_orden(o.id_orden_trabajo) > (SELECT AVG(CAST(dbo.fn_total_orden(x.id_orden_trabajo) AS DECIMAL(12,2)))
                                                FROM orden_de_trabajo x)
ORDER BY total DESC;
GO

SELECT m.id_mecanico,
       m.nombre,
       m.apellido,
       (SELECT COUNT(*)
        FROM empleados_grupos eg
        WHERE eg.id_mecanico = m.id_mecanico) AS grupos
FROM mecanicos m
WHERE (SELECT COUNT(*)
       FROM empleados_grupos eg
       WHERE eg.id_mecanico = m.id_mecanico) > 1
ORDER BY m.apellido;
GO

SELECT t.id_cliente, t.cliente, t.total
FROM (SELECT c.id_cliente,
             CONCAT(c.nombre, ' ', c.apellido)            AS cliente,
             SUM(dbo.fn_total_orden(o.id_orden_trabajo))  AS total
      FROM cliente c
      INNER JOIN vehiculos v        ON v.id_cliente = c.id_cliente
      INNER JOIN orden_de_trabajo o ON o.patente = v.patente
      GROUP BY c.id_cliente, c.nombre, c.apellido) t
WHERE t.total > (SELECT AVG(CAST(g.total AS DECIMAL(14,2)))
                 FROM (SELECT SUM(dbo.fn_total_orden(o2.id_orden_trabajo)) AS total
                       FROM vehiculos v2
                       INNER JOIN orden_de_trabajo o2 ON o2.patente = v2.patente
                       GROUP BY v2.id_cliente) g)
ORDER BY t.total DESC;
GO

SELECT o.id_orden_trabajo,
       o.estado,
       dbo.fn_total_orden(o.id_orden_trabajo) AS total,
       dbo.fn_saldo_orden(o.id_orden_trabajo) AS saldo
FROM orden_de_trabajo o
ORDER BY o.id_orden_trabajo;
GO

SELECT id_mecanico, nombre, apellido, telefono
FROM vw_mecanicos_publico
ORDER BY apellido, nombre;
GO

SELECT id_pedido,
       estado_pedido,
       total,
       cantidad_pagos,
       pagado,
       saldo,
       estado_pago
FROM vw_saldo_pedidos
ORDER BY id_pedido;
GO

EXEC dbo.sp_control_faltantes;
GO

-- ==========================================================================
-- SECCION 09_pruebas_error
-- ==========================================================================
USE tpDatos;
GO

IF OBJECT_ID('tempdb..#resultados') IS NOT NULL DROP TABLE #resultados;

CREATE TABLE #resultados (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    prueba       VARCHAR(150) NOT NULL,
    esperado     INT NULL,
    esperado_alt INT NULL,
    obtenido     INT NULL,
    mensaje      NVARCHAR(4000) NULL
);
GO

DECLARE @prueba VARCHAR(150), @esperado INT, @alt INT;
DECLARE @c INT, @o INT, @p INT, @n INT, @txt VARCHAR(10);

SET @alt = NULL;

PRINT 'SECCION 1 - Datos invalidos y violaciones de restricciones';

SET @prueba = 'T01 Patente con formato incorrecto (RN-03)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('abc123', 'Fiat', 'Uno', 2000, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T02 Año fuera de rango (RN-04)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 1900, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T03 Vehículo sin dueño (RN-01)'; SET @esperado = 515;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 2000, NULL);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T04 Patente duplicada (clave primaria)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('AB123CD', 'Fiat', 'Uno', 2000, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T05 Vehículo con cliente inexistente (clave foránea)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 2000, 999);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T06 Borrar un cliente que tiene vehículos (RN-05)'; SET @esperado = 547;
BEGIN TRY
    DELETE FROM cliente WHERE id_cliente = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T07 Servicio con tipo repetido (RN-06)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO servicios (tipo, precio) VALUES ('Cambio de batería', 1000);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T08 Servicio con precio negativo (RN-06)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO servicios (tipo, precio) VALUES ('Servicio nuevo', -1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T09 Repuesto con precio negativo (RN-07)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO repuestos (descripcion, precio, stock, id_proveedor) VALUES ('Repuesto nuevo', -5, 1, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T10 Stock negativo (RN-07)'; SET @esperado = 547;
BEGIN TRY
    UPDATE repuestos SET stock = -1 WHERE id_repuesto = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T11 Tipo de proveedor no permitido (RN-09)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO proveedores (nombre, tipoproveedor) VALUES ('Proveedor nuevo', 'Mayorista');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T12 Proveedor con nombre repetido (RN-09)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO proveedores (nombre, tipoproveedor) VALUES ('Autopartes del Sur', 'Repuestos');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T13 Salario igual a cero (RN-14)'; SET @esperado = 547;
BEGIN TRY
    UPDATE mecanicos SET salariomensual = 0 WHERE id_mecanico = 2;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T14 Mecánico repetido en el mismo grupo (RN-12)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO empleados_grupos (id_mecanico, id_grupo_de_trabajo) VALUES (1, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T15 Grupo con nombre repetido (RN-13)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO grupos_de_trabajo (nombre) VALUES ('Motor');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T16 Repuesto sin proveedor (RN-08)'; SET @esperado = 515;
BEGIN TRY
    INSERT INTO repuestos (descripcion, precio, id_proveedor) VALUES ('Repuesto sin proveedor', 100, NULL);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T17 Estado de orden no permitido (RN-17)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente, estado) VALUES ('AB123CD', 'Cerrado');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T18 Orden En progreso sin grupo (RN-18)'; SET @esperado = 547;
BEGIN TRY
    UPDATE orden_de_trabajo SET estado = 'En progreso' WHERE id_orden_trabajo = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T19 Orden Terminado sin fecha de fin (RN-19)'; SET @esperado = 547;
BEGIN TRY
    UPDATE orden_de_trabajo SET estado = 'Terminado', id_grupo_de_trabajo = 1 WHERE id_orden_trabajo = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T20 Fecha de fin anterior al ingreso (RN-19)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente, id_grupo_de_trabajo, estado, fecha_ingreso, fecha_fin)
    VALUES ('AB123CD', 1, 'Terminado', '2026-10-10', '2026-10-01');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T21 Orden sobre un vehículo inexistente (RN-16)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente) VALUES ('ZZ000ZZ');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T22 Repuesto de orden con cantidad cero (RN-22)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_repuesto (id_orden_trabajo, id_repuesto, cantidad, precio) VALUES (5, 3, 0, 38000);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T23 Repuesto repetido en la misma orden (RN-22)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO orden_repuesto (id_orden_trabajo, id_repuesto, cantidad, precio) VALUES (5, 7, 1, 145000);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T24 Cobro con monto cero (RN-28)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro) VALUES (5, 0, 'efectivo');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T25 Cobro con método inválido (RN-28)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro) VALUES (5, 100, 'bitcoin');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T26 Cobro sin orden (RN-28)'; SET @esperado = 515;
BEGIN TRY
    INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro) VALUES (NULL, 100, 'efectivo');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T27 Pedido con cantidad cero (RN-32)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO pedidos (id_repuesto, cantidad, precio_unidad) VALUES (1, 0, 100);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T28 Pedido con estado no permitido (RN-32)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO pedidos (id_repuesto, cantidad, precio_unidad, estado) VALUES (1, 1, 100, 'Archivado');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T29 Pago con método inválido (RN-36)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO pagos (id_pedido, monto, metodo_de_pago) VALUES (7, 1000, 'tarjeta');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T30 Pago con monto negativo (RN-36)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO pagos (id_pedido, monto, metodo_de_pago) VALUES (7, -5, 'efectivo');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T31 Texto en una columna numérica'; SET @esperado = 245; SET @txt = 'abc';
BEGIN TRY
    INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro) VALUES (5, @txt, 'efectivo');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T32 Texto más largo que la columna'; SET @esperado = 2628; SET @alt = 8152;
BEGIN TRY
    INSERT INTO cliente (nombre, apellido) VALUES (REPLICATE('A', 40), 'Largo');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @alt = NULL;

PRINT 'SECCION 2 - Parametros incorrectos y registros inexistentes en procedimientos';

SET @prueba = 'P01 Alta de cliente sin nombre'; SET @esperado = 50001; SET @c = NULL;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @apellido = 'Solo', @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P02 Agregar vehículo a un cliente inexistente'; SET @esperado = 50002; SET @c = 999;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @patente = 'ZZ111AA', @marca = 'Fiat', @modelo = 'Uno', @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P03 Cliente existente sin patente'; SET @esperado = 50003; SET @c = 1;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P04 Vehículo sin marca ni modelo'; SET @esperado = 50004; SET @c = NULL;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @nombre = 'Ana', @apellido = 'Lopez', @patente = 'ZZ111AA', @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P05 Alta con patente ya registrada (en minúscula)'; SET @esperado = 50005; SET @c = NULL;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @nombre = 'Ana', @apellido = 'Lopez', @patente = 'ab123cd', @marca = 'Fiat', @modelo = 'Uno', @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P06 Alta con patente de formato inválido'; SET @esperado = 547; SET @c = NULL;
BEGIN TRY
    EXEC dbo.sp_alta_cliente_vehiculo @nombre = 'Huerfano', @apellido = 'Prueba', @patente = 'XX1', @marca = 'Fiat', @modelo = 'Uno', @id_cliente = @c OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'P06b El rollback no dejó al cliente creado sin vehículo', 0, NULL, COUNT(*)
FROM cliente WHERE nombre = 'Huerfano';

SET @prueba = 'P07 Abrir orden con patente inexistente'; SET @esperado = 50011; SET @o = NULL;
BEGIN TRY
    EXEC dbo.sp_abrir_orden @patente = 'NOEXISTE', @id_orden = @o OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P08 Abrir orden sin patente'; SET @esperado = 50010; SET @o = NULL;
BEGIN TRY
    EXEC dbo.sp_abrir_orden @patente = NULL, @id_orden = @o OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P09 Agregar servicio a una orden inexistente'; SET @esperado = 50012;
BEGIN TRY
    EXEC dbo.sp_agregar_servicio @id_orden = 999, @id_servicio = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P10 Agregar un servicio inexistente'; SET @esperado = 50013;
BEGIN TRY
    EXEC dbo.sp_agregar_servicio @id_orden = 5, @id_servicio = 999;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P11 Agregar un servicio ya incluido (RN-21)'; SET @esperado = 50014;
BEGIN TRY
    EXEC dbo.sp_agregar_servicio @id_orden = 5, @id_servicio = 11;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P12 Agregar un repuesto inexistente'; SET @esperado = 50015;
BEGIN TRY
    EXEC dbo.sp_agregar_repuesto @id_orden = 5, @id_repuesto = 999, @cantidad = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P13 Agregar un repuesto con cantidad negativa'; SET @esperado = 50016;
BEGIN TRY
    EXEC dbo.sp_agregar_repuesto @id_orden = 5, @id_repuesto = 3, @cantidad = -1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P14 Agregar un repuesto ya incluido (RN-22)'; SET @esperado = 50017;
BEGIN TRY
    EXEC dbo.sp_agregar_repuesto @id_orden = 5, @id_repuesto = 7, @cantidad = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P15 Iniciar una orden que ya está En progreso'; SET @esperado = 50019;
BEGIN TRY
    EXEC dbo.sp_iniciar_orden @id_orden = 4, @id_grupo = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P16 Iniciar una orden con un grupo inexistente'; SET @esperado = 50018;
BEGIN TRY
    EXEC dbo.sp_iniciar_orden @id_orden = 5, @id_grupo = 999;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P17 Cerrar una orden que sigue Pendiente (RN-20)'; SET @esperado = 50020;
BEGIN TRY
    EXEC dbo.sp_cerrar_orden @id_orden = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

EXEC dbo.sp_abrir_orden @patente = 'AH567QR', @id_orden = @o OUTPUT;
EXEC dbo.sp_iniciar_orden @id_orden = @o, @id_grupo = 1;

SET @prueba = 'P18 Cerrar una orden sin servicios (RN-25)'; SET @esperado = 50021;
BEGIN TRY
    EXEC dbo.sp_cerrar_orden @id_orden = @o;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P19 Cobro con monto cero'; SET @esperado = 50022;
BEGIN TRY
    EXEC dbo.sp_registrar_cobro @id_orden = 5, @monto = 0, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P20 Cobro mayor al saldo de la orden (RN-30)'; SET @esperado = 50033;
BEGIN TRY
    EXEC dbo.sp_registrar_cobro @id_orden = 6, @monto = 1, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P21 Cobro sobre una orden inexistente'; SET @esperado = 50012;
BEGIN TRY
    EXEC dbo.sp_registrar_cobro @id_orden = 999, @monto = 100, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P22 Cobro con método inválido desde el procedimiento'; SET @esperado = 547;
BEGIN TRY
    EXEC dbo.sp_registrar_cobro @id_orden = 5, @monto = 100, @metodo = 'bitcoin';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P23 Pedido de un repuesto inexistente'; SET @esperado = 50015; SET @p = NULL;
BEGIN TRY
    EXEC dbo.sp_crear_pedido @id_repuesto = 999, @cantidad = 1, @precio_unidad = 100, @id_pedido = @p OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P24 Pedido con cantidad cero'; SET @esperado = 50016; SET @p = NULL;
BEGIN TRY
    EXEC dbo.sp_crear_pedido @id_repuesto = 1, @cantidad = 0, @precio_unidad = 100, @id_pedido = @p OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P25 Pedido con costo unitario negativo (RN-32)'; SET @esperado = 50025; SET @p = NULL;
BEGIN TRY
    EXEC dbo.sp_crear_pedido @id_repuesto = 1, @cantidad = 1, @precio_unidad = -1, @id_pedido = @p OUTPUT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P26 Recibir un pedido ya Recibido (RN-34)'; SET @esperado = 50027;
BEGIN TRY
    EXEC dbo.sp_recibir_pedido @id_pedido = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P27 Recibir un pedido Cancelado (RN-35)'; SET @esperado = 50027;
BEGIN TRY
    EXEC dbo.sp_recibir_pedido @id_pedido = 13;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P28 Recibir un pedido inexistente'; SET @esperado = 50026;
BEGIN TRY
    EXEC dbo.sp_recibir_pedido @id_pedido = 999;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P29 Cancelar un pedido que ya tiene pagos'; SET @esperado = 50029;
BEGIN TRY
    EXEC dbo.sp_cancelar_pedido @id_pedido = 11;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P30 Cancelar un pedido ya Recibido'; SET @esperado = 50027;
BEGIN TRY
    EXEC dbo.sp_cancelar_pedido @id_pedido = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P31 Pagar un pedido Cancelado (RN-35)'; SET @esperado = 50035;
BEGIN TRY
    EXEC dbo.sp_registrar_pago @id_pedido = 13, @monto = 1000, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P32 Pago mayor al saldo del pedido (RN-37)'; SET @esperado = 50034;
BEGIN TRY
    EXEC dbo.sp_registrar_pago @id_pedido = 1, @monto = 1, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P33 Pago sobre un pedido inexistente'; SET @esperado = 50026;
BEGIN TRY
    EXEC dbo.sp_registrar_pago @id_pedido = 999, @monto = 100, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'P34 Pago con monto cero'; SET @esperado = 50022;
BEGIN TRY
    EXEC dbo.sp_registrar_pago @id_pedido = 7, @monto = 0, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

PRINT 'SECCION 3 - Operaciones no permitidas y errores durante transacciones (triggers)';

SET @prueba = 'R01 Saltear un estado: Pendiente a Terminado (RN-20)'; SET @esperado = 50030;
BEGIN TRY
    UPDATE orden_de_trabajo SET id_grupo_de_trabajo = 1, estado = 'Terminado', fecha_fin = '2026-11-01' WHERE id_orden_trabajo = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R02 Retroceder un estado: Terminado a En progreso (RN-20)'; SET @esperado = 50030;
BEGIN TRY
    UPDATE orden_de_trabajo SET estado = 'En progreso', fecha_fin = NULL WHERE id_orden_trabajo = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R03 Agregar un servicio a una orden Terminado (RN-24)'; SET @esperado = 50032;
BEGIN TRY
    INSERT INTO orden_servicio (id_orden_trabajo, id_servicio, precio) VALUES (1, 2, 60000);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R04 Quitar repuestos de una orden Terminado (RN-24)'; SET @esperado = 50032;
BEGIN TRY
    DELETE FROM orden_repuesto WHERE id_orden_trabajo = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R05 Iniciar una orden sin stock suficiente (RN-23)'; SET @esperado = 50031;
BEGIN TRY
    EXEC dbo.sp_iniciar_orden @id_orden = 11, @id_grupo = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R06 Agregar a una orden En progreso un repuesto sin stock (RN-23)'; SET @esperado = 50031;
BEGIN TRY
    EXEC dbo.sp_agregar_repuesto @id_orden = 4, @id_repuesto = 9, @cantidad = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R07 Modificar un repuesto de una orden En progreso'; SET @esperado = 50036;
BEGIN TRY
    UPDATE orden_repuesto SET cantidad = 3 WHERE id_orden_trabajo = 4 AND id_repuesto = 6;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'R08 Volver a Pendiente un pedido Recibido (RN-34)'; SET @esperado = 50037;
BEGIN TRY
    UPDATE pedidos SET estado = 'Pendiente' WHERE id_pedido = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'R09 Tras los rechazos el stock no cambió (filtro de aire)', 32, NULL, stock
FROM repuestos WHERE id_repuesto = 8;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'R10 Tras el rechazo la orden 11 sigue Pendiente', 1, NULL, COUNT(*)
FROM orden_de_trabajo WHERE id_orden_trabajo = 11 AND estado = 'Pendiente';

PRINT 'SECCION 4 - Flujo completo sin errores';

EXEC dbo.sp_alta_cliente_vehiculo @nombre = 'Prueba', @apellido = 'Integral', @telefono = '11 0000-0000',
     @patente = 'zz111aa', @marca = 'Fiat', @modelo = 'Uno', @anio = 2001, @id_cliente = @c OUTPUT;
EXEC dbo.sp_abrir_orden @patente = 'ZZ111AA', @id_orden = @o OUTPUT;
EXEC dbo.sp_agregar_servicio @id_orden = @o, @id_servicio = 1;
EXEC dbo.sp_agregar_repuesto @id_orden = @o, @id_repuesto = 1, @cantidad = 2;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H01 Patente guardada en mayúsculas', 1, NULL, COUNT(*) FROM vehiculos WHERE patente = 'ZZ111AA';

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H02 Orden Pendiente no descuenta stock (filtro de aceite)', 40, NULL, stock FROM repuestos WHERE id_repuesto = 1;

EXEC dbo.sp_iniciar_orden @id_orden = @o, @id_grupo = 1;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H03 Al iniciar la orden se descuenta el stock', 38, NULL, stock FROM repuestos WHERE id_repuesto = 1;

EXEC dbo.sp_agregar_repuesto @id_orden = @o, @id_repuesto = 2, @cantidad = 1;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H04 Repuesto agregado En progreso descuenta stock (aceite)', 24, NULL, stock FROM repuestos WHERE id_repuesto = 2;

EXEC dbo.sp_cerrar_orden @id_orden = @o;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H05 Orden Terminado con fecha de fin', 1, NULL, COUNT(*)
FROM orden_de_trabajo WHERE id_orden_trabajo = @o AND estado = 'Terminado' AND fecha_fin IS NOT NULL;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H06 Total de la orden (85000 + 2 x 12500 + 48000)', 158000, NULL, dbo.fn_total_orden(@o);

EXEC dbo.sp_registrar_cobro @id_orden = @o, @monto = 50000, @metodo = 'efectivo';

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H07 Saldo tras un anticipo de 50000', 108000, NULL, dbo.fn_saldo_orden(@o);

EXEC dbo.sp_registrar_cobro @id_orden = @o, @monto = 108000, @metodo = 'transferencia';

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H08 Saldo tras cobrar el resto', 0, NULL, dbo.fn_saldo_orden(@o);

SET @prueba = 'H09 Cobrar de más una orden saldada (RN-30)'; SET @esperado = 50033;
BEGIN TRY
    EXEC dbo.sp_registrar_cobro @id_orden = @o, @monto = 1, @metodo = 'efectivo';
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'H10 Modificar la orden recién cerrada (RN-24)'; SET @esperado = 50032;
BEGIN TRY
    EXEC dbo.sp_agregar_servicio @id_orden = @o, @id_servicio = 2;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

EXEC dbo.sp_crear_pedido @id_repuesto = 9, @cantidad = 10, @precio_unidad = 20000, @id_pedido = @p OUTPUT;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H11 Pedido nuevo queda Pendiente y no suma stock (bujías)', 0, NULL, stock FROM repuestos WHERE id_repuesto = 9;

EXEC dbo.sp_recibir_pedido @id_pedido = @p;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H12 Al recibir el pedido el stock sube (bujías)', 10, NULL, stock FROM repuestos WHERE id_repuesto = 9;

EXEC dbo.sp_registrar_pago @id_pedido = @p, @monto = 100000, @metodo = 'transferencia';
EXEC dbo.sp_registrar_pago @id_pedido = @p, @monto = 100000, @metodo = 'cheque';

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H13 Pedido pagado en dos pagos queda Pagado', 1, NULL, COUNT(*)
FROM vw_saldo_pedidos WHERE id_pedido = @p AND estado_pago = 'Pagado' AND saldo = 0 AND cantidad_pagos = 2;

UPDATE servicios SET precio = precio + 1000 WHERE id_servicio = 1;
UPDATE servicios SET precio = precio - 1000 WHERE id_servicio = 1;
UPDATE repuestos SET precio = precio + 500 WHERE id_repuesto = 1;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H14 Cambios de precio auditados (2 de servicio + 1 de repuesto)', 3, NULL, COUNT(*)
FROM auditoria_precios WHERE (tabla_origen = 'servicios' AND id_registro = 1) OR (tabla_origen = 'repuestos' AND id_registro = 1);

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'H15 Precio guardado en la orden no cambia con el precio de lista', 85000, NULL, precio
FROM orden_servicio WHERE id_orden_trabajo = @o AND id_servicio = 1;

PRINT 'SECCION 5 - Seguridad: usuarios, roles y permisos';

SET @alt = 230;

SET @prueba = 'S01 Recepción intenta leer salarios (RN-15)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    SELECT @n = COUNT(salariomensual) FROM mecanicos;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S02 Compras intenta leer salarios (RN-15)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_compras';
    SELECT @n = COUNT(salariomensual) FROM mecanicos;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S03 Mecánico intenta leer salarios (RN-15)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_mecanico';
    SELECT @n = COUNT(salariomensual) FROM mecanicos;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S04 Auditor intenta leer salarios (RN-15)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_auditor';
    SELECT @n = COUNT(salariomensual) FROM mecanicos;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S05 Administrador sí lee salarios (RN-15)'; SET @esperado = 0; SET @alt = NULL;
BEGIN TRY
    EXECUTE AS USER = 'usr_admin';
    SELECT @n = COUNT(salariomensual) FROM mecanicos;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S06 Recepción lee mecánicos por la vista sin salario'; SET @esperado = 0;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    SELECT @n = COUNT(*) FROM vw_mecanicos_publico;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @alt = NULL;

SET @prueba = 'S07 Recepción no inserta directo en cliente (RN-39)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    INSERT INTO cliente (nombre, apellido) VALUES ('Directo', 'Prohibido');
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S08 Recepción abre una orden mediante el procedimiento (RN-39)'; SET @esperado = 0; SET @o = NULL;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    EXEC dbo.sp_abrir_orden @patente = 'AB123CD', @id_orden = @o OUTPUT;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S09 Recepción no modifica precios de servicios'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    UPDATE servicios SET precio = 1 WHERE id_servicio = 1;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S10 Recepción no registra pagos a proveedores'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_recepcion';
    EXEC dbo.sp_registrar_pago @id_pedido = 7, @monto = 1000, @metodo = 'efectivo';
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S11 Compras no ve clientes'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_compras';
    SELECT @n = COUNT(*) FROM cliente;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S12 Compras no modifica el stock directamente (RN-39)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_compras';
    UPDATE repuestos SET stock = 999 WHERE id_repuesto = 1;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S13 Compras crea un pedido mediante el procedimiento'; SET @esperado = 0; SET @p = NULL;
BEGIN TRY
    EXECUTE AS USER = 'usr_compras';
    EXEC dbo.sp_crear_pedido @id_repuesto = 1, @cantidad = 5, @precio_unidad = 12000, @id_pedido = @p OUTPUT;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S14 Compras no cierra órdenes de trabajo'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_compras';
    EXEC dbo.sp_cerrar_orden @id_orden = 4;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S15 Mecánico lee órdenes de trabajo'; SET @esperado = 0;
BEGIN TRY
    EXECUTE AS USER = 'usr_mecanico';
    SELECT @n = COUNT(*) FROM orden_de_trabajo;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S16 Mecánico no ve cobros'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_mecanico';
    SELECT @n = COUNT(*) FROM cobros;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S17 Mecánico no cierra órdenes de trabajo'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_mecanico';
    EXEC dbo.sp_cerrar_orden @id_orden = 4;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S18 Auditor consulta cobros'; SET @esperado = 0;
BEGIN TRY
    EXECUTE AS USER = 'usr_auditor';
    SELECT @n = COUNT(*) FROM cobros;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S19 Auditor no borra cobros'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_auditor';
    DELETE FROM cobros WHERE id_cobro = 1;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S20 Auditor no ejecuta procedimientos'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_auditor';
    EXEC dbo.sp_control_faltantes;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S21 Ni el administrador modifica la auditoría de precios (RN-11)'; SET @esperado = 229;
BEGIN TRY
    EXECUTE AS USER = 'usr_admin';
    UPDATE auditoria_precios SET usuario = 'otro';
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'S22 Administrador cambia un precio y queda auditado con su usuario'; SET @esperado = 0;
BEGIN TRY
    EXECUTE AS USER = 'usr_admin';
    UPDATE servicios SET precio = precio + 1 WHERE id_servicio = 2;
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido)
SELECT 'S23 La auditoría registró al usuario lg_admin', 1, NULL, COUNT(*)
FROM auditoria_precios WHERE usuario = 'lg_admin' AND tabla_origen = 'servicios' AND id_registro = 2;

SELECT id, prueba, esperado, esperado_alt, obtenido,
       CASE WHEN obtenido IN (esperado, esperado_alt) THEN 'OK' ELSE 'FALLO' END AS resultado,
       mensaje
FROM #resultados
ORDER BY id;

SELECT CASE WHEN obtenido IN (esperado, esperado_alt) THEN 'OK' ELSE 'FALLO' END AS resultado,
       COUNT(*) AS cantidad
FROM #resultados
GROUP BY CASE WHEN obtenido IN (esperado, esperado_alt) THEN 'OK' ELSE 'FALLO' END;
GO