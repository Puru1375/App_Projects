
import { Text, View } from "react-native";
import { supabase } from "@/src/lib/supabase";
import { Button } from "react-native";
import { useAuth } from "@/src/providers/Authprovider";



export default function Profilescreen(){

    const {user} = useAuth();

    return(
        <View>
            <Text>User id: {user?.id}</Text>

            <Button title='Sign Out' onPress={()=>supabase.auth.signOut()}/>
        </View>
    )
}