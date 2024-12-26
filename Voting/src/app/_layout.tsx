import { Slot, Stack, Tabs } from "expo-router";
import Authprovider from "../providers/Authprovider";


export default function RootLayout(){
    return (
    <Authprovider>
      <Stack>
        <Stack.Screen 
          name="(auth)" 
          options={{title:'Login', headerTitleAlign:'center'}}
        />
        <Stack.Screen 
          name="(protected)"
          options={{title:'Profile',headerTitleAlign:'center'}}
        />
      </Stack>
    </Authprovider> 

    )
}