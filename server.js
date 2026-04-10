const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// ==================== MIDDLEWARE ====================
app.use(cors());
app.use(express.json());

// ==================== DATABASE CONNECTION ====================
// AFTER
if (process.env.NODE_ENV !== 'test') {
  mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.log('❌ MongoDB Connection Error:', err.message));
}

// ==================== SCHEMAS ====================

// Task Schema
const taskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Please add a task title'],
    trim: true,
    maxlength: [100, 'Task title cannot be more than 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  completed: {
    type: Boolean,
    default: false
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'],
    default: 'medium'
  },
  dueDate: {
    type: Date,
    default: null
  },
  category: {
    type: String,
    default: 'General'
  },
  tags: [String],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

const Task = mongoose.model('Task', taskSchema);

// ==================== API ROUTES ====================

// Health check endpoint for ALB
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ message: 'TaskFlow API Server is Running ✅' });
});

// ============ TASK ROUTES ============

// GET ALL TASKS
app.get('/api/tasks', async (req, res) => {
  try {
    const { priority, completed, category, search } = req.query;
    
    let filter = {};
    
    if (priority) filter.priority = priority;
    if (completed !== undefined) filter.completed = completed === 'true';
    if (category) filter.category = category;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const tasks = await Task.find(filter).sort({ createdAt: -1 });
    res.json({
      success: true,
      count: tasks.length,
      data: tasks
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// GET SINGLE TASK
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    
    if (!task) {
      return res.status(404).json({ 
        success: false,
        message: 'Task not found' 
      });
    }

    res.json({
      success: true,
      data: task
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// CREATE TASK
app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description, priority, dueDate, category, tags } = req.body;

    if (!title || title.trim() === '') {
      return res.status(400).json({ 
        success: false,
        message: 'Task title is required' 
      });
    }

    const newTask = new Task({
      title: title.trim(),
      description: description?.trim() || '',
      priority: priority || 'medium',
      dueDate: dueDate || null,
      category: category || 'General',
      tags: tags || []
    });

    const savedTask = await newTask.save();
    
    res.status(201).json({
      success: true,
      message: 'Task created successfully',
      data: savedTask
    });
  } catch (error) {
    res.status(400).json({ 
      success: false,
      message: error.message 
    });
  }
});

// UPDATE TASK
app.patch('/api/tasks/:id', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);

    if (!task) {
      return res.status(404).json({ 
        success: false,
        message: 'Task not found' 
      });
    }

    // Update allowed fields
    const { title, description, completed, priority, dueDate, category, tags } = req.body;
    
    if (title !== undefined) task.title = title.trim();
    if (description !== undefined) task.description = description.trim();
    if (completed !== undefined) task.completed = completed;
    if (priority !== undefined) task.priority = priority;
    if (dueDate !== undefined) task.dueDate = dueDate;
    if (category !== undefined) task.category = category;
    if (tags !== undefined) task.tags = tags;
    
    task.updatedAt = new Date();

    const updatedTask = await task.save();

    res.json({
      success: true,
      message: 'Task updated successfully',
      data: updatedTask
    });
  } catch (error) {
    res.status(400).json({ 
      success: false,
      message: error.message 
    });
  }
});

// DELETE TASK
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const task = await Task.findByIdAndDelete(req.params.id);

    if (!task) {
      return res.status(404).json({ 
        success: false,
        message: 'Task not found' 
      });
    }

    res.json({
      success: true,
      message: 'Task deleted successfully',
      data: task
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// GET TASK STATISTICS
app.get('/api/stats', async (req, res) => {
  try {
    const totalTasks = await Task.countDocuments();
    const completedTasks = await Task.countDocuments({ completed: true });
    const activeTasks = await Task.countDocuments({ completed: false });
    const highPriorityTasks = await Task.countDocuments({ priority: 'high', completed: false });

    const priorityStats = await Task.aggregate([
      {
        $group: {
          _id: '$priority',
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        totalTasks,
        completedTasks,
        activeTasks,
        highPriorityTasks,
        completionRate: totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toFixed(2) : 0,
        priorityStats
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// BULK UPDATE TASKS
app.patch('/api/tasks/bulk/update', async (req, res) => {
  try {
    const { ids, updates } = req.body;

    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Task IDs array is required' 
      });
    }

    const result = await Task.updateMany(
      { _id: { $in: ids } },
      { ...updates, updatedAt: new Date() }
    );

    res.json({
      success: true,
      message: `${result.modifiedCount} tasks updated successfully`,
      data: result
    });
  } catch (error) {
    res.status(400).json({ 
      success: false,
      message: error.message 
    });
  }
});

// DELETE COMPLETED TASKS
app.delete('/api/tasks/completed/cleanup', async (req, res) => {
  try {
    const result = await Task.deleteMany({ completed: true });

    res.json({
      success: true,
      message: `${result.deletedCount} completed tasks deleted`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false,
    message: 'Route not found' 
  });
});

// ==================== SERVER STARTUP ====================
// AFTER
if (process.env.NODE_ENV !== 'test') {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 Server running on http://0.0.0.0:${PORT}`);
    console.log(`📝 API Base URL: http://0.0.0.0:${PORT}/api`);
    console.log(`🔗 Environment: ${process.env.NODE_ENV || 'development'}\n`);
  });
}


module.exports = app;
