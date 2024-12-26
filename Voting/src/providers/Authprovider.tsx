import { Session, User } from "@supabase/supabase-js";
import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

type Authcontext = {
    session:Session | null;
    user: User | null;
}

const Authcontext = createContext<Authcontext>({
    session : null,
    user : null,
})

export default function Authprovider({children}:PropsWithChildren){
    

    const [session, setSession] = useState<Session | null>(null)
    
      useEffect(() => {
        supabase.auth.getSession().then(({ data: { session } }) => {
          setSession(session)
        })
    
        supabase.auth.onAuthStateChange((_event, session) => {
          setSession(session)
        })
      }, [])
    
    return(
        <Authcontext.Provider value={{session, user:session?.user || null}}>
            {children}
        </Authcontext.Provider>
    )
}

export const useAuth = () => useContext(Authcontext);