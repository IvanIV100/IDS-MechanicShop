DROP TABLE VZTAH_MAT_OPR;
DROP TABLE VZTAH_MECH_TER;

DROP TABLE TERMIN;
DROP TABLE OPRAVA;
DROP TABLE OBJEDNAVKA;
DROP TABLE ZAKAZNIK;
DROP TABLE MATERIAL;
DROP TABLE MECHANIK;

DROP SEQUENCE zak_id_seq;
DROP SEQUENCE obj_id_seq;
DROP SEQUENCE op_id_seq;
DROP SEQUENCE mat_id_seq;
DROP SEQUENCE ter_id_seq;

CREATE SEQUENCE zak_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE obj_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE op_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE mat_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ter_id_seq START WITH 1 INCREMENT BY 1;


CREATE TABLE ZAKAZNIK (
    ID_ZAK NUMBER DEFAULT zak_id_seq.NEXTVAL PRIMARY KEY,
    JMENO VARCHAR(30),
    PRIJMENI VARCHAR(30),
    TELEFON VARCHAR(15),
    EMAIL VARCHAR(30),
    ULICE VARCHAR(30),
    CISLO_DOMU VARCHAR(10),
    MESTO VARCHAR(30),
    PSC NUMERIC(5, 0),

    CONSTRAINT TEL_REGEX CHECK (REGEXP_LIKE(TELEFON, '^\+?\d+(-\d+)*$')),
    CONSTRAINT MAIL_REGEX CHECK (REGEXP_LIKE(EMAIL, '.*@.*\..*'))
);

CREATE TABLE OBJEDNAVKA(
    ID_OBJ NUMBER DEFAULT obj_id_seq.NEXTVAL PRIMARY KEY,
    REG_ZNACKA VARCHAR(15),
    ZNACKA_AUTA VARCHAR(30),
    MODEL VARCHAR(30),
    CISLO_FAKTURY VARCHAR(30) DEFAULT NULL,

    REF_ZAK INT NOT NULL,

    CONSTRAINT FK_OBJ FOREIGN KEY (REF_ZAK) REFERENCES ZAKAZNIK ON DELETE CASCADE
);

CREATE TABLE OPRAVA(
    ID_OPR NUMBER DEFAULT op_id_seq.NEXTVAL PRIMARY KEY,
    TYP_OPRAVY VARCHAR(30),
    POPIS_OPRAVY VARCHAR(200),
    MISTO VARCHAR(30),  -- atribut, protože tam mechanik může zadat cokoli

    REF_OBJ INT NOT NULL,

    CONSTRAINT FK_OPR FOREIGN KEY (REF_OBJ) REFERENCES OBJEDNAVKA ON DELETE CASCADE
);

CREATE TABLE MATERIAL(
    ID_MAT NUMBER DEFAULT mat_id_seq.NEXTVAL PRIMARY KEY,
    NAZEV_MATERIALU VARCHAR(100),
    VYROBNI_CISLO VARCHAR(20),
    TYP VARCHAR(30),
    DODAVATEL VARCHAR(30),
    CENA_KC INT
);

CREATE TABLE VZTAH_MAT_OPR(
    POCET INT,

    REF_MAT INT NOT NULL,
    REF_OPR INT NOT NULL,

    CONSTRAINT FK_VZ_SPO_MAT FOREIGN KEY (REF_MAT) REFERENCES MATERIAL ON DELETE CASCADE,
    CONSTRAINT FK_VZ_SPO_OPR FOREIGN KEY (REF_OPR) REFERENCES OPRAVA ON DELETE CASCADE,
    CONSTRAINT PK_VZ_MAT_OPR PRIMARY KEY (REF_MAT, REF_OPR)
);

CREATE TABLE TERMIN(
    ID_TER NUMBER DEFAULT ter_id_seq.NEXTVAL PRIMARY KEY,
    DATUM DATE,
    CAS VARCHAR(5),
    REF_OPR INT NOT NULL,
    CONSTRAINT FK_TER FOREIGN KEY (REF_OPR) REFERENCES OPRAVA ON DELETE CASCADE
);

CREATE TABLE MECHANIK(
    CISLO_ZAMEST INT PRIMARY KEY NOT NULL,
    JMENO VARCHAR(30),
    PRIJMENI VARCHAR(30),
    TELEFON VARCHAR(15),
    EMAIL VARCHAR(30),
    ULICE VARCHAR(30),
    CISLO_DOMU VARCHAR(10),
    MESTO VARCHAR(30),
    PSC NUMERIC(5, 0),
    DATUM_NASTUPU DATE,
    DATUM_NAROZENI DATE,

    SPECIALIZACE VARCHAR(30) DEFAULT NULL
);

