USE [Sici]
GO
/****** Object:  StoredProcedure [DLL002].[paArchivoPlanoEnsambleLotes]    Script Date: 2021/06/08 10:24:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- DLL002.paArchivoPlanoEnsambleLotes '',0,302918

ALTER PROCEDURE [DLL002].[]
@NroProgramacion VARCHAR(10),
@intTipoDocumento INT,
@intIdEncMvtoRollos INT
AS
BEGIN
	/*Movimiento de salida*/
	SELECT   tmb.f150_id										AS f470_id_bodega
			, tme.Ubicacion										AS f470_id_ubicación_aux
			, tme.LoteImpo										AS f470_id_lote
			, '01'												AS f470_id_motivo
			, vTTelas.Unidad									AS f470_id_unidad_medida
			, SUM(tmr.Cantidad)									AS f470_cant_base
			, vTTelas.Item										AS f470_id_item
	INTO #tblDetalle
	FROM ControlTelas.dbo.TMovimientosRollos tmr
	INNER JOIN ControlTelas.dbo.TMovimientoRollos_Enc tme					ON tme.IdEncMvtoRollos = tmr.IdEncMvtoRollos
	INNER JOIN ControlTelas.dbo.TRollos TRollos				ON TRollos.IDRollo = tmr.IDRollo
	INNER JOIN ControlTelas.dbo.TImportacion TImportacion	ON TImportacion.CodigoImportacion = TRollos.NroImportacion
	INNER JOIN ControlTelas.dbo.TListaEmpaque TListaEmpaque ON TListaEmpaque.IDListaEmpaque = TRollos.IDListaEmpaque
	INNER JOIN UnoEE_Piloto.dbo.t150_mc_bodegas AS tmb		ON tmb.f150_rowid = tme.Bodega
	INNER JOIN GCT008.vTTelas vTTelas ON vTTelas.Item = TRollos.CodigoTela
	WHERE tmr.IdEncMvtoRollos = @intIdEncMvtoRollos
	GROUP BY tmb.f150_id										
			, tme.Ubicacion										
			, tme.LoteImpo										
			, vTTelas.Unidad									
			, vTTelas.Item		
			
	UNION ALL 
	/*Movimiento de entrada*/
	SELECT   tmb.f150_id										AS f470_id_bodega
			, TRollos.idUbicacion								AS f470_id_ubicación_aux
			, TRollos.UPC										AS f470_id_lote
			, '02'
			, vTTelas.Unidad									AS f470_id_unidad_medida
			, SUM(tmr.Cantidad)									AS f470_cant_base
			, vTTelas.Item										AS f470_id_item
	FROM ControlTelas.dbo.TMovimientosRollos tmr
	INNER JOIN ControlTelas.dbo.TMovimientoRollos_Enc tme					ON tme.IdEncMvtoRollos = tmr.IdEncMvtoRollos
	INNER JOIN ControlTelas.dbo.TRollos TRollos				ON TRollos.IDRollo = tmr.IDRollo
	INNER JOIN ControlTelas.dbo.TImportacion TImportacion	ON TImportacion.CodigoImportacion = TRollos.NroImportacion
	INNER JOIN ControlTelas.dbo.TListaEmpaque TListaEmpaque ON TListaEmpaque.IDListaEmpaque = TRollos.IDListaEmpaque
	INNER JOIN UnoEE_Piloto.dbo.t150_mc_bodegas AS tmb		ON tmb.f150_rowid = TListaEmpaque.idBodega
	INNER JOIN GCT008.vTTelas vTTelas ON vTTelas.Item = TRollos.CodigoTela
	WHERE tmr.IdEncMvtoRollos = @intIdEncMvtoRollos
	GROUP BY tmb.f150_id										
			, TRollos.idUbicacion								
			, TRollos.UPC										
			, vTTelas.Unidad									
			, vTTelas.Item

	--select * from #tblDetalle

	/*Validacion de existencia de lotes en Siesa*/
	IF EXISTS(SELECT top(1) f470_id_lote FROM #tblDetalle
	LEFT JOIN [UnoEE_Piloto].[dbo].[t403_cm_lotes] ON #tblDetalle.f470_id_lote = f403_id
	WHERE f403_id IS NULL)
	BEGIN 
		SELECT CONCAT('El lote: ',f470_id_lote, ' no existe en SIESA') Mensaje
		FROM #tblDetalle
		LEFT JOIN [UnoEE_Piloto].[dbo].[t403_cm_lotes] ON #tblDetalle.f470_id_lote = f403_id
		WHERE f403_id IS NULL
	    RETURN 
	END

	/*Encabezado*/
	SELECT  1											AS f350_consec_docto
			,CONVERT(VARCHAR,GETDATE(),112)				AS f350_fecha
			,CONCAT('ENSAMBLE-',@intIdEncMvtoRollos)	AS f350_notas

	/*Movimiento*/
	SELECT 1																		AS f470_consec_docto
			, ROW_NUMBER() OVER(ORDER BY f470_id_motivo,f470_id_item,f470_id_lote)  AS f470_nro_registro
			, f470_id_bodega														AS f470_id_bodega
			, f470_id_ubicación_aux													AS f470_id_ubicación_aux
			, f470_id_lote															AS f470_id_lote
			, f470_id_motivo
			, f470_id_unidad_medida
			, f470_cant_base
			, f470_id_item
	FROM #tblDetalle

END