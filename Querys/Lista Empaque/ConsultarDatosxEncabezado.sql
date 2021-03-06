USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[ConsultarDatosxEncabezado]    Script Date: 2021/06/08 11:01:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ConsultarDatosxEncabezado 302918
ALTER PROCEDURE [dbo].[ConsultarDatosxEncabezado]
@IdEncMvtoRollos INT
AS
BEGIN
	SELECT DISTINCT TMovimientoRollos_Enc.IdEncMvtoRollos, NULL NroProgramacion, 0 tipoMovimiento 
	FROM TMovimientoRollos_Enc
	INNER JOIN TMovimientosRollos ON TMovimientoRollos_Enc.IdEncMvtoRollos = TMovimientosRollos.IdEncMvtoRollos
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @IdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 1 
	UNION ALL

	SELECT DISTINCT TMovimientoRollos_Enc.IdEncMvtoRollos, NULL NroProgramacion, 0 tipoMovimiento 
	FROM TMovimientoRollos_Enc
	INNER JOIN TMovimientosRollos ON TMovimientoRollos_Enc.IdEncMvtoRollos = TMovimientosRollos.IdEncMvtoRollos
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @IdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento = 41 

	UNION ALL

	SELECT DISTINCT TMovimientoRollos_Enc.IdEncMvtoRollos, TProgramacionExtendida.NroProgramacion, CASE TMovimientoRollos_Enc.CodigoTipoMovimiento WHEN 3 THEN 2 ELSE 1 END tipoMovimiento 
	FROM TMovimientoRollos_Enc
	INNER JOIN TMovimientosRollos ON TMovimientoRollos_Enc.IdEncMvtoRollos = TMovimientosRollos.IdEncMvtoRollos
	INNER JOIN TDetalleProgExtendida ON TDetalleProgExtendida.IDRollo = TMovimientosRollos.IDRollo 
	INNER JOIN TProgramacionExtendida ON TProgramacionExtendida.NroProgramacion = TDetalleProgExtendida.NroProgramacion
	INNER JOIN TProgramacionTrazos ON TProgramacionTrazos.IDTrazo = TDetalleProgExtendida.IDTrazo AND CONVERT(INT,TMovimientoRollos_Enc.Trazo) = TProgramacionTrazos.NroTrazo
	WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @IdEncMvtoRollos
	AND TMovimientoRollos_Enc.CodigoTipoMovimiento in(3,19) 
	ORDER BY 1 DESC
END