CREATE TABLE VZTAH_MECH_TER(
    CENA_ZA_HOD NUMERIC(6, 2),
    POCET_HODIN NUMERIC(4, 2),

    REF_TER INT NOT NULL,
    REF_MECH INT NOT NULL,

    CONSTRAINT FK_VZ_PRA_MECH FOREIGN KEY (REF_MECH) REFERENCES MECHANIK ON DELETE CASCADE,
    CONSTRAINT FK_VZ_PRA_TER FOREIGN KEY (REF_TER) REFERENCES TERMIN ON DELETE CASCADE,
    CONSTRAINT PK_VZ_MECH_TER PRIMARY KEY (REF_TER, REF_MECH)
);

---TRIGGERS---
--Unify names format--
CREATE OR REPLACE TRIGGER capitalize_jmeno_prijmeni_ZAK
	BEFORE INSERT ON ZAKAZNIK
	FOR EACH ROW
BEGIN
  :NEW.JMENO := INITCAP(LOWER(:NEW.JMENO));
  :NEW.PRIJMENI := INITCAP(LOWER(:NEW.PRIJMENI));
END;

/

CREATE OR REPLACE TRIGGER capitalize_jmeno_prijmeni_MECH
BEFORE INSERT ON MECHANIK
FOR EACH ROW
BEGIN
  :NEW.JMENO := INITCAP(LOWER(:NEW.JMENO));
  :NEW.PRIJMENI := INITCAP(LOWER(:NEW.PRIJMENI));
END;

/
---Controls if there is a mechnic for given type of repair---
CREATE OR REPLACE TRIGGER trg_check_oprava_specialization
AFTER INSERT ON OPRAVA
FOR EACH ROW
DECLARE
  v_count NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM MECHANIK
  WHERE SPECIALIZACE = :NEW.TYP_OPRAVY;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'No mechanic found with matching specialization.');
  END IF;
END;

/


---INSERT DATA---
INSERT INTO ZAKAZNIK VALUES(DEFAULT, 'janko', 'doe', '+123-456789032', 'johndoe@example.com', 'Main Street', '123', 'Anytown', 12345);
INSERT INTO ZAKAZNIK VALUES(DEFAULT, 'Jane', 'Doe', '+321-987654321', 'jane.doe@example.com', 'Highway Avenue', '456', 'Anothercity', 67890);
INSERT INTO ZAKAZNIK VALUES(DEFAULT,'bob', 'SmITH', '+555-555555555', 'bob.smith@example.com', 'Elm Street', '789', 'Smalltown', 11111);
INSERT INTO ZAKAZNIK VALUES(DEFAULT,'Bib', 'ymiTH', '+666-6666666', 'bib.zmith@example.com', 'Slm Ave.', '987', 'Bigtown', 99999);
INSERT INTO ZAKAZNIK VALUES(DEFAULT,'BEb', 'KmIth', '+777-7777777', 'beb.kmith@example.com', 'Blimp Ave.', '666', 'midtown', 55555);
INSERT INTO ZAKAZNIK VALUES(DEFAULT, 'huGo', 'kokoška', '+420732349459', 'hugo@kokoska.cz', 'Tř. Kpt. Jaroše', '1829/14', 'Brno', 60200);

INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'ABC-123', 'Ford', 'Mustang', 'INV-1234', 1);
INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'ABC-123', 'Ford', 'Mustang', 'INV-5678', 1);
INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'ABC-789', 'Ford', 'Mondeo', 'INV-9012', 3);
INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'klk-753', 'Honda', 'Civic', 'INV-10012', 2);
INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'OLI-631', 'Toyota', 'Hillux', 'INV-1112', 4);
INSERT INTO OBJEDNAVKA VALUES(DEFAULT, 'GHI-789', 'Peugeot', '308', 'INV-1242', 5);

