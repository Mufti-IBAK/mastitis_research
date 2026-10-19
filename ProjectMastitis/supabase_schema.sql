-- ==========================================
-- Supabase Schema for Udder Health Data App
-- Aligned with Flutter Dart models
-- Maps ALL 99 columns from the Excel workbook
-- ==========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Auto-update updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';


-- ==========================================
-- TABLE: farms
-- Farm registry (Excel cols 2, 3, 4)
-- ==========================================
CREATE TABLE farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id TEXT NOT NULL UNIQUE,                    -- Col 4: Permanent farm identifier
    state TEXT CHECK (state IN ('Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Sokoto', 'Zamfara', 'Other')), -- Col 2
    lga TEXT,                                        -- Col 3: Local Government Area
    production_system TEXT,                          -- Baseline production system
    housing_type TEXT,                               -- Baseline housing type
    water_source TEXT,                               -- Baseline water source

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE TRIGGER update_farms_updated_at BEFORE UPDATE ON farms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ==========================================
-- TABLE: farm_visits
-- Per-visit farm conditions (Excel cols 5-22 + 88-96)
-- ==========================================
CREATE TABLE farm_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id TEXT NOT NULL REFERENCES farms(farm_id) ON DELETE CASCADE,

    -- Identifiers & Visit (cols 5-8)
    visit_id TEXT UNIQUE,                            -- Col 5
    visit_date DATE,                                 -- Col 6
    scheduled_visit_date DATE,                       -- Col 7
    observer_id TEXT,                                -- Col 8

    -- Farm Conditions (cols 9-22)
    production_system TEXT CHECK (production_system IN ('Intensive', 'Semi-intensive', 'Extensive/transhumant', 'Mixed')), -- Col 9
    total_cattle INTEGER CHECK (total_cattle >= 0),  -- Col 10
    lactating_cows INTEGER CHECK (lactating_cows >= 0), -- Col 11
    milking_method TEXT CHECK (milking_method IN ('Hand', 'Bucket machine', 'Pipeline/parlour', 'Other')), -- Col 12
    milking_frequency_day INTEGER CHECK (milking_frequency_day BETWEEN 1 AND 6), -- Col 13
    housing_type TEXT CHECK (housing_type IN ('Tie stall', 'Loose housing', 'Open yard', 'Pasture', 'Mixed', 'Other')), -- Col 14
    floor_wetness TEXT CHECK (floor_wetness IN ('Dry', 'Damp', 'Wet', 'Muddy', 'Unknown')), -- Col 15
    bedding_condition TEXT CHECK (bedding_condition IN ('Absent', 'Dry', 'Damp', 'Wet', 'Unknown')), -- Col 16
    manure_accumulation TEXT CHECK (manure_accumulation IN ('Low', 'Moderate', 'High', 'Unknown')), -- Col 17
    fly_abundance TEXT CHECK (fly_abundance IN ('Low', 'Moderate', 'High', 'Unknown')), -- Col 18
    water_available TEXT CHECK (water_available IN ('Yes', 'No', 'Unknown')), -- Col 19
    feed_change TEXT CHECK (feed_change IN ('Yes', 'No', 'Unknown')), -- Col 20
    milking_routine_change TEXT CHECK (milking_routine_change IN ('Yes', 'No', 'Unknown')), -- Col 21
    disease_outbreak TEXT CHECK (disease_outbreak IN ('Yes', 'No', 'Unknown')), -- Col 22

    -- Farm Management/Husbandry (cols 88-96)
    main_forage TEXT,                                -- Col 88
    concentrate_offered TEXT CHECK (concentrate_offered IN ('Yes', 'No', 'Unknown')), -- Col 89
    mineral_supplement TEXT CHECK (mineral_supplement IN ('Yes', 'No', 'Unknown')), -- Col 90
    water_source TEXT CHECK (water_source IN ('Borehole', 'Well', 'Tap', 'Surface water', 'Tanker', 'Other', 'Unknown')), -- Col 91
    forestripping TEXT CHECK (forestripping IN ('Always', 'Sometimes', 'Never', 'Unknown')), -- Col 92
    premilking_teat_cleaning TEXT CHECK (premilking_teat_cleaning IN ('Water only', 'Water and cloth', 'Disinfectant/predip', 'Dry cleaning', 'None', 'Other')), -- Col 93
    drying_material TEXT CHECK (drying_material IN ('Individual towel', 'Shared towel', 'Paper towel', 'Air dry', 'Not dried', 'Other')), -- Col 94
    gloves_used TEXT CHECK (gloves_used IN ('Always', 'Sometimes', 'Never', 'Unknown')), -- Col 95
    postmilking_teat_disinfection TEXT CHECK (postmilking_teat_disinfection IN ('Always', 'Sometimes', 'Never', 'Unknown')), -- Col 96

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE TRIGGER update_farm_visits_updated_at BEFORE UPDATE ON farm_visits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_farm_visits_farm_id ON farm_visits(farm_id);
CREATE INDEX idx_farm_visits_visit_date ON farm_visits(visit_date);


