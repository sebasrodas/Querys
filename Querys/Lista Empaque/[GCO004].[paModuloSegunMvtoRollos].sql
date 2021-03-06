USE [Sici]
GO
/****** Object:  StoredProcedure [GCO004].[paModuloSegunMvtoRollos]    Script Date: 2021/06/03 2:08:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * acorrea;02/16/2021;
 * 
Exec GCO004.paModuloSegunMvtoRollos 285490
Exec GCO004.paModuloSegunMvtoRollos 285489
Exec GCO004.paModuloSegunMvtoRollos 285468
Exec GCO004.paModuloSegunMvtoRollos 0

285490
285489
 */
ALTER PROCEDURE [GCO004].[paModuloSegunMvtoRollos]	
@intIdEncMvtoRollos INT 
AS
BEGIN
	DECLARE @intModulo INT = 0, @varlbEsperaText VARCHAR(200) = ''
	
	IF EXISTS(SELECT TOP 1 1
	FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
	INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 1)
	BEGIN
		Select @intModulo = 25, @varlbEsperaText = 'Procesando Documento Entrada Rollos' 	
	END

	IF EXISTS(SELECT TOP 1 1
	FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
	INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 41)
	BEGIN
		Select @intModulo = 42, @varlbEsperaText = 'Procesando Documento Entrada Rollos por ensamble' 	
	END
	
	IF EXISTS(SELECT TOP 1 1
	FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
	INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 3)
	BEGIN
		Select @intModulo = 24, @varlbEsperaText = CONCAT('Procesando Documento ',case when TTipoMovimientos.Codigo = 3 then 'SALIDA' else TTipoMovimientos.TipoMovimiento END)
		FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
		INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
		WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
		AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 3	
	END

	IF EXISTS(SELECT TOP 1 1
	FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
	INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 19)
	BEGIN
		Select @intModulo = 24, @varlbEsperaText = CONCAT('Procesando Documento ', TTipoMovimientos.TipoMovimiento)
		FROM ControlTelas.dbo.TMovimientoRollos_Enc TMovimientoRollos_Enc
		INNER JOIN ControlTelas.dbo.TTipoMovimientos TTipoMovimientos ON TTipoMovimientos.Codigo = TMovimientoRollos_Enc.CodigoTipoMovimiento
		WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncMvtoRollos
		AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 19	
	END
	
	SELECT @intModulo Modulo, @varlbEsperaText lbEsperaText
END
 
