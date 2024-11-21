import React, { useEffect, useState } from 'react';
import Navbar from './components/Navbar';
import TodoForm from './components/TodoForm';
import TodoCard from './components/TodoCard';
import { ToDo } from './types';

function App() {
  const [todos, setTodos] = useState<ToDo[]>([]);
  const [newTodo, setNewTodo] = useState<ToDo>({
    title: '',
    description: '',
    status: 'TODO',
    deadline: '',
    priority: 'LOW',
  });
  const [filter, setFilter] = useState('creationDate');
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<ToDo | null>(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [email, setEmail] = useState('');
  const [totalTasks, setTotalTasks] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [limit] = useState(10);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const fetchTasks = async () => {
      // Prevent unnecessary loading state if already fetching
      if (isLoading) return;
  
      if (isLoggedIn) {
        setIsLoading(true);
        try {
          const response = await fetch(`/api/tasks/read?limit=${limit}&page=${currentPage}`, {
            method: 'GET',
            credentials: 'include',
          });
  
          if (response.ok) {
            const data = await response.json();
            setTodos((prevTodos) => [...prevTodos, ...data.tasks]); 
            setTotalTasks(data.total);
          } else {
            console.error('Failed to fetch tasks');
          }
        } catch (error) {
          console.error('Error fetching tasks:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };
  
    fetchTasks();
  }, [currentPage, limit, isLoggedIn]); 
  

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const response = await fetch('/api/users/auth/check', {
          method: 'GET',
          credentials: 'include', // Ensures cookies are included if needed
        });

        if (response.ok) {
          const data = await response.json();
          setIsLoggedIn(data.isAuthenticated || false);

          if (data.user && data.user.email) {
            setEmail(data.user.email);
          }
        } else {
          setIsLoggedIn(false);
          setEmail('');
        }
      } catch (error) {
        console.error('Error checking authentication:', error);
        setIsLoggedIn(false);
        setEmail('');
      }
    };

    checkAuth();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const taskData = {
      ...newTodo,
    };

    if (editing) {
      try {
        const response = await fetch(`/api/tasks/update/${editing.task_id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(taskData),
          credentials: 'include',
        });

        if (response.ok) {
          const updatedTask = await response.json(); // Ensure the updated task has the ID
          setTodos(todos.map((todo) => (todo.task_id === editing.task_id ? updatedTask : todo)));
          setEditing(null);
        } else {
          console.error('Failed to update task');
        }
      } catch (error) {
        console.error('Error updating task:', error);
      }
    } else {
      try {
        const response = await fetch('/api/tasks/create', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(taskData),
          credentials: 'include',
        });

        if (response.ok) {
          const createdTask = await response.json(); // Expecting the task with the ID
          setTodos([...todos, createdTask]);
        } else {
          console.error('Failed to create task');
        }
      } catch (error) {
        console.error('Error creating task:', error);
      }
    }

    setNewTodo({
      title: '',
      description: '',
      status: 'TODO',
      deadline: '',
      priority: 'LOW',
    });
    setShowForm(false);
  };

  const handleDelete = async (id?: string) => {
    if (!id) {
      console.error('No ID!');
      return;
    }
    try {
      const response = await fetch(`/api/tasks/delete/${id}`, {
        method: 'DELETE',
        credentials: 'include',
      });

      if (response.ok) {
        setTodos(todos.filter((todo) => todo.task_id !== id));  // Filter out the deleted task
      } else {
        console.error('Failed to delete task');
      }
    } catch (error) {
      console.error('Error deleting task:', error);
    }
  };

  const handleEdit = (todo: ToDo) => {
    setNewTodo(todo);
    setEditing(todo);
    setShowForm(true);
  };

  const handleFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setFilter(e.target.value);
  };

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const target = e.target as HTMLDivElement;

    const bottom = target.scrollHeight === target.scrollTop + target.clientHeight;
    if (bottom && !isLoading && todos.length < totalTasks) {
      setCurrentPage((prevPage) => prevPage + 1); // Load the next page of tasks
    }
  };

  return (
    <div className="flex h-screen bg-gray-900 text-gray-100">
      <Navbar
        onCreateTodo={() => setShowForm(true)}
        filter={filter}
        onFilterChange={handleFilterChange}
        email={email}
        isLoggedIn={isLoggedIn}
      />

      <div
        className="flex-grow p-4 overflow-auto"
        onScroll={handleScroll} // Listen for scroll events
      >
        {showForm && (
          <TodoForm
            todo={newTodo}
            onSubmit={handleSubmit}
            onClose={() => setShowForm(false)}
            setTodo={setNewTodo}
            isEditing={!!editing}
          />
        )}

        <div className="flex flex-wrap gap-4">
          {todos.map((todo) => (
            <TodoCard
              key={todo.task_id} 
              todo={todo}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ))}
        </div>

        {isLoading && <div className="text-center">Loading...</div>}
      </div>
    </div>
  );
}

export default App;