-- ==========================================
-- TABLE: cow_visits
-- Per-cow-per-visit measurements (Excel cols 23-50)
-- ==========================================
CREATE TABLE cow_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_visit_id UUID NOT NULL REFERENCES farm_visits(id) ON DELETE CASCADE,

    -- Cow & Lactation Identity (cols 23-31)
    cow_id TEXT NOT NULL,                            -- Col 23
    local_tag_id TEXT,                               -- Col 24
    lactation_id TEXT,                               -- Col 25
    breed_genetic_group TEXT,                        -- Col 26
    cow_birth_date DATE,                             -- Col 27
    cow_age_years NUMERIC,                           -- Col 28
    cow_source TEXT CHECK (cow_source IN ('Homebred', 'Purchased', 'Gift/transfer', 'Other', 'Unknown')), -- Col 29
    parity INTEGER CHECK (parity BETWEEN 1 AND 25), -- Col 30
    calving_date DATE,                               -- Col 31
    dim_derived INTEGER,                             -- Col 32: auto-computed days in milk

    -- Pregnancy/History (cols 33-37)
    pregnancy_status TEXT CHECK (pregnancy_status IN ('Pregnant', 'Not pregnant', 'Unknown', 'Not assessed')), -- Col 33
    previous_clinical_mastitis TEXT CHECK (previous_clinical_mastitis IN ('Yes', 'No', 'Unknown')), -- Col 34
    previous_high_scc_cmt TEXT CHECK (previous_high_scc_cmt IN ('Yes', 'No', 'Unknown')), -- Col 35
    dry_cow_therapy_previous TEXT CHECK (dry_cow_therapy_previous IN ('Blanket', 'Selective', 'None', 'Unknown')), -- Col 36
    teat_sealant_previous TEXT CHECK (teat_sealant_previous IN ('Routine', 'Selective', 'None', 'Unknown')), -- Col 37

    -- Time-Varying Measurements (cols 38-50)
    milk_yield_value NUMERIC CHECK (milk_yield_value >= 0 AND milk_yield_value <= 200), -- Col 38
    milk_yield_unit TEXT CHECK (milk_yield_unit IN ('kg', 'L')), -- Col 39
    yield_period TEXT CHECK (yield_period IN ('Morning', 'Evening', '24-hour', 'Test milking', 'Other')), -- Col 40
    milking_frequency INTEGER,                       -- Col 41
    bcs_value NUMERIC,                               -- Col 42
    bcs_scale TEXT,                                   -- Col 43
    locomotion_score INTEGER CHECK (locomotion_score BETWEEN 1 AND 5), -- Col 44
    udder_hygiene_score INTEGER CHECK (udder_hygiene_score BETWEEN 1 AND 4), -- Col 45
    rectal_temperature_c NUMERIC CHECK (rectal_temperature_c BETWEEN 30 AND 45), -- Col 46
    concurrent_disease_signs TEXT,                    -- Col 47
    antimicrobial_previous_14d TEXT CHECK (antimicrobial_previous_14d IN ('Yes', 'No', 'Unknown')), -- Col 48
    mastitis_treatment_since_last TEXT CHECK (mastitis_treatment_since_last IN ('Yes', 'No', 'Unknown')), -- Col 49
    incomplete_milking_or_suckling TEXT CHECK (incomplete_milking_or_suckling IN ('Yes', 'No', 'Unknown')), -- Col 50

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE TRIGGER update_cow_visits_updated_at BEFORE UPDATE ON cow_visits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_cow_visits_farm_visit_id ON cow_visits(farm_visit_id);
CREATE INDEX idx_cow_visits_cow_id ON cow_visits(cow_id);


