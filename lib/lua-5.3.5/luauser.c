#include <stdbool.h>
#include <pthread.h>
#include "lua.h"
#include "luauser.h"
 
static struct {
    pthread_mutex_t mutex;
    bool init;
} lua_lock_mutex;
 
void lua_lock_(lua_State * L){
    pthread_mutex_lock(&lua_lock_mutex.mutex);
}
 
void lua_unlock_(lua_State * L){
    pthread_mutex_unlock(&lua_lock_mutex.mutex);
}
 
void lua_userstateopen_(lua_State * L){
    if(!lua_lock_mutex.init){
        pthread_mutex_init(&lua_lock_mutex.mutex, NULL);
        lua_lock_mutex.init = true;
    }
}