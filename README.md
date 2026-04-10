# 🚀 TaskFlow - Complete MERN Stack Task Management Application

A beautiful, feature-rich task management application built with the MERN stack (MongoDB, Express, React, Node.js). Fully responsive, production-ready, and easy to deploy.

## ✨ Features

### Core Features
- ✅ **Create, Read, Update, Delete Tasks** - Full CRUD operations.
- 🔴 **Priority Levels** - Low, Medium, High priority system.
- 📂 **Task Categories** - Organize tasks by category (Work, Personal, Shopping, etc.)
- 🏷️ **Smart Filtering** - Filter by status, priority, or search.
- ✏️ **Inline Editing** - Double-click to edit any task
- 📊 **Real-time Statistics** - Track completion rate and task metrics
- 🎨 **Beautiful UI** - Modern gradient design with smooth animations
- 📱 **Fully Responsive** - Perfect on mobile, tablet, and desktop.
- 🔍 **Advanced Search** - Search tasks by title or description
- 📤 **Bulk Operations** - Update multiple tasks at once
- 🧹 **Cleanup Feature** - Delete all completed tasks with one click.

### Advanced Features
- Completion rate tracking
- Category management
- Task tags support
- Due date management
- Keyboard shortcuts (Ctrl+Enter to save, Esc to cancel)
- Animations and micro-interactions
- Error handling with user feedback
- Loading states

## 📋 Prerequisites

- **Node.js** (v14 or higher)
- **npm** or **yarn**
- **MongoDB** (local installation or MongoDB Atlas cloud)

## 🛠️ Installation & Setup

### Step 1: Clone or Download Project
```bash
cd task-app-mern
```

### Step 2: Backend Setup

```bash
# Install backend dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your configuration
# MONGODB_URI=mongodb://localhost:27017/taskapp
# PORT=5000
# NODE_ENV=development
# JWT_SECRET=your_secret_key

# Start backend server (development)
npm run dev

# Or start server (production)
npm start
```

**Backend runs on:** `http://localhost:5000`

### Step 3: Frontend Setup

```bash
# In a new terminal
cd client

# Install frontend dependencies
npm install

# Start React development server
npm start
```

**Frontend runs on:** `http://localhost:3000`

> The frontend is automatically configured to proxy API calls to `http://localhost:5000`

## 📁 Project Structure

```
task-app-mern/
├── server.js                          # Main Express server
├── package.json                       # Backend dependencies
├── .env.example                       # Environment variables template
├── README.md                          # Documentation
│
└── client/                            # React Frontend
    ├── public/
    │   └── index.html                # HTML template
    ├── src/
    │   ├── index.js                  # React entry point
    │   ├── App.js                    # Main app component
    │   ├── App.css                   # App styles
    │   ├── api/
    │   │   └── taskAPI.js            # Axios API client
    │   └── components/
    │       ├── Header.js             # Header component
    │       ├── Header.css
    │       ├── TaskForm.js           # Task creation form
    │       ├── TaskForm.css
    │       ├── FilterBar.js          # Filter controls
    │       ├── FilterBar.css
    │       ├── Stats.js              # Statistics display
    │       ├── Stats.css
    │       ├── TaskList.js           # Task list container
    │       ├── TaskList.css
    │       ├── TaskItem.js           # Individual task
    │       └── TaskItem.css
    └── package.json                  # Frontend dependencies
```

## 🔌 API Endpoints

### Base URL
```
http://localhost:5000/api
```

### Task Endpoints

#### Get All Tasks
```bash
GET /api/tasks
# Query parameters (optional):
# ?priority=high
# ?completed=true
# ?category=Work
# ?search=keyword
```

**Response:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "_id": "...",
      "title": "Learn MERN",
      "description": "Build a complete application",
      "completed": false,
      "priority": "high",
      "category": "Learning",
      "tags": [],
      "dueDate": null,
      "createdAt": "2024-03-17T10:00:00Z",
      "updatedAt": "2024-03-17T10:00:00Z"
    }
  ]
}
```

#### Get Single Task
```bash
GET /api/tasks/:id
```

#### Create Task
```bash
POST /api/tasks
Content-Type: application/json

{
  "title": "Learn MERN",
  "description": "Build a complete application",
  "priority": "high",
  "category": "Learning",
  "tags": ["coding", "backend"]
}
```

#### Update Task
```bash
PATCH /api/tasks/:id
Content-Type: application/json

{
  "title": "Updated title",
  "description": "Updated description",
  "completed": true,
  "priority": "medium",
  "category": "Work"
}
```

#### Delete Task
```bash
DELETE /api/tasks/:id
```

#### Get Statistics
```bash
GET /api/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalTasks": 10,
    "completedTasks": 6,
    "activeTasks": 4,
    "highPriorityTasks": 2,
    "completionRate": 60,
    "priorityStats": [...]
  }
}
```

#### Bulk Update Tasks
```bash
PATCH /api/tasks/bulk/update
Content-Type: application/json

