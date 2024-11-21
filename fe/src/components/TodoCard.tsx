import React from 'react';
import { Edit, Trash } from 'lucide-react';
import { ToDo } from '../types';

interface TodoCardProps {
    todo: ToDo;
    onEdit: (todo: ToDo) => void;
    onDelete: (id?: string) => void;
}

const TodoCard: React.FC<TodoCardProps> = ({ todo, onEdit, onDelete }) => {
    return (
        <div className="bg-gray-800 p-4 rounded-lg shadow-lg transition-all hover:shadow-xl flex flex-col w-72 h-80">
        <div className="flex-1 overflow-hidden">
            <h2 className="text-lg font-bold text-gray-100 mb-2 truncate">
            {todo.title}
            </h2>
            <p className="text-gray-400 mb-4 overflow-y-auto max-h-20 text-sm">
            {todo.description}
            </p>
            <div className="space-y-1">
            <p className="text-gray-300 text-sm"><b>Priority:</b> {todo.priority}</p>
            <p className="text-gray-300 text-sm"><b>Status:</b> {todo.status}</p>
            <p className="text-gray-300 text-sm"><b>Due:</b> {todo.deadline}</p>
            </div>
        </div>
        
        <div className="mt-auto space-y-2 pt-2">
            <button
            className="bg-yellow-600 hover:bg-yellow-800 text-white font-bold py-1.5 px-4 rounded w-full flex items-center justify-center text-sm"
            onClick={() => onEdit(todo)}
            >
            <Edit className="w-3 h-3 mr-2" />
            Edit
            </button>
            <button
            className="bg-red-600 hover:bg-red-800 text-white font-bold py-1.5 px-4 rounded w-full flex items-center justify-center text-sm"
            onClick={() => onDelete(todo.task_id)}
            >
            <Trash className="w-3 h-3 mr-2" />
            Delete
            </button>
        </div>
        </div>
    );
};

export default TodoCard;