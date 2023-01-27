set serveroutput on

DECLARE
    TYPE rank IS RECORD(
        id  NUMBER,
        lvl NUMBER,
        last_id NUMBER,
        department NUMBER,
        salariu NUMBER
    );

    TYPE vect IS varray(300) of rank;
    aux vect := vect();
    angajatii vect := vect();
    nivel1 NUMBER;
    nivel NUMBER := 0;
    local NUMBER := 0;
    department_id1 NUMBER := 0;
    manager_id_aux NUMBER;
    ang_count NUMBER;
    sal NUMBER;
    functiee NUMBER;

    TYPE ang_struct IS RECORD(
        nume  varchar2(100),
        nr_colegi NUMBER,
        med_venit_nivel NUMBER := 0,
        status varchar2(20)
    );
    TYPE result IS varray(300) of ang_struct;
    rezultat result := result();

    PROCEDURE initialize(
        angajatii in out vect
    ) 
    is begin 
            FOR angajat IN (
            SELECT *
            from employees
    )
    loop
        SELECT COUNT(1)
            INTO ang_count
            FROM employees
            WHERE manager_id = angajat.employee_id;
            IF ang_count = nivel THEN
                angajatii.EXTEND;
                angajatii(angajatii.LAST).id := angajat.employee_id;
                angajatii(angajatii.LAST).last_id := 0;
                angajatii(angajatii.LAST).lvl := nivel;
                angajatii(angajatii.LAST).salariu := angajat.salary;
                angajatii(angajatii.LAST).department := angajat.department_id;
            end if;
        end loop;

    end initialize;
    
    FUNCTION condition(
        i in number
        )
    return number
    is
            
    begin
        FOR j IN angajatii.FIRST..angajatii.LAST
                    LOOP
                    IF angajatii(j).id = manager_id_aux THEN
                        IF nivel > angajatii(j).lvl and angajatii(angajatii(j).last_id).lvl = angajatii(i).lvl - 1 then
                            angajatii(j).lvl := nivel;
                            angajatii(j).last_id := i;
                        end if;
                        local := 1;
                    END IF;
                end loop;
                return 1;
    end condition;

BEGIN
    initialize(angajatii);
   
    FOR n IN (
        SELECT *
        from employees
    )
    loop
        nivel := nivel + 1;
        FOR i IN angajatii.FIRST..angajatii.LAST
        LOOP
            SELECT manager_id, department_id, salary
            INTO manager_id_aux, department_id1, sal
            FROM employees
            WHERE employee_id = angajatii(i).id;

            if manager_id_aux is not NULL then
                functiee := condition( i);
                if aux.count > 0 then
                FOR j IN aux.FIRST..aux.LAST
                    LOOP
                    IF aux(j).id = manager_id_aux THEN
                        IF nivel > aux(j).lvl and  angajatii(angajatii(j).last_id).lvl = angajatii(i).lvl - 1 then
                            aux(j).lvl := nivel;
                            aux(j).last_id := i;
                        end if;
                        local := 1;
                    END IF;
                end loop;
                end if;
                if local = 0 THEN
                    aux.EXTEND;
                    aux(aux.LAST).last_id := i;
                    aux(aux.LAST).id := manager_id_aux;
                    aux(aux.LAST).lvl := nivel;
                    aux(aux.LAST).department := department_id1;
                    aux(aux.LAST).salariu := sal;
                end if;
                local := 0;
            end if;
        end loop;
       
        if aux.count > 0 then
            FOR k IN aux.FIRST..aux.LAST
            loop
                angajatii.EXTEND;
                angajatii(angajatii.LAST).last_id := aux(k).last_id;
                angajatii(angajatii.LAST).id := aux(k).id;
                angajatii(angajatii.LAST).salariu := aux(k).salariu;
                angajatii(angajatii.LAST).department := aux(k).department;
                angajatii(angajatii.LAST).lvl := aux(k).lvl;
            end loop;
            aux.DELETE;
        end if;
    end loop;

   
    FOR i IN angajatii.FIRST..angajatii.LAST
    LOOP
        FOR angajat IN (
            SELECT *
            from employees
        )
        LOOP
            if angajat.employee_id = angajatii(i).id then
                    rezultat.EXTEND;
                    rezultat(rezultat.LAST).nume  :=  angajat.last_name || ' ' || angajat.first_name;
                    rezultat(rezultat.LAST).nr_colegi  :=  0;
             end if;
        end loop;
    end loop;
 

    FOR i IN angajatii.FIRST..angajatii.LAST
     
    LOOP
        FOR j IN angajatii.FIRST..angajatii.LAST
        LOOP
            if (angajatii(i).department = angajatii(j).department) and (angajatii(i).lvl = angajatii(j).lvl) then
                rezultat(i).nr_colegi  :=  rezultat(i).nr_colegi + 1;
                rezultat(i).med_venit_nivel :=  rezultat(i).med_venit_nivel + angajatii(j).salariu;
            end if;
        end loop;
    end loop;

    FOR i IN rezultat.FIRST..rezultat.LAST
    LOOP
        dbms_output.put_line( rpad(rezultat(i).nume, 20, ' ') || ' numar_colegi= ' || rpad(rezultat(i).nr_colegi, 12, ' ')
        || 'salariu mediu= ' || rpad(rezultat(i).med_venit_nivel / rezultat(i).nr_colegi, 12, ' ')
        );
    end loop;
END;
/