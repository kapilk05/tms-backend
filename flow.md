# Task Management System - Backend Flow

## Tech Stack
- **Backend Framework**: Ruby on Rails
- **Database**: PostgreSQL (hosted on services like Heroku, Railway, or Supabase)
- **Authentication**: JWT (JSON Web Tokens) or BCrypt with sessions
- **API Format**: RESTful JSON API

---

## Folder Structure

```
tms-backend/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── auth_controller.rb
│   │   ├── users_controller.rb
│   │   └── tasks_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── task.rb
│   │   └── task_assignment.rb
│   ├── serializers/
│   │   ├── user_serializer.rb
│   │   └── task_serializer.rb
│   ├── services/
│   │   ├── authentication_service.rb
│   │   └── authorization_service.rb
│   └── middleware/
│       └── jwt_middleware.rb
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── application.rb
│   └── environments/
│       ├── development.rb
│       ├── test.rb
│       └── production.rb
├── db/
│   ├── migrate/
│   │   ├── 001_create_users.rb
│   │   ├── 002_create_tasks.rb
│   │   └── 003_create_task_assignments.rb
│   ├── seeds.rb
│   └── schema.rb
├── lib/
│   └── json_web_token.rb
├── spec/ or test/
│   ├── controllers/
│   ├── models/
│   └── requests/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── config.ru
├── README.md
└── .env
```

---

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user', -- 'admin', 'manager', 'user'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed'
  priority VARCHAR(50) DEFAULT 'medium', -- 'low', 'medium', 'high'
  due_date DATE,
  created_by_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Task Assignments Table (Many-to-Many)
```sql
CREATE TABLE task_assignments (
  id SERIAL PRIMARY KEY,
  task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(task_id, user_id)
);
```

---

## API Endpoints

### Authentication
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register a new user | No |
| POST | `/api/auth/login` | Login and get JWT token | No |
| POST | `/api/auth/logout` | Logout (invalidate token) | Yes |

### Users
| Method | Endpoint | Description | Auth Required | Role |
|--------|----------|-------------|---------------|------|
| GET | `/api/users` | List all users (paginated) | Yes | Admin/Manager |
| GET | `/api/users/:id` | Get user details | Yes | Admin/Manager/Self |
| POST | `/api/users` | Create a new user | Yes | Admin |
| PUT | `/api/users/:id` | Update user | Yes | Admin/Self |
| DELETE | `/api/users/:id` | Delete user | Yes | Admin |

### Tasks
| Method | Endpoint | Description | Auth Required | Role |
|--------|----------|-------------|---------------|------|
| GET | `/api/tasks` | List all tasks (paginated) | Yes | All |
| GET | `/api/tasks/:id` | Get task details | Yes | All |
| POST | `/api/tasks` | Create a new task | Yes | All |
| PUT | `/api/tasks/:id` | Update task | Yes | Creator/Admin |
| DELETE | `/api/tasks/:id` | Delete task | Yes | Creator/Admin |
| POST | `/api/tasks/:id/assign` | Assign task to user(s) | Yes | Creator/Manager/Admin |
| DELETE | `/api/tasks/:id/unassign/:user_id` | Unassign user from task | Yes | Creator/Manager/Admin |
| GET | `/api/tasks/:id/assignments` | Get all assignments for a task | Yes | All |

---

## Authentication Flow

### 1. User Registration
```
User -> POST /api/auth/register
  {
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "role": "user"
  }
  
Backend:
  1. Validate input data
  2. Check if email already exists
  3. Hash password using BCrypt
  4. Create user record in database
  5. Return user details (without password)
  
Response:
  {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "created_at": "2026-02-10T10:00:00Z"
  }
```

### 2. User Login
```
User -> POST /api/auth/login
  {
    "email": "user@example.com",
    "password": "password123"
  }
  
Backend:
  1. Find user by email
  2. Verify password using BCrypt
  3. Generate JWT token with user_id and role
  4. Return token and user details
  
Response:
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "name": "John Doe",
      "role": "user"
    }
  }
```

### 3. Protected Route Access
```
User -> GET /api/tasks
Headers: {
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Backend:
  1. Extract token from Authorization header
  2. Verify and decode JWT token
  3. Extract user_id and role from token
  4. Fetch user from database
  5. Check authorization (role-based access)
  6. Process request
  7. Return response
```

---

## Role-Based Access Control (RBAC)

### Roles
1. **Admin**
   - Full access to all resources
   - Can create, read, update, delete users
   - Can manage all tasks
   - Can assign/unassign tasks to any user

2. **Manager**
   - Can view all users
   - Can create, read, update, delete own tasks
   - Can assign/unassign tasks to users
   - Cannot modify user roles

3. **User**
   - Can view own profile
   - Can create and view tasks
   - Can update/delete own tasks
   - Can view tasks assigned to them

