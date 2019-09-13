#define lua_lock(L) lua_lock_(L)
#define lua_unlock(L) lua_unlock_(L)
#define lua_userstateopen(L) lua_userstateopen_(L)
#define lua_userstatethread(L,L1) lua_userstateopen_(L1)  // Lua 5.1
 
void lua_lock_(lua_State * L);
void lua_unlock_(lua_State * L);
void lua_userstateopen_(lua_State * L);