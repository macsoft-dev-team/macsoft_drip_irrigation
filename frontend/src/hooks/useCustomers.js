import { useEffect, useState, useCallback } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { fetchCustomers } from '../reducers/customersSlice';

export const useCustomers = ({ initialPage = 1, pageSize = 10 } = {}) => {
    const dispatch = useDispatch();
    const { customers, totalPages, currentPage, loading, error } = useSelector((s) => s.customers);

    const [page, setPage] = useState(initialPage);
    const [search, setSearch] = useState('');

    const load = useCallback(
        (p = page, q = search) => {
            dispatch(fetchCustomers({ skip: p, take: pageSize, filter: q }));
        },
        [dispatch, page, pageSize, search]
    );

    useEffect(() => {
        load(1, '');
    }, []);

    const handleSearch = (value) => {
        setSearch(value);
        setPage(1);
        dispatch(fetchCustomers({ skip: 1, take: pageSize, filter: value }));
    };

    const handlePage = (p) => {
        setPage(p);
        dispatch(fetchCustomers({ skip: p, take: pageSize, filter: search }));
    };

    const reload = () => load(page, search);

    return {
        customers,
        totalPages,
        currentPage,
        loading,
        error,
        page,
        search,
        handleSearch,
        handlePage,
        reload,
    };
};
