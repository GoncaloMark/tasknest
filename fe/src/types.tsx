export interface ToDo {
    id: number;
    title: string;
    description: string;
    status: 'ToDo' | 'in Progress' | 'Done';
    dueDate: string;
    priority: 'Low' | 'Medium' | 'High';
    createdAt: string;
}

export const priorities = ['Low', 'Medium', 'High'] as const;
export const statuses = ['ToDo', 'in Progress', 'Done'] as const;