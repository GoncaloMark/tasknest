import React from 'react';
import { Plus } from 'lucide-react';

interface NavbarProps {
    onCreateTodo: () => void;
    filter: string;
    onFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
}

const Navbar: React.FC<NavbarProps> = ({ onCreateTodo, filter, onFilterChange }) => {
    return (
        <div className="bg-gray-800 w-64 p-4">
        <ul>
            <li className="mb-2 flex items-center justify-center">
            <img src='/logo.png' className='w-16 h-16 mb-4' alt="Logo" />
            </li>
            <li className="mb-2 flex items-center justify-center">
            <button
                className="bg-blue-600 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded w-48 flex items-center justify-between"
                onClick={onCreateTodo}
            >
                Create ToDo
                <Plus className="w-4 h-4 ml-2" />
            </button>
            </li>
            <li className="mb-2 flex items-center justify-center">
            <select
                className="bg-gray-700 hover:bg-gray-600 text-gray-100 w-48 font-bold py-2 px-4 rounded"
                value={filter}
                onChange={onFilterChange}
            >
                <option value="creationDate">Creation Date</option>
                <option value="deadline">Deadline</option>
                <option value="completionStatus">Completion</option>
            </select>
            </li>
        </ul>
        </div>
    );
};

export default Navbar;