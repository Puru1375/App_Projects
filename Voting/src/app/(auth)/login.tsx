import React, { useState } from 'react'
import { Alert, StyleSheet, View, AppState ,Button,TextInput, Text} from 'react-native'
import { supabase } from '../../lib/supabase'
import { Slot, Stack } from 'expo-router'



AppState.addEventListener('change', (state) => {
  if (state === 'active') {
    supabase.auth.startAutoRefresh()
  } else {
    supabase.auth.stopAutoRefresh()
  }
})


export default function Auth() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  async function signInWithEmail() {
    if (!email || !password) {
        Alert.alert('Please fill in both email and password.');
        return;
      }
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
    })

    if (error) Alert.alert(error.message)
    setLoading(false)
  }

  async function signUpWithEmail() {
    setLoading(true)
    const {
      data: { session },
      error,
    } = await supabase.auth.signUp({email,password})

    if (error) Alert.alert(error.message)
    else if (!session) Alert.alert('Please check your inbox for email verification!')
    setLoading(false)
  }

  return (
    <View style={styles.container}>
      
      <Text style={styles.title}>Sign In Or Create an Account</Text>  
      <View style={[styles.verticallySpaced, styles.mt20]}>
        <TextInput
          onChangeText={(text) => setEmail(text)}
          value={email}
          placeholder="email@address.com"
          autoCapitalize={'none'}
          style={styles.input}
        />
      </View>
      <View style={styles.verticallySpaced}>
        <TextInput
          onChangeText={(text) => setPassword(text)}
          value={password}
          secureTextEntry={true}
          placeholder="Password"
          autoCapitalize={'none'}
          style={styles.input}
        />
      </View>
      <View style={[styles.verticallySpaced, styles.mt20]}>
        <Button 
          title="Sign in" 
          disabled={loading} 
          onPress={() => signInWithEmail()} 
        />
      </View>
      <View style={styles.verticallySpaced}>
        <Button 
          title="Sign up" 
          disabled={loading} 
          onPress={() => signUpWithEmail()} 
        />
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    marginTop: 40,
    padding: 12,
  },
  title:{
    fontSize:23,
    textAlign:'center',
    marginBottom:20,
  },
  verticallySpaced: {
    paddingTop: 10,
    paddingBottom: 4,
    alignSelf: 'stretch',
  },
  mt20: {
    marginTop: 20,
  },
  input:{
    backgroundColor:'white',
    padding:10,
    borderRadius:5,
    marginVertical:5,
    borderWidth:1,
    borderColor:'#ccc'
},
})