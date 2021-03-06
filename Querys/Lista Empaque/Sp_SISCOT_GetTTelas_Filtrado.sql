USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[Sp_SISCOT_GetTTelas_Filtrado]    Script Date: 2021/06/02 2:55:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<PZAPATA>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

-- Sp_SISCOT_GetTTelas_Filtrado '12/6/2014 12:00:00 AM', '3/6/2015 12:00:00 AM'
-- Sp_SISCOT_GetTTelas_Filtrado '8/16/2020 12:00:00 AM', '2/12/2021 12:00:00 AM'

ALTER PROCEDURE [dbo].[Sp_SISCOT_GetTTelas_Filtrado] 
@FechaInicial DATETIME
, @FechaFinal DATETIME

AS
BEGIN
DECLARE @FirstTable TABLE (CodigoTela NUMERIC(18,0),AnchoUtilReal DECIMAL(18,1))


SELECT TTelasCrudaTransformada.CodigoTelaTransformada,
       TTelas.Nombre
INTO #ForrosCrudos
FROM TTelas
INNER JOIN TTelasCrudaTransformada ON TTelas.CodigoTela = TTelasCrudaTransformada.CodigoTelaCruda


SELECT te.IDListaEmpaque 
, COUNT(t.NroRollo) AS [Nro Tot. Rollo]
INTO #tmp_TListaEmpaque
FROM TListaEmpaque AS te
INNER JOIN TRollos AS t ON t.IDListaEmpaque = te.IDListaEmpaque
INNER JOIN Sici.GCT008.vTTelas  AS TTelas ON TTelas.Item = t.CodigoTela -- srodas
INNER JOIN TEstados AS TEstados ON TEstados.Codigo = TTelas.IdEstado -- srodas
WHERE convert(datetime,convert(VARCHAR,te.Fecha,101)) BETWEEN @FechaInicial AND @FechaFinal
AND TEstados.Codigo = 1  --Estado de la tela: Activa
---AND te.IDListaEmpaque ='13367'
GROUP BY te.IDListaEmpaque--, te.Fecha




SELECT distinct  te.IDListaEmpaque
, UPPER(LTRIM(RTRIM(Proveedor))) AS ProveedorDist
, ISNULL(t2.NroImportacion,'') AS IMPO_REM
, CASE WHEN  t2.CodigoTipoImpoRem = 1 THEN 'IMPORTACION' ELSE CASE WHEN  t2.CodigoTipoImpoRem = 2 THEN 'NACIONAL' ELSE '' END END Origen
, TClasificacionProduccion.Clasificacion
, tmp.[Nro Tot. Rollo]
, TTelas.Unidad AS UndMedida
, t2.CodigoImportacion
, TTelas.UnidadOrden AS UndMedidaCon
, te.Estado AS [Estado PL]
, idBodega
INTO #TListaEmpaque
FROM TListaEmpaque AS te
INNER JOIN TRollos AS t ON t.IDListaEmpaque = te.IDListaEmpaque
INNER JOIN Sici.GCT008.vTTelas AS TTelas ON TTelas.ITEM = t.CodigoTela -- srodas
INNER JOIN TEstados AS TEstados ON TEstados.Codigo = TTelas.IdEstado -- srodas
--INNER JOIN sici.dbo.Proveedores AS ProveedoresDist ON ProveedoresDist.Nit = t.NitProvDistribuye
INNER JOIN TImportacion AS t2 ON t2.CodigoImportacion = t.NroImportacion
INNER JOIN TClasificacionProduccion ON te.CodigoClasificacion = TClasificacionProduccion.Codigo
INNER JOIN #tmp_TListaEmpaque AS tmp ON tmp.IDListaEmpaque = te.IDListaEmpaque
--INNER JOIN TUnidadMedida AS tm ON tm.Codigo = t.CodigoUndMedida
--INNER JOIN TUnidadMedida AS TUnidadMedidaCon ON  TUnidadMedidaCon.Codigo = t.CodigoUndMedidaCon 
WHERE te.MigracionSiesa = 1 



--Ordenes de Compra------------------------------------------------------------------------------------
SELECT distinct te.IDListaEmpaque
, 	ISNULL(convert(varchar,oc.NombreOrden),'')	AS [Nro Orden Compra]  
INTO #tmp
from #TListaEmpaque AS te
INNER JOIN TRollos AS t ON t.IDListaEmpaque = te.IDListaEmpaque	   
LEFT JOIN (
			SELECT f420_rowid Numero_documento, CONCAT(f420_id_tipo_docto,'-',f420_consec_docto) NombreOrden
				FROM SIESASQL.UnoEE_Piloto.dbo.T420_cm_oc_docto
				WHERE (f420_id_grupo_clase_docto = 402) 	
			UNION ALL
			SELECT 0, 'IMPOREMI'
	   ) AS  oc ON oc.Numero_documento = t.NroOrdenCompra		   
		   
 SELECT #tmp.IDListaEmpaque,
		   STUFF((SELECT ', ' + T2.[Nro Orden Compra]  
	       FROM #tmp T2
	       WHERE #tmp.IDListaEmpaque = T2.IDListaEmpaque
		   for xml path('')),1,1,'') AS [Nro Orden Compra]  
		   INTO #OrdenesCompra	
         FROM #tmp
        GROUP BY #tmp.IDListaEmpaque
