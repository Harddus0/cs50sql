-- COMMON QUERIES 
-- Find all project documents of a company
SELECT "documents"."id", "documents"."name", "document",
    "code" AS "Project Code", "status" AS "Project Status" 
FROM "documents"
JOIN "projects" ON "project_id" = "projects"."id"
WHERE "projects"."company_id" = (
    SELECT "id" FROM "companies"
    WHERE "name" = 'Construction Company XYZ'
);

-- Find all stakeholders who might supply tiles
SELECT * FROM "stakeholders"
WHERE "type" = 'supplier'
AND "stakeholders"."discription" LIKE '%tile%' 
AND "company_id" = (
    SELECT "id" FROM "companies"
    WHERE "name" = 'Construction Company XYZ'
);

-- Find all pending supply orders of a project
SELECT "order_id", "status", "stakeholder_id", "analytic_id",
    "quantity", "budget_id", "task"
FROM "supply_orders"
JOIN "supply_items" ON "supply_items"."order_id" = "supply_orders"."id"
JOIN "wbs_budget" ON "supply_items"."wbs_budget_id" = "wbs_budget"."id"
JOIN "budgeting" ON "wbs_budget"."budget_id" = "budgeting"."id"
WHERE "status" = 'pending'
AND
"budgeting"."project_id" = (
    SELECT "id" FROM "projects"
    WHERE "code" = 'CW'
    AND "company_id" = (
        SELECT "id" FROM "companies"
        WHERE "name" = 'Construction Company XYZ'
    )
);

-- Find all inflow transactions
SELECT "transactions"."id", "stakeholders"."name", "amount", "transaction_date" 
FROM "transactions"
JOIN "stakeholders" ON "stakeholder_id" = "stakeholders"."id"
WHERE "transaction_type" = 'inflow'
AND
"company_id" = (
    SELECT "id" FROM "companies"
    WHERE "name" = 'Construction Company XYZ'
);

-- Find all transactions and involved stakeholders of a month
SELECT "transactions"."id", "transaction_type", "stakeholders"."name",
    "amount", "transaction_date", "transactions"."discription"
FROM "transactions"
JOIN "stakeholders" ON "stakeholder_id" = "stakeholders"."id"
WHERE "transaction_date" BETWEEN '2024-10-01' AND '2024-10-31'
AND
"company_id" = (
    SELECT "id" FROM "companies"
    WHERE "name" = 'Construction Company XYZ'
);

-- Find the full composition table for a company 
SELECT * FROM full_composition AS "composition_data" 
WHERE "composition_data"."company_id" = (
    SELECT "id" FROM "companies"
    WHERE "name" = 'Construction Company XYZ'
);

-- Find the total cost of a project
SELECT SUM(tc.synthetic_total + tc.analytic_total) AS "Total cost"
FROM total_cost AS tc
JOIN "wbs_budget" AS wb ON tc."id" = wb."id"
JOIN "budgeting" AS b ON wb."budget_id" = b."id"
WHERE b."project_id" = (
    SELECT "id" FROM "projects"
    WHERE "code" = 'CW'
    AND "company_id" = (
        SELECT "id" FROM "companies"
        WHERE "name" = 'Construction Company XYZ'
    )
);

-- Find the cost of a budgeting WBS's activity
SELECT 
    wb."task", 
    (tc.synthetic_total + tc.analytic_total) AS "Total cost"
FROM total_cost AS tc
JOIN "wbs_budget" AS wb ON tc."id" = wb."id"
JOIN "budgeting" AS b ON wb."budget_id" = b."id"
WHERE b."project_id" = (
    SELECT "id" FROM "projects"
    WHERE "code" = 'CW'
    AND "company_id" = (
        SELECT "id" FROM "companies"
        WHERE "name" = 'Construction Company XYZ'
    )
AND wb."task" = 'Walls'
);

-- Find the cost of a planning WBS's activity
SELECT 
    wp."task", 
    (tc.synthetic_total + tc.analytic_total) AS "Total cost"
