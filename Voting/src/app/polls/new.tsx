import { View , Text , StyleSheet, TextInput, Button, Alert} from "react-native";
import { Redirect, router, Stack } from "expo-router";
import { useState } from "react";
import Entypo from '@expo/vector-icons/Entypo';
import { useAuth } from "@/src/providers/Authprovider";
import { supabase } from "@/src/lib/supabase";


export default function Createpoll() {

    const [question,setquestion] = useState('');
    const [options, setoption] = useState(['',''])
    const [error, seterror] = useState('')

    const {user} = useAuth();
    
    
    const createpoll = async () => {

        seterror('')
        if(!question) {
            seterror('Please provide the question')
            return;
        }

        const validoption = options.filter((o) => !!o)
        if (validoption.length < 2) {
            seterror('Please provide the minimum Two options')
            return;
        }

        
        const { data, error } = await supabase
          .from('polls')
          .insert([{ question, options:validoption}])
          .select()
        if (error) {
            Alert.alert('Failed to create the Poll');
            return;
        }
        router.back();
        

        console.warn('Create',{question,options})
    };
    
    if(!user) {
        return <Redirect href="/login"/>
    }

    return (
        <View style={styles.container}>

            <Stack.Screen options={{
                title:'Create poll', 
                headerTitleAlign:'center'
            }}/>

            <Text style={styles.label}>Title</Text>
            <TextInput 
             value={question} 
             onChangeText={setquestion} 
             placeholder="Type your question here" 
             style={styles.input}
            />

            <Text style={styles.label}>Options</Text>
            {options.map((option,index) => (
            <View key={index} style={{justifyContent:'center'}}>
                <TextInput 
                 value={option} 
                 onChangeText={(Text)=>{
                    const updated = [...options]
                    updated[index] = Text
                    setoption(updated)
                 }}
                 placeholder={`Option ${index + 1}`} 
                 style={styles.input}
                />
                <Entypo 
                  name="cross" 
                  size={24} 
                  color="black" 
                  style={{position:'absolute', right:10}}
                  onPress={() => {
                    const updated = options.filter((_, optIndex) => optIndex !== index);
                    setoption(updated);
                  }}
                />
            </View>    
            ))}

            <Button title="Add option" onPress={()=>setoption([...options,''])}/>

            <Button title="Create poll" onPress={createpoll}/>
            <Text style={{color:'crimson'}}>{error}</Text>

        </View>
    )
}


const styles = StyleSheet.create({
    container:{
        padding:10,
        gap:8,
    },
    label:{
        fontSize:18,
        fontWeight:'800',
        paddingTop:9,
    },
    input:{
        backgroundColor:'white',
        padding:10,
        borderRadius:5,
        marginVertical:5
    },
})