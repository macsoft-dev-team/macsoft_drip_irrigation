import { configureStore } from "@reduxjs/toolkit";

import authReducer from "../reducers/authSlice";
import deviceReducer from "../reducers/deviceSlice";
import usersReducer from "../reducers/usersSlice";
import customersReducer from "../reducers/customersSlice";

const store = configureStore({
    reducer: {
        auth: authReducer,
        devices: deviceReducer,
        users: usersReducer,
        customers: customersReducer,
    },
});
    
export default store;