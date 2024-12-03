-- Core Tables Creation
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    start_date DATE NOT NULL,
    mobile VARCHAR(20),
    birth_date DATE,
    manager_id INTEGER REFERENCES employees(employee_id),
    country VARCHAR(50),
    gender VARCHAR(10),
    exp DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE leave_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    requires_hr_approval BOOLEAN DEFAULT false,
    requires_document BOOLEAN DEFAULT false,
    is_gender_specific BOOLEAN DEFAULT false,
    specific_gender VARCHAR(10),
    max_days_per_request INTEGER,
    max_requests_per_year INTEGER,
    advance_notice_days INTEGER DEFAULT 0,
    needs_activation BOOLEAN DEFAULT false,
    deduct_from_annual BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE employee_balances (
    balance_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    leave_type_id INTEGER REFERENCES leave_types(type_id),
    annual_balance DECIMAL(4,2) NOT NULL,
    active_balance DECIMAL(4,2) NOT NULL,
    last_accrual_date DATE,
    activation_date DATE,
    is_activated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, leave_type_id)
);

CREATE TABLE leave_requests (
    request_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    leave_type_id INTEGER REFERENCES leave_types(type_id),
    submit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    response VARCHAR(20) DEFAULT 'Pending',
    working_days_count DECIMAL(4,2),
    balance_before DECIMAL(4,2),
    balance_after DECIMAL(4,2),
    document_path VARCHAR(255),
    hr_approved BOOLEAN,
    remarks TEXT,
    return_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE holidays (
    holiday_date DATE PRIMARY KEY,
    description VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE food_allowance (
    allowance_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    month_year DATE NOT NULL,
    allowance_amount DECIMAL(10,2) NOT NULL,
    used_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, month_year)
);

CREATE TABLE food_orders (
    order_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    order_date DATE NOT NULL,
    receipt_path VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    ocr_text TEXT,
    status VARCHAR(20) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance_records (
    record_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    date DATE NOT NULL,
    check_in TIMESTAMP,
    check_out TIMESTAMP,
    device_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, date)
);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers
DO $$ 
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_%I_updated_at
                BEFORE UPDATE ON %I
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column();
        ', t, t);
    END LOOP;
END $$;