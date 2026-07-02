import { apiClient } from "./client";
import type { AdminFeesResponse, AdminFeesFilters, CreateFeeInput, FeeRecordRow, StudentFeesResponse } from "../types/fees";

export async function fetchAdminFees(filters?: AdminFeesFilters): Promise<AdminFeesResponse> {
  const response = await apiClient.get<AdminFeesResponse>("/admin/fees", { params: filters });
  return response.data;
}

export async function createFeeRecord(input: CreateFeeInput): Promise<FeeRecordRow> {
  const response = await apiClient.post<{ fee_record: FeeRecordRow }>("/admin/fees", {
    fee_record: input,
  });
  return response.data.fee_record;
}

export async function fetchStudentFees(): Promise<StudentFeesResponse> {
  const response = await apiClient.get<StudentFeesResponse>("/fees");
  return response.data;
}

async function parseBlobError(blob: Blob): Promise<string | null> {
  try {
    const text = await blob.text();
    const body = JSON.parse(text) as { errors?: string[]; error?: string };
    return body.errors?.join(", ") ?? body.error ?? null;
  } catch {
    return null;
  }
}

/** PDF magic bytes — Content-Type is not readable cross-origin for application/pdf. */
async function isPdfBlob(blob: Blob): Promise<boolean> {
  if (blob.type.includes("application/pdf")) {
    return true;
  }

  const header = new Uint8Array(await blob.slice(0, 4).arrayBuffer());
  return header[0] === 0x25 && header[1] === 0x50 && header[2] === 0x44 && header[3] === 0x46;
}

export async function downloadFeeReceipt(feeId: number): Promise<Blob> {
  try {
    const response = await apiClient.get(`/admin/fees/${feeId}/receipt`, {
      responseType: "blob",
      headers: { Accept: "application/pdf" },
    });

    const blob = response.data as Blob;
    if (await isPdfBlob(blob)) {
      return blob;
    }

    const message = await parseBlobError(blob);
    throw new Error(message ?? "Invalid receipt response");
  } catch (err: unknown) {
    if (err && typeof err === "object" && "response" in err) {
      const axiosErr = err as { response?: { data?: Blob } };
      const blob = axiosErr.response?.data;
      if (blob instanceof Blob) {
        const message = await parseBlobError(blob);
        if (message) {
          throw new Error(message);
        }
      }
    }
    throw err;
  }
}
