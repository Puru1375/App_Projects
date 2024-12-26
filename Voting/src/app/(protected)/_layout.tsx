import { useAuth } from "@/src/providers/Authprovider";
import { Redirect, Slot } from "expo-router";


export default function ProtectedLayout(){

    const {user} = useAuth()
    
        if(!user){
            return <Redirect href="/login"/>
        }

        
    return <Slot/>
}