--Ordenes de Compra------------------------------------------------------------------------------------

SELECT DISTINCT ISNULL(convert(varchar,te.IDListaEmpaque),'') AS [ID Lista Empaque]
,ISNULL(convert(varchar,t4.NroImportacion),'') AS [Nro Importacion] 
,ISNULL(oc.NombreOrden,'') AS [Nro Orden Compra]
,vt.PROVEEDOR
,vt.[CODIGO DESARROLLO] CodigoDesarrollo
,vt.Item AS CodigoTela
,vt.CodigoTelaMaster AS [Codigo TelaMaster]
, te.[Nro Tot. Rollo]
, te2.Fecha AS [Fecha Creacion PL]
, te2.Fecha AS [Fecha Creacion]
, 'N/A' AS CodigoTelaProveedor							-- revisar
,vt.Nombre AS [Nombre Tela]
,vt.Color
,vt.COMPOSICION AS ComposicionEspañol
,vt.[COMPOSICION INGLES] AS ComposicionIngles
,vt.CONSTRUCCION
,vt.[TIPO TEJIDO] AS TipoTejido
,vt.[TIPO DE TINTURA] AS TipoTintura
,vt.[Tipo Hilatura] AS TipoHilatura
,vt.[ESTRUCTURA DE TEJIDO] AS EstructuraTejido
,'N/A' AS DenominacionTejido							-- revisar
,vt.[TIPO DE ACABADO] AS TipoAcabado
,vt.[PESO RIGIDO (ONZAS)] AS Peso
,vt.IdEstado
,vt.Estado AS EstadoTela 
,'N/A' as [Ficha Tecnica]
,'Pendiente verificar de donde se saca' Observaciones	-- revisar
,vt.[GRUPO INVENTARIO] AS Producto						-- revisar
,vt.UnidadOrden AS UndMedCompra							-- revisar
,vt.Unidad AS UndMedConsumo								-- revisar
,'N/A' PosicionArancelaria								-- revisar
,vt.[PAIS DE ORIGEN] AS PaisProcedencia
,'N/A' AS Fac_ConversionDIAN							-- revisar
,'N/A' AS Factor_Conversion								-- revisar
,vt.[QUIEN PAGA] as CompraTela
,vt.[QUIEN CONTROLA INVENTARIO] AS ControlaTela
,'N/A' AS ForroCrudo									-- revisar
,'N/A' AS UndMedidaPeso									-- revisar
,'N/A' AS TelaMuestras
,'N/A' as AnchoUtilReal									-- revisar
,vt.UnidadOrden AS UndMedOrden							-- revisar
,'N/A' as FactorConvOrden								-- revisar
,vt.f120_fecha_creacion AS [Fecha Creacion Tela]
,vt.f120_usuario_creacion AS [Usuario Crea]
,vt.f120_fecha_Actualizacion AS [Fecha Modificacion]
,vt.f120_usuario_actualizacion AS [Usuario Modifica]
,vt.NitProveedor AS ProveedorRollo						-- revisar
,ISNULL(te.ProveedorDist, '') AS ProveedorDist
,vt.Item AS CodigoTelaRollo  
, ISNULL(te.IDListaEmpaque,0) AS IDListaEmpaque   
, te.IMPO_REM
, te.Origen
, ISNULL(te.Clasificacion, '') AS Clasificacion
--, isnull(te.UndMedida,'') AS UndMedida
, isnull(vt.Unidad,'') AS UndMedida
, isnull(te.CodigoImportacion,'') AS CodigoImportacion
, vt.NitProveedor AS NitProv
, te.[Estado PL]
, vt.UnidadOrden UndMedidaCon
--, vt.UndMedidaCon	
,ISNULL(te2.NumeroPedido,'') AS NumeroPedido
,ISNULL(t.Lote,'') AS Lote
,ISNULL(te.idBodega,'') AS idBodega

