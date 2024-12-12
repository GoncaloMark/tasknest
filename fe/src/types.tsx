export interface ToDo {
    task_id?: string;
    title: string;
    description: string;
    status: 'TODO' | 'IN_PROGRESS' | 'DONE';
    deadline: string;
    priority: 'LOW' | 'MEDIUM' | 'HIGH';
}

export const priorities = ['LOW', 'MEDIUM', 'HIGH'] as const;
export const statuses = ['TODO', 'IN_PROGRESS', 'DONE'] as const;

export interface StatusFilters {
    status?: string;
}

export interface PrioFilters {
    priority?: string;
}

export interface SortFilters {
    value?: string
}

export interface OrderFilters {
    value: string
}