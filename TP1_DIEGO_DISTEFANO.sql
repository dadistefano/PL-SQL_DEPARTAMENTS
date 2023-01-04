----------------------- TP1 BASE DE DATOS 2 ---------------------------------------
----------------------- Prof: Tomas De Amos ---------------------------------------
-----------------DIEGO DI STEFANO - LEGAJO N° 25764 -------------------------------
----Fecha de Entrega: 10/05/2022 --------------------------------------------------
/*Generar un paquete de PKG_DEPARTMENTS. En su interior debe estar conformado por estos componentes:

a. Un procedimiento Alta_dept para insertar un nuevo departamento en la tabla DEPARTMENTS: 
a.1 Se deben pasar todos los parametros necesarios para completar el registro de la tabla.
a.2 Se debe validar que el ID de departamento pasado no este duplicado. Esto se gestiona con la excepcion DUP_VAL_ON_INDEX.
a.3 El ID del empleado que sea manager, no debe ser manager de otro DEPTO, en caso de detectar esta situacion se debe lanzar una excepcion
a.4 El ID de la locacion debe ser uno no empleado anteriormente, o en caso contrario, se debe lanzar una excepcion.

b. Un procedimiento Upd_dept_man para actualizar el manager de un departamento:
b.1 El ID del empleado que sea manager, no debe ser manager de otro DEPTO, en caso de detectar esta situacion se debe lanzar una excepcion.

c. Un procedimiento Lista_dept_vacios que liste los departamentos que no tienen empleados asociados. */
----------------------------------------------------------------------------------
-- Punto 1)
SET SERVEROUTPUT ON;
CREATE TABLE DEP_AUX AS SELECT * FROM departments;

CREATE OR REPLACE PACKAGE PKG_DEPARTMENTS AS
    PROCEDURE SP_ALTA_DEPT (V_DEPT_ID departments.department_id%TYPE,
                            V_DEPT_NAME departments.department_name%TYPE,
                            V_MG_ID departments.manager_id%TYPE,
                            V_LOC_ID departments.location_id%TYPE); --Inserta nuevo departamento en la tabla DEPARTMENTS (Se utilizo una tabla auxiliar DEP_AUX)
	FUNCTION FN_EXISTE_IDDEPT(p_id_dep departments.department_id%TYPE) RETURN NUMBER; --Verifica que el DEPARTMENT_ID no sea duplicado	 
    FUNCTION FN_IDEMP_ESMANAGER(p_id_emp employees.employee_id%TYPE)RETURN NUMBER; --Verifica que el EMPLOYEE_ID tenga el trabajo de MANAGER
    FUNCTION FN_IDEMP_MANAGERDPTO(p_id_emp employees.employee_id%TYPE)RETURN NUMBER; --Verifica que el EMPLOYEE_ID no sea MANAGER de otro DEPARTAMENTO
    FUNCTION FN_EXISTE_IDLOCACION(p_id_loc locations.location_id%TYPE)RETURN NUMBER; --Verifica que el LOCATION_ID no sea duplicado
	PROCEDURE SP_UPD_DEPT_MAN (p_id_emp employees.employee_id%TYPE, p_id_dpto departments.department_id%TYPE);	-- Actualiza el MANAGER de un departamento
    PROCEDURE sp_Listado_Dpto_Vacio; --Lista los DEPARTAMENT que no tienen empleados asociados
END;

-- Punto a y a.1)
CREATE OR REPLACE PROCEDURE SP_ALTA_DEPT(
                            V_DEPT_ID departments.department_id%TYPE,
                            V_DEPT_NAME departments.department_name%TYPE,
                            V_MG_ID departments.manager_id%TYPE,
                            V_LOC_ID departments.location_id%TYPE) AUTHID CURRENT_USER AS
    DUP_VAL_ON_INDEX EXCEPTION;
    ID_MANAGER_EXCEPTION EXCEPTION;
    ID_LOCATION_EXCEPTION EXCEPTION;
