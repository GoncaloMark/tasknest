import React from 'react';
import { X } from 'lucide-react';
import { ToDo, priorities, statuses } from '../types';

interface TodoFormProps {
    todo: ToDo;
    onSubmit: (e: React.FormEvent) => void;
    onClose: () => void;
    setTodo: (todo: ToDo) => void;
    isEditing: boolean;
}

const TodoForm: React.FC<TodoFormProps> = ({
    todo,
    onSubmit,
    onClose,
    setTodo,
    isEditing,
}) => {
    return (
        <div className="fixed inset-0 bg-gray-900 bg-opacity-75 flex items-center justify-center">
        <div className="bg-gray-800 rounded-lg p-8 w-1/2">
            <button
            className="relative text-gray-400 hover:text-gray-200"
            onClick={onClose}
            >
            <X className="w-6 h-6" />
            </button>
            <form onSubmit={onSubmit}>
            <div className="mb-4">
                <label className="block text-gray-300 text-sm font-bold mb-2">
                Title
                </label>
                <input
                className="shadow appearance-none border rounded w-full py-2 px-3 bg-gray-700 text-gray-100 focus:outline-none focus:shadow-outline"
                type="text"
                value={todo.title}
                onChange={(e) => setTodo({ ...todo, title: e.target.value })}
                />
            </div>
            <div className="mb-4">
                <label className="block text-gray-300 text-sm font-bold mb-2">
                Description
                </label>
                <textarea
                className="shadow appearance-none border rounded w-full py-2 px-3 bg-gray-700 text-gray-100 focus:outline-none focus:shadow-outline"
                value={todo.description}
                onChange={(e) => setTodo({ ...todo, description: e.target.value })}
                />
            </div>
            <div className="mb-4">
                <label className="block text-gray-300 text-sm font-bold mb-2">
                Due Date
                </label>
                <input
                className="shadow appearance-none border rounded w-full py-2 px-3 bg-gray-700 text-gray-100 focus:outline-none focus:shadow-outline"
                type="date"
                value={todo.dueDate}
                onChange={(e) => setTodo({ ...todo, dueDate: e.target.value })}
                />
            </div>
            <div className="mb-4">
                <label className="block text-gray-300 text-sm font-bold mb-2">
                Priority
                </label>
                <select
                className="shadow appearance-none border rounded w-full py-2 px-3 bg-gray-700 text-gray-100 focus:outline-none focus:shadow-outline"
                value={todo.priority}
                onChange={(e) =>
                    setTodo({ ...todo, priority: e.target.value as ToDo['priority'] })
                }
                >
                {priorities.map((priority) => (
                    <option key={priority} value={priority}>
                    {priority}
                    </option>
                ))}
                </select>
            </div>
            <div className="mb-4">
                <label className="block text-gray-300 text-sm font-bold mb-2">
                Status
                </label>
                <select
                className="shadow appearance-none border rounded w-full py-2 px-3 bg-gray-700 text-gray-100 focus:outline-none focus:shadow-outline"
                value={todo.status}
                onChange={(e) =>
                    setTodo({ ...todo, status: e.target.value as ToDo['status'] })
                }
                >
                {statuses.map((status) => (
                    <option key={status} value={status}>
                    {status}
                    </option>
                ))}
                </select>
            </div>
            <button
                className="bg-blue-600 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded"
                type="submit"
            >
                {isEditing ? 'Update' : 'Create'}
            </button>
            </form>
        </div>
        </div>
    );
};

export default TodoForm;