FROM total_cost AS tc
JOIN "wbs_budget" AS wb ON tc."id" = wb."id"
JOIN "wbs_budget_plan" AS wbp ON wbp."wbs_plan_id" = wb."id"
JOIN "wbs_plan" AS wp ON wbp."wbs_plan_id" = wp."id"
JOIN "activity_planning" AS p ON wp."plan_id" = p."id"
WHERE p."project_id" = (
    SELECT "id" FROM "projects"
    WHERE "code" = 'CW'
    AND "company_id" = (
        SELECT "id" FROM "companies"
        WHERE "name" = 'Construction Company XYZ'
    )
AND wp."task" = 'Structure'
);

-- Find the aggregate progress of a planning WBS activity
SELECT ROUND(AVG("progress"), 2) AS "Average Progress" 
FROM "location_activity"
WHERE "activity_id" = (
    SELECT "wbs_plan"."id" FROM "wbs_plan"
    JOIN "activity_planning" ON "plan_id" = "activity_planning"."id"
    WHERE "task" = 'Structure'
    AND "project_id" = (
        SELECT "id" FROM "projects"
        WHERE "code" = 'CW'
        AND "company_id" = (
            SELECT "id" FROM "companies"
            WHERE "name" = 'Construction Company XYZ'
        )
    )
); 

-- Find incomplete activities that precede another 
SELECT "location_activity"."id", "activity_id", "location_id", "progress",
    "location_activity"."start_time", "location_activity"."end_time" 
FROM "wbs_plan"
LEFT JOIN "predecessors" ON "task_id" = "id"
JOIN "location_activity" ON "activity_id" = "wbs_plan"."id"
WHERE "progress" != 1
AND "activity_id" = (
    SELECT "wbs_plan"."id" FROM "wbs_plan"
    JOIN "activity_planning" ON "plan_id" = "activity_planning"."id"
    WHERE "task" = 'Structure'
    AND "project_id" = (
        SELECT "id" FROM "projects"
        WHERE "code" = 'CW'
        AND "company_id" = (
            SELECT "id" FROM "companies"
            WHERE "name" = 'Construction Company XYZ'
        )
    )
);

-- Find all service verification items for a location
SELECT "sheet_id", "service_verification_sheet"."id", "date" AS "verification_date", "status", "observation",
    "item", "check_method", "tolerance"  
FROM "location_activity"
JOIN "service_check" ON "location_activity_id" = "location_activity"."id"
JOIN "service_verification_sheet" ON "service_item_id" = "service_verification_sheet"."id"
WHERE "location_id" IN (
    SELECT "id" FROM "location_breakdown"
    WHERE "location" = 'Floor 1'
);

-- Find all the activities for a location
SELECT "wbs_plan"."id", "task", "location_activity"."start_time", "location_activity"."end_time"
FROM "location_activity"
JOIN "location_breakdown" ON "location_id" = "location_breakdown"."id"
JOIN "wbs_plan" ON "activity_id" = "wbs_plan"."id"
JOIN "activity_planning" ON "location_id" = "activity_planning"."id" 
WHERE "location" = 'Floor 1'
AND "project_id" = (
    SELECT "id" FROM "projects"
    WHERE "code" = 'CW'
    AND "company_id" = (
        SELECT "id" FROM "companies"
        WHERE "name" = 'Construction Company XYZ'
    )
);

-- Update an activity execution in a location as complete
UPDATE "location_activity"
SET "progress" = 1
WHERE "activity_id" = (
    SELECT "id" FROM "wbs_plan"
    WHERE "task" = 'Structure'
)
AND "location_id" = (
    SELECT "id" FROM "location_breakdown"
    WHERE "location" = 'Floor 1'
);

-- Update a successful delivery
UPDATE supply_orders
SET "status" = 'delivered'
WHERE "stakeholder_id" IN (
    SELECT "id" FROM "stakeholders"
    WHERE "name" = 'Rafael'
);


-- DATA INSERTION QUERIES
-- Add a new company
INSERT INTO "companies" ("name")
VALUES ('Construction Company XYZ');