-- ==========================================
-- TABLE: quarter_visits
-- Per-quarter-per-cow-per-visit (Excel cols 51-64 + 97-99)
-- ==========================================
CREATE TABLE quarter_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cow_visit_id UUID NOT NULL REFERENCES cow_visits(id) ON DELETE CASCADE,

    -- Quarter Examination & CMT (cols 51-64)
    quarter TEXT CHECK (quarter IN ('LF', 'RF', 'LR', 'RR')), -- Col 51
    functional_status TEXT CHECK (functional_status IN ('Functional', 'Blind/nonfunctional', 'Absent', 'Unknown')), -- Col 52
    clinical_mastitis TEXT CHECK (clinical_mastitis IN ('Yes', 'No', 'Unknown')), -- Col 53
    clinical_grade TEXT CHECK (clinical_grade IN ('0 None', '1 Mild', '2 Moderate', '3 Severe', 'Not assessed')), -- Col 54
    milk_abnormality TEXT CHECK (milk_abnormality IN ('Yes', 'No', 'Unknown')), -- Col 55
    swelling_heat_pain TEXT CHECK (swelling_heat_pain IN ('Yes', 'No', 'Unknown')), -- Col 56
    teat_end_score INTEGER CHECK (teat_end_score BETWEEN 1 AND 4), -- Col 57
    teat_lesion TEXT CHECK (teat_lesion IN ('Yes', 'No', 'Unknown')), -- Col 58
    udder_finding TEXT,                              -- Col 59
    cmt_score TEXT CHECK (cmt_score IN ('N', 'T', '1', '2', '3', 'Not done')), -- Col 60
    cmt_positive_derived TEXT CHECK (cmt_positive_derived IN ('Yes', 'No', 'Not assessable')), -- Col 61
    cmt_reader_id TEXT,                              -- Col 62
    cmt_reagent_lot TEXT,                            -- Col 63
    cmt_reagent_expiry DATE,                         -- Col 64

    -- Documentation (cols 97-99)
    missing_reason TEXT CHECK (missing_reason IN ('Not missing', 'Dry', 'Absent', 'Sold', 'Dead', 'Refused', 'Could not restrain', 'Blind quarter', 'Sample lost', 'Test failure', 'Other')), -- Col 97
    protocol_deviation TEXT,                         -- Col 98
    notes TEXT,                                      -- Col 99

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),

    UNIQUE (cow_visit_id, quarter)
);

CREATE TRIGGER update_quarter_visits_updated_at BEFORE UPDATE ON quarter_visits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_quarter_visits_cow_visit_id ON quarter_visits(cow_visit_id);


-- ==========================================
-- TABLE: sample_lab
-- Milk sample & lab results (Excel cols 65-76)
-- ==========================================
CREATE TABLE sample_lab (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quarter_visit_id UUID REFERENCES quarter_visits(id) ON DELETE CASCADE,
    cow_visit_id UUID REFERENCES cow_visits(id) ON DELETE CASCADE,

    -- Laboratory (cols 65-76)
    lab_sample_id TEXT UNIQUE,                        -- Col 65
    lab_sample_type TEXT CHECK (lab_sample_type IN ('Quarter', 'Composite cow')), -- Col 66
    lab_collected_before_treatment TEXT CHECK (lab_collected_before_treatment IN ('Yes', 'No', 'Unknown')), -- Col 67
    lab_scc_cells_ml INTEGER,                        -- Col 68
    lab_scc_result_flag TEXT CHECK (lab_scc_result_flag IN ('Within range', 'Below range', 'Above range', 'Not done', 'Unknown')), -- Col 69
    scs_derived NUMERIC,                             -- Col 70
    lab_culture_result_category TEXT CHECK (lab_culture_result_category IN ('Pathogen identified', 'No growth', 'Mixed/contaminated', 'Not done', 'Pending')), -- Col 71
    lab_organism_primary TEXT,                        -- Col 72
    lab_isolate_id TEXT,                              -- Col 73
    lab_mixed_contaminated TEXT CHECK (lab_mixed_contaminated IN ('Yes', 'No', 'Unknown')), -- Col 74
    lab_ast_method_standard TEXT,                     -- Col 75
    lab_ast_summary TEXT,                             -- Col 76

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),

    CONSTRAINT chk_sample_lab_refs CHECK (quarter_visit_id IS NOT NULL OR cow_visit_id IS NOT NULL)
);