### Authorization Logic
```ruby
def authorize_user!(required_role, resource = nil)
  # Check if user is authenticated
  return unauthorized_response unless current_user
  
  case required_role
  when :admin
    return forbidden_response unless current_user.admin?
  when :manager
    return forbidden_response unless current_user.admin? || current_user.manager?
  when :owner
    return forbidden_response unless resource.created_by_id == current_user.id || current_user.admin?
  end
end
```

---

## Task Management Flow

### 1. Create Task
```
User (authenticated) -> POST /api/tasks
  {
    "title": "Implement login feature",
    "description": "Create login endpoint with JWT authentication",
    "status": "pending",
    "priority": "high",
    "due_date": "2026-02-15"
  }

Backend:
  1. Authenticate user (verify JWT token)
  2. Validate input data
  3. Create task with created_by_id = current_user.id
  4. Save to database
  5. Return created task

Response:
  {
    "id": 1,
    "title": "Implement login feature",
    "description": "Create login endpoint with JWT authentication",
    "status": "pending",
    "priority": "high",
    "due_date": "2026-02-15",
    "created_by": {
      "id": 1,
      "name": "John Doe"
    },
    "assigned_users": [],
    "created_at": "2026-02-10T10:00:00Z"
  }
```

### 2. List Tasks (with Pagination)
```
User -> GET /api/tasks?page=1&per_page=10&status=pending&sort=due_date

Backend:
  1. Authenticate user
  2. Parse query parameters
     - page (default: 1)
     - per_page (default: 10, max: 100)
     - status (filter)
     - priority (filter)
     - sort (created_at, due_date, priority)
  3. Build database query with filters
  4. Apply pagination using OFFSET and LIMIT
  5. Calculate total pages
  6. Return paginated results

Response:
  {
    "tasks": [
      {
        "id": 1,
        "title": "Implement login feature",
        "status": "pending",
        "priority": "high",
        "due_date": "2026-02-15",
        "assigned_users": []
      },
      // ... more tasks
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_pages": 5,
      "total_count": 47
    }
  }
```

### 3. Update Task
```
User -> PUT /api/tasks/:id
  {
    "status": "in_progress",
    "priority": "medium"
  }

Backend:
  1. Authenticate user
  2. Find task by ID
  3. Check authorization (owner or admin)
  4. Validate input data
  5. Update task fields
  6. Save to database
  7. Return updated task

Response:
  {
    "id": 1,
    "title": "Implement login feature",
    "status": "in_progress",
    "priority": "medium",
    // ... other fields
  }
```

### 4. Assign Task to User
```
User (Manager/Admin) -> POST /api/tasks/:id/assign
  {
    "user_ids": [2, 3, 4]
  }

Backend:
  1. Authenticate user
  2. Check if user has permission (manager/admin or task creator)
  3. Find task by ID
  4. Validate user_ids exist
  5. Create task_assignment records
  6. Return updated task with assignments

Response:
  {
    "id": 1,
    "title": "Implement login feature",
    "assigned_users": [
      { "id": 2, "name": "Alice Smith" },
      { "id": 3, "name": "Bob Johnson" },
      { "id": 4, "name": "Carol White" }
    ]
  }
```

### 5. Delete Task
```
User -> DELETE /api/tasks/:id

Backend:
  1. Authenticate user
  2. Find task by ID
  3. Check authorization (owner or admin)
  4. Delete task (cascades to task_assignments)
  5. Return success message

Response:
  {
    "message": "Task deleted successfully"
  }
```

---

## User Management Flow

### 1. List Users (Admin/Manager only)
```
Admin -> GET /api/users?page=1&per_page=20&role=user

Backend:
  1. Authenticate user
  2. Check if user is admin or manager
  3. Parse pagination and filter parameters
  4. Query users with filters
  5. Apply pagination
  6. Return user list (excluding passwords)

Response:
  {
    "users": [
      {
        "id": 1,
        "email": "user@example.com",
        "name": "John Doe",
        "role": "user",
        "created_at": "2026-01-15T10:00:00Z"
      },
      // ... more users
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_pages": 3,
      "total_count": 52
    }
  }
```

### 2. Create User (Admin only)
```
Admin -> POST /api/users
  {
    "email": "newuser@example.com",
    "password": "password123",
    "name": "Jane Doe",
    "role": "manager"
  }

Backend:
  1. Authenticate user
  2. Check if user is admin
  3. Validate input data
  4. Check if email already exists
  5. Hash password
  6. Create user record
  7. Return created user

Response:
  {
    "id": 5,
    "email": "newuser@example.com",
    "name": "Jane Doe",
    "role": "manager",
    "created_at": "2026-02-10T10:00:00Z"
  }
```

---

## Error Handling

