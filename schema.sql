-- Represent companies that hired the ERP software
CREATE TABLE "companies" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(64) NOT NULL,
    "date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "discription" TEXT 
);

-- Represent users inside the company account
CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "name" VARCHAR(32) NOT NULL,
    "password_hash" CHAR(512) NOT NULL, -- Use HASH_SHA512 algorithm to hash passwords
    FOREIGN KEY("company_id") REFERENCES "companies"("id")
);

CREATE TYPE permission AS ENUM ('admin', 'budgeting', 'planning', 'financial', 'commercial', 'supply', 'quality');

-- Represent possible permissions
CREATE TABLE "permissions" (
    "id" SERIAL PRIMARY KEY, 
    "name" permission NOT NULL
);

-- Represent user permissions
CREATE TABLE "user_permissions" (
    "user_id" INTEGER,
    "permission_id" INTEGER,
    PRIMARY KEY("user_id", "permission_id"),
    FOREIGN KEY("user_id") REFERENCES "users"("id"), 
    FOREIGN KEY("permission_id") REFERENCES "permissions"("id")
);

-- Represent company projects
CREATE TABLE "projects" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "code" VARCHAR(32) NOT NULL, -- The internal code companies use to uniquely identify their projects
    "name" VARCHAR(64) NOT NULL,
    "discription" TEXT,
    "status" VARCHAR(18) CHECK("status" IN ('under construction', 'under evaluation', 'closed')),
    FOREIGN KEY("company_id") REFERENCES "companies"("id"),
    UNIQUE("company_id", "code")
);

-- Represent project documents
CREATE TABLE "documents" (
    "id" SERIAL PRIMARY KEY,
    "project_id" INTEGER NOT NULL,
    "name" VARCHAR(32) NOT NULL,
    "type" VARCHAR(32) NOT NULL,
    "date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "document" BYTEA NOT NULL,
    FOREIGN KEY("project_id") REFERENCES "projects"("id") ON DELETE CASCADE
);

-- Represent clients, suppliers and labor
CREATE TABLE "stakeholders" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "name" VARCHAR(32) NOT NULL,
    "email" VARCHAR(64) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "type" VARCHAR(8) CHECK("type" IN ('client', 'supplier', 'labor')),
    "discription" TEXT,
    FOREIGN KEY("company_id") REFERENCES "companies"("id")
);

-- Represent Budget versions
CREATE TABLE "budgeting" (
    "id" SERIAL PRIMARY KEY,
    "project_id" INTEGER NOT NULL,
    "name" VARCHAR(32) NOT NULL,
    "version" INTEGER NOT NULL,
    FOREIGN KEY("project_id") REFERENCES "projects"("id") ON DELETE CASCADE
);

-- Represent unitary cost of materials and labor
CREATE TABLE "composition_analytic" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "task_name" VARCHAR(32) NOT NULL,
    "unit" VARCHAR(32) NOT NULL,
    "unit_cost" NUMERIC(12, 2) NOT NULL,
    FOREIGN KEY("company_id") REFERENCES "companies"("id")
);

-- Represent unitary cost of whole activities
CREATE TABLE "composition_synthetic" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "task_name" VARCHAR(32) NOT NULL,
    "unit" VARCHAR(32) NOT NULL,
    FOREIGN KEY("company_id") REFERENCES "companies"("id")
);

-- Relates synthetic and analytic composition tables
CREATE TABLE "composition" (
    "synthetic_id" INTEGER,
    "analytic_id" INTEGER,
    "quantity" NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY("synthetic_id", "analytic_id"),
    FOREIGN KEY("synthetic_id") REFERENCES "composition_synthetic"("id") ON DELETE CASCADE,
    FOREIGN KEY("analytic_id") REFERENCES "composition_analytic"("id") ON DELETE CASCADE
);

-- Represent Budget Work Breakdown Structure for work quantity and cost
CREATE TABLE "wbs_budget" (
    "id" SERIAL PRIMARY KEY,
    "budget_id" INTEGER NOT NULL,
    "task" VARCHAR(32) NOT NULL,
    FOREIGN KEY("budget_id") REFERENCES "budgeting"("id") ON DELETE CASCADE
);

