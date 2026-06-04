import { configureStore } from "@reduxjs/toolkit";

import authReducer from "../reducers/authSlice";
import deviceReducer from "../reducers/deviceSlice";
import usersReducer from "../reducers/usersSlice";
import customersReducer from "../reducers/customersSlice";
import irrigationReducer from "../reducers/irrigationSlice";

const store = configureStore({
    reducer: {
        auth: authReducer,
        devices: deviceReducer,
        users: usersReducer,
        customers: customersReducer,
        irrigation: irrigationReducer,
    },
});
    
export default store;