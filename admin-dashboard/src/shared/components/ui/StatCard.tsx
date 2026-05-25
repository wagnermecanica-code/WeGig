import type { ReactNode } from "react";
import { Card, CardBody } from "./Card";

interface StatCardProps {
  label: string;
  value: ReactNode;
  hint?: string;
  icon?: ReactNode;
  trend?: { value: number; positive?: boolean };
}

export function StatCard({ label, value, hint, icon, trend }: StatCardProps) {
  return (
    <Card>
      <CardBody className="flex items-start justify-between">
        <div>
          <p className="text-xs uppercase tracking-wide text-gray-500 dark:text-slate-400">
            {label}
          </p>
          <p className="mt-2 text-2xl font-semibold text-gray-900 dark:text-white">
            {value}
          </p>
          {hint ? (
            <p className="mt-1 text-xs text-gray-500 dark:text-slate-400">
              {hint}
            </p>
          ) : null}
          {trend ? (
            <p
              className={`mt-2 text-xs font-medium ${
                trend.positive === false ? "text-red-600" : "text-green-600"
              }`}
            >
              {trend.positive === false ? "▼" : "▲"}{" "}
              {Math.abs(trend.value).toFixed(1)}%
            </p>
          ) : null}
        </div>
        {icon ? (
          <div className="rounded-lg bg-primary/10 p-2 text-primary dark:bg-primary/20">
            {icon}
          </div>
        ) : null}
      </CardBody>
    </Card>
  );
}