-- Initialize permissions
INSERT INTO "permissions" ("name")
VALUES ('admin'), ('budgeting'), ('planning'), ('financial'), ('commercial'), ('supply');
    
-- Add a new user
INSERT INTO "users" ("company_id", "name", "password_hash")
VALUES (1, 'Lucas', 'b109f3bbbc244eb82441917ed06d618b9008dd09b3befd1b5e07394c706a8bb980b1d7785e5976ec049b46df5f1326af5a2ea6d103fd07c95385ffab0cacbc86');

-- Add user permissions
INSERT INTO "user_permissions" ("user_id", "permission_id")
VALUES 
    (1, 2), -- planning permission
    (1, 3), -- budgeting permission
    (1, 6); -- supply permission 

-- Add stakeholders
INSERT INTO "stakeholders" ("company_id", "name", "email", "phone", "type", "discription")
VALUES
    (1, 'Sofia', 'sofia@email.com', '5548999999999', 'client', NULL),
    (1, 'Rafael', 'rafael@email.com', '5561999999999', 'supplier', 'sells porcelain tiles'),
    (1, 'John', 'john@email.com', '5511999999999', 'labor', 'carpenter');

-- Add a composition
INSERT INTO "composition_synthetic" ("company_id", "task_name", "unit")
VALUES 
    (1, 'structure', 'm³'),
    (1, 'masonry' , 'm²'),
    (1, 'flooring', 'm2');

INSERT INTO "composition_analytic" ("company_id", "task_name", "unit", "unit_cost")
VALUES
    (1, 'mason', 'man-hour', 10),
    (1, 'concrete', 'm³', 80),
    (1, 'steel', 'kg', 50),
    (1, 'brick', 'kg', 5),
    (1, 'tile', 'm²', 20);

INSERT INTO "composition" ("synthetic_id", "analytic_id", "quantity")
VALUES
    (1, 1, 4.0),    -- 1 m³ of structure requires 4 man-hour of mason
    (1, 2, 1.1),    -- 1 m³ of structure requires 1.1 m³ of concrete
    (1, 3, 15),     -- 1 m³ of structure requires 15 kg of steel
    (2, 1, 8),      -- 1 m² of masonry requires 8 man-hour of mason
    (2, 4, 2),      -- 1 m² of masonry requires 2 kg of bricks
    (3, 1, 1.5),    -- 1 m² of flooring requires 1.5 man-hour of mason
    (3, 5, 1.2);    -- 1 m² of masonry requires 1.2 m² of bricks

-- Add a new project
INSERT INTO "projects" ("company_id", "code", "name", "status")
VALUES (1, 'CW', 'Clean Water residential building', 'under construction');

-- Add a project document
INSERT INTO "documents" ("project_id", "name", "type", "document")
VALUES (1, 'city hall permit', 'permit', pg_read_binary_file('path_to_file.pdf'));

-- Add a plan
INSERT INTO "activity_planning" ("project_id", "name", "version")
VALUES (1, 'parallel build plan', 1);

-- Add a Planning Work Breakdown Structure
INSERT INTO "wbs_plan" ("plan_id", "task", "duration")
VALUES 
    (1, 'Structure', 8),
    (1, 'Masonry', 5),
    (1, 'Plaster', 6),
    (1, 'Flooring', 5);

-- Add predecessors to tasks
INSERT INTO "predecessors" ("task_id", "predecessor_id")
VALUES
    (2, 1), -- Structure precedes Masonry
    (3, 2), -- Masonry precedes Plaster
    (4, 3); -- Plaster precedes Flooring

-- Update planning WBS with Critical Path Method stats
UPDATE "wbs_plan"
SET "start_time" = '2024-10-10', "end_time" = '2024-10-18',
    "ES" = '2024-10-10', "EF" = '2024-10-18',
    "LS" = '2024-10-10', "LF" = '2024-10-18',
    "slack" = 0, "critical" = 1
WHERE "id" = 1;

-- Add a Location Breakdown Structure
INSERT INTO "location_breakdown" ("plan_id", "location")
VALUES
    (1, 'Floor 1'),
    (1, 'Floor 2'),
    (1, 'Floor 3');

