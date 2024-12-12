import React from 'react';
import { Plus } from 'lucide-react';

interface NavbarProps {
    onCreateTodo: () => void;
    sort?: string;
    order?: string
    sfilter?: string;
    pfilter?: string;
    onPFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
    onSFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
    onSortFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
    onOrderChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
    isLoggedIn: boolean;
    email?: string;
}

const Navbar: React.FC<NavbarProps> = ({ 
    onCreateTodo, 
    sort,
    sfilter, 
    pfilter,
    order,
    onPFilterChange, 
    onSFilterChange,
    onSortFilterChange,
    onOrderChange,
    isLoggedIn,  
    email
}) => {
    const cognito_ui = import.meta.env.VITE_APP_COGNITO_UI;
    const logout = import.meta.env.VITE_APP_COGNITO_LOGOUT;

    const handleCognitoLogin = () => {
        window.location.href = cognito_ui;
    };

    const handleCognitoSignup = () => {
        window.location.href = cognito_ui;
    };

    const handleLogout = () => {
        window.location.href = logout;
    }

    return (
        <div className="bg-gray-800 w-64 p-4">
            <ul>
                <li className="mb-2 flex items-center justify-center">
                    <img src='/logo.png' className='w-16 h-16 mb-4' alt="Logo" />
                </li>

                {!isLoggedIn ? (
                    <>
                        <li className="mb-2 flex items-center justify-center">
                            <button 
                                className="bg-blue-600 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded w-48"
                                onClick={handleCognitoLogin}
                            >
                                Log In
                            </button>
                        </li>
                        <li className="mb-2 flex items-center justify-center">
                            <button 
                                className="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded w-48"
                                onClick={handleCognitoSignup}
                            >
                                Sign Up
                            </button>
                        </li>
                    </>
                ) : (
                    <>
                        <li className="mb-2 text-center text-gray-200">
                            <div className="text-xs text-gray-400">{email}</div>
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
                                value={sort}
                                onChange={onSortFilterChange}
                            >
                                <option value="">None</option>
                                <option value="creation_date">Creation Date</option>
                                <option value="deadline">Deadline</option>
                                <option value="status">Status</option>
                                <option value="priority">Priority</option>
                            </select>
                        </li>

                        <li className="mb-2 flex items-center justify-center">
                            <select
                                className="bg-gray-700 hover:bg-gray-600 text-gray-100 w-48 font-bold py-2 px-4 rounded"
                                value={pfilter}
                                onChange={onPFilterChange}
                            >
                                <option value="">None</option>
                                <option value="HIGH">High</option>
                                <option value="LOW">Low</option>
                                <option value="MEDIUM">Medium</option>
                            </select>
                        </li>

                        <li className="mb-2 flex items-center justify-center">
                            <select
                                className="bg-gray-700 hover:bg-gray-600 text-gray-100 w-48 font-bold py-2 px-4 rounded"
                                value={sfilter}
                                onChange={onSFilterChange}
                            >
                                <option value="">None</option>
                                <option value="TODO">TODO</option>
                                <option value="IN_PROGRESS">In Progress</option>
                                <option value="DONE">Done</option>
                            </select>
                        </li>

                        <li className="mb-2 flex items-center justify-center">
                            <select
                                className="bg-gray-700 hover:bg-gray-600 text-gray-100 w-48 font-bold py-2 px-4 rounded"
                                value={order}
                                onChange={onOrderChange}
                            >
                                <option value="asc">Ascending</option>
                                <option value="desc">Descending</option>
                            </select>
                        </li>

                        <li className="mb-2 flex items-center justify-center">
                            <button
                                className="bg-red-600 hover:bg-red-800 text-white font-bold py-2 px-4 rounded w-48"
                                onClick={handleLogout} 
                            >
                                Log Out
                            </button>
                        </li>
                    </>
                )}
            </ul>
        </div>
    );
};

export default Navbar;
