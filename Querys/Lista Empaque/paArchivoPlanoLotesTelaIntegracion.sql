USE [Sici]
GO
/****** Object:  StoredProcedure [DLL002].[paArchivoPlanoLotesTelaIntegracion]    Script Date: 2021/06/03 4:05:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
  --==========================
  --Autor : srodas
  --Fecha Modificacion: 1/29/2021
  --Descripción: Procedimiento que me trae la informacion del plano de lotes telas
  --===========================


-- DLL002.paArchivoPlanoLotesTelaIntegracion 52237

ALTER PROCEDURE [DLL002].[paArchivoPlanoLotesTelaIntegracion] 
    @intIdListaEmpaque INT
AS
BEGIN
	SELECT --ROW_NUMBER() OVER (PARTITION BY te.IDListaEmpaque ORDER BY te.IDListaEmpaque, tr.IDROLLO) AS F_NUMERO_REG,
	   tr.UPC AS f403_id
	   ,tr.CodigoTela AS f403_id_item
	   , CONVERT(VARCHAR(8), GETDATE(),112) AS f403_fecha_creacion
	   , CONVERT(VARCHAR(8),GETDATE(),112) AS f403_fecha_vcto
	   , tr.NroRolloProv AS f403_lote_prov
	   , toc.NitProveedor AS f403_id_tercero_prov
	   , toc.Sucursal AS f403_id_sucursal_prov
	   , toc.NombreProveedor AS f403_fabricante
	   , tr.NroRollo f403_num_lote_fabricante
	   , ti.NroImportacion f403_notas
	FROM ControlTelas.dbo.TListaEmpaque te
	INNER JOIN ControlTelas.dbo.TRollos tr ON te.IDListaEmpaque = tr.IDListaEmpaque
	INNER JOIN ControlTelas.dbo.TImportacion ti ON ti.CodigoImportacion = tr.NroImportacion 
	LEFT JOIN ControlTelas.[dbo].[fnOrdenCompraSiesa](NULL, null) toc on toc.Numero_documento = TR.NroOrdenCompra
	WHERE te.IDListaEmpaque = @intIdListaEmpaque
	ORDER BY te.IDListaEmpaque, tr.IDROLLO
END