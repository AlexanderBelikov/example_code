DECLARE
    TYPE NumberTableType IS TABLE OF NUMBER;
    RequestId NUMBER := :RequestId;
    PersonId NUMBER;
    AdLogin VARCHAR2(100);
    PersonIds NumberTableType;
    PersonIdsStr VARCHAR2(500);
    RequestIds NumberTableType;

    ResRequestIds NumberTableType;
    ResRequestIdsTmp NumberTableType;
    ResRequestIdsStr VARCHAR2(500);

    TYPE RequestInfoType IS RECORD ( RequestId NUMBER, AdLogin VARCHAR2(100), SmtpAddress VARCHAR2(100), RequestedSmtpAddress VARCHAR2(100) );
    RequestInfo RequestInfoType;

    PROCEDURE  Get_RequestPersonId (RequestId IN NUMBER, PersonId OUT NUMBER)
    IS
    BEGIN
        SELECT 
            E_NUM.VALUE2 PERSON_ID INTO PersonId
        FROM
            XXRMS_APEX.RMS_REFERENCE_NUMBER R_NUM
            ,XXRMS_APEX.RMS_REFERENCES E
            ,XXRMS_APEX.RMS_REFERENCE_NUMBER E_NUM
        WHERE
            R_NUM.ID_REFERENCE = RequestId
            AND E.ID = R_NUM.VALUE2
            AND E_NUM.ID_REFERENCE = E.ID;
    END;

    
    PROCEDURE  Get_RequestAdLogin (RequestId IN NUMBER, AdLogin OUT VARCHAR2)
    IS
    BEGIN
            SELECT 
                LOWER(REQ_INFO.VALUE3) AD_LOGIN INTO AdLogin
            FROM (
                    SELECT 
                        R.ID ID_1
                        ,LOV_2.VALUE3 ID_2
                        ,LOV_3.VALUE3 ID_3
                        ,LOV_4.VALUE3 ID_4
                    FROM 
                        XXRMS_APEX.RMS_REFERENCES R
                        ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_1
                        ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_2
                        ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_2
                        ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_3
                        ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_3
                        ,XXRMS_APEX.RMS_REFERENCE_LOV LOV_4
                        ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO INFO_4
                    WHERE 1=1
                        AND R.ID = RequestId

                        AND INFO_1.ID_REFERENCE (+)= R.ID    
                        AND INFO_1.ID_EXTRA_INFO (+)= 63300
                                                                                                            
                        AND LOV_2.ID_REFERENCE (+)= INFO_1.VALUE3    
                        AND INFO_2.ID_REFERENCE (+)= LOV_2.VALUE3    
                        AND INFO_2.ID_EXTRA_INFO (+)= 63300
                                                                                                            
                        AND LOV_3.ID_REFERENCE (+)= INFO_2.VALUE3    
                        AND INFO_3.ID_REFERENCE (+)= LOV_3.VALUE3    
                        AND INFO_3.ID_EXTRA_INFO (+)= 63300
                                                                                                        
                        AND LOV_4.ID_REFERENCE (+)= INFO_3.VALUE3    
                        AND INFO_4.ID_REFERENCE (+)= LOV_4.VALUE3    
                        AND INFO_4.ID_EXTRA_INFO (+)= 63300
            ) REQ_CHAIN
            JOIN (
                    SELECT * 
                    FROM XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO
                    WHERE ID_EXTRA_INFO = 63309
                            AND VALUE2 = '369385'
                    ) REQ_INFO
                    ON REQ_INFO.ID_REFERENCE IN (REQ_CHAIN.ID_1,REQ_CHAIN.ID_2,REQ_CHAIN.ID_3,REQ_CHAIN.ID_4);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
    END;

    PROCEDURE  Get_RequestEmpAdLogin (RequestId IN NUMBER, AdLogin OUT VARCHAR2)
    IS
    BEGIN
        SELECT
            DISTINCT 
            lower(REQ_AD_INFO.VALUE3) AD_LOGIN INTO AdLogin
        FROM 
            XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
            ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_AD_NUM
            ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_AD_LOV
            ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_AD_INFO
        WHERE
            REQ_NUM.ID_REFERENCE = RequestId
            AND REQ_AD_NUM.VALUE2 = REQ_NUM.VALUE2
            AND REQ_AD_NUM.VALUE3 = 369365
            AND REQ_AD_LOV.VALUE3 = REQ_AD_NUM.ID_REFERENCE
            AND REQ_AD_INFO.ID_REFERENCE = REQ_AD_NUM.ID_REFERENCE
            AND REQ_AD_INFO.ID_EXTRA_INFO = 63309
            AND REQ_AD_INFO.VALUE2 = '369385';
    END;
    
    
    PROCEDURE  Get_RequestInfo (RequestId IN NUMBER, RequestInfo OUT RequestInfoType)
    IS
    BEGIN
        SELECT
            * INTO RequestInfo
        FROM (
            SELECT 
                RequestId R_ID_ROOT
                ,VALUE2  RES_ID
                ,VALUE3 RES_VALUE
            FROM (
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
                        AND R.ID = RequestId

                        AND INFO_1.ID_REFERENCE (+)= R.ID    
                        AND INFO_1.ID_EXTRA_INFO (+)= 63300
                                                                                                            
                        AND LOV_2.ID_REFERENCE (+)= INFO_1.VALUE3    
                        AND INFO_2.ID_REFERENCE (+)= LOV_2.VALUE3    
                        AND INFO_2.ID_EXTRA_INFO (+)= 63300
                                                                                                            
                        AND LOV_3.ID_REFERENCE (+)= INFO_2.VALUE3    
                        AND INFO_3.ID_REFERENCE (+)= LOV_3.VALUE3    
                        AND INFO_3.ID_EXTRA_INFO (+)= 63300                                                                                                        
            ) 
            UNPIVOT EXCLUDE NULLS(
                R_ID FOR R_LEVEL
                IN (
                    ID_1 AS 1,
                    ID_2 AS 2,
                    ID_3 AS 3
                    )
            ) R_TREE
            JOIN XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO R_INFO ON 
                R_TREE.R_ID=R_INFO.ID_REFERENCE 
                AND R_INFO.ID_EXTRA_INFO = 63309
                AND R_INFO.VALUE2 IN (369385,48109677)
        )
        PIVOT (max(RES_VALUE)
            for RES_ID in ( 
                369385 AS AD_LOGIN, 
                187354 AS SMTP_ADDRESS,
                30269411 AS REQUESTED_SMTP_ADDRESS
            )
        );
    END;
    PROCEDURE  Get_RequestsInfo (RequestIdsStr IN VARCHAR, RequestCursor OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN RequestCursor FOR 
                '
                SELECT 
                    A.*
                    ,B.EMP_AD_LOGIN
                    ,CASE
                            WHEN A.REQ_AD_LOGIN IS NOT NULL THEN A.REQ_AD_LOGIN
                            WHEN B.EMP_AD_LOGIN IS NOT NULL AND B.EMP_AD_LOGIN NOT LIKE '',''  THEN B.EMP_AD_LOGIN
                            ELSE NULL
                    END AD_LOGIN
                FROM (
                        SELECT
                            REQ_PIVOT.*
                            ,REQ_STATUS.ID RES_STATUS_ID
                            ,REQ_STATUS.NAME RES_STATUS_NAME    
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
                            (
                                SELECT
                                    R_ROOT_ID RES_REQ_ID
                                    ,REQ_AD_LOGIN
                                    ,SMTP_ADDRESS
                                    ,REQUESTED_SMTP_ADDRESS
                                FROM (
                                    SELECT 
                                        R_ROOT_ID
                                        ,VALUE2  RES_ID
                                        ,VALUE3 RES_VALUE
                                    FROM (
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
                                                AND R.ID IN ('||RequestIdsStr||')

                                                AND INFO_1.ID_REFERENCE (+)= R.ID    
                                                AND INFO_1.ID_EXTRA_INFO (+)= 63300
                                                                                                                                                    
                                                AND LOV_2.ID_REFERENCE (+)= INFO_1.VALUE3    
                                                AND INFO_2.ID_REFERENCE (+)= LOV_2.VALUE3    
                                                AND INFO_2.ID_EXTRA_INFO (+)= 63300
                                                                                                                                                    
                                                AND LOV_3.ID_REFERENCE (+)= INFO_2.VALUE3    
                                                AND INFO_3.ID_REFERENCE (+)= LOV_3.VALUE3    
                                                AND INFO_3.ID_EXTRA_INFO (+)= 63300
                                    ) 
                                    UNPIVOT EXCLUDE NULLS(
                                        (R_ROOT_ID,R_ID) FOR R_LEVEL
                                        IN (
                                            (ID_1,ID_1) AS 1,
                                            (ID_1,ID_2) AS 2,
                                            (ID_1,ID_3) AS 3
                                            )
                                    ) R_TREE
                                    LEFT JOIN XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO R_INFO ON 
                                        R_TREE.R_ID=R_INFO.ID_REFERENCE 
                                        AND R_INFO.ID_EXTRA_INFO = 63309
                                        AND R_INFO.VALUE2 IN (187354, 369385,30269411)

                                )
                                PIVOT (max(RES_VALUE)
                                    for RES_ID in ( 
                                        369385 AS REQ_AD_LOGIN, 
                                        187354 AS SMTP_ADDRESS,
                                        30269411 AS REQUESTED_SMTP_ADDRESS
                                    )
                                )
                            ) REQ_PIVOT
                            ,XXRMS_APEX.RMS_REFERENCE_LOV REQ_LOV
                            ,XXRMS_APEX.RMS_REFERENCES REQ_STATUS
                                    
                            ,XXRMS_APEX.RMS_REFERENCE_LOV PROV_LOV
                            ,XXRMS_APEX.RMS_REFERENCES PROV_STATUS
                                    
                            ,XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO REQ_INFO
                            ,XXRMS_APEX.RMS_REFERENCES ROUTE_STATUS
                                        
                            ,XXRMS_APEX.RMS_REFERENCE_NUMBER REQ_NUM
                            ,XXRMS_APEX.RMS_REFERENCES EMP_REQ
                            ,XXRMS_APEX.RMS_REFERENCE_DATE EMP_DATE
                            ,XXRMS_APEX.RMS_REFERENCES RES
                        WHERE
                            REQ_LOV.ID_REFERENCE = REQ_PIVOT.RES_REQ_ID
                            AND REQ_NUM.ID_REFERENCE = REQ_PIVOT.RES_REQ_ID
                            AND REQ_STATUS.ID = REQ_LOV.VALUE2
                            AND PROV_LOV.VALUE3 (+)= REQ_PIVOT.RES_REQ_ID
                            AND PROV_STATUS.ID (+)= PROV_LOV.VALUE4
                            AND REQ_INFO.ID_REFERENCE = REQ_PIVOT.RES_REQ_ID
                            AND REQ_INFO.ID_LINE (+)= REQ_LOV.VALUE4
                            AND ROUTE_STATUS.ID (+)= REQ_INFO.VALUE1
                            AND EMP_REQ.ID = REQ_NUM.VALUE2
                            AND EMP_DATE.ID_REFERENCE = REQ_NUM.VALUE2                    
                            AND RES.ID = REQ_NUM.VALUE3
                                    
                ) A
                LEFT JOIN (
                                SELECT
                                        DISTINCT 
                                        RES_REQ_ID
                                        ,listagg (AD_LOGIN,'','') within group (order by AD_LOGIN) OVER (PARTITION BY RES_REQ_ID) EMP_AD_LOGIN
                                FROM (
                                SELECT
                                        DISTINCT
                                        REQ_NUM.ID_REFERENCE RES_REQ_ID
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
                        ) B ON B.RES_REQ_ID = A.RES_REQ_ID             
                ' ;
    END;
    PROCEDURE  Get_PersonIdsByAdLogin (AdLogin IN VARCHAR2, PersonIds OUT NumberTableType)
    IS
    BEGIN
        SELECT 
            DISTINCT E_NUM.VALUE2 PERSON_ID BULK COLLECT INTO PersonIds
        FROM 
            XXRMS_APEX.RMS_REFERENCE_EXTRA_INFO R_INFO
            ,XXRMS_APEX.RMS_REFERENCE_LOV R_LOV
            ,XXRMS_APEX.RMS_REFERENCES R_PROV
            ,XXRMS_APEX.RMS_REFERENCE_NUMBER E_NUM
        WHERE      
            R_INFO.ID_EXTRA_INFO = 63309 
            AND R_INFO.VALUE2 = '369385'
            AND lower(R_INFO.VALUE3) = lower(AdLogin)
            AND R_LOV.VALUE3 = R_INFO.ID_REFERENCE
            AND R_PROV.ID = R_LOV.ID_REFERENCE
            AND R_PROV.TYPE_REF = 63334
            AND E_NUM.ID_REFERENCE = R_LOV.VALUE1;
    END;
    PROCEDURE  Get_ResRequestIdsByPersonId (PersonId IN NUMBER, RequestIds OUT NumberTableType)
    IS
    BEGIN
        SELECT 
            R_NUM.ID_REFERENCE BULK COLLECT INTO RequestIds
        FROM
            XXRMS_APEX.RMS_REFERENCE_NUMBER R_NUM
        WHERE
            R_NUM.VALUE2  in (
                SELECT 
                    E_NUM.ID_REFERENCE
                FROM
                    XXRMS_APEX.RMS_REFERENCE_NUMBER E_NUM
                    ,XXRMS_APEX.RMS_REFERENCE_DATE E_DATE
                WHERE
                    E_NUM.VALUE2  = PersonId
                    AND E_DATE.ID_REFERENCE = E_NUM.ID_REFERENCE
            )
            AND R_NUM.VALUE3 in (84317,3268185);            
    END;

BEGIN
    dbms_output.put_line('RequestId: ' || RequestId);

    Get_RequestPersonId (RequestId, PersonId);
    dbms_output.put_line('PersonId: ' || PersonId);

    Get_RequestAdLogin (RequestId, AdLogin);
    dbms_output.put_line('AdLogin: ' || AdLogin);
    
    IF AdLogin IS NULL THEN
        Get_RequestEmpAdLogin (RequestId, AdLogin);
        dbms_output.put_line('EmpAdLogin: ' || AdLogin);
    END IF;
    

    IF AdLogin IS NULL THEN
        PersonIds := NumberTableType();
        PersonIds.extend;
        PersonIds(PersonIds.Count) := PersonId;
    ELSE
        Get_PersonIdsByAdLogin (AdLogin, PersonIds);
    END IF;
    
    ResRequestIds := NumberTableType();

    FOR i in 1..PersonIds.COUNT LOOP
        dbms_output.put_line('PersonIds: ' || PersonIds(i));
        Get_ResRequestIdsByPersonId(PersonIds(i), ResRequestIdsTmp);
        FOR j in 1..ResRequestIdsTmp.COUNT LOOP
            dbms_output.put_line('ResRequestIdsTmp: ' || ResRequestIdsTmp(j));
            ResRequestIds.extend;
            ResRequestIds(ResRequestIds.Count) := ResRequestIdsTmp(j);
        END LOOP;
    END LOOP;
    
    FOR i in 1..ResRequestIds.COUNT LOOP
        IF I = 1 THEN
            ResRequestIdsStr := TO_CHAR (ResRequestIds(i));
        ELSE
            ResRequestIdsStr := ResRequestIdsStr || ',' || TO_CHAR (ResRequestIds(i));
        END IF;
    END LOOP;    
    dbms_output.put_line('ResRequestIdsStr: ' || ResRequestIdsStr);

    Get_RequestsInfo(ResRequestIdsStr, :RequestCursor);
    
    :ErrCode := 0;
    :ErrMsg := 'Success';           
    EXCEPTION
    WHEN OTHERS THEN
        :ErrCode := SQLCODE;
        :ErrMsg := SUBSTR(SQLERRM, 1 , 100);
        DBMS_OUTPUT.put_line('Err: '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 100));          
END;
