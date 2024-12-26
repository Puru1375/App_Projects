import { useAuth } from "@/src/providers/Authprovider";
import { Redirect, Slot } from "expo-router";


export default function Authlayout(){
    const {user} = useAuth();

    if(user) {
        return <Redirect href="/profile"/>
    }

    return <Slot />
}