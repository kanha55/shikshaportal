import axios from "axios";
import type { AxiosError, InternalAxiosRequestConfig } from "axios";
import { getApiBaseUrl } from "../lib/config";

type TokenGetter = () => string | null;
type UnauthorizedHandler = () => void;

let getToken: TokenGetter = () => null;
let onUnauthorized: UnauthorizedHandler = () => {};

export function configureApiClient(options: {
  getToken: TokenGetter;
  onUnauthorized: UnauthorizedHandler;
}) {
  getToken = options.getToken;
  onUnauthorized = options.onUnauthorized;
}

export const apiClient = axios.create({
  headers: { "Content-Type": "application/json", Accept: "application/json" },
  // Send the session cookie so the login can be restored after a page reload.
  withCredentials: true,
});

apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  config.baseURL = getApiBaseUrl();
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  if (config.data instanceof FormData) {
    delete config.headers["Content-Type"];
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      onUnauthorized();
    }
    return Promise.reject(error);
  }
);
