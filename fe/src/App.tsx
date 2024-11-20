import React, { useEffect, useState } from 'react';
import Navbar from './components/Navbar';
import TodoForm from './components/TodoForm';
import TodoCard from './components/TodoCard';
import { ToDo, statuses } from './types';

function App() {
  const [todos, setTodos] = useState<ToDo[]>([]);
  const [newTodo, setNewTodo] = useState<ToDo>({
    id: todos.length + 1,
    title: '',
    description: '',
    status: 'ToDo',
    dueDate: '',
    priority: 'Low',
    createdAt: new Date().toISOString(),
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
      if (isLoading) return;

      setIsLoading(true);

      try {
        const response = await fetch(`/api/tasks/read?limit=${limit}&page=${currentPage}`, {
          method: 'GET',
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
    };

    fetchTasks();
  }, [currentPage, limit, isLoading]);

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editing) {
      setTodos(todos.map((todo) => (todo.id === editing.id ? newTodo : todo)));
      setEditing(null);
    } else {
      setTodos([...todos, newTodo]);
    }
    setNewTodo({
      id: todos.length + 1,
      title: '',
      description: '',
      status: 'ToDo',
      dueDate: '',
      priority: 'Low',
      createdAt: new Date().toISOString(),
    });
    setShowForm(false);
  };

  const handleDelete = (id: number) => {
    setTodos(todos.filter((todo) => todo.id !== id));
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

  const sortedTodos = todos.sort((a, b) => {
    if (filter === 'creationDate') {
      return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
    } else if (filter === 'deadline') {
      return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
    } else if (filter === 'completionStatus') {
      return statuses.indexOf(a.status) - statuses.indexOf(b.status);
    }
    return 0;
  });

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
          {sortedTodos.map((todo) => (
            <TodoCard
              key={todo.id}
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