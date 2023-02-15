--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: get_available_ships_by_city(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_available_ships_by_city(required_city character varying) RETURNS TABLE(ship_id integer, ship_name character varying, model_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
		SELECT ship.ship_id, ship.ship_name, model.model_name FROM ship JOIN model ON ship.model_id = model.model_id JOIN city ON ship.city_id = city.city_id WHERE ship.ship_status = true AND city.city_name = required_city ORDER BY ship.ship_id ASC, model.model_name ASC;
END;
$$;


ALTER FUNCTION public.get_available_ships_by_city(required_city character varying) OWNER TO postgres;

--
-- Name: set_ship_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ship_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE ship SET ship_status = false WHERE ship.ship_id = NEW.ship_id;
	RETURN NEW;
END;$$;


ALTER FUNCTION public.set_ship_status() OWNER TO postgres;

--
-- Name: set_task_end(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_task_end() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF NEW.task_status = true THEN
		UPDATE task SET task_end = NOW()::date WHERE task_id = OLD.task_id;
		UPDATE ship SET ship_status = true WHERE ship_id IN (SELECT ship_id FROM ship_task WHERE task_id = OLD.task_id);
	END IF;
	RETURN NEW;
END;$$;


ALTER FUNCTION public.set_task_end() OWNER TO postgres;

--
-- Name: task_to_csv(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.task_to_csv()
    LANGUAGE plpgsql
    AS $$
BEGIN
	COPY
		(SELECT 
		 	task.task_id,
		 	task_type_name,
		 	task_start,
		 	task_end,
		 	task_status,
		 	city_name,
		 	ship_name,
		 	full_name AS captain_name
		 FROM task
		 JOIN task_type ON
		 	task.task_type_id = task_type.task_type_id
		 JOIN ship_task ON
		 	task.task_id = ship_task.task_id
		 JOIN ship ON
		 	ship_task.ship_id = ship.ship_id
		 JOIN city ON
		 	ship.city_id = city.city_id
		 JOIN ship_crew ON
		 	ship.ship_id = ship_crew.ship_id
		 JOIN crew ON
		 	ship_crew.crew_id = crew.crew_id
		 WHERE
		 	grade_id = 1
		 ORDER BY
		 	task.task_id ASC)
	TO 'C:\ships\tasks.csv'
	WITH DELIMITER ',' CSV HEADER;
END;
$$;


ALTER PROCEDURE public.task_to_csv() OWNER TO postgres;

--
-- Name: city_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.city_city_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.city_city_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: city; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.city (
    city_id integer DEFAULT nextval('public.city_city_id_seq'::regclass) NOT NULL,
    city_name character varying(255) NOT NULL
);


ALTER TABLE public.city OWNER TO postgres;

--
-- Name: crew_crew_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crew_crew_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.crew_crew_id_seq OWNER TO postgres;

--
-- Name: crew; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crew (
    crew_id integer DEFAULT nextval('public.crew_crew_id_seq'::regclass) NOT NULL,
    full_name character varying(255) NOT NULL,
    age integer NOT NULL,
    grade_id integer NOT NULL,
    city_id integer NOT NULL
);


ALTER TABLE public.crew OWNER TO postgres;

--
-- Name: grade_grade_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grade_grade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grade_grade_id_seq OWNER TO postgres;

--
-- Name: grade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade (
    grade_id integer DEFAULT nextval('public.grade_grade_id_seq'::regclass) NOT NULL,
    grade_name character varying(255) NOT NULL
);


ALTER TABLE public.grade OWNER TO postgres;

--
-- Name: ship_ship_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ship_ship_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ship_ship_id_seq OWNER TO postgres;

--
-- Name: ship; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ship (
    ship_id integer DEFAULT nextval('public.ship_ship_id_seq'::regclass) NOT NULL,
    ship_name character varying(255) NOT NULL,
    ship_status boolean DEFAULT true NOT NULL,
    city_id integer NOT NULL,
    model_id integer NOT NULL
);


ALTER TABLE public.ship OWNER TO postgres;

--
-- Name: ship_crew_ship_crew_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ship_crew_ship_crew_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ship_crew_ship_crew_id_seq OWNER TO postgres;

--
-- Name: ship_crew; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ship_crew (
    ship_crew_id integer DEFAULT nextval('public.ship_crew_ship_crew_id_seq'::regclass) NOT NULL,
    ship_id integer NOT NULL,
    crew_id integer NOT NULL
);


ALTER TABLE public.ship_crew OWNER TO postgres;

--
-- Name: crew_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.crew_view AS
 SELECT crew.crew_id,
    crew.full_name,
    grade.grade_name,
    ship.ship_name,
    city.city_name
   FROM ((((public.crew
     JOIN public.city ON ((crew.city_id = city.city_id)))
     JOIN public.grade ON ((crew.grade_id = grade.grade_id)))
     JOIN public.ship_crew ON ((crew.crew_id = ship_crew.crew_id)))
     JOIN public.ship ON ((ship_crew.ship_id = ship.ship_id)))
  ORDER BY crew.crew_id, ship.ship_name, grade.grade_id;


ALTER TABLE public.crew_view OWNER TO postgres;

--
-- Name: model_model_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.model_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.model_model_id_seq OWNER TO postgres;

--
-- Name: model; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.model (
    model_id integer DEFAULT nextval('public.model_model_id_seq'::regclass) NOT NULL,
    model_name character varying(255) NOT NULL
);


ALTER TABLE public.model OWNER TO postgres;

--
-- Name: ship_task_ship_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ship_task_ship_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ship_task_ship_task_id_seq OWNER TO postgres;

--
-- Name: ship_task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ship_task (
    ship_task_id integer DEFAULT nextval('public.ship_task_ship_task_id_seq'::regclass) NOT NULL,
    task_id integer NOT NULL,
    ship_id integer NOT NULL
);


ALTER TABLE public.ship_task OWNER TO postgres;

--
-- Name: ship_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ship_view AS
 SELECT ship.ship_id,
    ship.ship_name,
    ship.ship_status,
    city.city_name,
    model.model_name
   FROM ((public.ship
     JOIN public.city ON ((ship.city_id = city.city_id)))
     JOIN public.model ON ((ship.model_id = model.model_id)))
  ORDER BY ship.ship_id;


ALTER TABLE public.ship_view OWNER TO postgres;

--
-- Name: task_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_task_id_seq OWNER TO postgres;

--
-- Name: task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task (
    task_id integer DEFAULT nextval('public.task_task_id_seq'::regclass) NOT NULL,
    task_type_id integer NOT NULL,
    task_start date NOT NULL,
    task_end date,
    task_status boolean DEFAULT false NOT NULL
);


ALTER TABLE public.task OWNER TO postgres;

--
-- Name: task_type_task_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_type_task_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_type_task_type_id_seq OWNER TO postgres;

--
-- Name: task_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_type (
    task_type_id integer DEFAULT nextval('public.task_type_task_type_id_seq'::regclass) NOT NULL,
    task_type_name character varying(255) NOT NULL
);


ALTER TABLE public.task_type OWNER TO postgres;

--
-- Name: task_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.task_view AS
 SELECT task.task_id,
    task_type.task_type_name,
    task.task_start,
    ship.ship_name,
    crew.full_name AS captain_name
   FROM (((((public.task
     JOIN public.task_type ON ((task.task_type_id = task_type.task_type_id)))
     JOIN public.ship_task ON ((task.task_id = ship_task.task_id)))
     JOIN public.ship ON ((ship_task.ship_id = ship.ship_id)))
     JOIN public.ship_crew ON ((ship.ship_id = ship_crew.ship_id)))
     JOIN public.crew ON ((ship_crew.crew_id = crew.crew_id)))
  WHERE ((task.task_status = false) AND (crew.grade_id = 1))
  ORDER BY task.task_id;


ALTER TABLE public.task_view OWNER TO postgres;

--
-- Data for Name: city; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.city (city_id, city_name) FROM stdin;
1	New York
2	Norfolk
3	Boston
\.


--
-- Data for Name: crew; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.crew (crew_id, full_name, age, grade_id, city_id) FROM stdin;
1	Joseph Robertson	50	1	1
2	Kirk Moody	40	2	1
3	Donald Moore	35	3	1
4	Shawn Massey	36	3	1
5	Glenn Wright	23	4	1
6	Albert Beck	24	4	1
7	Harold Harris	26	4	1
8	Larry Scott	28	4	1
9	Steven Henry	52	1	1
10	James Harmon	46	2	1
11	James Graves	34	3	1
12	Fred Brown	33	3	1
13	Peter Bell	23	4	1
14	Phillip Powell	22	4	1
15	Jared Glover	24	4	1
16	Douglas Sanders	27	4	1
17	Adam Wright	51	1	1
18	Don Williams	48	2	1
19	Clyde Welch	38	3	1
20	William Gonzales	39	3	1
21	Matthew Garrett	25	4	1
22	Jon Butler	23	4	1
23	Paul Woods	22	4	1
24	Johnny Brown	25	4	1
25	Matthew Phillips	56	1	2
26	Roger Rodriguez	39	2	2
27	Willie Thompson	31	3	1
28	John Bowman	32	3	1
29	Andrew Brown	24	4	1
30	Robert Hogan	25	4	1
31	Fgrade Davis	24	4	1
32	Paul Harris	21	4	1
33	Robert Davis	46	1	2
34	James Griffith	34	2	2
35	Matthew Knight	38	3	2
36	Fgrade Miller	40	3	2
37	Gary Hart	21	4	2
38	Harold Davis	22	4	2
39	John Johnson	30	4	2
40	Thomas Carroll	21	4	2
41	Alexander Jennings	48	1	2
42	Joseph Stewart	33	2	2
43	Paul Hunt	33	3	2
44	Robert Anderson	32	3	2
45	Matthew Walker	21	4	2
46	William Hunt	22	4	2
47	Roy Harris	24	4	2
48	Steven Johnson	24	4	2
49	Christopher Campbell	52	1	2
50	Wayne Munoz	32	2	2
51	William Adams	33	3	2
52	Charles Smith	33	3	2
53	David Anderson	21	4	2
54	Neil Anderson	25	4	2
55	John Garcia	25	4	2
56	Everett Cole	24	4	2
57	Frederick Campbell	52	1	3
58	Chester Hayes	39	2	3
59	Lawrence Robinson	37	3	3
60	Richard Hampton	42	3	3
61	Fgrade Sanchez	27	4	3
62	Arthur Vega	19	4	3
63	David Cunningham	22	4	3
64	Dan Price	21	4	3
65	William Martin	53	1	3
66	Joshua Thomas	40	2	3
67	Robert Hansen	35	3	3
68	Donald Vega	33	3	3
69	Henry Adams	20	4	3
70	Milton Miller	21	4	3
71	Jason Colon	25	4	3
72	Jason Cox	26	4	3
73	Shawn Bailey	51	1	3
74	Billy Roy	45	2	3
75	Donald James	34	3	3
76	Jimmy Evans	29	3	3
77	William Potter	21	4	3
78	Eddie Allen	22	4	3
79	Roger Brown	22	4	3
80	Jimmy Carter	21	4	3
\.


--
-- Data for Name: grade; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade (grade_id, grade_name) FROM stdin;
1	Captain
2	Midshipman
3	Foreman
4	Sailor
\.


--
-- Data for Name: model; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.model (model_id, model_name) FROM stdin;
1	Cargo barge
2	Passenger ferry
3	Coast guard boat
\.


--
-- Data for Name: ship; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ship (ship_id, ship_name, ship_status, city_id, model_id) FROM stdin;
3	Ferreter	t	1	3
4	Pembroke Castle	t	2	1
5	Cairo	t	2	2
6	Utile	t	2	3
7	Cynthia	t	2	3
8	The Folkeston	t	3	1
9	Manilla	t	3	2
10	Thorough	t	3	3
1	Hood	t	1	1
2	Coureuse	t	1	2
\.


--
-- Data for Name: ship_crew; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ship_crew (ship_crew_id, ship_id, crew_id) FROM stdin;
1	1	1
2	1	2
3	1	3
4	1	4
5	1	5
6	1	6
7	1	7
8	1	8
9	2	9
10	2	10
11	2	11
12	2	12
13	2	13
14	2	14
15	2	15
16	2	16
17	3	17
18	3	18
19	3	19
20	3	20
21	3	21
22	3	22
23	3	23
24	3	24
25	4	25
26	4	26
27	4	27
28	4	28
29	4	29
30	4	30
31	4	31
32	4	32
33	5	33
34	5	34
35	5	35
36	5	36
37	5	37
38	5	38
39	5	39
40	5	40
41	6	41
42	6	42
43	6	43
44	6	44
45	6	45
46	6	46
47	6	47
48	6	48
49	7	49
50	7	50
51	7	51
52	7	52
53	7	53
54	7	54
55	7	55
56	7	56
57	8	57
58	8	58
59	8	59
60	8	60
61	8	61
62	8	62
63	8	63
64	8	64
65	9	65
66	9	66
67	9	67
68	9	68
69	9	69
70	9	70
71	9	71
72	9	72
73	10	73
74	10	74
75	10	75
76	10	76
77	10	77
78	10	78
79	10	79
80	10	80
\.


--
-- Data for Name: ship_task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ship_task (ship_task_id, task_id, ship_id) FROM stdin;
1	1	1
2	2	1
3	3	2
4	4	3
5	5	4
6	6	4
7	7	5
8	8	6
9	9	6
10	10	7
11	11	7
12	12	8
13	13	8
14	14	9
15	15	10
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task (task_id, task_type_id, task_start, task_end, task_status) FROM stdin;
1	1	2022-07-01	2022-07-15	t
2	4	2022-07-16	2022-07-17	t
3	2	2022-08-12	2022-08-13	t
4	3	2022-10-01	2022-10-02	t
5	1	2022-06-07	2022-06-14	t
6	4	2022-07-16	2022-07-17	t
7	2	2022-07-01	2022-07-02	t
8	3	2022-09-15	2022-09-21	t
9	4	2022-09-21	2022-09-22	t
10	3	2022-09-01	2022-09-02	t
11	4	2022-09-02	2022-09-03	t
12	1	2022-08-12	2022-08-22	t
13	4	2022-08-22	2022-08-23	t
14	2	2022-09-11	2022-09-15	t
15	3	2022-12-12	2022-12-13	t
\.


--
-- Data for Name: task_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task_type (task_type_id, task_type_name) FROM stdin;
1	Cargo transportation
2	Passengers transportation
3	Coast patrolling
4	Refueling
\.


--
-- Name: city_city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.city_city_id_seq', 3, true);


--
-- Name: crew_crew_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.crew_crew_id_seq', 80, true);


--
-- Name: grade_grade_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_grade_id_seq', 4, true);


--
-- Name: model_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.model_model_id_seq', 3, true);


--
-- Name: ship_crew_ship_crew_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ship_crew_ship_crew_id_seq', 80, true);


--
-- Name: ship_ship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ship_ship_id_seq', 10, true);


--
-- Name: ship_task_ship_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ship_task_ship_task_id_seq', 21, true);


--
-- Name: task_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_task_id_seq', 23, true);


--
-- Name: task_type_task_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_type_task_type_id_seq', 4, true);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);


--
-- Name: crew crew_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crew
    ADD CONSTRAINT crew_pkey PRIMARY KEY (crew_id);


--
-- Name: grade grade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade
    ADD CONSTRAINT grade_pkey PRIMARY KEY (grade_id);


--
-- Name: model model_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model
    ADD CONSTRAINT model_pkey PRIMARY KEY (model_id);


--
-- Name: ship_crew ship_crew_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_crew
    ADD CONSTRAINT ship_crew_pkey PRIMARY KEY (ship_crew_id);


--
-- Name: ship ship_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship
    ADD CONSTRAINT ship_pkey PRIMARY KEY (ship_id);


--
-- Name: ship_task ship_task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_task
    ADD CONSTRAINT ship_task_pkey PRIMARY KEY (ship_task_id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);


--
-- Name: task_type task_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_pkey PRIMARY KEY (task_type_id);


--
-- Name: crew_grade_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crew_grade_idx ON public.crew USING btree (grade_id);


--
-- Name: ship_task set_ship_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_ship_status AFTER INSERT ON public.ship_task FOR EACH ROW EXECUTE FUNCTION public.set_ship_status();


--
-- Name: task set_task_end; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_task_end AFTER UPDATE OF task_status ON public.task FOR EACH ROW EXECUTE FUNCTION public.set_task_end();


--
-- Name: crew crew_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crew
    ADD CONSTRAINT crew_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: crew crew_grade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crew
    ADD CONSTRAINT crew_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grade(grade_id);


--
-- Name: ship ship_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship
    ADD CONSTRAINT ship_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: ship_crew ship_crew_crew_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_crew
    ADD CONSTRAINT ship_crew_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES public.crew(crew_id);


--
-- Name: ship_crew ship_crew_ship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_crew
    ADD CONSTRAINT ship_crew_ship_id_fkey FOREIGN KEY (ship_id) REFERENCES public.ship(ship_id);


--
-- Name: ship ship_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship
    ADD CONSTRAINT ship_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.model(model_id);


--
-- Name: ship_task ship_task_ship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_task
    ADD CONSTRAINT ship_task_ship_id_fkey FOREIGN KEY (ship_id) REFERENCES public.ship(ship_id);


--
-- Name: ship_task ship_task_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ship_task
    ADD CONSTRAINT ship_task_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.task(task_id);


--
-- Name: task task_task_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_task_type_id_fkey FOREIGN KEY (task_type_id) REFERENCES public.task_type(task_type_id);


--
-- Name: FUNCTION get_available_ships_by_city(required_city character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_available_ships_by_city(required_city character varying) TO dispatcher;


--
-- Name: FUNCTION set_task_end(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.set_task_end() FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_task_end() TO dispatcher;


--
-- Name: PROCEDURE task_to_csv(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.task_to_csv() TO dispatcher;


--
-- Name: SEQUENCE city_city_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.city_city_id_seq TO dispatcher;


--
-- Name: TABLE city; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.city TO dispatcher;


--
-- Name: SEQUENCE crew_crew_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.crew_crew_id_seq TO dispatcher;


--
-- Name: TABLE crew; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.crew TO dispatcher;


--
-- Name: SEQUENCE grade_grade_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.grade_grade_id_seq TO dispatcher;


--
-- Name: TABLE grade; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.grade TO dispatcher;


--
-- Name: SEQUENCE ship_ship_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ship_ship_id_seq TO dispatcher;


--
-- Name: TABLE ship; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.ship TO dispatcher;


--
-- Name: SEQUENCE ship_crew_ship_crew_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ship_crew_ship_crew_id_seq TO dispatcher;


--
-- Name: TABLE ship_crew; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.ship_crew TO dispatcher;


--
-- Name: TABLE crew_view; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crew_view TO "crew member";
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.crew_view TO dispatcher;


--
-- Name: SEQUENCE model_model_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.model_model_id_seq TO dispatcher;


--
-- Name: TABLE model; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.model TO dispatcher;


--
-- Name: SEQUENCE ship_task_ship_task_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ship_task_ship_task_id_seq TO dispatcher;


--
-- Name: TABLE ship_task; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.ship_task TO dispatcher;


--
-- Name: TABLE ship_view; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.ship_view TO "crew member";
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.ship_view TO dispatcher;


--
-- Name: SEQUENCE task_task_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.task_task_id_seq TO dispatcher;


--
-- Name: TABLE task; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.task TO dispatcher;


--
-- Name: SEQUENCE task_type_task_type_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.task_type_task_type_id_seq TO dispatcher;


--
-- Name: TABLE task_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.task_type TO dispatcher;


--
-- Name: TABLE task_view; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.task_view TO "crew member";
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE public.task_view TO dispatcher;


--
-- PostgreSQL database dump complete
--

