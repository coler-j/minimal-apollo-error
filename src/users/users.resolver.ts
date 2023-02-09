import { Query, Resolver } from '@nestjs/graphql';

class User {
  constructor() {
    this.id = '1';
  }
  id: string;
}

@Resolver(() => User)
export class UsersResolver {
  @Query(() => User)
  async user(): Promise<User> {
    const user = new User();
    return user;
  }
}