-- Relate WBS to both the synthetic and analytic compositions 
CREATE TABLE "wbs_composition" (
    "id" SERIAL PRIMARY KEY,
    "wbs_budget_id" INTEGER NOT NULL,
    "analytic_id" INTEGER,
    "synthetic_id" INTEGER,
    "work_quantity" INTEGER NOT NULL,
    CHECK (
        ("analytic_id" IS NOT NULL AND "synthetic_id" IS NULL) OR 
        ("analytic_id" IS NULL AND "synthetic_id" IS NOT NULL)
    ), 
    UNIQUE("wbs_budget_id", "analytic_id", "synthetic_id"),
    FOREIGN KEY("wbs_budget_id") REFERENCES "wbs_budget"("id") ON DELETE CASCADE,
    FOREIGN KEY("analytic_id") REFERENCES "composition_analytic"("id") ON DELETE CASCADE,
    FOREIGN KEY("synthetic_id") REFERENCES "composition_synthetic"("id") ON DELETE CASCADE
);

-- Represent Plan versions
CREATE TABLE "activity_planning" (
    "id" SERIAL PRIMARY KEY,
    "project_id" INTEGER NOT NULL,
    "name" VARCHAR(32) NOT NULL,
    "version" INTEGER NOT NULL,
    FOREIGN KEY("project_id") REFERENCES "projects"("id") ON DELETE CASCADE
);

-- Represent Location Breakdown Structure to define project locations
CREATE TABLE "location_breakdown" (
    "id" SERIAL PRIMARY KEY,
    "plan_id" INTEGER NOT NULL,
    "location" VARCHAR(32) NOT NULL,
    FOREIGN KEY("plan_id") REFERENCES "activity_planning"("id") ON DELETE CASCADE,
    UNIQUE("plan_id", "location")
);

-- Represent Work Wreakdown Structure to define activities
CREATE TABLE "wbs_plan" (
    "id" SERIAL PRIMARY KEY,
    "plan_id" INTEGER NOT NULL, 
    "task" TEXT NOT NULL,
    "duration" REAL NOT NULL,
    "start_time" DATE,
    "end_time" DATE,  
    "ES" DATE,
    "EF" DATE,
    "LS" DATE,
    "LF" DATE,
    "slack" REAL,
    "critical" SMALLINT CHECK("critical" IN (0, 1)),
    FOREIGN KEY("plan_id") REFERENCES "activity_planning"("id") ON DELETE CASCADE
);

-- Relate activities to their predecessors
CREATE TABLE "predecessors" (
    "task_id" INTEGER NOT NULL,
    "predecessor_id" INTEGER NOT NULL,
    CHECK("task_id" != "predecessor_id"),
    PRIMARY KEY("task_id", "predecessor_id"),
    FOREIGN KEY("task_id") REFERENCES "wbs_plan"("id") ON DELETE CASCADE,
    FOREIGN KEY("predecessor_id") REFERENCES "wbs_plan"("id") ON DELETE CASCADE
);

-- Relate Budgeting and Planning WBS
CREATE TABLE "wbs_budget_plan" (
    "wbs_plan_id" INTEGER,
    "wbs_budget_id" INTEGER,
    PRIMARY KEY("wbs_plan_id", "wbs_budget_id"),
    FOREIGN KEY("wbs_plan_id") REFERENCES "wbs_plan"("id") ON DELETE CASCADE,
    FOREIGN KEY("wbs_budget_id") REFERENCES "wbs_budget"("id") ON DELETE CASCADE
);

-- Relate activities and locations
CREATE TABLE "location_activity" (
    "id" SERIAL PRIMARY KEY,
    "activity_id" INTEGER NOT NULL,
    "location_id" INTEGER NOT NULL,
    "start_time" DATE NOT NULL,
    "end_time" DATE NOT NULL,
    "progress" NUMERIC(3, 2) DEFAULT 0,
    CHECK("progress" BETWEEN 0 AND 1),
    FOREIGN KEY("activity_id") REFERENCES "wbs_plan"("id") ON DELETE CASCADE,
    FOREIGN KEY("location_id") REFERENCES "location_breakdown"("id") ON DELETE CASCADE
);

-- Represent Quality Control related documents
CREATE TABLE "service_verification_sheets" (
    "id" SERIAL PRIMARY KEY,
    "company_id" INTEGER NOT NULL,
    "name" VARCHAR(64) NOT NULL,
    "version" INTEGER NOT NULL,
    FOREIGN KEY("company_id") REFERENCES "companies"("id") ON DELETE CASCADE
);

-- Represents service verification sheets
CREATE TABLE "service_verification_sheet" (
    "id" SERIAL PRIMARY KEY,
    "sheet_id" INTEGER NOT NULL,
    "item" VARCHAR(64) NOT NULL,
    "check_method" VARCHAR(64) NOT NULL,
    "tolerance" VARCHAR(16),
    FOREIGN KEY("sheet_id") REFERENCES "service_verification_sheets"("id") ON DELETE CASCADE
);

