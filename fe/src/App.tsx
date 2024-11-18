import React, { useState } from 'react';
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
        email='ah'
        isLoggedIn={false}
      />

      <div className="flex-grow p-4 overflow-auto">
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
      </div>
    </div>
  );
}

export default App;