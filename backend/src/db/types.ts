export type UserRow = {
  id: string;
  email: string;
  password_hash: string | null;
  google_sub: string | null;
  full_name: string;
  display_name: string;
  headline: string;
  district: string;
  bio: string;
  skills: string;
  experience: string;
  role: 'worker' | 'employer';
  max_distance_km: number;
  min_pay: number;
  start_hour: number;
  end_hour: number;
  photo_url: string | null;
  phone: string;
  created_at: string;
  updated_at: string;
};

export type JobRow = {
  id: string;
  employer_id: string;
  title: string;
  company: string;
  category: string;
  description: string;
  pay: number;
  pay_period: string;
  district: string;
  distance_km: number;
  start_hour: number;
  end_hour: number;
  urgency: 'today' | 'thisWeek' | 'flexible';
  skills: string;
  contact: string;
  filled: number;
  created_at: string;
  updated_at: string;
};

export type ApplicationRow = {
  id: string;
  job_id: string;
  worker_id: string;
  status:
    | 'sent'
    | 'viewed'
    | 'interview'
    | 'accepted'
    | 'rejected'
    | 'withdrawn';
  note: string;
  created_at: string;
  updated_at: string;
};

export type ChatRow = {
  id: string;
  job_id: string;
  application_id: string;
  worker_id: string;
  employer_id: string;
  created_at: string;
  updated_at: string;
};

export type MessageRow = {
  id: string;
  chat_id: string;
  sender_id: string;
  body: string;
  created_at: string;
};

export type Experience = {
  title: string;
  company: string;
  period: string;
  detail: string;
};

export const emptyExperience: Experience = {
  title: '',
  company: '',
  period: '',
  detail: '',
};

function parseList(raw: string): string[] {
  try {
    const value = JSON.parse(raw);
    return Array.isArray(value) ? value.filter((v) => typeof v === 'string') : [];
  } catch {
    return [];
  }
}

function parseExperience(raw: string): Experience[] {
  try {
    const value = JSON.parse(raw);
    if (!Array.isArray(value)) return [];
    const list: Experience[] = [];
    for (const item of value) {
      if (item === null || typeof item !== 'object') continue;
      list.push({
        title: String((item as Record<string, unknown>).title ?? ''),
        company: String((item as Record<string, unknown>).company ?? ''),
        period: String((item as Record<string, unknown>).period ?? ''),
        detail: String((item as Record<string, unknown>).detail ?? ''),
      });
    }
    return list;
  } catch {
    return [];
  }
}

export type PublicUser = {
  id: string;
  fullName: string;
  displayName: string;
  headline: string;
  district: string;
  bio: string;
  skills: string[];
  experience: Experience[];
  role: 'worker' | 'employer';
  photoUrl: string | null;
  createdAt: string;
};

export type SelfUser = PublicUser & {
  email: string;
  phone: string;
  maxDistanceKm: number;
  minPay: number;
  startHour: number;
  endHour: number;
  hasPassword: boolean;
  hasGoogle: boolean;
};

export function toPublicUser(row: UserRow): PublicUser {
  return {
    id: row.id,
    fullName: row.full_name,
    displayName: row.display_name,
    headline: row.headline,
    district: row.district,
    bio: row.bio,
    skills: parseList(row.skills),
    experience: parseExperience(row.experience),
    role: row.role,
    photoUrl: row.photo_url,
    createdAt: row.created_at,
  };
}

export function toSelfUser(row: UserRow): SelfUser {
  return {
    ...toPublicUser(row),
    email: row.email,
    phone: row.phone,
    maxDistanceKm: row.max_distance_km,
    minPay: row.min_pay,
    startHour: row.start_hour,
    endHour: row.end_hour,
    hasPassword: row.password_hash !== null,
    hasGoogle: row.google_sub !== null,
  };
}

export type JobDto = {
  id: string;
  employerId: string;
  title: string;
  company: string;
  category: string;
  description: string;
  pay: number;
  payPeriod: string;
  district: string;
  distanceKm: number;
  startHour: number;
  endHour: number;
  urgency: 'today' | 'thisWeek' | 'flexible';
  skills: string[];
  contact: string;
  filled: boolean;
  createdAt: string;
  employer: {
    id: string;
    fullName: string;
    displayName: string;
    photoUrl: string | null;
    headline: string;
  } | null;
  application: { id: string; status: ApplicationRow['status'] } | null;
  applicantCount: number;
};

export function toEmployerSummary(row: UserRow | undefined) {
  if (row === undefined) return null;
  return {
    id: row.id,
    fullName: row.full_name,
    displayName: row.display_name,
    photoUrl: row.photo_url,
    headline: row.headline,
  };
}

export function toJobDto(
  row: JobRow,
  employer: UserRow | undefined,
  application: { id: string; status: ApplicationRow['status'] } | null,
  applicantCount: number,
): JobDto {
  return {
    id: row.id,
    employerId: row.employer_id,
    title: row.title,
    company: row.company,
    category: row.category,
    description: row.description,
    pay: row.pay,
    payPeriod: row.pay_period,
    district: row.district,
    distanceKm: row.distance_km,
    startHour: row.start_hour,
    endHour: row.end_hour,
    urgency: row.urgency,
    skills: parseList(row.skills),
    contact: row.contact,
    filled: row.filled === 1,
    createdAt: row.created_at,
    employer: toEmployerSummary(employer),
    application,
    applicantCount,
  };
}

export function parseSkillsInput(raw: string): string[] {
  return parseList(raw);
}

export function serializeSkills(skills: readonly string[]): string {
  return JSON.stringify(skills);
}

export function serializeExperience(list: readonly Experience[]): string {
  return JSON.stringify(list);
}
