import type { Request } from 'express';

export function routeParam(params: Request['params'], key: string): string {
  const value = params[key];
  const parameter = Array.isArray(value) ? value[0] : value;
  if (typeof parameter !== 'string' || parameter.length === 0) {
    throw {
      statusCode: 400,
      code: 'INVALID_ROUTE_PARAMETER',
      message: 'Parameter rute tidak valid.',
    };
  }
  return parameter;
}
