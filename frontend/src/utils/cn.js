// Simple class-name joiner — filters falsy values and merges strings
export function cn(...classes) {
    return classes.filter(Boolean).join(' ');
}
