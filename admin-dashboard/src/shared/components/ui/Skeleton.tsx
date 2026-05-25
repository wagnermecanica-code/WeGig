import { clsx } from "clsx";

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      className={clsx(
        "animate-pulse rounded bg-gray-200 dark:bg-slate-800",
        className,
      )}
    />
  );
}
