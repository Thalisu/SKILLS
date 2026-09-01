export interface UserRecord {
  id: string;
}

export enum UserStatus {
  Active = "active",
  Blocked = "blocked",
}

export class UserService {
  async findUser(id: string): Promise<UserRecord> {
    const localOnly = id.trim();
    return { id: localOnly };
  }
}
