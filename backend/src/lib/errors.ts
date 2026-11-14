export class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }

  static badRequest(message: string, code = 'bad_request') {
    return new ApiError(400, code, message);
  }

  static unauthorized(message = 'Sesi tidak valid. Silakan masuk kembali.') {
    return new ApiError(401, 'unauthorized', message);
  }

  static forbidden(message = 'Kamu tidak punya akses ke sini.') {
    return new ApiError(403, 'forbidden', message);
  }

  static notFound(message = 'Data tidak ditemukan.') {
    return new ApiError(404, 'not_found', message);
  }

  static conflict(message: string, code = 'conflict') {
    return new ApiError(409, code, message);
  }

  static tooMany(message = 'Terlalu banyak percobaan. Coba lagi nanti.') {
    return new ApiError(429, 'rate_limited', message);
  }

  static unavailable(message = 'Layanan sedang tidak tersedia.') {
    return new ApiError(503, 'unavailable', message);
  }
}