### Standard Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is already taken",
    "details": {
      "field": "email"
    }
  }
}
```

### HTTP Status Codes
- **200** - Success
- **201** - Created
- **400** - Bad Request (validation errors)
- **401** - Unauthorized (not authenticated)
- **403** - Forbidden (not authorized)
- **404** - Not Found
- **422** - Unprocessable Entity
- **500** - Internal Server Error

---

## Database Hosting Options

### Recommended PostgreSQL Hosting Services

1. **Railway.app** (Easiest, Free Tier Available)
   - Quick setup, no credit card required
   - Suitable for development and small projects
   - URL: https://railway.app/

2. **Supabase** (Free Tier with Features)
   - PostgreSQL + additional features
   - Good for production
   - URL: https://supabase.com/

3. **ElephantSQL** (Free Tier)
   - Dedicated PostgreSQL hosting
   - Easy to use
   - URL: https://www.elephantsql.com/

4. **Heroku Postgres** (Paid after free tier sunset)
   - Reliable and scalable
   - Good for production
   - URL: https://www.heroku.com/postgres

5. **Neon** (Serverless Postgres)
   - Modern serverless PostgreSQL
   - Generous free tier
   - URL: https://neon.tech/

### Configuration Example
```yaml
# config/database.yml
production:
  adapter: postgresql
  encoding: unicode
  pool: 5
  url: <%= ENV['DATABASE_URL'] %>
```

---

## Security Best Practices

1. **Password Security**
   - Use BCrypt for password hashing
   - Minimum password length: 8 characters
   - Store only hashed passwords

2. **JWT Security**
   - Use strong secret key (stored in environment variable)
   - Set reasonable token expiration (e.g., 24 hours)
   - Implement token refresh mechanism

3. **Input Validation**
   - Validate all user inputs
   - Sanitize data to prevent SQL injection
   - Use parameterized queries

4. **CORS Configuration**
   - Configure allowed origins
   - Restrict to specific domains in production

5. **Rate Limiting**
   - Implement rate limiting for authentication endpoints
   - Prevent brute force attacks

6. **Environment Variables**
   - Store sensitive data in .env file
   - Never commit .env to version control
   - Use different credentials for development/production

---

## Implementation Steps

### Phase 1: Setup
1. Initialize Rails API application
2. Configure PostgreSQL database
3. Set up database migrations
4. Install required gems (bcrypt, jwt, etc.)

### Phase 2: Authentication
1. Create User model with password encryption
2. Implement JWT token generation and verification
3. Create authentication endpoints (register, login)
4. Implement authentication middleware

### Phase 3: User Management
1. Create Users controller
2. Implement CRUD operations for users
3. Add role-based access control
4. Implement user listing with pagination

### Phase 4: Task Management
1. Create Task model
2. Create TaskAssignment model (join table)
3. Implement task CRUD operations
4. Add task listing with pagination and filters
5. Implement task assignment functionality

### Phase 5: Authorization
1. Implement role-based authorization logic
2. Add permission checks to all endpoints
3. Test access control for different roles

### Phase 6: Testing & Deployment
1. Write unit tests for models
2. Write integration tests for API endpoints
3. Deploy to hosting platform (Heroku, Railway, etc.)
4. Configure production database
5. Set up environment variables
6. Test production deployment

---

## Sample .env Configuration

```
DATABASE_URL=postgresql://username:password@host:5432/database_name
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
RAILS_ENV=development
PORT=3000
```

---

## API Testing with cURL Examples

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### List Tasks (with authentication)
```bash
curl -X GET http://localhost:3000/api/tasks?page=1&per_page=10 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Create Task
```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Task",
    "description": "Task description",
    "priority": "high",
    "due_date": "2026-02-15"
  }'
```

---

## Next Steps

1. Set up Ruby on Rails project
2. Configure PostgreSQL connection
3. Create database migrations
4. Implement models with associations
5. Create controllers and routes
6. Implement authentication and authorization
7. Add pagination logic
8. Write tests
9. Deploy to production
10. Document API with Swagger/OpenAPI (optional)

---

## Useful Gems

```ruby
# Gemfile
gem 'rails', '~> 7.0'
gem 'pg', '~> 1.5'           # PostgreSQL adapter
gem 'bcrypt', '~> 3.1.7'     # Password hashing
gem 'jwt'                     # JWT token generation
gem 'rack-cors'               # CORS support
gem 'kaminari'                # Pagination
gem 'active_model_serializers' # JSON serialization

group :development, :test do
  gem 'rspec-rails'           # Testing framework
  gem 'factory_bot_rails'     # Test fixtures
  gem 'faker'                 # Fake data generation
end
```

---

## Conclusion

This flow document provides a complete blueprint for building the Task Management System backend. Follow the implementation phases sequentially, test each component thoroughly, and ensure security best practices are followed throughout the development process.