-- Relate a activity-location to their service verification sheet
CREATE TABLE "service_check" (
    "service_item_id" INTEGER NOT NULL,
    "location_activity_id" INTEGER NOT NULL,
    "date" DATE DEFAULT CURRENT_TIMESTAMP,
    "status" CHAR(4) CHECK("status" IN ('Pass','Fail')),
    "observation" TEXT,
    PRIMARY KEY("service_item_id", "location_activity_id"),
    FOREIGN KEY("service_item_id") REFERENCES "service_verification_sheet"("id") ON DELETE CASCADE,
    FOREIGN KEY("location_activity_id") REFERENCES "location_activity"("id") ON DELETE CASCADE
);

-- Store supply orders for both material and labor
CREATE TABLE "supply_orders" (
    "id" SERIAL PRIMARY KEY,
    "stakeholder_id" INTEGER NOT NULL,
    "delivery_date" DATE, -- only valid for materials
    "status" VARCHAR(22) CHECK("status" IN ('pending', 'delivered', 'canceled', NULL)),
    FOREIGN KEY("stakeholder_id") REFERENCES "stakeholders"("id")
);

-- Represent individual items of a supply order
CREATE TABLE "supply_items" (
    "order_id" INTEGER,
    "analytic_id" INTEGER,
    "wbs_budget_id" INTEGER,
    "quantity" NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY("order_id", "analytic_id", "wbs_budget_id"),
    FOREIGN KEY("order_id") REFERENCES "supply_orders"("id"),
    FOREIGN KEY("analytic_id") REFERENCES "composition_analytic"("id"),
    FOREIGN KEY("wbs_budget_id") REFERENCES "wbs_budget"("id")
);

CREATE TYPE flow AS ENUM ('inflow', 'outflow');

-- Register financial inflows and outflows
CREATE TABLE "transactions" (
    "id" SERIAL PRIMARY KEY,
    "transaction_type" flow NOT NULL,
    "stakeholder_id" INTEGER NOT NULL,
    "supply_id" INTEGER,
    "amount" NUMERIC(12, 2) NOT NULL,
    "transaction_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "discription" TEXT,
    FOREIGN KEY("stakeholder_id") REFERENCES "stakeholders"("id"),
    FOREIGN KEY("supply_id") REFERENCES "supply_orders"("id")
);

-- Represent full joint composition tables
CREATE VIEW full_composition AS
    SELECT "composition_synthetic"."id" AS "synthetic_id",
        "composition_analytic"."id" AS "analytic_id",
        "composition_synthetic"."company_id" AS "company_id",
        "composition_synthetic"."task_name" AS "activity",
        "composition_analytic"."task_name" AS "labor_material",
        "composition_analytic"."unit" AS "unit",
        "quantity",
        "unit_cost"
    FROM "composition_synthetic"
    JOIN "composition" ON "synthetic_id" = "composition_synthetic"."id"
    JOIN "composition_analytic" ON "analytic_id" = "composition_analytic"."id";

-- Calculate total cost based on budgeting WBS
CREATE VIEW total_cost AS
SELECT
    wb."id" AS id,
    ROUND(COALESCE(SUM(tc.synthetic_total), 0), 2) AS synthetic_total,
    ROUND(COALESCE(SUM(ac.analytic_total), 0), 2) AS analytic_total
FROM "wbs_budget" AS wb
LEFT JOIN (
    SELECT 
        wc."wbs_budget_id",
        SUM("unit_cost" * "quantity" * "work_quantity") AS synthetic_total
    FROM "wbs_composition" AS wc
    JOIN "full_composition" AS fc ON wc."synthetic_id" = fc."synthetic_id"
    JOIN "wbs_budget" AS wbb ON wc."wbs_budget_id" = wbb."id"
    GROUP BY wc."wbs_budget_id"
) AS tc ON wb."id" = tc."wbs_budget_id"
LEFT JOIN (
    SELECT 
        wc."wbs_budget_id",
        SUM("unit_cost" * "work_quantity") AS analytic_total
    FROM "wbs_composition" AS wc
    JOIN "composition_analytic" AS ca ON wc."analytic_id" = ca."id"
    JOIN "wbs_budget" AS wbb ON wc."wbs_budget_id" = wbb."id"
    GROUP BY wc."wbs_budget_id"
) AS ac ON wb."id" = ac."wbs_budget_id"
GROUP BY wb."id";

-- Create indexes to speed common searches
CREATE INDEX comapny_name ON "companies" ("name");
CREATE INDEX project_code ON "projects" ("code");
CREATE INDEX wbs_budget_task ON "wbs_budget" ("task");
CREATE INDEX wbs_plan_task ON "wbs_plan" ("task");
CREATE INDEX location_name ON "location_breakdown" ("location");