export type FeeType = "tuition" | "transport" | "exam" | "other";
export type FeeStatus = "pending" | "paid";

export type FeeRecordRow = {
  id: number;
  student_id: number;
  student_name: string;
  class_name: string;
  section: string;
  fee_type: FeeType;
  amount: number;
  due_date: string | null;
  paid_on: string | null;
  status: FeeStatus;
  receipt_number: string | null;
  notes: string | null;
  receipt_url: string | null;
};

export type AdminFeesFilters = {
  year?: string;
  student_name?: string;
  class_name?: string;
  section?: string;
};

export type AdminFeesResponse = {
  fee_records: FeeRecordRow[];
  summary: {
    pending_count: number;
    unpaid_amount: number;
  };
};

export type StudentFeesResponse = {
  summary: {
    pending_count: number;
    pending_amount: number;
    paid_total: number;
  };
  fee_records: Array<{
    id: number;
    fee_type: FeeType;
    amount: number;
    due_date: string | null;
    paid_on: string | null;
    status: FeeStatus;
    receipt_number: string | null;
  }>;
};

export type CreateFeeInput = {
  student_id: number;
  fee_type: FeeType;
  amount: number;
  due_date?: string;
  paid_on?: string;
  status: FeeStatus;
  notes?: string;
};
