CREATE PROCEDURE DLL002.paArchivoPlanoRollosDevolucionMP
@NroProgramacion NUMERIC,
@intTipoDocumento INT,
@intIdEncabezadoDocumento INT
AS
BEGIN
	DECLARE  @varTipoDocumento VARCHAR(3) = 'MDC'--Devolucion
			 ,@varMotivo VARCHAR(2) = '05'

	SELECT  ISNULL(f850_id_tipo_docto,'')				AS f850_id_tipo_docto_op
			, ISNULL(f850_consec_docto,0)				AS f850_consec_docto_op
			, f150_id									AS f470_id_bodega
			, f470_id_ubicacion_aux						AS f470_id_ubicacion_aux
			, t350_co_docto_contable.f350_id_tipo_docto AS f350_id_tipo_docto_consumo
			, t350_co_docto_contable.f350_consec_docto	AS f350_consec_docto_consumo
			, v121_comp.v121_id_item					AS f470_id_item_comp
			, v121_comp.v121_id_unidad_inventario		AS f470_id_unidad_medida
			, f470_id_lote								AS f470_id_lote
			, TMovimientoRollos_Enc.IdEncMvtoRollos		AS IdEncMvtoRollos
			, @varMotivo								AS f470_id_motivo
			, TMovimientosRollos.Cantidad				AS f470_cant_base
			, '01'										AS f470_id_un_movto
			, @varTipoDocumento							AS f470_id_tipo_docto
	INTO #tmpRollos
	from ControlTelas.dbo.TMovimientoRollos_Enc 
		INNER	   JOIN ControlTelas.dbo.TMovimientosRollos ON TMovimientoRollos_Enc.IdEncMvtoRollos = TMovimientosRollos.IdEncMvtoRollos
		INNER	   JOIN ControlTelas.dbo.TRollos ON TMovimientosRollos.IDRollo = TRollos.IDRollo
		INNER	   JOIN Sici.dbo.Tbl_Contratos ON TMovimientoRollos_Enc.Contrato = Tbl_Contratos.Contrato
		INNER      JOIN PPR005.tblOPsEnFirme tof ON Tbl_Contratos.f850_rowid =tof.f850_rowid_Padre
		LEFT       JOIN UnoEE_Piloto.dbo.t850_mf_op_docto ON t850_mf_op_docto.f850_rowid = tof.f850_rowid_Hijo 
		LEFT       JOIN UnoEE_Piloto.dbo.t470_cm_movto_invent ON t850_mf_op_docto.f850_rowid = f470_rowid_op_docto AND t470_cm_movto_invent.f470_id_lote = TRollos.UPC
		LEFT	   JOIN UnoEE_Piloto.dbo.t350_co_docto_contable on f350_rowid = f470_rowid_docto
		LEFT	   JOIN UnoEE_Piloto.dbo.t150_mc_bodegas on f150_rowid = f470_rowid_bodega
		LEFT	   JOIN UnoEE_Piloto.dbo.v121 v121_comp on v121_comp.v121_rowid_item_ext = f470_rowid_item_ext AND TRollos.CodigoTela = v121_comp.v121_id_item
	where TMovimientoRollos_Enc.IdEncMvtoRollos = @intIdEncabezadoDocumento AND t850_mf_op_docto.f850_id_tipo_docto = 'MPC' AND ISNULL(TMovimientoRollos_Enc.TrasmitidoSiesa,0) = 0


	IF	NOT EXISTS(SELECT IdEncMvtoRollos FROM #tmpRollos)
	BEGIN
		SELECT  'Alerta!!! No se encontraron devolucionones pendientes por subir a Siesa.' AS Mensaje 
		RETURN  
	END

	IF EXISTS(	SELECT TOP 1 1 FROM  UnoEE_Piloto.dbo.t350_co_docto_contable WHERE RTRIM(f350_Notas) = CONCAT('DEVOLUCION TELA:',@intIdEncabezadoDocumento))
	BEGIN 
		     SELECT  'Alerta!!! El registro que trata de subir a siesa ya existe. Por favor verifique la información. ' Mensaje 
   		     RETURN 
	END 

	--ENCABEZADO
	SELECT DISTINCT  f470_id_tipo_docto								AS f350_id_tipo_docto
					,IdEncMvtoRollos								AS f350_consec_docto
					,CONVERT(VARCHAR(8), GETDATE(),112)				AS f350_id_fecha
					,CONCAT('DEVOLUCION TELA:',IdEncMvtoRollos)		AS f350_notas
					,@varMotivo										AS f350_id_motivo
					,f850_id_tipo_docto_op							AS f850_tipo_docto
                    ,f850_consec_docto_op							AS f850_consec_docto
     FROM   #tmpRollos

	--DETALLE
	SELECT  f470_id_tipo_docto
			,IdEncMvtoRollos
			,ROW_NUMBER() OVER(ORDER BY IdEncMvtoRollos, f470_id_item_comp) f470_nro_registro
			,f350_id_tipo_docto_consumo AS f850_tipo_docto_consumo
			,f350_consec_docto_consumo AS f850_consec_docto_consumo
			,f470_id_item_comp
			,f470_id_bodega
			,f470_id_ubicacion_aux
			,f470_id_lote
			,f470_id_motivo
			,f470_id_un_movto
			,f470_id_unidad_medida
			,f470_cant_base
			,'' AS f470_notas
	FROM #tmpRollos

	DROP TABLE #tmpRollos

END