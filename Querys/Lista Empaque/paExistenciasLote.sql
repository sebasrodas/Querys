USE [Sici]
GO
/****** Object:  StoredProcedure [dbo].[paExistenciasLote]    Script Date: 2021/06/08 9:44:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- paExistenciasLote 30,''
ALTER PROCEDURE [dbo].[paExistenciasLote]
@varBodega VARCHAR(20)
, @varUbicacion VARCHAR(20)
AS
BEGIN
	IF(LEN(@varUbicacion) = 0)
	BEGIN
		SET @varUbicacion = NULL
	END

	SELECT  t401_cm_existencia_lote.f401_id_lote UPC
			, t150_mc_bodegas.f150_id
			, t155_u1.f155_id
	from GCT008.vTTelas  AS t
	INNER JOIN UnoEE_Piloto.dbo.t121_mc_items_extensiones			ON f121_rowid_item = t.rowid_Item
	INNER JOIN UnoEE_Piloto.dbo.t400_cm_existencia					ON t121_mc_items_extensiones.f121_rowid = t400_cm_existencia.f400_rowid_item_ext
	INNER JOIN UnoEE_Piloto.dbo.t401_cm_existencia_lote				ON f401_rowid_item_ext = f400_rowid_item_ext and f401_rowid_bodega = f400_rowid_bodega
	INNER JOIN UnoEE_Piloto.dbo.t150_mc_bodegas						ON f400_rowid_bodega = t150_mc_bodegas.f150_rowid
	LEFT JOIN UnoEE_Piloto.dbo.t155_mc_ubicacion_auxiliares t155_u1 ON t155_u1.f155_rowid_bodega = f401_rowid_bodega and t155_u1.f155_id = f401_id_ubicacion_aux
	WHERE f400_rowid_bodega = @varBodega AND CASE WHEN @varUbicacion IS NULL THEN 1 ELSE t155_u1.f155_id END = CASE WHEN @varUbicacion IS NULL THEN 1 ELSE @varUbicacion END
	GROUP BY t.Item
			, t.Nombre
			, t.[Grupo Inventario]
			, t.Unidad
			, t401_cm_existencia_lote.f401_id_lote 
			, t150_mc_bodegas.f150_id
			, t155_u1.f155_id
	ORDER BY 1 ASC
END