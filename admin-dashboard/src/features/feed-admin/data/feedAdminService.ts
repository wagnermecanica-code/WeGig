import {
  collection,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface FeedPost {
  id: string;
  title: string;
  description?: string;
  city?: string;
  state?: string;
  authorProfileId?: string;
  createdAt?: Date;
  featured?: boolean;
  promoted?: boolean;
  pinned?: boolean;
  expiresAt?: Date;
}

function parseDate(value: unknown): Date | undefined {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return undefined;
}

function mapPost(id: string, data: Record<string, any>): FeedPost {
  return {
    id,
    title: data.title ?? data.name ?? "(sem título)",
    description: data.description ?? data.text,
    city: data.city ?? data.locationCity,
    state: data.state ?? data.locationState,
    authorProfileId: data.profileId ?? data.authorProfileId,
    createdAt: parseDate(data.createdAt),
    featured: data.featured === true,
    promoted: data.promoted === true,
    pinned: data.pinned === true,
    expiresAt: parseDate(data.expiresAt),
  };
}

export interface FeedListParams {
  filter?: "all" | "featured" | "promoted" | "pinned";
  pageSize?: number;
  searchTerm?: string;
}

export async function listFeedPosts(
  params: FeedListParams = {},
): Promise<FeedPost[]> {
  const pageSize = params.pageSize ?? 60;
  const constraints: any[] = [];

  if (params.filter === "featured") {
    constraints.push(where("featured", "==", true));
  } else if (params.filter === "promoted") {
    constraints.push(where("promoted", "==", true));
  } else if (params.filter === "pinned") {
    constraints.push(where("pinned", "==", true));
  }

  constraints.push(orderBy("createdAt", "desc"));
  constraints.push(limit(pageSize));

  const snap = await getDocs(query(collection(db, "posts"), ...constraints));
  let items = snap.docs.map((d) => mapPost(d.id, d.data()));

  const term = params.searchTerm?.trim().toLowerCase();
  if (term) {
    items = items.filter(
      (post) =>
        post.title.toLowerCase().includes(term) ||
        (post.description ?? "").toLowerCase().includes(term) ||
        (post.city ?? "").toLowerCase().includes(term) ||
        (post.state ?? "").toLowerCase().includes(term),
    );
  }

  return items;
}

export type FeedFlag = "featured" | "promoted" | "pinned";

export async function setFeedFlag(
  postId: string,
  flag: FeedFlag,
  value: boolean,
): Promise<void> {
  await updateDoc(doc(db, "posts", postId), {
    [flag]: value,
    [`${flag}UpdatedAt`]: Timestamp.now(),
  });
}