INSERT INTO MECHANIK VALUES(7493, 'john', 'Smith', '+1-1234567890', 'johnsmith@example.com', '123 Main St', 'Apt 456', 'Anytown', 12345, DATE '2022-01-01', DATE '1980-01-01', 'Engine');
INSERT INTO MECHANIK VALUES(9102, 'Jane', 'Doe', '+1-2345678901', 'janedoe@example.com', '456 First St', 'Suite 789', 'Anycity', 23456, DATE '2022-02-01', DATE '1985-02-01', 'Brakes');
INSERT INTO MECHANIK VALUES(2483, 'Bob', 'Johnson', '+1-345678901', 'bobjohnson@example.com', '789 Second St', 'Unit 123', 'Somewhere', 34567, DATE '2022-03-01', DATE '1990-03-01', 'Suspension');
INSERT INTO MECHANIK VALUES(6749, 'janko', 'Mrin', '+420-123456789', 'janni@example.com', '13 jankoByva', 'Apt 13', 'Anytown', 12345, DATE '2023-01-01', DATE '1986-01-01', 'Electronics');
INSERT INTO MECHANIK VALUES(7649, 'Mima', 'Nima', '+421-234567890', 'mmimma@example.com', '15 Svätého Vila', 'Suite 7', 'Anycity', 23456, DATE '2023-02-01', DATE '1975-02-01', 'Bottom');
INSERT INTO MECHANIK VALUES(3489, 'Kubo', 'Smrad', '+421-345678901', 'Kubbo@example.com', '78 Seco', 'Unit 12', 'Somewhere', 34567, DATE '2023-03-01', DATE '1995-03-01', 'Bodywork');
INSERT INTO MECHANIK VALUES(1234, 'Adam', 'Březík', '735345928', 'adambrezik@samohylmb.cz', 'Závodní', '14', 'Zlín', 58612, DATE '2020-04-19', DATE '1996-09-02', NULL);


INSERT INTO OPRAVA VALUES(DEFAULT, 'Brakes', 'Výměna brzdových destiček', 'Slot1', 1);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Engine', 'Výměna oleje a filtru', 'Slot2', 2);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Suspension','Geometria', 'Slot3', 3);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Bodywork' ,'Kontrola pred STK', 'Slot1', 4);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Electronics','Výměna rozvodů', 'Slot2', 5);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Electronics','Výměna rozvodů', 'Slot3', 6);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Bottom','Přezutí pneu na zimní - zákazník má vlastní', 'Rampa', 2);
INSERT INTO OPRAVA VALUES(DEFAULT, 'Electronics','Výměna rozvodů - zákazník chce rozvody zkontrolovat, zavolat na tel. a domluvit se co dále', 'Díra', 3);

INSERT INTO MATERIAL VALUES(DEFAULT, 'Řetězová pila', '123456', 'Elektrická', 'STIHL', 5000);
INSERT INTO MATERIAL VALUES(DEFAULT, 'Ocelová trubka', '789012', 'Konstrukční', 'Svoboda Steel', 10);
INSERT INTO MATERIAL VALUES(DEFAULT, 'Univerzální sportovní vzduchový filtr Races, velký', 'RS-AF1_70BL', 'Vzduchový filtr', 'Races', 212);

INSERT INTO VZTAH_MAT_OPR VALUES(2, 2, 2);
INSERT INTO VZTAH_MAT_OPR VALUES(1, 1, 1);

INSERT INTO TERMIN VALUES(DEFAULT, DATE '2023-03-25', '9:00', 1);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2023-03-25', '11:30', 2);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2023-03-26', '13:00', 3);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2023-02-20', '15:00', 4);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2022-03-05', '10:30', 5);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2022-07-12', '12:00', 5);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2022-03-31', '10:00', 6);
INSERT INTO TERMIN VALUES(DEFAULT, DATE '2023-03-31', '14:30', 8);


INSERT INTO VZTAH_MECH_TER VALUES(200, 4, 1, 9102);
INSERT INTO VZTAH_MECH_TER VALUES(150, 3, 2, 2483);
INSERT INTO VZTAH_MECH_TER VALUES(180, 2, 3, 6749);
INSERT INTO VZTAH_MECH_TER VALUES(200, 4, 4, 7649);
INSERT INTO VZTAH_MECH_TER VALUES(150, 3, 5, 7493);
INSERT INTO VZTAH_MECH_TER VALUES(180, 2, 5, 9102);

--SPOJENÍ DVOU TABULEK (1/2)
--Výpis kontaktních informací o zákaznících, kterým bylo opraveno auto značky Ford.
SELECT JMENO, PRIJMENI, TELEFON, EMAIL, CISLO_FAKTURY
    FROM ZAKAZNIK
        JOIN OBJEDNAVKA O ON ZAKAZNIK.ID_ZAK=O.REF_ZAK
    WHERE ZNACKA_AUTA = 'Ford'
    ORDER BY PRIJMENI ASC;