BEGIN
    IF (FN_EXISTE_IDDEPT(V_DEPT_ID)=1) THEN
        RAISE DUP_VAL_ON_INDEX;
    END IF;
    IF (FN_IDEMP_MANAGERDPTO(V_MG_ID)=1) THEN
        RAISE ID_MANAGER_EXCEPTION;
    END IF;    
    IF (FN_EXISTE_IDLOCACION(V_LOC_ID)=1) THEN
        RAISE ID_LOCATION_EXCEPTION;
    END IF;    
    
    INSERT INTO DEP_AUX (department_id, department_name, manager_id, location_id)
        VALUES (V_DEPT_ID, V_DEPT_NAME, V_MG_ID, V_LOC_ID);
        
    DBMS_OUTPUT.PUT_LINE('EL ALTA DEL DEPARTAMENTO SE REALIZO CORRECTAMENTE');

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('ID_DEPARTMENT DUPLICADO --NO SE INSERTO EL NUEVO DPTO--');
    WHEN ID_MANAGER_EXCEPTION THEN
        DBMS_OUTPUT.PUT_LINE('MANAGER_ID INVALIDO, TIENE OTRO DEPARTAMENTO --NO SE INSERTO EL NUEVO DPTO--');
    WHEN ID_LOCATION_EXCEPTION THEN
        DBMS_OUTPUT.PUT_LINE('LOCATION_ID DUPLICADO --NO SE INSERTO EL NUEVO DPTO--');
END;

-- Punto a.2) 
CREATE OR REPLACE FUNCTION FN_EXISTE_IDDEPT(p_id_dep departments.department_id%TYPE)
RETURN NUMBER
IS
    v_aux_num NUMBER;
BEGIN
    SELECT department_id
    INTO v_aux_num
    FROM departments
    WHERE department_id = p_id_dep;
    
    DBMS_OUTPUT.PUT_LINE('EXISTE DEPARTMENTS DE ID_DEPT: ' || v_aux_num);
    RETURN 1; --TRUE=1
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO EXISTE DE ID_DEPT');
        RETURN 0; --FALSE=0
END;

-- Punto a.3)
CREATE OR REPLACE FUNCTION FN_IDEMP_MANAGERDPTO(p_id_emp employees.employee_id%TYPE)
RETURN NUMBER
IS
    v_aux_num NUMBER;
BEGIN
        select employees.employee_ID
        INTO v_aux_num
        from employees
        where employees.employee_ID IN (select departments.manager_ID
                                             from departments
                                            where manager_ID is not null)
        and employees.employee_ID = p_id_emp;
        DBMS_OUTPUT.PUT_LINE('EL ID EMPLEADO: ' || v_aux_num || ' ES MANAGER DE UN DEPARTAMENTO');
        RETURN 1; -- TRUE=1
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO ES MANAGER DE NINGUN DEPARTAMENT');
     RETURN 0; -- FALSE=0
END;

-- Punto a.4)
CREATE OR REPLACE FUNCTION FN_EXISTE_IDLOCACION(p_id_loc locations.location_id%TYPE)
RETURN NUMBER
IS
    v_aux_num NUMBER;
BEGIN
    SELECT location_id
    INTO v_aux_num
    FROM locations
    WHERE location_id = p_id_loc;
    
    DBMS_OUTPUT.PUT_LINE('EXISTE LOCATIONS DE ID_LOC: ' || v_aux_num);
    RETURN 1; -- TRUE=1
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO EXISTE DE ID_LOC');
        RETURN 0; -- FALSE=0
END;

-- Punto b)
CREATE OR REPLACE PROCEDURE SP_UPD_DEPT_MAN (p_id_emp employees.employee_id%TYPE, p_id_dpto departments.department_id%TYPE)
AS
    v_booleanMAN NUMBER;
    v_booleanMAN_DEPT NUMBER;
BEGIN
    v_booleanMAN_DEPT := FN_IDEMP_MANAGERDPTO(p_id_emp); --ES MANAGER DE ALGUN DPTO TRUE=1 // NO MANAGER DE ALGUN DPTO FALSE=0
    v_booleanMAN := FN_IDEMP_ESMANAGER(p_id_emp); --ES MANAGER TRUE=1 // NO ES MANAGER FALSE=0
    IF (v_booleanMAN_DEPT=0) THEN
        IF (v_booleanMAN=1) THEN
    
            update DEP_AUX
                SET MANAGER_ID = p_id_emp
            WHERE DEPARTMENT_ID = p_id_dpto;
            
            DBMS_OUTPUT.PUT_LINE('SE GRABO EL MANAGER: ' || p_id_emp || ' EN EL DPTO: ' || p_id_dpto );
        ELSE
            DBMS_OUTPUT.PUT_LINE('NO ES MANAGER, NO SE GRABO');
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('ES MANAGER DE OTRO DPTO, NO SE GRABO');
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO SE ENCONTRO DEPARTAMENTO, NO SE GRABO!!');
END;

