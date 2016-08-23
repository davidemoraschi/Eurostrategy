INSERT INTO MSTR_DET_CENSO_DE_PACIE
--select count(NUHSA), NUHSA
--from
(
         SELECT TRUNC (SYSDATE - 1) NATID_DIA_CENSAL
               ,NVL (MSTR_MAE_CENTROS.SUBID_CENTRO, -1) SUBID_CENTRO
               ,NVL (UF_PACIENTE.SUBID_UNIDAD_FUNCIONAL, -1) SUBID_UNIDAD_FUNCIONAL
               ,codigo_estructura NATID_UBICACION
               ,ubi_nombre DESCR_UBICACION
               ,DECODE (NVL (UF_CAMA.SUBID_UNIDAD_FUNCIONAL, -1) - NVL (UF_PACIENTE.SUBID_UNIDAD_FUNCIONAL, -1)
                       ,0, 0
                       ,1)
                   IND_ECTOPICO
               ,EPISODIO_ID
               ,ADMISION_ID
               ,NUHSA
               , (SELECT SUBID_DIA
                    FROM MSTR_MAE_TIEMPO_03_DIAS
                   WHERE NATID_DIA = TRUNC (SYSDATE - 1))
                   SUBID_DIA_CENSAL
           FROM his_own.COM_UBICACION_GESTION_LOCAL@dae
                JOIN his_own.COM_M_UBICACION@dae
                   ON (CODIGO_ESTRUCTURA = UBI_CODIGO)
                LEFT JOIN MSTR_MAE_UNIDADES_FUNCIONALES UF_CAMA
                   ON (UNIDAD_FUNCIONAL = UF_CAMA.NATID_UNIDAD_FUNCIONAL)
                LEFT JOIN MSTR_MAE_CENTROS
                   ON (UBI_CAH_CODIGO = NATID_CENTRO)
                LEFT JOIN his_own.ADM_EPIS_DETALLE@dae
                   USING (EPISODIO_ID)
                JOIN his_own.ADM_ADMISION@dae D
                   ON (REFERENCIA_ID = ADMISION_ID)
                JOIN his_own.COM_USUARIO@dae U
                   ON (USUARIO = ID_USUARIO)
                LEFT JOIN MSTR_MAE_UNIDADES_FUNCIONALES UF_PACIENTE
                   ON (UNID_FUNC_RESP = UF_PACIENTE.NATID_UNIDAD_FUNCIONAL)
          WHERE activa = 1 AND UBI_ACTIVO = 0 AND UNIDAD_FUNCIONAL IS NOT NULL
and ubi_nombre <> 'OBU 19'
)

--group by nuhsa
--order by 1