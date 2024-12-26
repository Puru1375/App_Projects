// supabase Database Password is 'H-cmwTaer-HPyf6'
import { Link, Redirect, Stack } from 'expo-router';
import React, { useEffect, useState } from 'react';
import {FlatList, Image, StyleSheet, Platform,Text,View, Alert } from 'react-native';
import AntDesign from '@expo/vector-icons/AntDesign';
import { supabase } from '../lib/supabase';
import { useAuth } from '../providers/Authprovider';


// const polls = [{id:1},{id:2},{id:3}]

export default function HomeScreen() {
  // const {user} = useAuth()
  
  //     if(!user){
  //         return <Redirect href="/login"/>
  //     }

  const [polls,setPolls] = useState<any[] | null>(null)

  useEffect(()=>{

    const fetchpolls = async () => {

      let { data, error } = await supabase.from('polls').select('*')

      if(error){
        Alert.alert('Error fetching data')
      }  
      console.log(data);
      setPolls(data);

    }
    fetchpolls();

  },[])

  return (
    <>
    <Stack.Screen options={{
      title:"Polls", 

      headerRight: ()=> (
        <Link href={"/polls/new"}>
          <AntDesign name="plus" size={22} color="black" />
        </Link>
      ), 
      headerTitleAlign:'center',

      headerLeft: () => (
        <View style={{borderRadius:20,backgroundColor:'#cfcbca',height:40,width:40,justifyContent:'center',paddingLeft:6.5}}>
        <Link href={"/profile"}>
          <AntDesign name="user" size={27} color="black" />
        </Link>
        </View>
      )
    }}/>
    <FlatList
     data={polls}
     style={{backgroundColor:'gainsboro'}}
     contentContainerStyle={styles.container}
     renderItem={({item})=>(
      <Link href={`/polls/${item.id}`} style={styles.pollcontainer}>
        <Text style={styles.polltitle}>{item.id}. Examlie poll question</Text>
      </Link>
     )}
    />
    </>
  );
}

const styles = StyleSheet.create({
  container:{
    flex:1,
    padding:6,
    paddingTop:10,
    gap:8,
  },
  pollcontainer:{
    backgroundColor:"white",
    padding:8,
    borderRadius:4,
  },
  polltitle:{
    fontSize:17,
  },
});
