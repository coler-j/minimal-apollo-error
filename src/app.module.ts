import { UsersModule } from './users/users.module';
import { Module } from '@nestjs/common';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { GraphQLModule } from '@nestjs/graphql';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: 'schema.gql', // path where automatically generated schema will be created
      sortSchema: true,
    }),
    UsersModule
  ],
})
export class AppModule {}
