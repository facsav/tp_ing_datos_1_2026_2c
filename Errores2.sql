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
