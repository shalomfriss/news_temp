# Firebase Data Connect Setup

This repo can act as a gateway to Firebase Data Connect. It expects a GraphQL
endpoint and (optionally) an API key or bearer token. Set these environment
variables when running the server:

- DATA_CONNECT_ENDPOINT=https://<DATA_CONNECT_ENDPOINT>/graphql
- DATA_CONNECT_API_KEY=<DATA_CONNECT_API_KEY>
- DATA_CONNECT_AUTH_TOKEN=<DATA_CONNECT_BEARER_TOKEN>

If DATA_CONNECT_ENDPOINT is not set, the API falls back to in-memory data.

## Schema (GraphQL)

Create a Data Connect schema that stores blocks and lists as JSON strings.
Use these definitions as a starting point.

File: dataconnect/schema.gql

```
scalar JSON

type Category @table(name: "categories") {
  name: String! @primaryKey
}

type Feed @table(name: "feeds") {
  category: String! @primaryKey
  blocks_json: String!
  total_count: Int!
}

type Article @table(name: "articles") {
  id: String! @primaryKey
  title: String!
  url: String!
  is_premium: Boolean!
  total_count: Int!
  content_json: String!
  content_preview_json: String
  post_json: String
}

type RelatedArticles @table(name: "related_articles") {
  article_id: String! @primaryKey
  blocks_json: String!
  total_count: Int!
}

type PopularSearch @table(name: "popular_search") {
  id: String! @primaryKey
  topics_json: String!
  articles_json: String!
}

type RelevantSearch @table(name: "relevant_search") {
  term: String! @primaryKey
  topics_json: String!
  articles_json: String!
}

type Subscription @table(name: "subscriptions") {
  id: String! @primaryKey
  name: String!
  monthly: Int!
  annual: Int!
  benefits_json: String!
}

type User @table(name: "users") {
  id: String! @primaryKey
  subscription: String!
}
```

## Queries and Mutations

File: dataconnect/queries.gql

```
query GetCategories {
  categories { name }
}

query GetFeed($category: String!) {
  feeds_by_pk(category: $category) {
    blocks_json
    total_count
  }
}

query GetArticle($id: String!) {
  articles_by_pk(id: $id) {
    id
    title
    url
    is_premium
    total_count
    content_json
    content_preview_json
    post_json
  }
}

query GetArticleMeta($id: String!) {
  articles_by_pk(id: $id) {
    is_premium
  }
}

query GetRelatedArticles($id: String!) {
  related_articles_by_pk(article_id: $id) {
    blocks_json
    total_count
  }
}

query GetPopularSearch {
  popular_search_by_pk(id: "current") {
    topics_json
    articles_json
  }
}

query GetRelevantSearch($term: String!) {
  relevant_search_by_pk(term: $term) {
    topics_json
    articles_json
  }
}

query GetSubscriptions {
  subscriptions {
    id
    name
    monthly
    annual
    benefits_json
  }
}

query GetSubscriptionPlan($id: String!) {
  subscriptions_by_pk(id: $id) {
    name
  }
}

query GetUser($id: String!) {
  users_by_pk(id: $id) {
    id
    subscription
  }
}

mutation UpsertUserSubscription($id: String!, $subscription: String!) {
  insert_users_one(
    object: { id: $id, subscription: $subscription }
    on_conflict: { constraint: users_pkey, update_columns: [subscription] }
  ) {
    id
    subscription
  }
}
```

## Seed Data (SQL)

File: data/dataconnect_seed.sql

This file inserts sample rows using JSON strings that match the block format.
You can paste these into a SQL client connected to your Data Connect database.
