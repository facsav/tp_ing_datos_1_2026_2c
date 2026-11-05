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