{
  "ids": ["id1", "id2", "id3"],
  "updates": {
    "completed": true,
    "category": "Work"
  }
}
```

#### Delete Completed Tasks
```bash
DELETE /api/tasks/completed/cleanup
```

## 🎨 UI/UX Features

### Color Scheme
- **Primary**: Purple gradient (#667eea → #764ba2)
- **Success**: Green (#48bb78)
- **Warning**: Orange (#ed8936)
- **Danger**: Red (#f56565)
- **Info**: Blue (#4299e1)

### Typography
- **Primary Font**: Poppins (modern, friendly)
- **Mono Font**: JetBrains Mono (code snippets)

### Animations
- Smooth fade-in animations
- Slide transitions
- Hover effects and micro-interactions
- Pulse animations for emphasis
- Staggered list animations

## 🚀 Usage Guide

### Adding a Task
1. Click in the "What do you need to do?" field
2. Type your task
3. (Optional) Add description, priority, and category
4. Click "Add Task" or press Enter

### Completing a Task
- Click the checkbox next to the task to mark it as complete
- Completed tasks will appear dimmed with strikethrough

### Editing a Task
- Click the edit icon on a task
- Modify the title, description, priority, or category
- Click "Save" to confirm or "Cancel" to discard changes
- Keyboard shortcut: Ctrl+Enter to save, Esc to cancel

### Filtering Tasks
- **Status**: Filter by All, Active, or Completed
- **Priority**: Filter by All, Low, Medium, or High
- **Search**: Type keywords to search tasks

### Deleting Tasks
- Click the trash icon on any task
- Confirm the deletion

### Bulk Actions
- Use "Clear Completed" button to delete all completed tasks
- Confirmation dialog prevents accidental deletion

## 🔧 Configuration

### Environment Variables

**Backend (.env)**
```env
# MongoDB connection string
MONGODB_URI=mongodb://localhost:27017/taskapp

# Server port
PORT=5000

# Environment
NODE_ENV=development

# JWT secret (if using authentication)
JWT_SECRET=your_secret_key_here
```

**Frontend (.env)**
```env
# API base URL
REACT_APP_API_URL=http://localhost:5000/api
```

## 📊 Database Schema

### Task Model
```javascript
{
  title: String (required, max 100 chars),
  description: String (max 500 chars),
  completed: Boolean (default: false),
  priority: String (enum: ['low', 'medium', 'high'], default: 'medium'),
  category: String (default: 'General'),
  tags: [String],
  dueDate: Date,
  createdAt: Date (auto-generated),
  updatedAt: Date (auto-generated)
}
```

## 🌐 Deployment

### Deploy Backend (Heroku)

```bash
# Install Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login

# Create new app
heroku create your-app-name

# Set environment variables
heroku config:set MONGODB_URI=your_mongodb_uri
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

### Deploy Frontend (Vercel)

```bash
# Install Vercel CLI
npm i -g vercel

# Navigate to client directory
cd client

# Deploy
vercel
```

During deployment, set `REACT_APP_API_URL` to your deployed backend URL.

### Deploy with Docker

Create a `Dockerfile` in the root:

```dockerfile
FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY server.js .

EXPOSE 5000

CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t taskflow .
docker run -p 5000:5000 taskflow
```

## 🐛 Troubleshooting

### MongoDB Connection Error
- **Solution**: Ensure MongoDB is running or check MongoDB Atlas connection string
- **Verify**: `mongodb+srv://username:password@cluster.mongodb.net/taskapp`

### CORS Error
- **Solution**: Check backend CORS configuration in `server.js`
- **Verify**: Frontend URL is allowed in CORS settings

### Port Already in Use
- **Solution**: Change PORT in .env or kill existing process
- **Linux/Mac**: `lsof -i :5000` then `kill -9 <PID>`
- **Windows**: `netstat -ano | findstr :5000` then `taskkill /PID <PID> /F`

### API Calls Failing
- **Solution**: Verify backend is running on correct port
- **Check**: Backend URL in `client/src/api/taskAPI.js`
- **Test**: Visit `http://localhost:5000` in browser

### Blank Page on Frontend
- **Solution**: Check browser console for errors
- **Verify**: Ensure all dependencies are installed (`npm install`)
- **Try**: Clear browser cache and restart dev server

## 📝 Available Scripts

### Backend
```bash
npm start      # Start production server
npm run dev    # Start development server with auto-reload
```

### Frontend
```bash
npm start      # Start development server
npm build      # Build for production
npm test       # Run tests
```

## 🔐 Security Considerations

- Validate all user input on backend
- Use HTTPS in production
- Secure MongoDB with authentication
- Use environment variables for sensitive data
- Implement rate limiting for API endpoints
- Add user authentication (future enhancement)
- Sanitize data before displaying

## 🎯 Future Enhancements

- 👤 User authentication and authorization
- 🔔 Push notifications
- 📅 Calendar integration
- 🎯 Recurring tasks
- 👥 Task sharing and collaboration
- 📎 File attachments
- 🏷️ Advanced tagging system
- 📈 Analytics and insights
- 🌙 Dark mode
- 🌍 Multi-language support

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section
2. Review the API documentation
3. Check browser console for errors
4. Verify all environment variables are set correctly

## 📄 License

MIT License - Feel free to use this project for personal or commercial purposes.

## 🙏 Acknowledgments

- Built with React 18
- Styled with modern CSS3
- Icons from Lucide React
- Powered by Node.js and Express
- Database by MongoDB

---

**Happy Task Managing! 🚀**

Made with ❤️ using MERN Stack