-- Add an activity being executed in a location
INSERT INTO "location_activity" ("activity_id", "location_id", "start_time", "end_time")
VALUES
    (1, 1, '2024-10-10', '2024-10-18'), -- Structure being executed across the 3 floors
    (1, 2, '2024-10-18', '2024-10-26'),
    (1, 3, '2024-10-26', '2024-11-03'),
    (2, 1, '2024-10-18', '2024-10-23'), -- Masonry being executed across the 3 floors
    (2, 2, '2024-10-26', '2024-10-31'),
    (2, 3, '2024-11-03', '2024-11-08'),
    (3, 1, '2024-10-23', '2024-10-29'), -- Plaster being executed across the 3 floors
    (3, 2, '2024-10-31', '2024-11-06'),
    (3, 3, '2024-11-08', '2024-11-14'),
    (4, 1, '2024-10-29', '2024-11-03'), -- Flooring being executed across the 3 floors
    (4, 2, '2024-11-06', '2024-11-11'),
    (4, 3, '2024-11-14', '2024-11-19');

-- Add a budget
INSERT INTO "budgeting" ("project_id", "name", "version")
VALUES (1, 'parallel build budget', 1);

-- Add a budgeting Work Breakdown Structure
INSERT INTO "wbs_budget" ("budget_id", "task")
VALUES
    (1, 'Structure'),
    (1, 'Walls'),
    (1, 'Flooring');

INSERT INTO "wbs_composition" ("wbs_budget_id", "analytic_id", "synthetic_id", "work_quantity")
VALUES
    (1, 2, NULL, 50),  -- Relate the Structure task to 50 m³ of concrete
    (1, 3, NULL, 800), -- Relate the Structure task to 800 kg of steel
    (2, NULL, 2, 120), -- Relate the Walls task to 120 m² of masonry
    (3, NULL, 3, 200); -- Relate the Flooring task to 120 m² of the flooring composition

-- Relate the planning and budgeting Work Breakdown Structures
INSERT INTO "wbs_budget_plan" ("wbs_plan_id", "wbs_budget_id")
VALUES
    (1, 1), -- Relates planning Structure to budgeting Structure
    (2, 2), -- Relates planning Masonry to budgeting Walls
    (3, 2), -- Relates planning Plaster to budgeting Walls
    (4, 3); -- Relates planning Flooring to budgeting Flooring

-- Add a new service verification sheet
INSERT INTO "service_verification_sheets" ("company_id", "name", "version")
VALUES (1, 'structure check', 1);

INSERT INTO "service_verification_sheet" ("sheet_id", "item", "check_method", "tolerance")
VALUES
    (1, 'frame', 'laser', '5mm'),
    (1, 'concrete', 'visual', NULL);

-- Add a service verification
INSERT INTO "service_check" ("service_item_id", "location_activity_id", "status", "observation")
VALUES 
    (1, 1, 'Pass', NULL), -- Structure passes first item verification
    (2, 1, 'Fail', 'Big hole near pillar 8'); -- Structure fails second item verification

-- Add a supply order
INSERT INTO "supply_orders" ("stakeholder_id", "delivery_date", "status")
VALUES
    (1, '2024-10-01', 'pending'),
    (2, '2024-10-10', 'canceled'),
    (2, '2024-10-30', 'delivered');

INSERT INTO "supply_items" ("order_id", "analytic_id", "wbs_budget_id", "quantity")
VALUES
    (1, 1, 1, 240), -- Add 240 man-hour of mason
    (1, 2, 1, 40.5), -- Add 40.5 m³ of concrete
    (1, 3, 1, 1800); -- Add 1800 kg of steel

-- Add financial inflows and outflows
INSERT INTO "transactions" ("transaction_type", "stakeholder_id", "supply_id", "amount", "transaction_date", "discription")
VALUES
    ('outflow', 2, 1, 50000, '2024-10-30', 'supplier successfully deliverd'),
    ('inflow', 1, NULL, 200000, '2024-10-30', 'Apartment 201 sold!');
    -- Leave supply_id NULL if it's an administrative cost or a revenue

