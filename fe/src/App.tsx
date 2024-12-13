import React, { useEffect, useState } from 'react';
import Navbar from './components/Navbar';
import TodoForm from './components/TodoForm';
import TodoCard from './components/TodoCard';
import { PrioFilters, StatusFilters, SortFilters, OrderFilters, ToDo } from './types';

function App() {
  const [todos, setTodos] = useState<ToDo[]>([]);
  const [newTodo, setNewTodo] = useState<ToDo>({
    title: '',
    description: '',
    status: 'TODO',
    deadline: '',
    priority: 'LOW',
  });

  const [pFilter, setPFilter] = useState<PrioFilters>({priority: ""});
  const [sFilter, setSFilter] = useState<StatusFilters>({status: ""});
  const [orderFilter, setOrderFilter] = useState<OrderFilters>({value: 'desc'});
  const [sortFilter, setSortFilter] = useState<SortFilters>({value: "creation_date"})

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
          let query = `limit=${limit}&page=${currentPage}`;
          if(pFilter.priority != "") query += `&priority=${pFilter.priority}`;
          if(sortFilter.value != "") query += `&sort=${sortFilter.value}`
          if(sFilter.status != "") query += `&status=${sFilter.status}`
          if(orderFilter.value != "") query += `&order=${orderFilter.value}`

          // console.log(query)

          const response = await fetch(`/api/tasks/read?${query}`, {
            method: 'GET',
            credentials: 'include',
          });
  
          if (response.ok) {
            const data = await response.json();
            setTodos(data.tasks); 
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
  }, [currentPage, limit, isLoggedIn, pFilter, sFilter, orderFilter, sortFilter]); 
  

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

    let query = `limit=${limit}&page=${currentPage}`;
    if(pFilter.priority != "") query += `&priority=${pFilter.priority}`;
    if(sortFilter.value != "") query += `&sort=${sortFilter.value}`
    if(sFilter.status != "") query += `&status=${sFilter.status}`
    if(orderFilter.value != "") query += `&order=${orderFilter.value}`

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
          console.log("Getting after update")
          const response = await fetch(`/api/tasks/read?${query}`, {
            method: 'GET',
            credentials: 'include',
          });
  
          if (response.ok) {
            const data = await response.json();
            setTodos(data.tasks); 
            setTotalTasks(data.total);
          } else {
            console.error('Failed to fetch tasks');
          }
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
          console.log("Getting after create")
          const response = await fetch(`/api/tasks/read?${query}`, {
            method: 'GET',
            credentials: 'include',
          });
  
          if (response.ok) {
            const data = await response.json();
            setTodos(data.tasks); 
            setTotalTasks(data.total);
          } else {
            console.error('Failed to fetch tasks');
          }
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

  const handlePrioFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setPFilter({priority: e.target.value})
  };

  const handleStatusFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSFilter({status: e.target.value})
  };

  const handleOrderChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setOrderFilter({value: e.target.value});
  };

  const handleSortFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSortFilter({value: e.target.value});
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
        order={orderFilter.value}
        pfilter={pFilter?.priority}
        sfilter={sFilter?.status}
        sort={sortFilter?.value}

        onOrderChange={handleOrderChange}
        onSortFilterChange={handleSortFilterChange}
        onSFilterChange={handleStatusFilterChange}
        onPFilterChange={handlePrioFilterChange}

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
