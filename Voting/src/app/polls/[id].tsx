import { View,Text,StyleSheet, Pressable, Button } from "react-native";
import { Link, Stack, useLocalSearchParams } from 'expo-router';
import React from "react";
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { useState } from "react";

const poll = {
    question:'React Native vs Flutter ?',
    options:['React Native FTW','Flutter','SwiftUI'],
}




export default function Polldetails(){

    const {id} =  useLocalSearchParams<{id:string}>();

    const [selected , setSelected] = useState('React Native FTW')

    const vote = () => {
        console.warn('Vote: ', selected)
    } 

    return (
        <View style={styles.container}>
            <Stack.Screen options={{
                title:"Poll Voting", 
                headerTitleAlign:'center',
            }}/> 

            <Text style={styles.question}>{poll.question}</Text>

            <View style={{gap: 5,paddingTop:3}}>
                {poll.options.map((option) => (
                    <Pressable 
                    onPress={() => setSelected(option)} 
                    key={option} 
                    style={styles.optioncontainer}
                    >
                        <FontAwesome 
                            name={option === selected ? "check-square-o" : "square"} 
                            size={23} 
                            color={option === selected ? 'green' : 'gray'}
                        />
                        <Text style={styles.innertext}>{option}</Text>
                    </Pressable>
                ))}
            </View>
            <View style={styles.votebutton}>
                 <Button onPress={vote} title="Vote" />
            </View>    

        </View>
    )
}

const styles = StyleSheet.create({
    container:{
        padding:6,
    },
    question:{
        paddingLeft:4,
        fontSize:17,
        fontWeight:"bold"
    },
    optioncontainer:{
        backgroundColor:'white',
        padding:9,
        marginTop:4,
        borderRadius:5,
        flexDirection:'row',
        gap:7,
    },
    innertext:{
        paddingLeft:4
    },
    votebutton:{
        paddingTop:17,
    },
})