DECLARE
        RequestId NUMBER := :RequestId;

        PROCEDURE  Get_RequestAdLogin (RequestId IN NUMBER, AdLogin OUT VARCHAR2)
        IS
        BEGIN
                WITH
                        REQ_CHAIN AS (
                                SELECT 
                                    R.ID ID_1
                                    ,LOV_2.VALUE3 ID_2
                                    ,LOV_3.VALUE3 ID_3
                                FROM 
                                    XXRMS_APEX.RMS_REFERENCES R
                                    ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_1
                                    ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_2
                                    ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_2
                                    ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_3
                                    ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_3
                                WHERE 1=1
                                    AND INFO_1.ID_REFERENCE (+)= R.ID    
                                    AND INFO_1.ID_EXTRA_INFO (+)= 63300
                                                                                                                                    
                                    AND LOV_2.ID_REFERENCE (+)= INFO_1.VALUE3    
                                    AND INFO_2.ID_REFERENCE (+)= LOV_2.VALUE3    
                                    AND INFO_2.ID_EXTRA_INFO (+)= 63300
                                                                                                                                    
                                    AND LOV_3.ID_REFERENCE (+)= INFO_2.VALUE3    
                                    AND INFO_3.ID_REFERENCE (+)= LOV_3.VALUE3    
                                    AND INFO_3.ID_EXTRA_INFO (+)= 63300
                        )
                        ,REQ_CHAIN_AD_LOGIN AS (
                                SELECT
                                        DISTINCT
                                        REQ_CHAIN.ID_1 REQ_ID
                                        ,LOWER(A.VALUE3) REQ_AD_LOGIN
                                FROM
                                        REQ_CHAIN
                                LEFT JOIN (
                                                SELECT ID_REFERENCE, VALUE3 FROM XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO WHERE ID_EXTRA_INFO = 63309 AND VALUE2 = 369385
                                        ) A ON 
                                        A.ID_REFERENCE=REQ_CHAIN.ID_1
                                        OR A.ID_REFERENCE=REQ_CHAIN.ID_2
                                        OR A.ID_REFERENCE=REQ_CHAIN.ID_3
                        )
                        ,REQ_EMP_AD_LOGIN AS (
                                SELECT
                                        DISTINCT 
                                        REQ_ID
                                        ,listagg (AD_LOGIN,',') within group (order by AD_LOGIN) OVER (PARTITION BY REQ_ID) EMP_AD_LOGIN
                                FROM (
                                        SELECT
                                                DISTINCT
                                                REQ_NUM.ID_REFERENCE REQ_ID
                                                ,lower(REQ_AD_INFO.VALUE3) AD_LOGIN
                                        FROM 
                                                XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                                                ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_AD_NUM
                                                ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_AD_LOV
                                                ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_AD_INFO
                                        WHERE 1=1
                                                AND REQ_AD_NUM.VALUE2 = REQ_NUM.VALUE2
                                                AND REQ_AD_NUM.VALUE3 = 369365
                                                AND REQ_AD_LOV.VALUE3 = REQ_AD_NUM.ID_REFERENCE
                                                AND REQ_AD_INFO.ID_REFERENCE = REQ_AD_NUM.ID_REFERENCE
                                                AND REQ_AD_INFO.ID_EXTRA_INFO = 63309
                                                AND REQ_AD_INFO.VALUE2 = '369385'
                                )
                        )
                        ,REQ_AD_LOGIN AS (
                                SELECT 
                                        R.REQ_ID
                                        ,CASE
                                                WHEN REQ_AD_LOGIN IS NOT NULL THEN REQ_AD_LOGIN
                                                WHEN EMP_AD_LOGIN IS NOT NULL AND EMP_AD_LOGIN NOT LIKE '%,%'  THEN EMP_AD_LOGIN
                                                ELSE NULL
                                        END AD_LOGIN
                                FROM REQ_CHAIN_AD_LOGIN R
                                LEFT JOIN REQ_EMP_AD_LOGIN A ON A.REQ_ID=R.REQ_ID
                        )
                        
                        SELECT AD_LOGIN INTO AdLogin
                        FROM REQ_AD_LOGIN
                        WHERE REQ_ID = RequestId;
        END;

        PROCEDURE  Get_RelatedResources (RequestId IN NUMBER, RefCursor OUT SYS_REFCURSOR)
        IS
        BEGIN
                OPEN RefCursor FOR
                        SELECT RES_MAP.REL_RES_ID RES_ID
                        FROM XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                        JOIN (
                                SELECT objectschema RES_ID, objectname REL_RES_ID
                                FROM TABLE(
                                        sys.ODCIObjectList(
                                                sys.odciobject(84317,84317),
                                                sys.odciobject(84317,3268185),
                                                sys.odciobject(3268185,84317),
                                                sys.odciobject(3268185,3268185),
                                                sys.odciobject(88528,88528),
                                                sys.odciobject(88528,88533),
                                                sys.odciobject(88533,88528),
                                                sys.odciobject(88533,88533)
                                                )
                                        )
                                ) RES_MAP ON RES_MAP.RES_ID = REQ_NUM.VALUE3
                        WHERE REQ_NUM.ID_REFERENCE = RequestId;
        END;

        PROCEDURE  Get_RelatedRequests (AdLogin IN VARCHAR2, ResIds IN sys.odcinumberlist, RefCursor OUT SYS_REFCURSOR)
        IS
        BEGIN
                OPEN RefCursor FOR
                        WITH
                            AD_LOGIN_EMP AS (
                                            SELECT
                                                    DISTINCT
                                                    lower(REQ_INFO.VALUE3) AD_LOGIN
                                                    ,REQ_NUM.VALUE2 EMP_ID
                                            FROM 
                                                    XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_INFO
                                                    ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_LOV
                                                    ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                                            WHERE 1=1
                                                    AND REQ_INFO.ID_EXTRA_INFO = 63309
                                                    AND REQ_INFO.VALUE2 = '369385'        
                                                    AND REQ_INFO.VALUE3 IS NOT NULL        
                                                    AND REQ_LOV.VALUE3 = REQ_INFO.ID_REFERENCE
                                                    AND REQ_NUM.ID_REFERENCE = REQ_INFO.ID_REFERENCE
                                    )
                                    , EMP_REQ AS (
                                            SELECT
                                                    DISTINCT
                                                    REQ_NUM.VALUE2 EMP_ID
                                                    ,REQ_NUM.ID_REFERENCE REQ_ID
                                                    ,REQ_NUM.VALUE3 RES_ID
                                            FROM 
                                                    XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                                            WHERE 1=1
                                                    AND REQ_NUM.VALUE3 IN (SELECT * FROM TABLE(ResIds))
                                    )
                                    ,AD_LOGIN_EMP_RES_REQ AS (
                                            SELECT
                                                    AD_LOGIN_EMP.AD_LOGIN
                                                    ,EMP_REQ.REQ_ID
                                                    ,EMP_REQ.RES_ID
                                            FROM AD_LOGIN_EMP
                                            JOIN EMP_REQ ON EMP_REQ.EMP_ID=AD_LOGIN_EMP.EMP_ID
                                    )
                                    SELECT REQ_ID
                                    FROM AD_LOGIN_EMP_RES_REQ
                                    WHERE AD_LOGIN like AdLogin;                           
        END;        
        
        PROCEDURE  Get_RequestInfo (ReqIds IN sys.odcinumberlist, RefCursor OUT SYS_REFCURSOR)
        IS
                ReqIdsStr VARCHAR2(500);
        BEGIN
                SELECT listagg(column_value, ',') within group (order by column_value) INTO ReqIdsStr
                FROM TABLE(ReqIds);

                OPEN RefCursor FOR
                        'WITH
                                REQ_CHAIN AS (
                                        SELECT 
                                            R.ID ID_1
                                            ,LOV_2.VALUE3 ID_2
                                            ,LOV_3.VALUE3 ID_3
                                        FROM 
                                            XXRMS_APEX.RMS_REFERENCES R
                                            ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_1
                                            ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_2
                                            ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_2
                                            ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_3
                                            ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_3
                                        WHERE 1=1
                                            AND INFO_1.ID_REFERENCE (+)= R.ID    
                                            AND INFO_1.ID_EXTRA_INFO (+)= 63300
                                                                                                                                            
                                            AND LOV_2.ID_REFERENCE (+)= INFO_1.VALUE3    
                                            AND INFO_2.ID_REFERENCE (+)= LOV_2.VALUE3    
                                            AND INFO_2.ID_EXTRA_INFO (+)= 63300
                                                                                                                                            
                                            AND LOV_3.ID_REFERENCE (+)= INFO_2.VALUE3    
                                            AND INFO_3.ID_REFERENCE (+)= LOV_3.VALUE3    
                                            AND INFO_3.ID_EXTRA_INFO (+)= 63300
                                )
                                ,REQ_CHAIN_AD_LOGIN AS (
                                        SELECT
                                                DISTINCT
                                                REQ_CHAIN.ID_1 REQ_ID
                                                ,LOWER(A.VALUE3) REQ_AD_LOGIN
                                        FROM
                                                REQ_CHAIN
                                        LEFT JOIN (
                                                        SELECT ID_REFERENCE, VALUE3 FROM XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO WHERE ID_EXTRA_INFO = 63309 AND VALUE2 = 369385
                                                ) A ON 
                                                A.ID_REFERENCE=REQ_CHAIN.ID_1
                                                OR A.ID_REFERENCE=REQ_CHAIN.ID_2
                                                OR A.ID_REFERENCE=REQ_CHAIN.ID_3
                                )
                                ,REQ_EMP_AD_LOGIN AS (
                                        SELECT
                                                DISTINCT 
                                                REQ_ID
                                                ,listagg (AD_LOGIN,'','') within group (order by AD_LOGIN) OVER (PARTITION BY REQ_ID) EMP_AD_LOGIN
                                        FROM (
                                                SELECT
                                                        DISTINCT
                                                        REQ_NUM.ID_REFERENCE REQ_ID
                                                        ,lower(REQ_AD_INFO.VALUE3) AD_LOGIN
                                                FROM 
                                                        XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                                                        ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_AD_NUM
                                                        ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_AD_LOV
                                                        ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_AD_INFO
                                                WHERE 1=1
                                                        AND REQ_AD_NUM.VALUE2 = REQ_NUM.VALUE2
                                                        AND REQ_AD_NUM.VALUE3 = 369365
                                                        AND REQ_AD_LOV.VALUE3 = REQ_AD_NUM.ID_REFERENCE
                                                        AND REQ_AD_INFO.ID_REFERENCE = REQ_AD_NUM.ID_REFERENCE
                                                        AND REQ_AD_INFO.ID_EXTRA_INFO = 63309
                                                        AND REQ_AD_INFO.VALUE2 = ''369385''
                                        )
                                )
                                ,REQ_AD_LOGIN AS (
                                        SELECT 
                                                R.REQ_ID
                                                ,CASE
                                                        WHEN REQ_AD_LOGIN IS NOT NULL THEN REQ_AD_LOGIN
                                                        WHEN EMP_AD_LOGIN IS NOT NULL AND EMP_AD_LOGIN NOT LIKE ''%,%''  THEN EMP_AD_LOGIN
                                                        ELSE NULL
                                                END AD_LOGIN
                                        FROM REQ_CHAIN_AD_LOGIN R
                                        LEFT JOIN REQ_EMP_AD_LOGIN A ON A.REQ_ID=R.REQ_ID
                                )
                                ,REQ_STATUS AS (
                                        SELECT 
                                                REQ.ID REQ_ID
                                                ,REQ_STATUS.ID REQ_STATUS_ID
                                                ,REQ_STATUS.NAME REQ_STATUS_NAME    
                                                ,PROV_STATUS.ID PROV_STATUS_ID
                                                ,PROV_STATUS.NAME PROV_STATUS_NAME
                                                ,ROUTE_STATUS.ID ROUTE_STATUS_ID
                                                ,ROUTE_STATUS.NAME ROUTE_STATUS_NAME
                                                ,EMP_REQ.ID    EMP_ID
                                                ,EMP_REQ.NAME    EMP_NAME
                                                ,EMP_DATE.VALUE1    EMP_DISMISSAL
                                                ,RES.ID RES_ID
                                                ,RES.NAME   RES_NAME
                                        FROM 
                                                XXRMS_APEX.RMS_REFERENCES REQ
                                                ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM      
                                                ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_LOV
                                                ,XXRMS_APEX.RMS_REFERENCES REQ_STATUS
                                                        
                                                ,XXRMS_APEX.RMS_REFERENCE_LOV PROV_LOV
                                                ,XXRMS_APEX.RMS_REFERENCES PROV_STATUS
                                                        
                                                ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_INFO
                                                ,XXRMS_APEX.RMS_REFERENCES ROUTE_STATUS
                                                            
                                                ,XXRMS_APEX.RMS_REFERENCES EMP_REQ
                                                ,XXRMS_APEX.RMS_REFERENCE_DATE EMP_DATE
                                                ,XXRMS_APEX.RMS_REFERENCES RES
                                        WHERE
                                                REQ.TYPE_REF = 63282       
                                                AND REQ_NUM.ID_REFERENCE = REQ.ID   
                                                AND REQ_LOV.ID_REFERENCE = REQ.ID
                                                AND REQ_STATUS.ID = REQ_LOV.VALUE2
                                                AND PROV_LOV.VALUE3 (+)= REQ_NUM.ID_REFERENCE
                                                AND PROV_STATUS.ID (+)= PROV_LOV.VALUE4
                                                AND REQ_INFO.ID_REFERENCE = REQ.ID
                                                AND REQ_INFO.ID_LINE (+)= REQ_LOV.VALUE4
                                                AND ROUTE_STATUS.ID (+)= REQ_INFO.VALUE1
                                                AND EMP_REQ.ID = REQ_NUM.VALUE2
                                                AND EMP_DATE.ID_REFERENCE = REQ_NUM.VALUE2                    
                                                AND RES.ID = REQ_NUM.VALUE3
                                )
                                SELECT REQ_STATUS.*,REQ_AD_LOGIN.AD_LOGIN
                                FROM REQ_AD_LOGIN
                                JOIN REQ_STATUS ON REQ_STATUS.REQ_ID = REQ_AD_LOGIN.REQ_ID
                                WHERE REQ_AD_LOGIN.REQ_ID IN ( '||ReqIdsStr||')'; 
        END;        
        PROCEDURE  Get_RelatedRequests (RequestId IN NUMBER, OutCursor OUT SYS_REFCURSOR)
        IS
                AdLogin VARCHAR2(100);
                RefCursor SYS_REFCURSOR;
                TmpId NUMBER;
                ResIds sys.odcinumberlist := sys.odcinumberlist();
                ReqIds sys.odcinumberlist := sys.odcinumberlist();
        BEGIN
                Get_RequestAdLogin (RequestId, AdLogin);
                dbms_output.put_line('AdLogin: ' || AdLogin);
                IF AdLogin IS NULL THEN
                        RAISE_APPLICATION_ERROR(-1000,'AdLogin IS NULL');
                END IF;
                Get_RelatedResources (RequestId, RefCursor);
                LOOP
                        FETCH RefCursor INTO TmpId;
                        EXIT WHEN RefCursor%NOTFOUND;
                        ResIds.extend;
                        ResIds(ResIds.Count) := TmpId;
                END LOOP;

                Get_RelatedRequests (AdLogin, ResIds, RefCursor);
                LOOP
                        FETCH RefCursor INTO TmpId;
                        EXIT WHEN RefCursor%NOTFOUND;
                        dbms_output.put_line('TmpId: ' || TmpId);
                        ReqIds.extend;
                        ReqIds(ReqIds.Count) := TmpId;
                END LOOP;

                Get_RequestInfo(ReqIds, OutCursor);
        END;

BEGIN
    dbms_output.put_line('RequestId: ' || RequestId);
    Get_RelatedRequests(RequestId, :RefCursor);
    :ErrCode := 0;
    :ErrMsg := 'Success';           
    EXCEPTION
    WHEN OTHERS THEN
        :ErrCode := SQLCODE;
        :ErrMsg := SUBSTR(SQLERRM, 1 , 100);
        DBMS_OUTPUT.put_line('Err: '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 100));          
END;
