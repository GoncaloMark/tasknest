import React from 'react';
import { Plus } from 'lucide-react';

interface NavbarProps {
    onCreateTodo: () => void;
    filter: string;
    onFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
    isLoggedIn: boolean;
    username?: string;
    email?: string;
}

const Navbar: React.FC<NavbarProps> = ({ 
    onCreateTodo, 
    filter, 
    onFilterChange, 
    isLoggedIn, 
    username, 
    email
}) => {
    const handleCognitoLogin = () => {
        window.location.href = `${process.env.REACT_APP_COGNITO_UI}`;
    };

    const handleCognitoSignup = () => {
        window.location.href = `${process.env.REACT_APP_COGNITO_UI}`;
    };

    const handleLogout = () => {
        window.location.href = `${process.env.REACT_APP_COGNITO_LOGOUT}`;
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
                            <div className="text-sm">{username}</div>
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
                                value={filter}
                                onChange={onFilterChange}
                            >
                                <option value="creationDate">Creation Date</option>
                                <option value="deadline">Deadline</option>
                                <option value="completionStatus">Completion</option>
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