-- Punto b.1)
CREATE OR REPLACE FUNCTION FN_IDEMP_ESMANAGER(p_id_emp employees.employee_id%TYPE)
RETURN NUMBER
IS
    v_aux_num NUMBER;
BEGIN
    select e.employee_ID
        into v_aux_num   
        from employees e
        join jobs j
        on e.job_id = j.job_id
        where e.employee_ID = p_id_emp
            and j.job_title LIKE '%Manager%';
        
        DBMS_OUTPUT.PUT_LINE('EL ID EMPLEADO: ' || v_aux_num || ' ES MANAGER');
        RETURN 1; -- TRUE=1
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('EL ID EMPLEADO NO ES MANAGER');
     RETURN 0; -- FALSE=0
END;

-- Punto c)
CREATE OR REPLACE PROCEDURE sp_Listado_Dpto_Vacio
AS
CURSOR c_dptoVacios IS
    select departments.DEPARTMENT_ID, departments.DEPARTMENT_NAME
    from departments
    where departments.DEPARTMENT_ID NOT IN (select employees.DEPARTMENT_ID
                                            from employees
                                            where department_id is not null);

v_id_department departments.DEPARTMENT_ID%TYPE;
v_name_department departments.DEPARTMENT_NAME%TYPE;

BEGIN

	DBMS_OUTPUT.PUT_LINE('DEPARTAMENTOS SIN EMPLEADOS: ');
	DBMS_OUTPUT.PUT_LINE('ID DEPARTAMENTO     ' || '    NOMBRE DEPARTAMENTO ' );
	DBMS_OUTPUT.PUT_LINE('--------------------------------------------------' );
	
	OPEN c_dptoVacios;
	LOOP
	FETCH c_dptoVacios INTO v_id_department, v_name_department;
		EXIT WHEN c_dptoVacios%NOTFOUND;

		DBMS_OUTPUT.PUT_LINE(v_id_department ||'                     '|| v_name_department);
	
	END LOOP;
	CLOSE c_dptoVacios;
	
END;

-- Punto 2) 
-- funcion FN_IDEMP_MANAGERDPTO

/* Notas: -------------------------------------------------------------------
* Se utilizo una funcion FN_EXISTE_IDDEPT para que se pueda reutilizar, se podria haber hecho adentro del del procedemiento.
* Se utilizo una funcion FN_IDEMP_MANAGERDPTO para que se pueda reutilizar, se podria haber hecho adentro del del procedemiento.
* Hice 2 funciones FN_IDEMP_ESMANAGER (Valida si el empleado tiene el puesto de trabajo "Manager") y FN_IDEMP_MANAGERDPTO (Valida si el
empleado es Manager de algun departamento) ya que no estaba especificado y hay empleados que no son manager pueden ser manager de un 
departamento como viceversa, ambas funciones las utilice en el procedimiento SP_UPD_DEPT_MAN. 
* Se utilizo una tabla auxiliar DEP_AUX para no modificar DEPARTMENTS del esquema HR */

-------------------------****** Testeo ********-------------------------------
DROP TABLE DEP_AUX;
EXECUTE SP_ALTA_DEPT(2,'RRHH',150,1700);
SELECT * FROM DEP_AUX;
SELECT FN_EXISTE_IDDEPT(230) FROM DUAL;
SELECT department_id FROM departments;
SELECT FN_IDEMP_MANAGERDPTO(203) FROM DUAL;	
SELECT FN_IDEMP_ESMANAGER(145) FROM DUAL;
SELECT FN_EXISTE_IDLOCALICION(10000) FROM DUAL;
SELECT * FROM LOCATIONS; 
EXECUTE SP_UPD_DEPT_MAN(108,10);
EXECUTE sp_Listado_Dpto_Vacio;
