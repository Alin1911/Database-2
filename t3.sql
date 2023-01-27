BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE TabLogare';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('It was not existing previously, nice.');
END;
/

CREATE TABLE TABLOGARE AS
    SELECT
        USER      AS WHO_ACTED,
        'SALARY INCREASE' AS HOW_ACTED,
        SYSDATE   AS WHEN_ACTED,
        'Steven King' AS FOR_WHOM_ACTED,
        0         AS IMPACT
    FROM
        EMPLOYEES
    WHERE
        1 = 0;

CREATE OR REPLACE PACKAGE P_TEST_FINAL AS
    FUNCTION F_BONUS(
        ID_AND EMPLOYEES.EMPLOYEE_ID%TYPE
    ) RETURN NUMBER;
    PROCEDURE ACTUALIZARE_DATE(
        ID_AND EMPLOYEES.EMPLOYEE_ID%TYPE
    );
    PROCEDURE ACTUALIZARE_DATE_TOTI_ANGAJATII;
END;
/

SELECT
    *
FROM
    TABLOGARE;


CREATE OR REPLACE PACKAGE BODY P_TEST_FINAL AS
  FUNCTION F_BONUS(ID_AND EMPLOYEES.EMPLOYEE_ID%TYPE)
  RETURN NUMBER
  IS
    diff NUMBER;
    maxmin NUMBER;
    salariu NUMBER;
  BEGIN
  
  SELECT salary
    INTO salariu
    FROM EMPLOYEES
    WHERE employee_id = ID_AND;
  
  SELECT MAX(salary)
    INTO maxmin 
    FROM EMPLOYEES
    WHERE salary < salariu;
    
  SELECT salary - maxmin
    INTO diff
    FROM employees
    WHERE employee_id = ID_AND;  
  
  RETURN diff;
  END F_BONUS;
  
  PROCEDURE ACTUALIZARE_DATE(ID_AND EMPLOYEES.EMPLOYEE_ID%TYPE)
  IS
  medie NUMBER;
  salariu_ang NUMBER;
  id_depp NUMBER;
  BEGIN
    SELECT salary
    INTO salariu_ang
    FROM EMPLOYEES
    WHERE employee_id = ID_AND;
  
    SELECT department_id
        INTO id_depp
        FROM EMPLOYEES
        WHERE employee_id = ID_AND;
    
    SELECT avg(salary)
        INTO medie
        FROM EMPLOYEES
        WHERE department_id = id_depp;
        
    IF salariu_ang > medie THEN
        UPDATE employees SET salary = salariu_ang - 15 * salariu_ang / 100 WHERE employee_id = ID_AND;
    ELSIF salariu_ang < medie THEN
        UPDATE employees SET salary =  salariu_ang + 15 * salariu_ang / 100 WHERE employee_id = ID_AND;
    END IF;
    
  END ACTUALIZARE_DATE;
  
  PROCEDURE ACTUALIZARE_DATE_TOTI_ANGAJATII
  IS
  BEGIN
    for angajat_id in (SELECT employee_id
        FROM EMPLOYEES
        WHERE department_id in (SELECT department_id FROM DEPARTMENTS WHERE department_name  LIKE '%[A,E,I,O,U,a,e,i,o,u]%';)
    LOOP
      ACTUALIZARE_DATE(angajat_id);
    END LOOP;
  END ACTUALIZARE_DATE_TOTI_ANGAJATII;
  
END P_TEST_FINAL;


CREATE OR REPLACE trigger modificare_salariu
AFTER UPDATE OF salary ON employees
FOR EACH ROW
DECLARE
  salariu_bonus NUMBER;
  data_ date;
  utilizator VARCHAR2(30);
  nume VARCHAR2(50);
BEGIN
  utilizator := USER;
  data_ := SYSDATE;
  salariu_bonus := F_BONUS(:old.employee_id);
  full_name := :old.first_name||' ' :old.last_name;
  IF :old.salary > :new.salary THEN
    INSERT INTO TABLOGARE VALUES(utilizator, 'scade', data_, nume, salariu_bonus);
  ELSIF :old.salary > :new.salary THEN
    INSERT INTO TABLOGARE VALUES(utilizator, 'creste', data_, nume, salariu_bonus);
  END IF;
END;
/