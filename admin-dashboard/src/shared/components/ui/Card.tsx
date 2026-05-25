import { type ReactNode } from "react";
import { clsx } from "clsx";

interface CardProps {
  children: ReactNode;
  className?: string;
}

export function Card({ children, className }: CardProps) {
  return (
    <div
      className={clsx(
        "rounded-xl border bg-white shadow-sm border-gray-200",
        "dark:bg-slate-900 dark:border-slate-800",
        className,
      )}
    >
      {children}
    </div>
  );
}

export function CardHeader({ children, className }: CardProps) {
  return (
    <div
      className={clsx(
        "px-5 py-4 border-b border-gray-100 dark:border-slate-800",
        className,
      )}
    >
      {children}
    </div>
  );
}

export function CardBody({ children, className }: CardProps) {
  return <div className={clsx("px-5 py-4", className)}>{children}</div>;
}

export function CardTitle({ children, className }: CardProps) {
  return (
    <h3
      className={clsx(
        "text-sm font-semibold text-gray-700 dark:text-slate-200",
        className,
      )}
    >
      {children}
    </h3>
  );
}