FROM #TListaEmpaque AS te
INNER JOIN TListaEmpaque AS te2 ON te2.IDListaEmpaque = te.IDListaEmpaque
INNER JOIN TRollos AS t ON t.IDListaEmpaque = te.IDListaEmpaque
INNER JOIN [Sici].[GCT008].[vTTelas] vt ON vt.Item = t.CodigoTela
INNER JOIN TImportacion AS t4 ON t4.CodigoImportacion = t.NroImportacion
LEFT JOIN (
			SELECT f420_rowid Numero_documento, CONCAT(f420_id_tipo_docto,'-',f420_consec_docto) NombreOrden
				FROM SIESASQL.UnoEE_Piloto.dbo.T420_cm_oc_docto
				WHERE (f420_id_grupo_clase_docto = 402) 
			UNION ALL
			SELECT 0, 'IMPOREMI'
	   ) AS  oc ON oc.Numero_documento = t.NroOrdenCompra		
ORDER BY ISNULL(convert(varchar,te.IDListaEmpaque),'') DESC 
		


--SELECT DISTINCT ISNULL(convert(varchar,te.IDListaEmpaque),'') AS [ID Lista Empaque]
--, ISNULL(convert(varchar,t4.NroImportacion),'') AS [Nro Importacion] 
--, ISNULL(oc.[Nro Orden Compra],'') AS [Nro Orden Compra]

--, ISNULL(UPPER(LTRIM(RTRIM(Proveedores.Nombre))),'') AS Proveedor
--, TTelas.CodigoDesarrollo
--, TTelas.CodigoTela
--, TTelas.CodigoTelaMaster AS [Codigo TelaMaster]

--, te.[Nro Tot. Rollo]
--, te2.Fecha AS [Fecha Creacion PL]
--, te2.Fecha AS [Fecha Creacion]

--, TTelas.CodigoTelaProveedor
--, TTelas.Nombre AS [Nombre Tela]
--, TColores.Color
--, TTelas.ComposicionEspañol
--, TTelas.ComposicionIngles
--, TTelas.Construccion
--, TTipoTejidos.TipoTejido
--, TTipoTinturas.TipoTintura
--, TTiposHilatura.TipoHilatura
--, TEstructuraTejido.EstructuraTejido
--, TDenominacionTejido.DenominacionTejido
--, TTipoAcabados.TipoAcabado
--, TTelas.Peso
----, TEstados.Codigo AS CodEstado
--, TEstados.Estado AS EstadoTela 
--, (CASE WHEN ISNULL(TTelas.FichaTecnica, '') ='Ficha Tecnica' THEN '' ELSE ISNULL(TTelas.FichaTecnica, '') END) AS [Ficha Tecnica]
		 
--, ISNULL(TTelas.Observacion, '') AS Observacion
--, TProducto.Producto
--, ISNULL(TUnidadMedida.UnidadMedida,'') AS UndMedCompra
--, ISNULL(TUnidadMedida2.UnidadMedida,'') AS UndMedConsumo
--, ISNULL(Tbl_PA.PA,'') AS PosicionArancel
--, ISNULL(T_PaisesDIAN.Pais,'') AS PaisProcedencia
--, ISNULL(TTelas.Fac_ConversionDIAN,0) AS Fac_ConversionDIAN
--, ISNULL(TTelas.Factor_Conversion,0) AS Factor_Conversion
--, ISNULL(LTRIM(RTRIM(Clientes.Alias)),'')AS CompraTela
--, ISNULL(LTRIM(RTRIM(Clientes2.Alias)),'') AS ControlaTela
--, ISNULL(ForrosCrudos.Nombre,'') AS ForroCrudo
--, TUnidadMedidaPeso.UnidadMedida AS UndMedidaPeso
--, TTelas.TelaMuestras
--, ISNULL(AnchoUtil.AnchoUtilReal,0) AS AnchoUtilReal
--, ISNULL(TUnidadMedida3.UnidadMedida,'') AS UndMedOrden
--, TTelas.FactorConvOrden
       