CREATE TRIGGER update_sample_lab_updated_at BEFORE UPDATE ON sample_lab FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_sample_lab_quarter_visit_id ON sample_lab(quarter_visit_id);
CREATE INDEX idx_sample_lab_cow_visit_id ON sample_lab(cow_visit_id);


-- ==========================================
-- TABLE: treatments
-- Treatment events (Excel cols 77-87)
-- ==========================================
CREATE TABLE treatments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cow_visit_id UUID NOT NULL REFERENCES cow_visits(id) ON DELETE CASCADE,

    -- Treatment (cols 77-87)
    tx_event_id TEXT,                                -- Col 77
    tx_current_treatment TEXT CHECK (tx_current_treatment IN ('Yes', 'No', 'Unknown')), -- Col 78
    tx_product_trade_name TEXT,                      -- Col 79
    tx_active_ingredient TEXT,                       -- Col 80
    tx_dose NUMERIC,                                 -- Col 81
    tx_dose_unit TEXT,                               -- Col 82
    tx_route TEXT CHECK (tx_route IN ('Intramammary', 'IM', 'IV', 'SC', 'Oral', 'Topical', 'Other')), -- Col 83
    tx_start_date DATE,                              -- Col 84
    tx_stop_date DATE,                               -- Col 85
    tx_milk_withdrawal_end_date DATE,                -- Col 86
    tx_outcome_next_visit TEXT CHECK (tx_outcome_next_visit IN ('Resolved', 'Improved', 'Unchanged', 'Worsened', 'Recurred', 'Culled/died', 'Pending', 'Unknown')), -- Col 87
    quarters TEXT[],                                 -- Affected quarters array (LF, RF, LR, RR)

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE TRIGGER update_treatments_updated_at BEFORE UPDATE ON treatments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_treatments_cow_visit_id ON treatments(cow_visit_id);


-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- All authenticated users can read all data
-- All authenticated users can insert
-- Only owners can update their own records
-- ==========================================

ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE cow_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE quarter_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE sample_lab ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatments ENABLE ROW LEVEL SECURITY;

-- farms
CREATE POLICY "All authenticated can read farms" ON farms FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert farms" ON farms FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update farms" ON farms FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);

-- farm_visits
CREATE POLICY "All authenticated can read farm_visits" ON farm_visits FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert farm_visits" ON farm_visits FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update farm_visits" ON farm_visits FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);

-- cow_visits
CREATE POLICY "All authenticated can read cow_visits" ON cow_visits FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert cow_visits" ON cow_visits FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update cow_visits" ON cow_visits FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);

-- quarter_visits
CREATE POLICY "All authenticated can read quarter_visits" ON quarter_visits FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert quarter_visits" ON quarter_visits FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update quarter_visits" ON quarter_visits FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);

-- sample_lab
CREATE POLICY "All authenticated can read sample_lab" ON sample_lab FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert sample_lab" ON sample_lab FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update sample_lab" ON sample_lab FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);

-- treatments
CREATE POLICY "All authenticated can read treatments" ON treatments FOR SELECT TO authenticated USING (true);
CREATE POLICY "All authenticated can insert treatments" ON treatments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Owners can update treatments" ON treatments FOR UPDATE TO authenticated USING ((select auth.uid()) = created_by) WITH CHECK ((select auth.uid()) = created_by);
