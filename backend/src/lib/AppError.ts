export class AppError extends Error {
  statusCode: number;
  code: string;

  constructor(statusCode: number, message: string, code = "appError") {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}