--, TTelas.FechaCreacion AS [Fecha Creacion Tela]
--, Tbl_Personal.Nombre AS [Usuario Crea]
--, ISNULL((CASE WHEN CONVERT(VARCHAR,TTelas.FechaMod,101) = '1/1/1900' THEN '' ELSE CONVERT(VARCHAR,TTelas.FechaMod,101) END),'') AS [Fecha Modificacion]
--, REPLACE(REPLACE(ISNULL(TTelas.UsuarioMod, ''),'JEANSSA\',''),'\','') AS [Usuario Modifica]


--, CASE WHEN Proveedores.Nit = '8909003084' THEN 'FABRICATO' ELSE
--	   CASE WHEN Proveedores.Nit = '10000086' THEN 'AMERICAN COTTON' ELSE
--	   CASE WHEN Proveedores.Nit = '10000096' THEN 'CONE MILLS' ELSE
--	   CASE WHEN Proveedores.Nit = '8909002591' THEN 'COLTEJER' ELSE
--	   CASE WHEN Proveedores.Nit = '10000123' THEN 'VICUNHA' ELSE UPPER(LTRIM(RTRIM(Proveedores.Nombre))) END END END END END AS ProveedorRollo
-- , ISNULL(te.ProveedorDist, '') AS ProveedorDist
-- , TTelas.CodigoTela AS CodigoTelaRollo  
-- , ISNULL(te.IDListaEmpaque,0) AS IDListaEmpaque   
-- , te.IMPO_REM
-- , te.Origen
--  , ISNULL(te.Clasificacion, '') AS Clasificacion
--  , isnull(te.UndMedida,'') AS UndMedida
--  , isnull(te.CodigoImportacion,'') AS CodigoImportacion
--  , Proveedores.Nit AS NitProv
--  , te.[Estado PL]
--  , te.UndMedidaCon	
--  ,ISNULL(te2.NumeroPedido,'') AS NumeroPedido
--  --,ISNULL(t.Lote,'') AS Lote
--INTO #TMP_Final
--from #TListaEmpaque AS te
--INNER JOIN TListaEmpaque AS te2 ON te2.IDListaEmpaque = te.IDListaEmpaque
--INNER JOIN TRollos AS t ON t.IDListaEmpaque = te.IDListaEmpaque
--INNER JOIN Sici.GCT008.vTTelas AS TTelas ON TTelas.CodigoTela = t.CodigoTela
--INNER JOIN TEstados AS TEstados ON TEstados.Codigo = TTelas.IdEstado
--INNER JOIN TImportacion AS t4 ON t4.CodigoImportacion = t.NroImportacion	
--LEFT JOIN sici.dbo.Proveedores AS Proveedores ON Proveedores.Nit = TTelas.CodigoProveedor
--INNER JOIN TTipoTejidos ON TTelas.CodigoTipoTejido = TTipoTejidos.Codigo
--INNER JOIN TTipoTinturas ON TTelas.CodigoTipoTintura = TTipoTinturas.Codigo
--INNER JOIN TColores ON TTelas.CodigoColor = TColores.Codigo
--INNER JOIN TTiposHilatura ON TTelas.CodigoTipoHilatura = TTiposHilatura.Codigo
--INNER JOIN TEstructuraTejido ON TTelas.CodigoEstructuraTejido = TEstructuraTejido.Codigo
--INNER JOIN TDenominacionTejido ON TTelas.CodigoDenominacionTejido = TDenominacionTejido.Codigo
--INNER JOIN TTipoAcabados ON TTelas.CodigoTipoAcabado = TTipoAcabados.Codigo
--INNER JOIN TProducto ON TTelas.CodigoProducto = TProducto.CodigoProducto
--LEFT JOIN TUnidadMedida ON TUnidadMedida.Codigo = TTelas.CodUndMedCompra
--LEFT JOIN TUnidadMedida TUnidadMedida2 ON TUnidadMedida2.Codigo = TTelas.CodUndMedConsumo
--LEFT JOIN sici.dbo.Tbl_PA AS Tbl_PA ON TTelas.IdPA = Tbl_PA.IdPA_Nueva
--INNER JOIN sici.dbo.Tbl_Personal AS Tbl_Personal ON TTelas.CodigoUsuarioCrea = Tbl_Personal.IdPersonal
--LEFT JOIN sici.dbo.T_PaisesDIAN T_PaisesDIAN ON T_PaisesDIAN.Cod = TTelas.PaisProcedencia
--LEFT JOIN sici.dbo.Clientes Clientes ON Clientes.Nit = TTelas.NitCompra
--LEFT JOIN sici.dbo.Clientes Clientes2 ON Clientes2.Nit = TTelas.NitControl
--LEFT JOIN #ForrosCrudos ForrosCrudos ON TTelas.CodigoTela = ForrosCrudos.CodigoTelaTransformada
--INNER JOIN TUnidadMedida TUnidadMedidaPeso ON TUnidadMedidaPeso.Codigo = TTelas.CodUnidadMedidaPeso
--LEFT OUTER JOIN @FirstTable AnchoUtil ON AnchoUtil.CodigoTela = TTelas.CodigoTela
--LEFT OUTER JOIN TUnidadMedida TUnidadMedida3 ON TUnidadMedida3.Codigo = TTelas.CodUndMedOrden
--LEFT OUTER JOIN #OrdenesCompra AS oc ON oc.IDListaEmpaque = te.IDListaEmpaque   

--SELECT *
--FROM #TMP_Final AS tmp
--ORDER BY tmp.[ID Lista Empaque] DESC 
END