--SPOJENÍ DVOU TABULEK (2/2)
--Kde všude za poslední rok probíhala výměna rozvodů?
SELECT DISTINCT O.MISTO
    FROM TERMIN T, OPRAVA O
    WHERE T.REF_OPR = O.ID_OPR
        AND O.TYP_OPRAVY LIKE 'Výměna rozvodů%'
        AND T.DATUM BETWEEN DATE '2022-04-02' AND DATE '2023-04-02';

--SPOJENÍ TŘÍ TABULEK (1/1)
--Kolik mechaniků pracuje 25. 3. 2023 v 9:00?
SELECT COUNT(*)
    FROM VZTAH_MECH_TER V
        JOIN TERMIN T ON T.ID_TER = V.REF_TER 
        JOIN MECHANIK M ON V.REF_MECH = M.CISLO_ZAMEST
    WHERE T.DATUM = DATE '2023-03-25'
        AND T.CAS = '9:00';

--EXISTS (1/1)
--Kterým opravám (z jaké objednávky od jakého zákazníka) ještě nebyly přiřazeny žádné termíny?
SELECT Z.JMENO, Z.PRIJMENI, OBJ.REG_ZNACKA, OPR.MISTO, OPR.TYP_OPRAVY
    FROM ZAKAZNIK Z, OBJEDNAVKA OBJ, OPRAVA OPR
    WHERE Z.ID_ZAK = OBJ.REF_ZAK
        AND OPR.REF_OBJ = OBJ.ID_OBJ
        AND NOT EXISTS(
            SELECT *
                FROM TERMIN T
                WHERE T.REF_OPR = OPR.ID_OPR
        );

--IN (1/1)
--Jaké materiály ještě nebyly na nic použity?
SELECT *
    FROM MATERIAL M
    WHERE M.ID_MAT NOT IN (
        SELECT M.ID_MAT
            FROM VZTAH_MAT_OPR V
                JOIN OPRAVA O ON V.REF_OPR = O.ID_OPR
                JOIN MATERIAL M ON V.REF_MAT = M.ID_MAT
    );

--GROUP BY (1/2)
--Kolik oprav je v jednotlivé dny (alespoň jedna oprava), seřazeno sestupně?
SELECT DATUM, COUNT(*) POCET
    FROM TERMIN
    GROUP BY DATUM
    ORDER BY POCET DESC;

--GROUP BY (2/2)
--Kolik peněz si vydělali jednotliví mechanici? (v abecedním pořadí)
SELECT JMENO, PRIJMENI, SUM(CENA_ZA_HOD * POCET_HODIN) AS VYDELEK
    FROM MECHANIK M
        LEFT JOIN VZTAH_MECH_TER V ON M.CISLO_ZAMEST = V.REF_MECH
    GROUP BY JMENO, PRIJMENI
    ORDER BY JMENO, PRIJMENI ASC;







-- PROCEDURY --
-- Výpis faktury dané objednávky / celkové ceny objednávky

-- Přidání materiálu k opravě (pokud v databázi není, přidá se automaticky)


-- INDEX --
--

CREATE INDEX IDX_VZTAH_MAT_OPR_REF_OPR ON VZTAH_MAT_OPR(REF_OPR);


EXPLAIN PLAN FOR
SELECT O.ID_OPR, O.POPIS_OPRAVY, SUM(M.CENA_KC) AS TOTAL_PRICE_MAT
FROM OPRAVA O
JOIN VZTAH_MAT_OPR V ON V.REF_OPR = O.ID_OPR
JOIN MATERIAL M ON M.ID_MAT = V.REF_MAT
GROUP BY O.ID_OPR, O.POPIS_OPRAVY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

DROP INDEX IDX_VZTAH_MAT_OPR_REF_OPR;
CREATE INDEX IDX_VZTAH_MAT_OPR_REF_OPR_MAT ON VZTAH_MAT_OPR(REF_OPR, REF_MAT);
EXPLAIN PLAN FOR
SELECT O.ID_OPR, O.POPIS_OPRAVY, SUM(M.CENA_KC) AS TOTAL_PRICE_MAT
FROM OPRAVA O
JOIN VZTAH_MAT_OPR V ON V.REF_OPR = O.ID_OPR
JOIN MATERIAL M ON M.ID_MAT = V.REF_MAT
GROUP BY O.ID_OPR, O.POPIS_OPRAVY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- EXPLAIN PLAN --
-- 


-- PŘÍSTUPOVÁ PRÁVA --
-- 


-- MATERIALIZOVANÝ POHLED --
-- 


-- SELECT S WITH A CASE
-- 