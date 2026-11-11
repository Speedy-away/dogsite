if not ENTITY then
    local InvokeBool,InvokeFloat,InvokeInt,InvokeString,InvokeVoid=Natives.InvokeBool,Natives.InvokeFloat,Natives.InvokeInt,Natives.InvokeString,Natives.InvokeVoid
    local function InvokeV3(Hash,...)return V3.New(Natives.InvokeV3(Hash,...))end
    AUDIO = {}
    AUDIO.GET_SOUND_ID=function()return InvokeInt(0x430386FE9BF80B45)end
    AUDIO.PLAY_SOUND=function(soundId,audioName,audioRef,p3,p4,p5)return InvokeVoid(0x7FF4944CC209192D,soundId,audioName,audioRef,p3,p4,p5)end
    AUDIO.RELEASE_SOUND_ID=function(soundId)return InvokeVoid(0x353FC880830B88FA,soundId)end
    AUDIO.STOP_SOUND=function(soundId)return InvokeVoid(0xA3B0C41BA5CC0BB5,soundId)end
    AUDIO.STOP_AUDIO_SCENES=function()return InvokeVoid(0xBAC7FC81A75EC1A1)end
    AUDIO.TRIGGER_MUSIC_EVENT=function(n)return InvokeBool(0x706D57B0F50DA710,n)end
    CAM = {}
    CAM.GET_FINAL_RENDERED_CAM_COORD=function()return InvokeV3(0xA200EB1EE790F448)end
    CAM.GET_FINAL_RENDERED_CAM_ROT=function(p0)return InvokeV3(0x5B4E4C817FCC2DFB,p0)end
    CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING=function()return InvokeFloat(0x743607648ADD4587)end
    CAM.GET_GAMEPLAY_CAM_RELATIVE_PITCH=function()return InvokeFloat(0x3A6867B4845BEDA2)end
    CAM.SET_GAMEPLAY_CAM_RELATIVE_HEADING=function(h)return InvokeVoid(0xB4EC2312F4E5B1F1,h+.0)end
    CAM.SET_GAMEPLAY_CAM_RELATIVE_PITCH=function(a,s)return InvokeVoid(0x6D0858B8EDFD2B7D,a+.0,s+.0)end
    CUTSCENE = {}
    CUTSCENE.IS_CUTSCENE_PLAYING=function()return InvokeBool(0xD3C2E180A40F031E)end
    DECORATOR = {}
    DECORATOR.DECOR_GET_INT=function(e,n)return InvokeInt(0xA06C969B02A97298,e,n)end
    DECORATOR.DECOR_REMOVE=function(e,n)return InvokeBool(0x00EE9F297C738720,e,n)end
    ENTITY = {}
    ENTITY.APPLY_FORCE_TO_ENTITY=function(e,f,x,y,z,ox,oy,oz,bi,dr,iu,fr,p12,p13)return InvokeVoid(0xC5F68BE9613E2D18,e,f,x+.0,y+.0,z+.0,ox+.0,oy+.0,oz+.0,bi,dr,iu,fr,p12,p13)end
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS=function(e,f,x,y,z,p5,dr,fr,p8)return InvokeVoid(0x18FF00FC7EFF559E,e,f,x+.0,y+.0,z+.0,p5,dr,fr,p8)end
    ENTITY.CLEAR_ENTITY_LAST_DAMAGE_ENTITY=function(e)return InvokeVoid(0xA72CD9CA74A5ECBA,e)end
    ENTITY.CLEAR_ENTITY_LAST_WEAPON_DAMAGE=function(e)return InvokeVoid(0xAC678E40BE7C74D2,e)end
    ENTITY.DELETE_ENTITY=function(e)return InvokeVoid(0xAE3CBE5BF394C9C9,e)end
    ENTITY.DOES_ENTITY_EXIST=function(e)return InvokeBool(0x7239B21A38F536BA,e)end
    ENTITY.FREEZE_ENTITY_POSITION=function(e,t)return InvokeVoid(0x428CA6DBD1094446,e,t)end
    ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME=function(e,n)return InvokeInt(0xFB71170B7E76ACBA,e,n)end
    ENTITY.GET_ENTITY_COORDS=function(e,a)return InvokeV3(0x3FEF770D40960D5A,e,a)end
    ENTITY.GET_ENTITY_FORWARD_VECTOR=function(e)return InvokeV3(0x0A794A5A57F8DF91,e)end
    ENTITY.GET_ENTITY_HEADING=function(e)return InvokeFloat(0xE83D4F9BA2A38914,e)end
    ENTITY.GET_ENTITY_MATRIX=function(e,f,r,u,p)return InvokeVoid(0xECB2FC7235A7D137,e,f,r,u,p)end
    ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND=function(e)return InvokeFloat(0x1DD55701034110E5,e)end
    ENTITY.GET_ENTITY_MODEL=function(e)return InvokeInt(0x9F47B058362C84B5,e)end
    ENTITY.GET_ENTITY_PITCH=function(e)return InvokeFloat(0xD45DC2893621E1FE,e)end
    ENTITY.GET_ENTITY_ROLL=function(e)return InvokeFloat(0x831E0242595560DF,e)end
    ENTITY.GET_ENTITY_ROTATION=function(e,r)return InvokeV3(0xAFBD61CC738D9EB9,e,r)end
    ENTITY.GET_ENTITY_ROTATION_VELOCITY=function(e)return InvokeV3(0x213B91045D09B983,e)end
    ENTITY.GET_ENTITY_SPEED=function(e)return InvokeFloat(0xD5037BA82E12416F,e)end
    ENTITY.GET_ENTITY_VELOCITY=function(e)return InvokeV3(0x4805D2B1D8CF94A9,e)end
    ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE=function(e,b)return InvokeV3(0x44A8FCB8ED227738,e,b)end
    ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY=function(e1,e2,p)return InvokeBool(0xC86D67D52A707CF8,e1,e2,p)end
    ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_WEAPON=function(e,w,t)return InvokeBool(0x131D401334815E94,e,w,t)end
    ENTITY.IS_ENTITY_A_PED=function(e)return InvokeBool(0x524AC5ECEA15343E,e)end
    ENTITY.IS_ENTITY_A_VEHICLE=function(e)return InvokeBool(0x6AC7003FA6E5575E,e)end
    ENTITY.IS_ENTITY_IN_AIR=function(e)return InvokeBool(0x886E37EC497200B6,e)end
    ENTITY.IS_ENTITY_UPRIGHT=function(e,a)return InvokeBool(0x5333F526F6AB19AA,e,a+.0)end
    ENTITY.RESET_ENTITY_ALPHA=function(e)return InvokeVoid(0x9B1E824FFBB7027A,e)end
    ENTITY.SET_ENTITY_ALPHA=function(e,a,s)return InvokeVoid(0x44A0870B7E92D7C0,e,a,s)end
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY=function(e,p1,p2)return InvokeVoid(0xAD738C3085FE7E11,e,p1,p2)end
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED=function(e)return InvokeVoid(0xB736A491E64A32CF,e)end
    ENTITY.SET_ENTITY_COLLISION=function(e,t,k)return InvokeVoid(0x1A9205C1B9EE827F,e,t,k)end
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION=function(e,t,k)return InvokeVoid(0x9EBC85ED0FFFE51C,e,t,k)end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET=function(e,x,y,z,xa,ya,za)return InvokeVoid(0x239A3351AC1DA385,e,x+.0,y+.0,z+.0,xa,ya,za)end
    ENTITY.SET_ENTITY_HAS_GRAVITY=function(e,t)return InvokeVoid(0x4A4722448F18EEF5,e,t)end
    ENTITY.SET_ENTITY_INVINCIBLE=function(e,t)return InvokeVoid(0x3882114BDE571AD4,e,t)end
    ENTITY.SET_ENTITY_HEADING=function(e,h)return InvokeVoid(0x8E2530AA8ADA980E,e,h+.0)end
    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY=function(e1,e2,t)return InvokeVoid(0xA53ED5520C07654A,e1,e2,t)end
    ENTITY.SET_ENTITY_ROTATION=function(e,p,r,y,ro,p5)return InvokeVoid(0x8524A8B0171D5E07,e,p+.0,r+.0,y+.0,ro,p5)end
    ENTITY.SET_ENTITY_VELOCITY=function(e,x,y,z)return InvokeVoid(0x1C99BB7B6E96D16F,e,x+.0,y+.0,z+.0)end
    ENTITY.SET_ENTITY_IS_TARGET_PRIORITY=function(e,p,d)return InvokeVoid(0xEA02E132F5C68722,e,p,d+.0)end
    FIRE = {}
    FIRE.ADD_EXPLOSION=function(x,y,z,t,d,a,i,c,n)return InvokeVoid(0xE3AD2BDBAEE269AC,x+.0,y+.0,z+.0,t,d+.0,a,i,c+.0,n)end
    FIRE.ADD_OWNED_EXPLOSION=function(p,x,y,z,t,d,a,i,c)return InvokeVoid(0x172AA1B624FA1013,p,x+.0,y+.0,z+.0,t,d+.0,a,i,c+.0)end
    GRAPHICS = {}
    GRAPHICS.CLEAR_TIMECYCLE_MODIFIER=function()return InvokeVoid(0x0F07E7745A236711)end
    GRAPHICS.DRAW_RECT=function(x,y,w,h,r,g,b,a,p8)return InvokeVoid(0x3A618A217E5154F0,x+.0,y+.0,w+.0,h+.0,r,g,b,a,p8)end
    GRAPHICS.SET_TIMECYCLE_MODIFIER=function(n)return InvokeVoid(0x2C933ABF17A1DF41,n)end
    GRAPHICS.SET_TIMECYCLE_MODIFIER_STRENGTH=function(s)return InvokeVoid(0x82E7FFCD5B2326B3,s+.0)end
    GRAPHICS.START_PARTICLE_FX_NON_LOOPED_AT_COORD=function(n,x,y,z,rx,ry,rz,s,xa,ya,za)return InvokeBool(0x25129531F77B9ED3,n,x+.0,y+.0,z+.0,rx+.0,ry+.0,rz+.0,s+.0,xa,ya,za)end
    GRAPHICS.USE_PARTICLE_FX_ASSET=function(n)return InvokeVoid(0x6C38AF3693A69A91,n)end
    HUD = {}
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME=function(t)return InvokeVoid(0x6C188BE134E074AA,t)end
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT=function(t)return InvokeVoid(0x25FBB336DF1804CB,t)end
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT=function(x,y,p)return InvokeVoid(0xCD015E5BB0D96A57,x+.0,y+.0,p)end
    HUD.IS_PAUSE_MENU_ACTIVE=function()return InvokeBool(0xB0034A223497FFCB)end
    HUD.IS_MP_TEXT_CHAT_TYPING=function()return InvokeBool(0xB118AF58B5F332A1)end
    HUD.SET_TEXT_CENTRE=function(a)return InvokeVoid(0xC02F4DBFB51D988B,a)end
    HUD.SET_TEXT_COLOUR=function(r,g,b,a)return InvokeVoid(0xBE6B23FFA53FB442,r,g,b,a)end
    HUD.SET_TEXT_FONT=function(f)return InvokeVoid(0x66E0276CC5F6B9DA,f)end
    HUD.SET_TEXT_OUTLINE=function()return InvokeVoid(0x2513DFB0FB8400FE)end
    HUD.SET_TEXT_SCALE=function(s,sz)return InvokeVoid(0x07C837F9A01C34C9,s+.0,sz+.0)end
    HUD.CLEAR_PRINTS=function()return InvokeVoid(0xCC33FA791322B9D9)end
    HUD.CLEAR_HELP=function(t)return InvokeVoid(0x8DFCED7A656F8802,t)end
    HUD.CLEAR_BRIEF=function()return InvokeVoid(0x9D292F73ADBD9313)end
    MISC = {}
    MISC.GET_GAME_TIMER=function()return InvokeInt(0x9CD27B0045628463)end
    MISC.SET_MISSION_FLAG=function(t)return InvokeVoid(0xC4301E5121A0ED73,t)end
    MISC.TERMINATE_ALL_SCRIPTS_WITH_THIS_NAME=function(n)return InvokeVoid(0x9DC711BC69C548DF,n)end
    NETWORK = {}
    NETWORK.GET_MAX_NUM_NETWORK_VEHICLES=function()return InvokeInt(0x0AFCE529F69B21FF)end
    NETWORK.NETWORK_CONCEAL_PLAYER=function(p,t,p2)return InvokeVoid(0xBBDF066252829606,p,t,p2)end
    NETWORK.NETWORK_GET_AVERAGE_PING=function(p)return InvokeFloat(0x0E3A041ED6AC2B45,p)end
    NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED=function(e)return InvokeBool(0xC7827959479DCC78,e)end
    NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY=function(e)return InvokeInt(0xA11700682F3AD45C,e)end
    NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY=function(e)return InvokeBool(0x01BF60A500E28887,e)end
    NETWORK.NETWORK_IS_HOST=function()return InvokeBool(0x8DB296B814EDDA07)end
    NETWORK.NETWORK_IS_IN_SPECTATOR_MODE=function()return InvokeBool(0x048746E388762E11)end
    NETWORK.NETWORK_IS_PLAYER_CONNECTED=function(p)return InvokeBool(0x93DC1BE4E1ABE9D1,p)end
    NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED=function(e)return InvokeVoid(0x06FAACD625D80CAA,e)end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY=function(e)return InvokeBool(0xB69317BF5E782347,e)end
    NETWORK.NETWORK_SET_FRIENDLY_FIRE_OPTION=function(t)return InvokeVoid(0xF808475FA571D823,t)end
    NETWORK.NETWORK_SET_PLAYER_IS_PASSIVE=function(t)return InvokeVoid(0x1B857666604B1A74,t)end
    NETWORK.NETWORK_UNREGISTER_NETWORKED_ENTITY=function(e)return InvokeVoid(0x7368E683BB9038D6,e)end
    NETWORK.RESET_GHOST_ALPHA=function()return InvokeVoid(0x17330EBF2F2124A8)end
    NETWORK.SET_LOCAL_PLAYER_AS_GHOST=function(t,p)return InvokeVoid(0x5FFE9B4144F9712F,t,p)end
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE=function(n,t)return InvokeVoid(0x299EEB23175895FC,n,t)end
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES=function(n,t)return InvokeVoid(0xE05E81A888FA63C8,n,t)end
    PAD = {}
    PAD.DISABLE_CONTROL_ACTION=function(c,a,d)return InvokeVoid(0xFE99B66D079CF6BC,c,a,d)end
    PAD.GET_DISABLED_CONTROL_NORMAL=function(c,a)return InvokeFloat(0x11E65974A982637C,c,a)end
    PAD.IS_CONTROL_JUST_PRESSED=function(c,a)return InvokeBool(0x580417101DDB492F,c,a)end
    PAD.IS_CONTROL_PRESSED=function(c,a)return InvokeBool(0xF3A21BCD95725A4A,c,a)end
    PAD.IS_DISABLED_CONTROL_JUST_PRESSED=function(c,a)return InvokeBool(0x91AEF906BCA88877,c,a)end
    PAD.IS_DISABLED_CONTROL_PRESSED=function(c,a)return InvokeBool(0xE2587F8CBBD87B1D,c,a)end
    PAD.IS_USING_KEYBOARD_AND_MOUSE=function(c)return InvokeBool(0xA571D46727E2B718,c)end
    PAD.SET_CONTROL_VALUE_NEXT_FRAME=function(c,a,v)return InvokeBool(0xE8A25867FBA3B05E,c,a,v+.0)end
    PED = {}
    PED.CREATE_PED=function(pt,h,x,y,z,hd,n,s)return InvokeInt(0xD49F9B0955C367DE,pt,h,x+.0,y+.0,z+.0,hd+.0,n,s)end
    PED.GET_MELEE_TARGET_FOR_PED=function(p)return InvokeInt(0x18A3E9EE1297FD39,p)end
    PED.GET_VEHICLE_PED_IS_IN=function(p,i)return InvokeInt(0x9A9112A0FE9A4713,p,i)end
    PED.IS_PED_A_PLAYER=function(p)return InvokeBool(0x12534C348C6CB68B,p)end
    PED.IS_PED_DEAD_OR_DYING=function(p,p1)return InvokeBool(0x3317DEDB88C95038,p,p1)end
    PED.IS_PED_FALLING=function(p)return InvokeBool(0xFB92A102F1C4DFA3,p)end
    PED.IS_PED_GETTING_UP=function(p)return InvokeBool(0x2A74E1D5F2F00EEC,p)end
    PED.IS_PED_HURT=function(p)return InvokeBool(0x5983BB449D7FDB12,p)end
    PED.IS_PED_INJURED=function(p)return InvokeBool(0x84A2DD9AC37C35C1,p)end
    PED.IS_PED_IN_ANY_VEHICLE=function(p,a)return InvokeBool(0x997ABD671D25CA0B,p,a)end
    PED.IS_PED_RAGDOLL=function(p)return InvokeBool(0x47E4E977581C5B55,p)end
    PED.IS_PED_RUNNING_RAGDOLL_TASK=function(p)return InvokeBool(0xE3B6097CC25AA69E,p)end
    PED.IS_PED_SHOOTING=function(p)return InvokeBool(0x34616828CD07F1A1,p)end
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS=function(p,t)return InvokeVoid(0x90D2156198831D69,p,t)end
    PED.SET_PED_CAN_RAGDOLL=function(p,t)return InvokeVoid(0xB128377056A54E2A,p,t)end
    PED.SET_PED_INTO_VEHICLE=function(p,v,s)return InvokeVoid(0xF75B0D629E1C063D,p,v,s)end
    PED.SET_PED_CONFIG_FLAG=function(p,f,v)return InvokeVoid(0x1913FE4CBF41C463,p,f,v)end
    PED.SET_PED_RESET_FLAG=function(p,f,v)return InvokeVoid(0xC1E8A365BF3B29F2,p,f,v)end
    PLAYER = {}
    PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT=function(p,e)return InvokeBool(0x2975C866E6713290,p,e)end
    PLAYER.GET_PLAYER_NAME=function(p)return InvokeString(0x6D0DE6A7B5DA71F8,p)end
    PLAYER.GET_PLAYER_PED_SCRIPT_INDEX=function(p)return InvokeInt(0x50FAC3A3E030A6E1,p)end
    PLAYER.IS_PLAYER_PLAYING=function(p)return InvokeBool(0x5E9564D8246B909A,p)end
    PLAYER.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE=function(p)return InvokeBool(0x690A61A6D13583F6,p)end
    PLAYER.GET_PLAYER_TEAM=function(p)return InvokeInt(0x37039302F4E0A008,p)end
    PLAYER.PLAYER_PED_ID=function()return InvokeInt(0xD80958FC74E988A6)end
    PLAYER.ADD_PLAYER_TARGETABLE_ENTITY=function(p,e)return InvokeVoid(0x9097EB6D4BB9A12A,p,e)end
    PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY=function(p,e)return InvokeVoid(0x9F260BFB59ADBCA3,p,e)end
    PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER=function(p,m,b)return InvokeVoid(0x4A3DC7ECCC321032,p,m+.0,b)end
    PLAYER.FORCE_CLEANUP_FOR_ALL_THREADS_WITH_THIS_NAME=function(n,f)return InvokeVoid(0x4C68DDDDF0097317,n,f)end
    SCRIPT = {}
    SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH=function(h)return InvokeInt(0x2C83A9DA6BFFC4F9,h)end
    SHAPETEST = {}
    SHAPETEST.GET_SHAPE_TEST_RESULT=function(h,hi,ec,sn,eh)return InvokeInt(0x3D87450E15D98694,h,hi,ec,sn,eh)end
    SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE=function(x1,y1,z1,x2,y2,z2,f,e,p)return InvokeInt(0x377906D8A31E5586,x1+.0,y1+.0,z1+.0,x2+.0,y2+.0,z2+.0,f,e,p)end
    STREAMING = {}
    STREAMING.HAS_ANIM_DICT_LOADED=function(a)return InvokeBool(0xD031A9162D01088C,a)end
    STREAMING.HAS_COLLISION_LOADED_AROUND_ENTITY=function(e)return InvokeBool(0xE9676F61BC0B3321,e)end
    STREAMING.HAS_MODEL_LOADED=function(m)return InvokeBool(0x98A4EB5D89A0C952,m)end
    STREAMING.HAS_NAMED_PTFX_ASSET_LOADED=function(n)return InvokeBool(0x8702416E512EC454,n)end
    STREAMING.IS_MODEL_VALID=function(m)return InvokeBool(0xC0296A2EDF545E92,m)end
    STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS=function()return InvokeBool(0xD9D2CFFF49FAB35F)end
    STREAMING.REMOVE_ANIM_DICT=function(a)return InvokeVoid(0xF66A602F829E2A06,a)end
    STREAMING.REQUEST_ANIM_DICT=function(a)return InvokeVoid(0xD3BD40951412FEF6,a)end
    STREAMING.REQUEST_MODEL=function(m)return InvokeVoid(0x963D27A58DF860AC,m)end
    STREAMING.REQUEST_NAMED_PTFX_ASSET=function(n)return InvokeVoid(0xB80D8756B4668AB6,n)end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED=function(m)return InvokeVoid(0xE532F5D78798DAAB,m)end
    STREAMING.SET_FOCUS_POS_AND_VEL=function(x,y,z,ox,oy,oz)return InvokeVoid(0xBB7454BAFF08FE25,x+.0,y+.0,z+.0,ox+.0,oy+.0,oz+.0)end
    STREAMING.CLEAR_FOCUS=function()return InvokeVoid(0x31B73D1EA9F01DA2)end
    STREAMING.REQUEST_COLLISION_AT_COORD=function(x,y,z)return InvokeVoid(0x07503F7948F491A7,x+.0,y+.0,z+.0)end
    TASK = {}
    TASK.CLEAR_PED_TASKS_IMMEDIATELY=function(p)return InvokeVoid(0xAAA34F8A7CB32098,p)end
    TASK.GET_IS_TASK_ACTIVE=function(p,t)return InvokeBool(0xB0760331C7AA4155,p,t)end
    TASK.TASK_ENTER_VEHICLE=function(p,v,t,s,sp,f,cs,p7)return InvokeVoid(0xC20E50AA46D09CA8,p,v,t,s,sp+.0,f,cs,p7)end
    TASK.TASK_VEHICLE_DRIVE_WANDER=function(p,v,s,d)return InvokeVoid(0x480142959D337D00,p,v,s+.0,d)end
    TASK.TASK_PLAY_ANIM=function(p,d,n,bi,bo,du,f,pr,lx,ly,lz)return InvokeVoid(0xEA47FE3719165B94,p,d,n,bi+.0,bo+.0,du,f,pr+.0,lx,ly,lz)end
    TASK.TASK_SHUFFLE_TO_NEXT_VEHICLE_SEAT=function(p,v,a)return InvokeVoid(0x7AA80209BDA643EB,p,v,a)end
    PED.SET_PED_CYCLE_VEHICLE_WEAPONS_ONLY=function(p)return InvokeVoid(0x50276EF8172F5F12,p)end
    VEHICLE = {}
    VEHICLE.CONTROL_LANDING_GEAR=function(v,s)return InvokeVoid(0xCFC8BE9A5E1FE575,v,s)end
    VEHICLE.CREATE_VEHICLE=function(m,x,y,z,h,n,s,p)return InvokeInt(0xAF35D0D2583051B0,m,x+.0,y+.0,z+.0,h+.0,n,s,p)end
    VEHICLE.DOES_VEHICLE_HAVE_WEAPONS=function(v)return InvokeBool(0x25ECB9F8017D98E0,v)end
    VEHICLE.GET_CLOSEST_VEHICLE=function(x,y,z,r,m,f)return InvokeInt(0xF73EB622C4F1689B,x+.0,y+.0,z+.0,r+.0,m,f)end
    VEHICLE.GET_PED_IN_VEHICLE_SEAT=function(v,s,p)return InvokeInt(0xBB40DD2270B65366,v,s,p)end
    VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS=function(v)return InvokeInt(0xA7C4F2C6E744A550,v)end
    VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS=function(m)return InvokeInt(0x2AD93716F184EDA4,m)end
    VEHICLE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER=function(v,p)return InvokeBool(0xF6AF6CB341349015,v,p)end
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER=function(v,p,t)return InvokeVoid(0x517AAF684BB50CD1,v,p,t)end
    VEHICLE.SET_HELI_BLADES_FULL_SPEED=function(v)return InvokeVoid(0xA178472EBB8AE60D,v)end
    VEHICLE.SET_VEHICLE_BRAKE=function(v,t)return InvokeVoid(0xE4E2FD323574965C,v,t)end
    VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE=function(v,val)return InvokeVoid(0xB59E4BD37AE292DB,v,val+.0)end
    VEHICLE.SET_VEHICLE_DOORS_LOCKED=function(v,d)return InvokeVoid(0xB664292EAECF7FA6,v,d)end
    VEHICLE.SET_VEHICLE_ENGINE_ON=function(v,val,i,d)return InvokeVoid(0x2497C4717C8B881E,v,val,i,d)end
    VEHICLE.SET_VEHICLE_FORWARD_SPEED=function(v,s)return InvokeVoid(0xAB54A438726D25D5,v,s+.0)end
    VEHICLE.MODIFY_VEHICLE_TOP_SPEED=function(v,val)return InvokeVoid(0x93A3996368C94158,v,val+.0)end
    VEHICLE.SET_VEHICLE_HANDBRAKE=function(v,t)return InvokeVoid(0x684785568EF26A22,v,t)end
    VEHICLE.GET_VEHICLE_HOMING_LOCKON_STATE=function(v)return InvokeInt(0xE6B0E8CFC3633BF0,v)end
    VEHICLE.GET_VEHICLE_LOCK_ON_TARGET=function(v,e)return InvokeBool(0x8F5EBAB1F260CFCE,v,e)end
    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET=function(d,e,x,y,z)return InvokeVoid(0x74CD9A9327A282EA,d,e,x+.0,y+.0,z+.0)end
    VEHICLE.GET_VEHICLE_CLASS=function(v)return InvokeInt(0x29439776AAA00A62,v)end
    VEHICLE.SET_VEHICLE_WEAPON_RESTRICTED_AMMO=function(v,i,c)return InvokeVoid(0x44CD1F493DB2A0A6,v,i,c)end
    VEHICLE.GET_VEHICLE_WEAPON_RESTRICTED_AMMO=function(v,i)return InvokeInt(0x8181CE2F25CB9BB7,v,i)end
    VEHICLE.SET_VEHICLE_BOMB_AMMO=function(v,a)return InvokeVoid(0xF4B2ED59DEB5D774,v,a)end
    VEHICLE.GET_VEHICLE_BOMB_AMMO=function(v)return InvokeInt(0xEA12BD130D7569A1,v)end
    VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO=function(v,a)return InvokeVoid(0x9BDA23BF666F0855,v,a)end
    VEHICLE.GET_VEHICLE_COUNTERMEASURE_AMMO=function(v)return InvokeInt(0xF846AA63DF56B804,v)end
    WEAPON = {}
    WEAPON.CLEAR_ENTITY_LAST_WEAPON_DAMAGE=function(e)return InvokeVoid(0xAC678E40BE7C74D2,e)end
    WEAPON.GET_AMMO_IN_CLIP=function(p,w,a)return InvokeBool(0x2E1202248937775C,p,w,a)end
    WEAPON.GET_SELECTED_PED_WEAPON=function(p)return InvokeInt(0x0A6DB4965674D243,p)end
    WEAPON.GET_WEAPONTYPE_GROUP=function(w)return InvokeInt(0xC3287EE3050FB74C,w)end
    WEAPON.HAS_ENTITY_BEEN_DAMAGED_BY_WEAPON=function(e,w,t)return InvokeBool(0x131D401334815E94,e,w,t)end
    WEAPON.SET_CURRENT_PED_WEAPON=function(p,w,f)return InvokeVoid(0xADF692B254977C0C,p,w,f)end
    WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON=function(p,w)return InvokeBool(0x75C55983C2C39DAA,p,w)end
    WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON=function(p,h)return InvokeBool(0x1017582BCD3832DC,p,h)end
    WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX=function(p,p1)return InvokeInt(0x3B390A939AF0B5FC,p,p1)end
end

local VIBE_VERSION = "1.9.2"

local OFF = {
    PED_WEAPON_MGR       = 0x10B8,
    EQUIPPED_WEAPON      = 0x58,
    VEH_WEAPON_INFO      = 0x18,
    WEAPON_NAME_HASH     = 0x10,
    DAMAGE               = 0xB0,
    AMMO_INFO            = 0x60,
    RELOAD_TIME_MP       = 0x128,
    RELOAD_TIME_SP       = 0x12C,
    ANIM_RELOAD_RATE     = 0x134,
    TIME_BETWEEN_SHOTS   = 0x13C,
    TIME_LEFT_CACHED     = 0x140,
    ALT_WAIT_TIME        = 0x150,
    VEH_RELOAD_TIME      = 0x130,
    SPIN_UP_TIME         = 0x144,
    SPIN_TIME            = 0x148,
    SPIN_DOWN_TIME       = 0x14C,
    LAUNCH_SPEED         = 0x58,
    LIFETIME             = 0x44,
    VEH_LIFETIME         = 0x48,
    LIFETIME_LOCKON_MP   = 0x198,
    LOCK_ON_TIME         = 0x154,
    LOCK_ON_RANGE        = 0x288,
    WEAPON_RANGE         = 0x28C,
    TIME_BEFORE_HOMING   = 0x178,
    PITCH_CHANGE_RATE    = 0x188,
    YAW_CHANGE_RATE      = 0x18C,
}

local INPUT = {
    VEH_ATTACK         = 69,
    VEH_AIM            = 68,
    VEH_FLY_ATTACK     = 114,
    VEH_FLY_ATTACK2    = 331,
    AIM                = 25,
    ATTACK             = 24,
    CURSOR_SCROLL_UP   = 241,
    CURSOR_SCROLL_DOWN = 242,
}

local speedMultiplier = 1.0
local superDriveKey = {
    vk = 0x57,
    DEFAULT_VK = 0x57,
    controlId = 208,
    DEFAULT_CONTROL = 208,
    captureState = nil,
    captureHeld = nil,
}

local CONTROLLER_BUTTONS = {
    { id = 0,   name = "(none)" },
    { id = 208, name = "RT" },
    { id = 207, name = "LT" },
    { id = 206, name = "RB" },
    { id = 205, name = "LB" },
    { id = 201, name = "A" },
    { id = 202, name = "B" },
    { id = 203, name = "X" },
    { id = 204, name = "Y" },
    { id = 209, name = "LS" },
    { id = 210, name = "RS" },
    { id = 188, name = "DPad Up" },
    { id = 187, name = "DPad Down" },
    { id = 189, name = "DPad Left" },
    { id = 190, name = "DPad Right" },
    { id = 199, name = "Start" },
    { id = 217, name = "Back" },
    { id = 61,  name = "LS Up (analog)" },
    { id = 62,  name = "LS Down (analog)" },
    { id = 3,   name = "RS Up (analog)" },
    { id = 4,   name = "RS Down (analog)" },
}
local function controllerButtonName(id)
    for _, b in ipairs(CONTROLLER_BUTTONS) do
        if b.id == id then return b.name end
    end
    return ("Ctrl %d"):format(id)
end

wheelie = {
    vk              = 0xA2,
    DEFAULT_VK      = 0xA2,
    controlId       = 62,
    DEFAULT_CONTROL = 62,
    captureState    = nil,
    captureHeld     = nil,
    strength        = 1.0,
    debug           = false,

    BUTTONS = CONTROLLER_BUTTONS,
}

titanCannonCycle = {
    vk              = 0x42,
    DEFAULT_VK      = 0x42,
    controlId       = 0,
    DEFAULT_CONTROL = 0,
    captureState    = nil,
    captureHeld     = nil,
    kbdLast         = false,
    lastFireMs      = 0,
    shuffleHops      = 1,
    shuffleDelayMs   = 1500,
    useAlternate     = false,
    layoutInspected  = false,
    targetGunnerSeat   = 2,
    DEFAULT_TARGET     = 2,
    exitTargetSeat     = 1,
    DEFAULT_EXIT       = 1,
    originalPrimary    = nil,
    patchedPsoAddr     = nil,
    patchActive        = false,
    exitPatchedEntry   = nil,
    exitOriginalPrimary = nil,
    exitPatchActive    = false,
    pendingHops      = 0,
    nextHopMs        = 0,
    BUTTONS = CONTROLLER_BUTTONS,
}

DEV = DEV or {}

local H = {
    RAPID_FIRE      = Utils.Joaat("LUA_VehRapidFire"),
    ONFOOT_RAPID    = Utils.Joaat("LUA_OnFootRapidFire"),
    ONFOOT_HOMING_SPAM = Utils.Joaat("LUA_OnFootHomingSpam"),
    ROCKET_SPEED    = Utils.Joaat("LUA_RocketSpeed"),
    NOCLIP_ROCKETS  = Utils.Joaat("LUA_NoclipRockets"),
    VEH_INF_AMMO    = Utils.Joaat("LUA_VehInfiniteAmmo"),
    INFINITE_RANGE  = Utils.Joaat("LUA_InfiniteRange"),
    INSTANT_ROCKET  = Utils.Joaat("LUA_InstantRocket"),
    SUPERDRIVE      = Utils.Joaat("LUA_SuperDriveToggle"),
    SUPERDRIVE_MULT = Utils.Joaat("LUA_SuperDriveMultiplier"),
    SUPERDRIVE_CAM  = Utils.Joaat("LUA_SuperDriveUseCam"),
    WHEELIE         = Utils.Joaat("LUA_WheelieToggle"),
    WHEELIE_STRENGTH= Utils.Joaat("LUA_WheelieStrength"),
    ENGINE_POWER    = Utils.Joaat("LUA_EnginePower"),
    ENGINE_POWER_MULT = Utils.Joaat("LUA_EnginePowerMult"),
    GRAVITY_GUN     = Utils.Joaat("LUA_GravityGun"),
    GRAV_FORCE      = Utils.Joaat("LUA_GravForce"),
    GRAV_COLLISION  = Utils.Joaat("LUA_GravCollision"),
    GRAV_IN_VEH     = Utils.Joaat("LUA_GravInVehicle"),
    GRAV_CONTRIVED  = Utils.Joaat("LUA_GravContrived"),
    INSTANT_LOCKON  = Utils.Joaat("LUA_InstantLockon"),
    AUTO_LOCKON_FIRE= Utils.Joaat("LUA_AutoLockonFire"),
    LOCK_ONTO_PLAYERS = Utils.Joaat("LUA_LockOntoPlayers"),
    LOCK_ONTO_NPCS  = Utils.Joaat("LUA_LockOntoNPCs"),
    INF_LOCKON_RANGE = Utils.Joaat("LUA_InfiniteLockonRange"),
    DISABLE_LOS     = Utils.Joaat("LUA_DisableLOS"),
    FRENCH_KICKER   = Utils.Joaat("LUA_FrenchKicker"),
    FRENCH_REGIONS  = Utils.Joaat("LUA_FrenchRegions"),
    CHINESE_KICKER  = Utils.Joaat("LUA_ChineseKicker"),
    CHINESE_REGIONS = Utils.Joaat("LUA_ChineseRegions"),
    MY_COUNTRY_ONLY = Utils.Joaat("LUA_MyCountryOnly"),
    VPN_KICKER      = Utils.Joaat("LUA_VPNKicker"),
    RELAY_KICKER    = Utils.Joaat("LUA_RelayKicker"),
    SMS_MSG         = Utils.Joaat("LUA_SmsMessage"),
    SMS_SEND        = Utils.Joaat("LUA_SmsSend"),
    SMS_STATUS      = Utils.Joaat("LUA_SmsStatus"),
    SMS_BCAST_MSG   = Utils.Joaat("LUA_SmsBroadcastMessage"),
    SMS_BCAST       = Utils.Joaat("LUA_SmsBroadcast"),
    SMS_BCAST_STATUS = Utils.Joaat("LUA_SmsBroadcastStatus"),
    SMS_KEEP_TEXT   = Utils.Joaat("LUA_SmsKeepText"),
    DRIFT_ASSIST    = Utils.Joaat("LUA_DriftAssist"),
    DRIFT_TRACTION  = Utils.Joaat("LUA_DriftTraction"),
    DRIFT_SCORE     = Utils.Joaat("LUA_DriftScoreDisplay"),
    DRIFT_SMOKE     = Utils.Joaat("LUA_DriftSmoke"),
    DRIFT_EXIT_BOOST= Utils.Joaat("LUA_DriftExitBoost"),
    JTURN           = Utils.Joaat("LUA_JTurn"),
    LTURN           = Utils.Joaat("LUA_LTurn"),
    TURN_LEFT       = Utils.Joaat("LUA_TurnLeft"),
    TURN_RIGHT      = Utils.Joaat("LUA_TurnRight"),
    TURN_SPIN_FORCE = Utils.Joaat("LUA_TurnSpinForce"),
    TURN_BOOST_FORCE= Utils.Joaat("LUA_TurnBoostForce"),
    TURN_POP        = Utils.Joaat("LUA_TurnPop"),
    DRIFT_TARGET    = Utils.Joaat("LUA_DriftTarget"),
    DRIFT_TARGET_TR = Utils.Joaat("LUA_DriftTargetTraction"),
    DRIFT_TARGET_F  = Utils.Joaat("LUA_DriftTargetForce"),
    DRIFT_FORCE     = Utils.Joaat("LUA_DriftForce"),
    DRIFT_POWER     = Utils.Joaat("LUA_DriftPower"),
    VEH_GUN         = Utils.Joaat("LUA_VehicleGun"),
    VEH_GUN_IN_VEH  = Utils.Joaat("LUA_VehGunInVehicle"),
    VEH_GUN_SPEED   = Utils.Joaat("LUA_VehGunSpeed"),
    VEH_GUN_DIST    = Utils.Joaat("LUA_VehGunDist"),
    VEH_GUN_RANDOM  = Utils.Joaat("LUA_VehGunRandom"),
    VEH_GUN_RAND_AIR = Utils.Joaat("LUA_VehGunRandAir"),
    VEH_GUN_RAND_SEA = Utils.Joaat("LUA_VehGunRandSea"),
    VEH_GUN_TARGET  = Utils.Joaat("LUA_VehGunTarget"),
    SUPER_MELEE     = Utils.Joaat("LUA_SuperMelee"),
    FLY_WINDSCREEN  = Utils.Joaat("LUA_FlyWindscreen"),
    REWIND          = Utils.Joaat("LUA_Rewind"),
    REWIND_LENGTH   = Utils.Joaat("LUA_RewindLength"),
    REWIND_SPEED    = Utils.Joaat("LUA_RewindSpeed"),
    REWIND_PROTOCOL = Utils.Joaat("LUA_RewindProtocolVersion"),
    REWIND_REMOTE_HOLD = Utils.Joaat("LUA_RewindRemoteHold"),
    REWIND_KEY      = Utils.Joaat("LUA_RewindKey"),
    WEAPON_WHEEL    = Utils.Joaat("LUA_WeaponWheel"),
    DRIVEBY_ANY_VEH = Utils.Joaat("LUA_DrivebyAnyVeh"),
    TITAN_DRIVER_WEAPONS = Utils.Joaat("LUA_TitanDriverWeapons"),
    TITAN_PROBE     = Utils.Joaat("LUA_TitanProbe"),
    TITAN_CANNON_CYCLE = Utils.Joaat("LUA_TitanCannonCycle"),
    BLACK_ICE       = Utils.Joaat("LUA_BlackIce"),
    PHANTOM_BRAKE   = Utils.Joaat("LUA_PhantomBrake"),
    PHANTOM_MIN     = Utils.Joaat("LUA_PhantomMin"),
    PHANTOM_MAX     = Utils.Joaat("LUA_PhantomMax"),
    PHANTOM_DUR     = Utils.Joaat("LUA_PhantomDur"),
    STEER_INVERT    = Utils.Joaat("LUA_SteerInvert"),
    STEER_INV_STR   = Utils.Joaat("LUA_SteerInvertStrength"),
    PLAYER_SPEED    = Utils.Joaat("LUA_PlayerSpeedMultiplier"),
    PLAYER_SPEED_MULT = Utils.Joaat("LUA_PlayerSpeedMultiplierValue"),
    PLAYER_SPEED_SYNC = Utils.Joaat("LUA_PlayerSpeedSync"),
    WATCH_YO_JET    = Utils.Joaat("LUA_WatchYoJet"),
    WATCH_YO_JET_FU = Utils.Joaat("LUA_WatchYoJetFU"),
    WATCH_YO_JET_DEL= Utils.Joaat("LUA_WatchYoJetDel"),
    RAGDOLL_FIX     = Utils.Joaat("LUA_RagdollFix"),
    BETTER_ESC_ENGINE = Utils.Joaat("LUA_BetterEscEngine"),
    BETTER_ALT_F4   = Utils.Joaat("LUA_BetterAltF4"),
    LOCK_CINE_CAM        = Utils.Joaat("LUA_LockCineCam"),
    LOCK_CINE_CAM_SWITCH = Utils.Joaat("LUA_LockCineCamSwitch"),
    YOGA_RUN        = Utils.Joaat("LUA_YogaRun"),
    WP_INTERIOR     = Utils.Joaat("LUA_WaypointsInInterior"),
    WP_INSIDE_INT   = Utils.Joaat("LUA_WaypointsInsideInterior"),
    AUTO_TP_OBJECTIVE = Utils.Joaat("LUA_AutoTeleportObjective"),
    RICK_ROLL_HORN  = Utils.Joaat("LUA_RickRollHorn"),
    PAUSED_SPOOF    = Utils.Joaat("LUA_PausedSpoof"),
    PASSIVE_SPOOF   = Utils.Joaat("LUA_PassiveSpoof"),
    REMOVE_PASSIVE = Utils.Joaat("LUA_RemovePassive"),
    STRIP_VEH_GOD  = Utils.Joaat("LUA_StripVehGod"),
    JOIN_CEO       = Utils.Joaat("LUA_JoinCEO"),
    BOUNTY_AMOUNT    = Utils.Joaat("LUA_BountyAmount"),
    SET_BOUNTY_NPC   = Utils.Joaat("LUA_SetBountyNpc"),
    SET_BOUNTY_OWNED = Utils.Joaat("LUA_SetBountyOwned"),
    SET_BOUNTY_ALL_NPC   = Utils.Joaat("LUA_SetBountyAllNpc"),
    SET_BOUNTY_ALL_OWNED = Utils.Joaat("LUA_SetBountyAllOwned"),
    SI_LIST_ALL     = Utils.Joaat("LUA_SiListAll"),
    ENTER_INTERIOR  = Utils.Joaat("LUA_EnterInterior"),
    KICK_INTERIOR   = Utils.Joaat("LUA_KickInterior"),
    RAGDOLL_NO_RAG  = Utils.Joaat("LUA_RagdollNoRag"),
    PAUSE_TARGET    = Utils.Joaat("LUA_PauseTarget"),
    PAUSE_TGT_DUR   = Utils.Joaat("LUA_PauseTgtDur"),
    OPP_NERF        = Utils.Joaat("LUA_OppressorNerf"),
    LAZER_NERF      = Utils.Joaat("LUA_LazerNerf"),
    CANNON_RANGE    = Utils.Joaat("LUA_CannonRange"),
    ALL_ROCKETS     = Utils.Joaat("LUA_AllRockets"),
    CHIMP_SWARM     = Utils.Joaat("LUA_ChimpSwarm"),
    CHIMP_COUNT     = Utils.Joaat("LUA_ChimpSwarmCount"),
    CHIMP_DIST      = Utils.Joaat("LUA_ChimpSwarmDist"),
    CHIMP_DEL       = Utils.Joaat("LUA_ChimpSwarmDel"),
    TAKEOVER_VEH    = Utils.Joaat("LUA_TakeoverVehicle"),
    HIJACK_VEH      = Utils.Joaat("LUA_HijackVehicle"),
    WEAPON_DIFF_SNAP_A = Utils.Joaat("LUA_WeaponDiffSnapA"),
    WEAPON_DIFF_SNAP_B = Utils.Joaat("LUA_WeaponDiffSnapB"),
    WEAPON_DIFF_RUN    = Utils.Joaat("LUA_WeaponDiffRun"),
    WEAPON_DIFF_PATCH  = Utils.Joaat("LUA_WeaponDiffPatch"),
    WEAPON_DIFF_REVERT = Utils.Joaat("LUA_WeaponDiffRevert"),
    WEAPON_DIFF_AMMO_PATCH  = Utils.Joaat("LUA_WeaponDiffAmmoPatch"),
    WEAPON_DIFF_AMMO_REVERT = Utils.Joaat("LUA_WeaponDiffAmmoRevert"),
    PED_DIFF_SNAP_A  = Utils.Joaat("LUA_PedDiffSnapA"),
    PED_DIFF_SNAP_A2 = Utils.Joaat("LUA_PedDiffSnapA2"),
    PED_DIFF_SNAP_B  = Utils.Joaat("LUA_PedDiffSnapB"),
    PED_DIFF_RUN     = Utils.Joaat("LUA_PedDiffRun"),
    PED_DIFF_APPLY   = Utils.Joaat("LUA_PedDiffApply"),
    PED_DIFF_REVERT  = Utils.Joaat("LUA_PedDiffRevert"),
    PED_DIFF_STRICT  = Utils.Joaat("LUA_PedDiffStrict"),
    JOIN_CEO_WATCH = Utils.Joaat("LUA_JoinCeoWatch"),
    CLEAN_MISSION_STATE = Utils.Joaat("LUA_CleanMissionState"),
}

TELEMETRY_ACTIONS = {}
TELEMETRY_TOGGLE_EDGE = {}

function telemetryCountAction(key)
    TELEMETRY_ACTIONS[key] = (TELEMETRY_ACTIONS[key] or 0) + 1
end

function telemetryCountToggleEdge(key, pid, isOn)
    local slots = TELEMETRY_TOGGLE_EDGE[key]
    if isOn then
        if not slots then
            slots = {}
            TELEMETRY_TOGGLE_EDGE[key] = slots
        end
        if not slots[pid] then
            slots[pid] = true
            telemetryCountAction(key)
        end
    elseif slots then
        slots[pid] = nil
    end
end

local weaponState = {
    originalVehTimings = {},
    originalLaunchSpeed = {},
    originalLifeTimes = {},
    rocketSpeedMult = 1.0,
    savedOnFootWeapon = nil,
    lastRapidFireVeh = 0,
    rapidFireVehTick = 0,
    rapidFireResolved = false,
    rangeMult = 1.0,
    originalLockonValues = {},
    originalWeaponRanges = {},
    UNARMED_HASH = Utils.Joaat("WEAPON_UNARMED"),
    GROUP_THROWN  = Utils.Joaat("GROUP_THROWN"),
    lastVehicle  = 0,
    vehTick      = 0,
    VEH_INIT_DELAY = 15,
}
local autoLockBuf = Memory.Alloc(4)
local vwSyncHashBuf = Memory.Alloc(4)


local driftState = {
    score = 0.0, active = false, tractionMult = 0.5, forceMult = 1.0,
    bestScore = 0.0, scoreShow = 0.0, scoreExpiry = 0,
    ptfxReady = false, smokeTick = 0,
    powerMult = 1.5,
    lastVeh = 0,
}

local watchYoJet = {
    pool = {},
    TIMEOUT = 15000,
    SPEED = 80.0,
    COLLISION_DIST = 40.0,
    delBuf = Memory.Alloc(4),
    jetHash = 0,
    focusSet = false,
    FOCUS_MIN_MS = 700,
    SPAWN_WAIT_MS = 4000,
    NEAR_DIST_SQ = 300.0 * 300.0,
}

local lazerExpTag = {
    idx = 2,
    labels = {
        "Vanilla (Balanced Cannons)",
        "Grenade",
        "Rocket",
        "Tank Shell",
        "RPG",
        "Plane Rocket",
        "Stickybomb",
        "Pipebomb",
        "Bombushka Cannon",
        "Hunter Cannon",
        "Valkyrie Cannon",
        "Oppressor MK2 Cannon",
        "APC Shell",
        "Explosive Ammo",
        "Railgun",
    },
    values = {
        85,
        0,
        4,
        5,
        1,
        32,
        2,
        43,
        53,
        56,
        41,
        62,
        46,
        45,
        36,
    },
}

local vehGun = {
    pool = {},
    MAX = 80,
    TIMEOUT = 120000,
    NOCOL_DURATION = 2000,
    modelName = "adder",
    modelHash = 0,
    classIdx = 1,
    vehIdx = 1,
    lastSpawnTime = 0,
    SPAWN_INTERVAL = 80,
    delBuf = Memory.Alloc(4),
    ammoBuf = Memory.Alloc(4),
    lastClipAmmo = nil,
    lastWeaponHash = 0,
    randomReady = false,
    modelRequestStart = 0,
    spawnFailCount = 0,
    MODEL_LOAD_TIMEOUT = 5000,
    MUZZLE_BONES = { "gun_muzzle", "WAPMuzzle" },
    matrixBuf = Memory.Alloc(96),
    lastAimSrc = "",
    lastAimDot = 0.0,
}

local IS_ENHANCED = not Cherax.GetEdition():find("^LE")

local windscreen = {
    patches = {},
    patched = false,
    useConfigFlag = false,
}




local rewindState = {
    snapshots = {},
    head = 0,
    count = 0,
    playhead = 0,
    maxSnapshots = 600,
    state = 0,
    settleStart = 0,
    soundId = -1,
    frozenEntity = 0,
    SETTLE_MS = 200,
    REWIND_SPEED = 1,
    lengthSec = 10,
    VK_BACKSPACE = 0x08,
    rewindVK = 0x08,
    controlId = 0,
    DEFAULT_CONTROL = 0,
    captureState = nil,
    captureHeld = nil,
    VK_NAMES = {
        [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x10] = "Shift",
        [0x11] = "Ctrl", [0x12] = "Alt", [0x13] = "Pause", [0x14] = "CapsLock",
        [0x1B] = "Escape", [0x20] = "Space",
        [0x5B] = "LWin", [0x5C] = "RWin", [0x5D] = "Menu",
        [0x90] = "NumLock", [0x91] = "ScrollLock",
        [0xA0] = "LShift", [0xA1] = "RShift", [0xA2] = "LCtrl", [0xA3] = "RCtrl",
        [0xA4] = "LAlt", [0xA5] = "RAlt",
        [0x21] = "PgUp", [0x22] = "PgDn", [0x23] = "End", [0x24] = "Home",
        [0x25] = "Left", [0x26] = "Up", [0x27] = "Right", [0x28] = "Down",
        [0x2D] = "Insert", [0x2E] = "Delete",
        [0x60] = "Num0", [0x61] = "Num1", [0x62] = "Num2", [0x63] = "Num3",
        [0x64] = "Num4", [0x65] = "Num5", [0x66] = "Num6", [0x67] = "Num7",
        [0x68] = "Num8", [0x69] = "Num9",
        [0x6A] = "Num*", [0x6B] = "Num+", [0x6D] = "Num-", [0x6E] = "Num.", [0x6F] = "Num/",
        [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
        [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
        [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
        [0xBB] = "=", [0xBC] = ",", [0xBD] = "-", [0xBE] = ".", [0xBF] = "/",
        [0xC0] = "`", [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'",
    },
}
do
    for i = 0x41, 0x5A do rewindState.VK_NAMES[i] = string.char(i) end
    for i = 0x30, 0x39 do rewindState.VK_NAMES[i] = string.char(i) end
    rewindState.VK_NAMES[0x01] = "LMB"
    rewindState.VK_NAMES[0x02] = "RMB"
    rewindState.VK_NAMES[0x04] = "MMB"
    rewindState.VK_NAMES[0x05] = "Mouse4"
    rewindState.VK_NAMES[0x06] = "Mouse5"
end

local MOUSE_VK_TO_IMGUI = {
    [0x01] = 0, [0x02] = 1, [0x04] = 2, [0x05] = 3, [0x06] = 4,
}
local function isAnyKeyDown(vk)
    local mb = MOUSE_VK_TO_IMGUI[vk]
    if mb then
        local down = ImGui.IsMouseDown(mb)
        return down
    end
    return Utils.IsKeyDown(vk)
end

local function isGameChatOpen()
    if IS_ENHANCED then return false end
    return HUD.IS_MP_TEXT_CHAT_TYPING() or false
end

local weaponWheel = {
    patches = {},
    patchAddr = nil,
    originalByte = nil,
    patched = false,
    isEnhanced = false,
}

local VEH_CLASSES = {
    { name = "Super", vehicles = {
        "adder","autarch","banshee2","bullet","cheetah","cyclone","deveste",
        "emerus","entity2","entityxf","fmj","furia","gp1","ignus","italigtb",
        "italigtb2","krieger","le7b","lm87","nero","nero2","osiris","penetrator",
        "pfister811","prototipo","reaper","s80","sc1","scramjet","sheava",
        "sultanrs","t20","taipan","tempesta","tezeract","thrax","tigon",
        "turismor","tyrant","tyrus","vacca","vagner","vigilante","virtue",
        "visione","voltic","voltic2","zentorno","zorrusso",
    }},
    { name = "Sports", vehicles = {
        "alpha","banshee","bestiagts","buffalo","buffalo2","buffalo3",
        "calico","carbonizzare","comet2","comet3","comet4","comet5","comet6",
        "comet7","coquette","coquette4","corsita","cypher","drafter","elegy",
        "elegy2","euros","feltzer2","flashgt","fusilade","futo","futo2",
        "gb200","growler","hotring","imorgon","issi7","italigto",
        "jester","jester2","jester3","jester4","jugular","khamelion",
        "komoda","kuruma","kuruma2","locust","lynx","massacro","massacro2",
        "neo","neon","ninef","ninef2","omnis","omnisegt","panthere",
        "paragon","paragon2","pariah","penumbra","penumbra2","raiden",
        "rapidgt","rapidgt2","raptor","remus","revolter","ruston",
        "schafter2","schafter3","schafter4","schafter5","schlagen",
        "schwarzer","sentinel3","seven70","specter","specter2","streiter",
        "sugoi","sultan","sultan2","sultan3","surano","swinger",
        "tropos","vectre","verlierer2","veto","veto2","vstr",
        "zr350","zr380","zr3802","zr3803",
    }},
    { name = "Sports Classics", vehicles = {
        "ardent","btype","btype2","btype3","casco","cheburek","cheetah2",
        "coquette2","coquette3","deluxo","dynasty","fagaloa","feltzer3",
        "gt500","infernus2","jb700","jb7002","mamba","manana","manana2",
        "michelli","monroe","nebula","peyote","peyote3","pigalle",
        "rapidgt3","retinue","retinue2","savestra","stinger","stingergt",
        "stromberg","swinger","toreador","torero","torero2","tornado",
        "tornado2","tornado3","tornado4","tornado5","tornado6","turismo2",
        "viseris","z190","zion3","ztype",
    }},
    { name = "Muscle", vehicles = {
        "blade","broadway","buccaneer","buccaneer2","buffalo4","chino",
        "chino2","clique","coquette3","deviant","dominator","dominator2",
        "dominator3","dominator4","dominator5","dominator6","dominator7",
        "dominator8","dukes","dukes2","dukes3","ellie","eudora",
        "faction","faction2","faction3","gauntlet","gauntlet2","gauntlet3",
        "gauntlet4","gauntlet5","greenwood","hermes","hotknife","hustler",
        "impaler","impaler2","impaler3","impaler4","imperator","imperator2",
        "imperator3","lurcher","manana2","moonbeam","moonbeam2","nightshade",
        "peyote2","phoenix","picador","pisswasser","ratloader","ratloader2",
        "ruiner","ruiner2","ruiner3","sabregt","sabregt2",
        "slamvan","slamvan2","slamvan3","slamvan4","slamvan5","slamvan6",
        "stalion","stalion2","tampa","tampa3","tulip","tulip2",
        "vamos","vigero","vigero2","vigero3","virgo","virgo2","virgo3",
        "voodoo","voodoo2","weevil2","yosemite","yosemite2","yosemite3",
    }},
    { name = "Sedans", vehicles = {
        "asea","asea2","asterope","asterope2","cog55","cog552","cognoscenti",
        "cognoscenti2","emperor","emperor2","emperor3","fugitive","glendale",
        "glendale2","ingot","intruder","limo2","premier","primo","primo2",
        "regina","rhinehart","schafter2","stafford","stanier","stratum",
        "stretch","superd","surge","tailgater","tailgater2","warrener",
        "warrener2","washington",
    }},
    { name = "Coupes", vehicles = {
        "cogcabrio","exemplar","f620","felon","felon2","jackal","oracle",
        "oracle2","previon","sentinel","sentinel2","windsor","windsor2",
        "zion","zion2",
    }},
    { name = "Compacts", vehicles = {
        "asbo","blista","brioso","brioso2","brioso3","club","dilettante",
        "dilettante2","issi2","issi3","issi4","issi5","issi6","kanjo",
        "panto","prairie","rhapsody","weevil",
    }},
    { name = "SUVs", vehicles = {
        "baller","baller2","baller3","baller4","baller5","baller6","baller7",
        "bjxl","cavalcade","cavalcade2","contender","deity","dubsta",
        "dubsta2","fq2","granger","granger2","gresley","habanero","huntley",
        "iwagen","jubilee","landstalker","landstalker2","mesa","mesa2",
        "novak","patriot","patriot2","patriot3","radius","rebla","rocoto",
        "seminole","seminole2","serrano","squaddie","toros","xls","xls2",
    }},
    { name = "Off-Road", vehicles = {
        "bfinjection","bifta","blazer","blazer2","blazer3","blazer4",
        "blazer5","brawler","bruiser","bruiser2","bruiser3","brutus",
        "brutus2","brutus3","caracara","caracara2","dloader",
        "dubsta3","dune","dune2","dune3","dune4","dune5","everon",
        "freecrawler","hellion","insurgent","insurgent2","insurgent3",
        "kalahari","kamacho","marshall","menacer","mesa3","monster",
        "monster3","monster4","monster5","nightshark","outlaw","rancherxl",
        "rancherxl2","rcbandito","rebel","rebel2","riata","sandking",
        "sandking2","technical","technical2","technical3","trophytruck",
        "trophytruck2","vagrant","verus","winky","zhaba",
    }},
    { name = "Motorcycles", vehicles = {
        "akuma","avarus","bagger","bati","bati2","bf400","carbonrs",
        "chimera","cliffhanger","daemon","daemon2","deathbike","deathbike2",
        "deathbike3","defiler","diablous","diablous2","double","enduro",
        "esskey","faggio","faggio2","faggio3","fcr","fcr2","gargoyle",
        "hakuchou","hakuchou2","hexer","innovation","lectro","manchez",
        "manchez2","manchez3","nemesis","nightblade","oppressor","oppressor2",
        "pcj","powersurge","ratbike","reever","ruffian","rrocket",
        "sanchez","sanchez2","sanctus","shotaro","sovereign","stryder",
        "thrust","vader","vindicator","vortex","wolfsbane","zombiea",
        "zombieb",
    }},
    { name = "Vans", vehicles = {
        "bison","bison2","bison3","bobcatxl","boxville","boxville2",
        "boxville3","boxville4","boxville5","burrito","burrito2","burrito3",
        "burrito4","burrito5","camper","gburrito","gburrito2","journey",
        "journey2","minivan","minivan2","paradise","pony","pony2",
        "rumpo","rumpo2","rumpo3","speedo","speedo2","speedo4","surfer",
        "surfer2","surfer3","taco","youga","youga2","youga3","youga4",
    }},
    { name = "Military", vehicles = {
        "apc","barracks","barracks2","barracks3","barrage","chernobog",
        "crusader","halftrack","khanjali","minitank","rhino","scarab",
        "scarab2","scarab3","thruster","trailersmall2","vetir",
    }},
    { name = "Emergency", vehicles = {
        "ambulance","fbi","fbi2","firetruk","lguard","pbus","police",
        "police2","police3","police4","policeb","policeold1","policeold2",
        "policet","polmav","pranger","predator","riot","riot2","sheriff",
        "sheriff2",
    }},
    { name = "Helicopters", vehicles = {
        "akula","annihilator","annihilator2","buzzard","buzzard2","cargobob",
        "cargobob2","cargobob3","cargobob4","conada","frogger","frogger2",
        "havok","hunter","maverick","polmav","savage","seasparrow",
        "seasparrow2","seasparrow3","skylift","supervolito","supervolito2",
        "swift","swift2","valkyrie","valkyrie2","volatus",
    }},
    { name = "Planes", vehicles = {
        "alkonost","alphaz1","avenger","avenger2","besra","bombushka",
        "cargoplane","cuban800","dodo","duster","howard","hydra",
        "jet","lazer","luxor","luxor2","mammatus","microlight","miljet",
        "mogul","molotok","nimbus","nokota","pyro","raiju","rogue",
        "seabreeze","shamal","starling","streamer216","strikeforce",
        "stunt","titan","tula","velum","velum2","vestra","volatol",
    }},
    { name = "Boats", vehicles = {
        "avisa","dinghy","dinghy2","dinghy3","dinghy4","dinghy5","jetmax",
        "kosatka","longfin","marquis","patrolboat","predator","seashark",
        "seashark2","seashark3","speeder","speeder2","squalo","submersible",
        "submersible2","suntrap","toro","toro2","tropic","tropic2","tug",
    }},
    { name = "Utility", vehicles = {
        "airtug","caddy","caddy2","caddy3","docktug","forklift","mower",
        "ripley","sadler","sadler2","scrap","towtruck","towtruck2",
        "tractor","tractor2","tractor3","utillitruck","utillitruck2",
        "utillitruck3",
    }},
    { name = "Commercial", vehicles = {
        "benson","benson2","biff","cerberus","cerberus2","cerberus3",
        "hauler","hauler2","mule","mule2","mule3","mule4","mule5",
        "packer","phantom","phantom2","phantom3","phantom4","pounder",
        "pounder2","stockade","stockade3","terbyte",
    }},
    { name = "Industrial", vehicles = {
        "cutter","dump","flatbed","guardian","handler","mixer","mixer2",
        "rubble","tiptruck","tiptruck2",
    }},
    { name = "Service", vehicles = {
        "airbus","bus","coach","rallytruck","rentalbus","taxi","tourbus",
        "trash","trash2","washer",
    }},
}

local randomPool = {
    land = {},
    air  = {},
    sea  = {},
    airClasses = { Helicopters = true, Planes = true },
    seaClasses = { Boats = true },
}
for _, cls in ipairs(VEH_CLASSES) do
    for _, name in ipairs(cls.vehicles) do
        if randomPool.airClasses[cls.name] then
            randomPool.air[#randomPool.air + 1] = name
        elseif randomPool.seaClasses[cls.name] then
            randomPool.sea[#randomPool.sea + 1] = name
        else
            randomPool.land[#randomPool.land + 1] = name
        end
    end
end
randomPool.all = {}
for _, v in ipairs(randomPool.land) do randomPool.all[#randomPool.all + 1] = v end
for _, v in ipairs(randomPool.air) do randomPool.all[#randomPool.all + 1] = v end
for _, v in ipairs(randomPool.sea) do randomPool.all[#randomPool.all + 1] = v end

local quickTurn = {
    tick = 0, prevHeading = 0, totalRotation = 0,
    direction = 1, settleStart = 0, startHeading = 0,
    entrySpeed = 0,
    targetAngle = 180,
    activeFeature = nil,
    boostStart = 0,
    veh = 0,
    spinForce = 3.0,
    boostForce = 0.4,
    popForce = 2.0,
}

local KICKER = {
    MAX_RETRIES  = 5,
    RETRY_DELAY  = 1.0,
    KICK_SERVER  = 2722806748,
    KICK_HOST    = 369865739,
}

local function isPlayerFriend(playerId)
    local player = Players.GetById(playerId)
    if player and player.PlayerInfo then
        return player.PlayerInfo.FriendStatus >= 2
    end
    return false
end

local GPBD_FM_3_BASE = IS_ENHANCED and 1893070 or 1892925
local GPBD_FM_3_SIZE = 615

local function getOrgBoss(playerId)
    local idx = GPBD_FM_3_BASE + 1 + playerId * GPBD_FM_3_SIZE + 10
    return ScriptGlobal.GetInt(idx) or -1
end

local function isPlayerTeammate(playerId)
    local result = (function()
        local localId = GTA.GetLocalPlayerId()
        local localBoss = getOrgBoss(localId)
        local theirBoss = getOrgBoss(playerId)
        if localBoss >= 0 and localBoss <= 31 and localBoss == theirBoss then return true end
        local localTeam = PLAYER.GET_PLAYER_TEAM(localId)
        local theirTeam = PLAYER.GET_PLAYER_TEAM(playerId)
        if localTeam ~= -1 and localTeam ~= 0 and localTeam == theirTeam then return true end
        return false
    end)()
    return result
end

local scriptUnloading = false

CENTRAL_TICK = { single = {}, player = {} }
do
    local _AddFeature = FeatureMgr.AddFeature
    FeatureMgr.AddFeature = function(...)
        CENTRAL_TICK._lastCb = (select(5, ...))
        return _AddFeature(...)
    end
end
function centralOnTick(feat)
    if feat then
        CENTRAL_TICK.single[#CENTRAL_TICK.single + 1] = { feat = feat, fn = CENTRAL_TICK._lastCb }
    end
    return feat
end
function centralPlayerOnTick(hash, fn)
    CENTRAL_TICK.player[#CENTRAL_TICK.player + 1] = { hash = hash, fn = fn }
end
function CENTRAL_TICK.run()
    if scriptUnloading then return end
    local single = CENTRAL_TICK.single
    for i = 1, #single do
        local t = single[i]
        local ok, err = pcall(t.fn, t.feat)
        if not ok and not t.warned then
            t.warned = true
            Logger.LogInfo("[VibeScript] central OnTick error: " .. tostring(err))
        end
    end
    local player = CENTRAL_TICK.player
    local np = #player
    if np > 0 then
        for pid = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                for j = 1, np do
                    local p = player[j]
                    local ok, err = pcall(p.fn, FeatureMgr.GetFeature(p.hash, pid))
                    if not ok and not p.warned then
                        p.warned = true
                        Logger.LogInfo("[VibeScript] central player OnTick error: " .. tostring(err))
                    end
                end
            end
        end
    end
end
function CENTRAL_TICK.driver()
    if scriptUnloading then return end
    local ok, err = pcall(CENTRAL_TICK.run)
    if not ok and not CENTRAL_TICK.driverWarned then
        CENTRAL_TICK.driverWarned = true
        pcall(Logger.LogInfo, "[VibeScript] central driver error: " .. tostring(err))
    end
end
FeatureMgr.AddFeature(Utils.Joaat("LUA_CentralTickDriver"), "##CentralTickDriver",
    eFeatureType.Toggle, "", CENTRAL_TICK.driver)
    :RegisterCallbackTrigger(eCallbackTrigger.OnTick)
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
    :SetSearchable(false)
    :SetVisible(false)
FeatureMgr.GetFeature(Utils.Joaat("LUA_CentralTickDriver")):Toggle(true)

local pendingKicks = {}

local function doKick(playerId)
    pendingKicks[#pendingKicks + 1] = playerId
end

Script.RegisterLooped(function()
    if scriptUnloading or #pendingKicks == 0 then
        Script.Yield(100)
        return
    end
    local pid = table.remove(pendingKicks, 1)
    pcall(function()
        if NETWORK.NETWORK_IS_HOST() then
            FeatureMgr.TriggerFeatureCallback(KICKER.KICK_HOST, pid)
        else
            FeatureMgr.TriggerFeatureCallback(KICKER.KICK_SERVER, pid)
        end
    end)
    Script.Yield()
end)

local frenchKicker  = { kicked = {}, pending = {}, eventId = nil, scanned = false }
local chineseKicker = { kicked = {}, pending = {}, eventId = nil, scanned = false }
local myCountryOnly = { kicked = {}, pending = {}, eventId = nil, scanned = false, localCC = nil }
local vpnKicker     = { kicked = {}, pending = {}, eventId = nil, scanned = false }
local relayKicker   = { kicked = {}, pending = {}, eventId = nil, scanned = false }

Script.RegisterLooped(function()
    Script.Yield(60000)
    if scriptUnloading then return end
    local kickers = {
        { H.FRENCH_KICKER,  frenchKicker  },
        { H.CHINESE_KICKER, chineseKicker },
        { H.MY_COUNTRY_ONLY,myCountryOnly },
        { H.VPN_KICKER,     vpnKicker     },
        { H.RELAY_KICKER,   relayKicker   },
    }
    for _, k in ipairs(kickers) do
        local feat = FeatureMgr.GetFeature(k[1])
        if feat and feat:IsToggled() then
            k[2].scanned = false
        end
    end
end)

do
    local SMS_MAX_LEN    = 60
    local SMS_SEND_DELAY = 200
    local handleBuf      = Memory.Alloc(104)
    local profTokenBuf   = Memory.Alloc(8)
    local sendQueue      = {}

    local function setStatusFeature(job, msg)
        local f = job.broadcast and FeatureMgr.GetFeature(H.SMS_BCAST_STATUS)
                               or FeatureMgr.GetFeature(H.SMS_STATUS, job.target)
        if f then f:SetStringValue(msg) end
    end

    local function keepAfterSend()
        local f = FeatureMgr.GetFeature(H.SMS_KEEP_TEXT)
        return f ~= nil and f:IsToggled() == true
    end

    local function localPid()
        local pid = GTA.GetLocalPlayerId()
        return type(pid) == "number" and pid or -1
    end

    local function playerName(pid)
        local name = PLAYER.GET_PLAYER_NAME(pid)
        if type(name) == "string" and name ~= "" then return name end
        return "Player" .. tostring(pid)
    end

    local function sendToPlayer(text, targetPid)
        if type(targetPid) ~= "number" or targetPid < 0 or targetPid == localPid() then
            return false
        end
        Natives.InvokeVoid(0x388EB2B86C73B6B3, targetPid, handleBuf, 13)
        Natives.InvokeBool(0x3A214F2EC889B100, tostring(text):sub(1, SMS_MAX_LEN), handleBuf)
        return true
    end

    local function textIsClean(text)
        local token, started
        do
            Memory.WriteInt(profTokenBuf, 0)
            started = Natives.InvokeBool(0x75632C5ECD7ED843, tostring(text), profTokenBuf)
            token   = Memory.ReadInt(profTokenBuf)
        end
        if not started or not token or token == 0 then return true end

        local deadline = os.clock() + 5
        while os.clock() < deadline do
            local pending = Natives.InvokeBool(0x82E4A58BABC15AE7, token)
            if not pending then break end
            Script.Yield(50)
        end

        local valid = Natives.InvokeBool(0x1753344C770358AE, token)
        if not valid then return true end

        local passed = Natives.InvokeBool(0x85535ACF97FC0969, token)
        return passed == true
    end

    Script.RegisterLooped(function()
        if scriptUnloading or #sendQueue == 0 then
            Script.Yield(100)
            return
        end
        local job = table.remove(sendQueue, 1)
        local jobOk, jobErr = pcall(function()
            local clean = textIsClean(job.text)

            if not clean then
                setStatusFeature(job, "[GTA Restriction] Blocked - message contains profanity")
                GUI.AddToast("VibeScript SMS",
                    "[GTA Restriction] Not sent - message contains profanity", 4000)
                return
            end

            if job.broadcast then
                local me   = localPid()
                local sent = 0
                for pid = 0, 31 do
                    if pid ~= me then
                        local connected = NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid)
                        if connected then
                            if sendToPlayer(job.text, pid) then sent = sent + 1 end
                            Script.Yield(SMS_SEND_DELAY)
                        end
                    end
                end
                setStatusFeature(job, "")
                if not keepAfterSend() then
                    local box = FeatureMgr.GetFeature(H.SMS_BCAST_MSG)
                    if box then box:SetStringValue("") end
                end
                GUI.AddToast("VibeScript SMS",
                    string.format("Broadcast sent to %d player(s)", sent), 4000)
            else
                sendToPlayer(job.text, job.target)
                setStatusFeature(job, "")
                if not keepAfterSend() then
                    local box = FeatureMgr.GetFeature(H.SMS_MSG, job.target)
                    if box then box:SetStringValue("") end
                end
                GUI.AddToast("VibeScript SMS", "Sent to " .. playerName(job.target), 3000)
            end
        end)
        if not jobOk then
            Logger.LogInfo("[VibeScript] SMS send error: " .. tostring(jobErr))
        end
        Script.Yield()
    end)

    local smsMsgFeatures = FeatureMgr.AddPlayerFeature(H.SMS_MSG, "Send SMS",
        eFeatureType.InputText,
        "Type a text message to send to this player as an in-game SMS (max 60 chars).")
    for _, hash in ipairs(smsMsgFeatures) do
        FeatureMgr.GetFeature(hash):SetStringValue(""):SetSaveable(false)
            :SetSearchable(false):SetMaxValue(255)
    end

    local smsSendFeatures = FeatureMgr.AddPlayerFeature(H.SMS_SEND, "Send",
        eFeatureType.Button,
        "Send the message typed above to this player.",
        function(f)
            local target = f:GetPlayerIndex()
            local body = FeatureMgr.GetFeatureString(H.SMS_MSG, target)
            if not body or body == "" then
                GUI.AddToast("VibeScript SMS", "Type a message first.", 3000)
                return
            end
            if #body > SMS_MAX_LEN then
                GUI.AddToast("VibeScript SMS", "Message too long (max 60).", 3000)
                return
            end
            if target == localPid() then
                GUI.AddToast("VibeScript SMS", "Can't SMS yourself.", 3000)
                return
            end
            sendQueue[#sendQueue + 1] = { text = body, target = target }
            telemetryCountAction("SmsSend")
            GUI.AddToast("VibeScript SMS", "Sending SMS to player " .. tostring(target) .. "...", 2000)
        end)
    for _, hash in ipairs(smsSendFeatures) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    local smsStatusFeatures = FeatureMgr.AddPlayerFeature(H.SMS_STATUS, "SMS Status",
        eFeatureType.InputText, "")
    for _, hash in ipairs(smsStatusFeatures) do
        FeatureMgr.GetFeature(hash):SetStringValue(""):SetSaveable(false)
            :SetSearchable(false):SetMaxValue(255)
    end

    FeatureMgr.AddFeature(H.SMS_BCAST_MSG, "Broadcast SMS",
        eFeatureType.InputText,
        "Type a text message to send to everyone in the session as an in-game SMS (max 60 chars).")
        :SetStringValue("")
        :SetSaveable(false)
        :SetSearchable(false)
        :SetMaxValue(255)

    FeatureMgr.AddFeature(H.SMS_BCAST, "Broadcast To Lobby",
        eFeatureType.Button,
        "Send the message typed above to every player in the current session.",
        function(f)
            local body = FeatureMgr.GetFeatureString(H.SMS_BCAST_MSG)
            if not body or body == "" then
                GUI.AddToast("VibeScript SMS", "Type a message first.", 3000)
                return
            end
            if #body > SMS_MAX_LEN then
                GUI.AddToast("VibeScript SMS", "Message too long (max 60).", 3000)
                return
            end
            sendQueue[#sendQueue + 1] = { text = body, broadcast = true }
            telemetryCountAction("SmsBroadcast")
            GUI.AddToast("VibeScript SMS", "Broadcasting to lobby...", 2000)
        end)

    FeatureMgr.AddFeature(H.SMS_BCAST_STATUS, "Broadcast Status",
        eFeatureType.InputText, "")
        :SetStringValue("")
        :SetSaveable(false)
        :SetSearchable(false)
        :SetMaxValue(255)

    FeatureMgr.AddFeature(H.SMS_KEEP_TEXT, "Keep Message",
        eFeatureType.Toggle,
        "Persist the message after sending.")
end

local FRENCH_BLOCKLIST = {
    {name = "Quebec (Canada)"},
    {name = "France",           code = "FR"},
    {name = "Belgium",          code = "BE"},
    {name = "Switzerland",      code = "CH"},
    {name = "Luxembourg",       code = "LU"},
    {name = "Monaco",           code = "MC"},
    {name = "Haiti",            code = "HT"},
    {name = "Senegal",          code = "SN"},
    {name = "Ivory Coast",      code = "CI"},
    {name = "DR Congo",         code = "CD"},
    {name = "Republic of Congo", code = "CG"},
    {name = "Cameroon",         code = "CM"},
    {name = "Madagascar",       code = "MG"},
    {name = "Mali",             code = "ML"},
    {name = "Burkina Faso",     code = "BF"},
    {name = "Niger",            code = "NE"},
    {name = "Guinea",           code = "GN"},
    {name = "Chad",             code = "TD"},
    {name = "Rwanda",           code = "RW"},
    {name = "Burundi",          code = "BI"},
    {name = "Benin",            code = "BJ"},
    {name = "Togo",             code = "TG"},
    {name = "Central African Republic", code = "CF"},
    {name = "Gabon",            code = "GA"},
    {name = "Comoros",          code = "KM"},
    {name = "Djibouti",         code = "DJ"},
    {name = "Seychelles",       code = "SC"},
    {name = "Equatorial Guinea", code = "GQ"},
    {name = "Vanuatu",          code = "VU"},
}
local FRENCH_LIST_NAMES = {}
local FRENCH_CODE_TO_INDEX = {}
for i, entry in ipairs(FRENCH_BLOCKLIST) do
    FRENCH_LIST_NAMES[i] = entry.name
    if entry.code then
        FRENCH_CODE_TO_INDEX[entry.code] = i - 1
    end
end
local EXP_TAG = {
    ROCKET           = 4,
    TANKSHELL        = 5,
    PLANE_ROCKET     = 32,
    VEHICLE_BULLET   = 33,
    VALKYRIE_CANNON  = 41,
    APCSHELL         = 46,
    BOMBUSHKA_CANNON = 53,
    HUNTER_BARRAGE   = 55,
    HUNTER_CANNON    = 56,
    ROGUE_CANNON     = 57,
    OPPRESSOR2_CANNON = 62,
}

local WEAPON_EXPLOSION_MAP = {
    [Utils.Joaat("VEHICLE_WEAPON_TANK")]                  = EXP_TAG.TANKSHELL,
    [Utils.Joaat("VEHICLE_WEAPON_KHANJALI_CANNON")]       = EXP_TAG.TANKSHELL,
    [Utils.Joaat("VEHICLE_WEAPON_KHANJALI_CANNON_HEAVY")] = EXP_TAG.TANKSHELL,
    [Utils.Joaat("VEHICLE_WEAPON_APC_CANNON")]            = EXP_TAG.APCSHELL,
    [Utils.Joaat("VEHICLE_WEAPON_PLAYER_LAZER")]          = EXP_TAG.PLANE_ROCKET,
    [Utils.Joaat("VEHICLE_WEAPON_PLAYER_SAVAGE")]         = EXP_TAG.HUNTER_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_HUNTER_CANNON")]         = EXP_TAG.HUNTER_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_ROGUE_CANNON")]          = EXP_TAG.ROGUE_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_BOMBUSHKA_CANNON")]      = EXP_TAG.BOMBUSHKA_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_B11_CANNON")]            = EXP_TAG.PLANE_ROCKET,
    [Utils.Joaat("VEHICLE_WEAPON_NOSE_TURRET_VALKYRIE")]  = EXP_TAG.VALKYRIE_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_OPPRESSOR2_CANNON")]     = EXP_TAG.OPPRESSOR2_CANNON,
    [Utils.Joaat("VEHICLE_WEAPON_AKULA_BARRAGE")]         = EXP_TAG.HUNTER_BARRAGE,
    [Utils.Joaat("VEHICLE_WEAPON_HUNTER_BARRAGE")]        = EXP_TAG.HUNTER_BARRAGE,
    [Utils.Joaat("VEHICLE_WEAPON_PLAYER_BULLET")]         = EXP_TAG.VEHICLE_BULLET,
    [Utils.Joaat("VEHICLE_WEAPON_RUINER_BULLET")]         = EXP_TAG.VEHICLE_BULLET,
}

local TURRET_WEAPONS = {
    [Utils.Joaat("VEHICLE_WEAPON_TANK")]                  = true,
    [Utils.Joaat("VEHICLE_WEAPON_KHANJALI_CANNON")]       = true,
    [Utils.Joaat("VEHICLE_WEAPON_KHANJALI_CANNON_HEAVY")] = true,
    [Utils.Joaat("VEHICLE_WEAPON_APC_CANNON")]            = true,
    [Utils.Joaat("VEHICLE_WEAPON_APC_MISSILE")]           = true,
    [Utils.Joaat("VEHICLE_WEAPON_NOSE_TURRET_VALKYRIE")]  = true,
    [Utils.Joaat("VEHICLE_WEAPON_PLAYER_SAVAGE")]         = true,
    [Utils.Joaat("VEHICLE_WEAPON_HUNTER_CANNON")]         = true,
    [Utils.Joaat("VEHICLE_WEAPON_CHERNO_MISSILE")]        = true,
    [Utils.Joaat("VEHICLE_WEAPON_TRAILER_QUAD_MG")]       = true,
    [Utils.Joaat("VEHICLE_WEAPON_TRAILER_MISSILE")]       = true,
    [Utils.Joaat("VEHICLE_WEAPON_HALFTRACK_QUAD_MG")]     = true,
    [Utils.Joaat("VEHICLE_WEAPON_INSURGENT_MINIGUN")]     = true,
    [Utils.Joaat("VEHICLE_WEAPON_TECHNICAL_MINIGUN")]     = true,
    [Utils.Joaat("VEHICLE_WEAPON_DUNE_MG")]               = true,
    [Utils.Joaat("VEHICLE_WEAPON_MULE_GUN")]              = true,
    [Utils.Joaat("VEHICLE_WEAPON_TAMPA_MISSILE")]         = true,
}

local ROCKET_TYPE_WEAPONS = {}
for weaponHash, expTag in pairs(WEAPON_EXPLOSION_MAP) do
    if expTag ~= EXP_TAG.VEHICLE_BULLET then
        ROCKET_TYPE_WEAPONS[weaponHash] = true
    end
end
for _, name in ipairs({
    "VEHICLE_WEAPON_DELUXO_MISSILE",
    "VEHICLE_WEAPON_OPPRESSOR_MISSILE",
    "VEHICLE_WEAPON_OPPRESSOR2_MISSILE",
    "VEHICLE_WEAPON_SPACE_ROCKET",
    "VEHICLE_WEAPON_PLANE_ROCKET",
    "VEHICLE_WEAPON_RUINER_ROCKET",
    "VEHICLE_WEAPON_HUNTER_MISSILE",
    "VEHICLE_WEAPON_AKULA_MISSILE",
    "VEHICLE_WEAPON_SAVAGE_MISSILE",
    "VEHICLE_WEAPON_PLAYER_BUZZARD",
    "VEHICLE_WEAPON_AVENGER_MISSILE",
    "VEHICLE_WEAPON_BOMBUSHKA_MISSILE",
    "VEHICLE_WEAPON_APC_MISSILE",
    "VEHICLE_WEAPON_TAMPA_MISSILE",
    "VEHICLE_WEAPON_CHERNO_MISSILE",
    "VEHICLE_WEAPON_TRAILER_MISSILE",
    "VEHICLE_WEAPON_THRUSTER_MISSILE",
    "VEHICLE_WEAPON_VIGILANTE_MISSILE",
    "VEHICLE_WEAPON_ROGUE_MISSILE",
    "VEHICLE_WEAPON_SEABREEZE_MISSILE",
}) do
    ROCKET_TYPE_WEAPONS[Utils.Joaat(name)] = true
end

local grav = {
    target      = 0,
    yeeted      = 0,
    distance    = 10.0,
    spinAngle   = 0.0,
    forceMult   = 1,
    spinning    = false,
    buf         = Memory.Alloc(8),
    rayBuf      = Memory.Alloc(64),
    HITSCAN_RANGE = 10000.0,
    VK_E        = 0x45,
    VK_RBUTTON  = 0x02,
    VK_LBUTTON  = 0x01,
}

local logging = {
    enabled    = VIBESCRIPT_LOADER == true,
    toasts     = VIBESCRIPT_LOADER == true,
    buffer     = {},
    MAX_LINES  = 200,
    logDirty   = true,
}

local function trimLogBuffer()
    local n = #logging.buffer
    if n <= logging.MAX_LINES then return end
    local keep = {}
    for i = n - logging.MAX_LINES + 1, n do keep[#keep + 1] = logging.buffer[i] end
    logging.buffer = keep
    logging.logDirty = true
end

local function log(msg)
    if not logging.enabled then return end
    local text = tostring(msg)
    Logger.LogInfo(("[VibeScript] %s"):format(text))
    table.insert(logging.buffer, "[INFO] " .. text)
    logging.logDirty = true
    trimLogBuffer()
end

local function logf(fmt, ...)
    if not logging.enabled then return end
    local text = fmt:format(...)
    Logger.LogInfo(("[VibeScript] %s"):format(text))
    table.insert(logging.buffer, "[INFO] " .. text)
    logging.logDirty = true
    trimLogBuffer()
end

local function logErr(msg)
    local text = tostring(msg)
    Logger.LogError(("[VibeScript] %s"):format(text))
    table.insert(logging.buffer, "[ERROR] " .. text)
    logging.logDirty = true
    trimLogBuffer()
    GUI.AddToast("VibeScript", text, 5000, eToastPos.TOP_RIGHT)
end

local function debugToast(text, duration)
    if not logging.toasts then return end
    GUI.AddToast("VibeScript", text, duration or 5000)
end

scanDoctor = { entries = {}, ran = false, tries = 0, MAX_TRIES = 300,
               PARTIAL_TRIES = 120 }

function scanDoctor.register(code, spec)
    spec.name = code
    scanDoctor.entries[#scanDoctor.entries + 1] = spec
end

function scanDoctor.scanOk(pat)
    if type(pat) ~= "string" or pat == "" then return false end
    local hit = Memory.Scan(pat)
    return type(hit) == "number" and hit ~= 0
end

function scanDoctor.fieldSig(tbl, key, legField, enhField)
    return function()
        local t = tbl and tbl[key]
        if not t then return nil end
        if IS_ENHANCED then return t[enhField] end
        return t[legField]
    end
end

function scanDoctor.litSig(legPat, enhPat)
    return function() if IS_ENHANCED then return enhPat else return legPat end end
end

function scanDoctor.nowMs()
    local t = Time.GetEpocheMs()
    return type(t) == "number" and t or 0
end

function scanDoctor.evalEntry(e)
    if e.probe then
        local ok, res = pcall(e.probe)
        if not ok then return "fail" end
        if res == nil then return "na" end
        return res and "ok" or "fail"
    end
    local pat = e.sig
    if type(pat) == "function" then
        local ok, s = pcall(pat)
        pat = ok and s or nil
    end
    if pat == nil then return "na" end
    return scanDoctor.scanOk(pat) and "ok" or "fail"
end

function scanDoctor.scanAll()
    local pass, fail = 0, 0
    local failedCodes = {}
    for _, e in ipairs(scanDoctor.entries) do
        local st = scanDoctor.evalEntry(e)
        if st == "ok" then pass = pass + 1
        elseif st == "fail" then fail = fail + 1; failedCodes[#failedCodes + 1] = e.name end
    end
    return pass, fail, failedCodes
end

function scanDoctor.report(pass, fail, failedCodes, elapsedMs)
    local ran = pass + fail
    if fail > 0 then
        local codes = table.concat(failedCodes, ", ")
        Logger.LogInfo(("[VibeScript] Scanned %d patterns in %dms - failed: %s")
            :format(ran, elapsedMs or 0, codes))
        GUI.AddToast("VibeScript",
            ("Game update broke %d scan(s): %s. Affected features may not work.")
                :format(fail, codes), 10000)
    else
        Logger.LogInfo(("[VibeScript] Scanned %d patterns in %dms")
            :format(ran, elapsedMs or 0))
    end
end

function scanDoctor.gate()
    if scanDoctor.ran then return true end
    if #scanDoctor.entries == 0 then scanDoctor.ran = true; return true end
    scanDoctor.tries = scanDoctor.tries + 1
    local t0 = scanDoctor.nowMs()
    local pass, fail, failedCodes = scanDoctor.scanAll()
    if fail > 0 then
        if pass == 0 and scanDoctor.tries < scanDoctor.MAX_TRIES then
            return false
        end
        if pass > 0 and scanDoctor.tries < scanDoctor.PARTIAL_TRIES then
            return false
        end
    end
    scanDoctor.ran = true
    scanDoctor.report(pass, fail, failedCodes, scanDoctor.nowMs() - t0)
    return true
end


local function readPtr(addr)
    if not addr or addr <= 0 or addr >= 0x800000000000 then return nil end
    local val = Memory.ReadLong(addr)
    if val <= 0 or val >= 0x800000000000 then return nil end
    return val
end

local function getWeaponManagerAddr()
    local ped = GTA.GetLocalPed()
    if not ped then return nil end
    local pedAddr = ped:GetAddress()
    return readPtr(pedAddr + OFF.PED_WEAPON_MGR)
end

local function getVehicleWeaponInfoAddr()
    local weaponMgr = getWeaponManagerAddr()
    if not weaponMgr then return nil, false end

    local info = readPtr(weaponMgr + OFF.EQUIPPED_WEAPON + OFF.VEH_WEAPON_INFO)
    if info then return info, true end

    return readPtr(weaponMgr + 0x20), false
end

local vehWeaponSyncCooldown = 0
local function forceSyncVehicleWeaponInfoIfStale(ped, weaponInfoAddr)
    if vehWeaponSyncCooldown > 0 then
        vehWeaponSyncCooldown = vehWeaponSyncCooldown - 1
        return false
    end
    if not weaponInfoAddr then return false end
    local infoHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
    if infoHash == 0 then return false end
    Memory.WriteInt(vwSyncHashBuf, 0)
    if not WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(ped, vwSyncHashBuf) then return false end
    local currentHash = Memory.ReadUInt(vwSyncHashBuf)
    if currentHash == 0 or currentHash == infoHash then return false end
    WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, currentHash)
    vehWeaponSyncCooldown = 5
    return true
end

local restoreAndClearAllWeaponCache

local function weaponVehicleChanged(veh)
    if veh == weaponState.lastVehicle then
        weaponState.vehTick = weaponState.vehTick + 1
        return weaponState.vehTick <= weaponState.VEH_INIT_DELAY
    end
    weaponState.lastVehicle = veh
    weaponState.vehTick = 0
    weaponState.rapidFireVehTick = 0
    weaponState.rapidFireResolved = false
    return true
end

local function getExplosionTagForCurrentWeapon()
    local weaponInfoAddr = getVehicleWeaponInfoAddr()
    if not weaponInfoAddr then return EXP_TAG.ROCKET end
    local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
    return WEAPON_EXPLOSION_MAP[nameHash] or EXP_TAG.ROCKET
end

local function rotationToDirection(rotation)
    local pitch = math.rad(rotation.x)
    local yaw = math.rad(rotation.z)

    return {
        x = -math.sin(yaw) * math.cos(pitch),
        y = math.cos(yaw) * math.cos(pitch),
        z = math.sin(pitch)
    }
end

local function directionBetween(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len < 0.001 then return {x=0, y=0, z=0}, 0 end
    return {x = dx/len, y = dy/len, z = dz/len}, len
end

local function releaseGravTarget()
    if grav.target ~= 0 and ENTITY.DOES_ENTITY_EXIST(grav.target) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(grav.target)
        ENTITY.SET_ENTITY_COLLISION(grav.target, true, false)
        ENTITY.SET_ENTITY_HAS_GRAVITY(grav.target, true)
    end
    grav.target = 0
    grav.spinning = false
    grav.spinAngle = 0.0
end

local function isPlayerReady()
    local playerId = GTA.GetLocalPlayerId()
    if not PLAYER.IS_PLAYER_PLAYING(playerId) then return false end
    if CUTSCENE.IS_CUTSCENE_PLAYING() then return false end
    if STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS() then return false end
    return true
end


local TIMING_OFFSETS = {
    OFF.RELOAD_TIME_MP,
    OFF.RELOAD_TIME_SP,
    OFF.VEH_RELOAD_TIME,
    OFF.ANIM_RELOAD_RATE,
    OFF.TIME_BETWEEN_SHOTS,
    OFF.TIME_LEFT_CACHED,
    OFF.SPIN_UP_TIME,
    OFF.SPIN_TIME,
    OFF.SPIN_DOWN_TIME,
    OFF.ALT_WAIT_TIME,
}

local TIMING_MULTIPLIER = 0.085

local function applyRapidFireTimings(weaponInfoAddr, nameHash)
    if not weaponState.originalVehTimings[nameHash] then
        local originals = {}
        for i, off in ipairs(TIMING_OFFSETS) do
            originals[i] = Memory.ReadFloat(weaponInfoAddr + off)
        end
        weaponState.originalVehTimings[nameHash] = { addr = weaponInfoAddr, values = originals }
    end

    local data = weaponState.originalVehTimings[nameHash]
    for i, off in ipairs(TIMING_OFFSETS) do
        Memory.WriteFloat(weaponInfoAddr + off, data.values[i] * TIMING_MULTIPLIER)
    end
end

local function restoreAllTimings()
    for _, data in pairs(weaponState.originalVehTimings) do
        for i, off in ipairs(TIMING_OFFSETS) do
            Memory.WriteFloat(data.addr + off, data.values[i])
        end
    end
    weaponState.originalVehTimings = {}
end


local function rapidFireOnTick(f)
    if not f:IsToggled() then
        restoreAllTimings()
        titanCannonTune.restoreRate()
        weaponState.savedOnFootWeapon = nil
        weaponState.lastRapidFireVeh = 0
        weaponState.rapidFireVehTick = 0
        weaponState.rapidFireResolved = false
        return
    end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end
    if not isPlayerReady() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        weaponState.savedOnFootWeapon = WEAPON.GET_SELECTED_PED_WEAPON(ped)
        weaponState.lastRapidFireVeh = 0
        restoreAndClearAllWeaponCache()
        titanCannonTune.restoreRate()
        weaponState.lastVehicle = 0
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then
        weaponState.lastRapidFireVeh = 0
        restoreAndClearAllWeaponCache()
        titanCannonTune.restoreRate()
        weaponState.lastVehicle = 0
        return
    end

    if not VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then
        restoreAndClearAllWeaponCache()
        titanCannonTune.restoreRate()
        return
    end

    if ENTITY.GET_ENTITY_MODEL(veh) == titanCannonTune.MODEL then
        titanCannonTune.applyRate()
        local infos = titanCannonTune.cannonInfos(veh)
        if not titanCannonTune.rateLogged and #infos > 0 then
            titanCannonTune.rateLogged = true
            for _, c in ipairs(infos) do
                log(("[TitanRate] 0x%08X TBS=%s reloadSP=%s reloadMP=%s vehReload=%s spinUp=%s"):format(
                    Memory.ReadUInt(c.cwi + OFF.WEAPON_NAME_HASH),
                    tostring(Memory.ReadFloat(c.cwi + OFF.TIME_BETWEEN_SHOTS)),
                    tostring(Memory.ReadFloat(c.cwi + OFF.RELOAD_TIME_SP)),
                    tostring(Memory.ReadFloat(c.cwi + OFF.RELOAD_TIME_MP)),
                    tostring(Memory.ReadFloat(c.cwi + OFF.VEH_RELOAD_TIME)),
                    tostring(Memory.ReadFloat(c.cwi + OFF.SPIN_UP_TIME))))
            end
        end
        for _, c in ipairs(infos) do
            local nameHash = Memory.ReadUInt(c.cwi + OFF.WEAPON_NAME_HASH)
            if nameHash ~= 0 then applyRapidFireTimings(c.cwi, nameHash) end
        end
        return
    end
    titanCannonTune.restoreRate()

    weaponVehicleChanged(veh)

    if veh ~= weaponState.lastRapidFireVeh then
        weaponState.lastRapidFireVeh = veh
        weaponState.rapidFireVehTick = 0
        weaponState.rapidFireResolved = false
    end
    weaponState.rapidFireVehTick = weaponState.rapidFireVehTick + 1

    if weaponState.rapidFireVehTick <= 30 then
    else
        if not weaponState.rapidFireResolved then
            if weaponState.rapidFireVehTick == 31 or (weaponState.rapidFireVehTick > 31 and weaponState.rapidFireVehTick % 60 == 0) then
                WEAPON.SET_CURRENT_PED_WEAPON(ped, weaponState.UNARMED_HASH, true)
            end
        end

        local weaponInfoAddr, trusted = getVehicleWeaponInfoAddr()
        if weaponInfoAddr then
            if forceSyncVehicleWeaponInfoIfStale(ped, weaponInfoAddr) then
                weaponState.rapidFireResolved = false
                return
            end
            local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
            if nameHash ~= 0 then
                if trusted then
                    weaponState.rapidFireResolved = true
                    applyRapidFireTimings(weaponInfoAddr, nameHash)
                    return
                end
                if nameHash ~= weaponState.UNARMED_HASH
                   and (not weaponState.savedOnFootWeapon or nameHash ~= weaponState.savedOnFootWeapon) then
                    weaponState.rapidFireResolved = true
                    applyRapidFireTimings(weaponInfoAddr, nameHash)
                    return
                end
            end
        end
    end

end


local vehInfiniteAmmoOnTick
do
    local WEAPON_SLOT_MAX = 6
    local BOMB_INFINITE = 20
    local CM_INFINITE = 20
    local state = { orig = {}, bombOrig = {}, cmOrig = {} }

    local function vehInfAmmoRestore()
        for veh, slots in pairs(state.orig) do
            if ENTITY.DOES_ENTITY_EXIST(veh) then
                for slot, cap in pairs(slots) do
                    VEHICLE.SET_VEHICLE_WEAPON_RESTRICTED_AMMO(veh, slot, cap)
                end
            end
        end
        for veh, cm in pairs(state.cmOrig) do
            if ENTITY.DOES_ENTITY_EXIST(veh) then
                VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO(veh, cm)
            end
        end
        for veh, bombs in pairs(state.bombOrig) do
            if ENTITY.DOES_ENTITY_EXIST(veh) then
                VEHICLE.SET_VEHICLE_BOMB_AMMO(veh, bombs)
            end
        end
        state.orig = {}
        state.bombOrig = {}
        state.cmOrig = {}
    end
    weaponState.restoreVehInfAmmo = vehInfAmmoRestore

    function vehInfiniteAmmoOnTick(f)
        if not f:IsToggled() then
            vehInfAmmoRestore()
            return
        end
        if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end
        if not isPlayerReady() then return end

        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end

        local cls = VEHICLE.GET_VEHICLE_CLASS(veh)
        if cls == 16 then
            local bombs = VEHICLE.GET_VEHICLE_BOMB_AMMO(veh)
            if state.bombOrig[veh] == nil then state.bombOrig[veh] = bombs end
            VEHICLE.SET_VEHICLE_BOMB_AMMO(veh, BOMB_INFINITE)
        end

        if not VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then return end

        local ovw = state.orig[veh]
        for i = 0, WEAPON_SLOT_MAX do
            local cap = VEHICLE.GET_VEHICLE_WEAPON_RESTRICTED_AMMO(veh, i)
            if cap >= 0 then
                if not ovw then ovw = {}; state.orig[veh] = ovw end
                if ovw[i] == nil then ovw[i] = cap end
                VEHICLE.SET_VEHICLE_WEAPON_RESTRICTED_AMMO(veh, i, -1)
            end
        end

        if cls == 8 or cls == 15 or cls == 16 or cls == 19 then
            local cm = VEHICLE.GET_VEHICLE_COUNTERMEASURE_AMMO(veh)
            if cm >= 0 then
                if state.cmOrig[veh] == nil then state.cmOrig[veh] = cm end
                if cm < CM_INFINITE then
                    VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO(veh, CM_INFINITE)
                end
            end
        end
    end
end



local function applyRocketSpeed(weaponInfoAddr, multiplier)
    local ammoInfoAddr = readPtr(weaponInfoAddr + OFF.AMMO_INFO)
    if not ammoInfoAddr then return end

    local weaponNameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)

    if not weaponState.originalLaunchSpeed[weaponNameHash] then
        local speed = Memory.ReadFloat(ammoInfoAddr + OFF.LAUNCH_SPEED)
        if speed ~= speed or speed <= 0.0 then return end
        weaponState.originalLaunchSpeed[weaponNameHash] = { addr = ammoInfoAddr, speed = speed }
    end

    local data = weaponState.originalLaunchSpeed[weaponNameHash]
    Memory.WriteFloat(ammoInfoAddr + OFF.LAUNCH_SPEED, data.speed * multiplier)
end

local function restoreAllLaunchSpeeds()
    for _, data in pairs(weaponState.originalLaunchSpeed) do
        Memory.WriteFloat(data.addr + OFF.LAUNCH_SPEED, data.speed)
    end
    weaponState.originalLaunchSpeed = {}
end

local INSTANT_SPEED = 50000.0

local function rocketSpeedOnTick(f)
    local instantFeature = FeatureMgr.GetFeature(H.INSTANT_ROCKET)
    local instantOn = instantFeature and instantFeature:IsToggled()

    if not f:IsToggled() and not instantOn then
        restoreAllLaunchSpeeds()
        return
    end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end
    if not isPlayerReady() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end
    if weaponVehicleChanged(veh) then return end

    local weaponInfoAddr = getVehicleWeaponInfoAddr()
    if not weaponInfoAddr then return end

    if forceSyncVehicleWeaponInfoIfStale(ped, weaponInfoAddr) then return end

    if instantOn then
        applyRocketSpeed(weaponInfoAddr, INSTANT_SPEED)
    else
        applyRocketSpeed(weaponInfoAddr, weaponState.rocketSpeedMult)
    end
end


local function instantRocketOnTick(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end

    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end

    if not VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then return end

    local weaponInfoAddr, trusted = getVehicleWeaponInfoAddr()
    if not weaponInfoAddr or not trusted then return end
    local weaponHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
    if weaponHash == 0 or weaponHash == weaponState.UNARMED_HASH then return end

    if not ROCKET_TYPE_WEAPONS[weaponHash] then return end

    PAD.DISABLE_CONTROL_ACTION(0, INPUT.VEH_ATTACK, true)
    PAD.DISABLE_CONTROL_ACTION(0, INPUT.VEH_FLY_ATTACK, true)

    local firing = PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.VEH_ATTACK)
                or PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.VEH_FLY_ATTACK)
    if not firing then return end

    Memory.WriteInt(autoLockBuf, 0)
    local hasLockTarget = VEHICLE.GET_VEHICLE_LOCK_ON_TARGET(veh, autoLockBuf)
    if hasLockTarget then
        local lockEnt = Memory.ReadInt(autoLockBuf)
        if lockEnt ~= 0 and ENTITY.DOES_ENTITY_EXIST(lockEnt) then
            local tgtPos = ENTITY.GET_ENTITY_COORDS(lockEnt, true)
            local expTag = WEAPON_EXPLOSION_MAP[weaponHash] or EXP_TAG.ROCKET
            FIRE.ADD_OWNED_EXPLOSION(ped,
                tgtPos.x, tgtPos.y, tgtPos.z,
                expTag, 1.0, true, false, 0.0)
            return
        end
    end

    local originX, originY, originZ, dirX, dirY, dirZ

    if TURRET_WEAPONS[weaponHash] then
        local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
        local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
        local dir    = rotationToDirection(camRot)
        originX, originY, originZ = camPos.x, camPos.y, camPos.z
        dirX, dirY, dirZ = dir.x, dir.y, dir.z
    else
        local vehCoords = ENTITY.GET_ENTITY_COORDS(veh, true)
        local fwd       = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
        originX, originY, originZ = vehCoords.x, vehCoords.y, vehCoords.z
        dirX, dirY, dirZ = fwd.x, fwd.y, fwd.z
    end

    local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
        originX, originY, originZ,
        originX + dirX * grav.HITSCAN_RANGE,
        originY + dirY * grav.HITSCAN_RANGE,
        originZ + dirZ * grav.HITSCAN_RANGE,
        -1, veh, 7
    )

    SHAPETEST.GET_SHAPE_TEST_RESULT(handle,
        grav.rayBuf, grav.rayBuf + 8, grav.rayBuf + 32, grav.rayBuf + 56)

    if Memory.ReadByte(grav.rayBuf) ~= 0 then
        local expTag = WEAPON_EXPLOSION_MAP[weaponHash] or EXP_TAG.ROCKET
        FIRE.ADD_OWNED_EXPLOSION(ped,
            Memory.ReadFloat(grav.rayBuf + 8),
            Memory.ReadFloat(grav.rayBuf + 16),
            Memory.ReadFloat(grav.rayBuf + 24),
            expTag, 1.0, true, false, 0.0)
    end
end


local function isProjectileAmmo(ammoInfoAddr)
    local lt  = Memory.ReadFloat(ammoInfoAddr + OFF.LIFETIME)
    local vlt = Memory.ReadFloat(ammoInfoAddr + OFF.VEH_LIFETIME)
    local ls  = Memory.ReadFloat(ammoInfoAddr + OFF.LAUNCH_SPEED)
    local ltCache = weaponState.originalLifeTimes[ammoInfoAddr]
    if ltCache then
        lt  = ltCache.lifetime
        vlt = ltCache.vehLifetime
    end
    for _, d in pairs(weaponState.originalLaunchSpeed) do
        if d.addr == ammoInfoAddr then ls = d.speed; break end
    end
    if lt ~= lt or vlt ~= vlt or ls ~= ls then return false end
    if lt <= 0.0 or lt > 120.0 then return false end
    if vlt < 0.0 or vlt > 120.0 then return false end
    if ls <= 10.0 or ls > 10000.0 then return false end
    return true, lt, vlt
end

local IS_ROCKET_HASH = {}
for _, h in ipairs({
    "VEHICLE_WEAPON_DELUXO_MISSILE",
    "VEHICLE_WEAPON_OPPRESSOR_MISSILE",
    "VEHICLE_WEAPON_OPPRESSOR2_MISSILE",
    "VEHICLE_WEAPON_SPACE_ROCKET",
    "VEHICLE_WEAPON_PLANE_ROCKET",
    "VEHICLE_WEAPON_RUINER_ROCKET",
    "VEHICLE_WEAPON_HUNTER_MISSILE",
    "VEHICLE_WEAPON_AKULA_MISSILE",
    "VEHICLE_WEAPON_SAVAGE_MISSILE",
    "VEHICLE_WEAPON_PLAYER_BUZZARD",
    "VEHICLE_WEAPON_AVENGER_MISSILE",
    "VEHICLE_WEAPON_BOMBUSHKA_MISSILE",
    "VEHICLE_WEAPON_APC_MISSILE",
    "VEHICLE_WEAPON_TAMPA_MISSILE",
    "VEHICLE_WEAPON_CHERNO_MISSILE",
    "VEHICLE_WEAPON_TRAILER_MISSILE",
    "VEHICLE_WEAPON_THRUSTER_MISSILE",
    "VEHICLE_WEAPON_VIGILANTE_MISSILE",
    "VEHICLE_WEAPON_ROGUE_MISSILE",
    "VEHICLE_WEAPON_SEABREEZE_MISSILE",
}) do
    IS_ROCKET_HASH[Utils.Joaat(h)] = true
end

local function tryCacheRocketAmmo(weaponInfoAddr, weaponHash)
    local ammoInfoAddr = readPtr(weaponInfoAddr + OFF.AMMO_INFO)
    if not ammoInfoAddr then return nil end
    if weaponState.originalLifeTimes[ammoInfoAddr] then return ammoInfoAddr end
    local ok, lt, vlt = isProjectileAmmo(ammoInfoAddr)
    if not ok then return nil end

    local entry = { addr = ammoInfoAddr, lifetime = lt, vehLifetime = vlt }
    if weaponHash and IS_ROCKET_HASH[weaponHash] then
        local lockonOrig = Memory.ReadFloat(ammoInfoAddr + OFF.LIFETIME_LOCKON_MP)
        if lockonOrig == lockonOrig
           and ((lockonOrig == -1.0) or (lockonOrig > 0.0 and lockonOrig < 600.0)) then
            entry.lockonOverride = lockonOrig
        end
    end

    weaponState.originalLifeTimes[ammoInfoAddr] = entry
    return ammoInfoAddr
end

local function writeRangeMultiplier(data, multiplier)
    Memory.WriteFloat(data.addr + OFF.LIFETIME, data.lifetime * multiplier)
    if data.vehLifetime > 0.0 then
        Memory.WriteFloat(data.addr + OFF.VEH_LIFETIME, data.vehLifetime * multiplier)
    end
    if data.lockonOverride and data.lockonOverride > 0.0 then
        Memory.WriteFloat(data.addr + OFF.LIFETIME_LOCKON_MP, data.lockonOverride * multiplier)
    end
end

local function applyAllCachedRanges(multiplier)
    for _, data in pairs(weaponState.originalLifeTimes) do
        writeRangeMultiplier(data, multiplier)
    end
end

local function restoreAllLifeTimes()
    for _, data in pairs(weaponState.originalLifeTimes) do
        Memory.WriteFloat(data.addr + OFF.LIFETIME,    data.lifetime)
        Memory.WriteFloat(data.addr + OFF.VEH_LIFETIME, data.vehLifetime)
        if data.lockonOverride then
            Memory.WriteFloat(data.addr + OFF.LIFETIME_LOCKON_MP, data.lockonOverride)
        end
    end
    weaponState.originalLifeTimes = {}
end

local PROBE_ROCKET_HASHES = {
    Utils.Joaat("VEHICLE_WEAPON_OPPRESSOR_MISSILE"),
    Utils.Joaat("VEHICLE_WEAPON_OPPRESSOR2_MISSILE"),
    Utils.Joaat("VEHICLE_WEAPON_SPACE_ROCKET"),
}

local rrProbe = {
    state = "idle",
    targetIdx = 0,
    targetHash = 0,
    origHash = 0,
    framesLeft = 0,
    cooldown = 0,
    discovered = {},
}
local rrHashBuf = Memory.Alloc(4)


local function rrResetProbe()
    rrProbe.state = "idle"
    rrProbe.targetIdx = 0
    rrProbe.targetHash = 0
    rrProbe.origHash = 0
    rrProbe.framesLeft = 0
    rrProbe.cooldown = 5
    for hash, val in pairs(rrProbe.discovered) do
        if val == false then rrProbe.discovered[hash] = nil end
    end
end

local function rrClearDiscovered()
    rrProbe.discovered = {}
    rrResetProbe()
end

local function rocketRangeProbeTick(ped)
    if rrProbe.cooldown > 0 then
        rrProbe.cooldown = rrProbe.cooldown - 1
        return
    end

    if rrProbe.state == "idle" then
        local idx = rrProbe.targetIdx + 1
        while idx <= #PROBE_ROCKET_HASHES and rrProbe.discovered[PROBE_ROCKET_HASHES[idx]] do
            idx = idx + 1
        end
        if idx > #PROBE_ROCKET_HASHES then return end

        rrProbe.targetIdx = idx
        rrProbe.targetHash = PROBE_ROCKET_HASHES[idx]

        Memory.WriteInt(rrHashBuf, 0)
        if WEAPON.GET_CURRENT_PED_VEHICLE_WEAPON(ped, rrHashBuf) then
            rrProbe.origHash = Memory.ReadUInt(rrHashBuf)
        else
            rrProbe.origHash = 0
        end

        if WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, rrProbe.targetHash) then
            rrProbe.state = "switching"
            rrProbe.framesLeft = 30
        else
            rrProbe.discovered[rrProbe.targetHash] = false
            rrProbe.cooldown = 3
        end
        return
    end

    if rrProbe.state == "switching" then
        local info = getVehicleWeaponInfoAddr()
        if info then
            local hash = Memory.ReadUInt(info + OFF.WEAPON_NAME_HASH)
            if hash == rrProbe.targetHash then
                local ammo = tryCacheRocketAmmo(info, hash)
                if ammo then
                    rrProbe.discovered[rrProbe.targetHash] = ammo
                    logf("[RocketRange] discovered hash=0x%08X ammo=0x%X", rrProbe.targetHash, ammo)
                end
                if rrProbe.origHash ~= 0 and rrProbe.origHash ~= rrProbe.targetHash then
                    WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, rrProbe.origHash)
                end
                rrProbe.state = "idle"
                rrProbe.cooldown = 10
                return
            end
        end
        rrProbe.framesLeft = rrProbe.framesLeft - 1
        if rrProbe.framesLeft <= 0 then
            if rrProbe.origHash ~= 0 and rrProbe.origHash ~= rrProbe.targetHash then
                WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, rrProbe.origHash)
            end
            rrProbe.state = "idle"
            rrProbe.cooldown = 60
        end
    end
end

local function infiniteRangeOnTick(f)
    if not f:IsToggled() then
        restoreAllLifeTimes()
        rrClearDiscovered()
        return
    end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        weaponState.savedOnFootWeapon = WEAPON.GET_SELECTED_PED_WEAPON(ped)
        restoreAndClearAllWeaponCache()
        rrResetProbe()
        weaponState.lastVehicle = 0
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end

    if not VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then
        restoreAndClearAllWeaponCache()
        rrResetProbe()
        return
    end

    if weaponVehicleChanged(veh) then
        rrResetProbe()
        return
    end

    local weaponInfoAddr, trusted = getVehicleWeaponInfoAddr()
    if weaponInfoAddr then
        local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
        local skipped = false
        if not trusted then
            if nameHash == 0 or nameHash == weaponState.UNARMED_HASH then
                skipped = true
            else
                local onFoot = weaponState.savedOnFootWeapon or WEAPON.GET_SELECTED_PED_WEAPON(ped)
                if onFoot ~= 0 and nameHash == onFoot then skipped = true end
            end
        end
        if not skipped then tryCacheRocketAmmo(weaponInfoAddr, nameHash) end
    end

    rocketRangeProbeTick(ped)

    applyAllCachedRanges(weaponState.rangeMult)
end


local function applyInstantLockon(weaponInfoAddr, nameHash)
    if not weaponState.originalLockonValues[nameHash] then
        local lockTime  = Memory.ReadFloat(weaponInfoAddr + OFF.LOCK_ON_TIME)
        local lockRange = Memory.ReadFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE)

        local ammoAddr = readPtr(weaponInfoAddr + OFF.AMMO_INFO)
        local timeBeforeHoming = 0.0
        local pitchRate = 0.0
        local yawRate = 0.0
        if ammoAddr then
            timeBeforeHoming = Memory.ReadFloat(ammoAddr + OFF.TIME_BEFORE_HOMING)
            pitchRate = Memory.ReadFloat(ammoAddr + OFF.PITCH_CHANGE_RATE)
            yawRate   = Memory.ReadFloat(ammoAddr + OFF.YAW_CHANGE_RATE)
        end

        weaponState.originalLockonValues[nameHash] = {
            weaponAddr = weaponInfoAddr,
            ammoAddr = ammoAddr,
            lockOnTime = lockTime,
            lockOnRange = lockRange,
            timeBeforeHoming = timeBeforeHoming,
            pitchRate = pitchRate,
            yawRate = yawRate,
        }
    end

    local data = weaponState.originalLockonValues[nameHash]

    Memory.WriteFloat(weaponInfoAddr + OFF.LOCK_ON_TIME, 0.0)
    Memory.WriteFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE, 1500.0)

    if data.ammoAddr then
        Memory.WriteFloat(data.ammoAddr + OFF.TIME_BEFORE_HOMING, 0.0)
    end
end

local function restoreAllLockonValues()
    for _, data in pairs(weaponState.originalLockonValues) do
        Memory.WriteFloat(data.weaponAddr + OFF.LOCK_ON_TIME,  data.lockOnTime)
        Memory.WriteFloat(data.weaponAddr + OFF.LOCK_ON_RANGE, data.lockOnRange)
        if data.ammoAddr then
            Memory.WriteFloat(data.ammoAddr + OFF.TIME_BEFORE_HOMING, data.timeBeforeHoming)
            Memory.WriteFloat(data.ammoAddr + OFF.PITCH_CHANGE_RATE,  data.pitchRate)
            Memory.WriteFloat(data.ammoAddr + OFF.YAW_CHANGE_RATE,    data.yawRate)
        end
    end
    weaponState.originalLockonValues = {}
end

local function restoreAllWeaponRanges()
    for addr, orig in pairs(weaponState.originalWeaponRanges) do
        Memory.WriteFloat(addr + OFF.WEAPON_RANGE, orig)
    end
    weaponState.originalWeaponRanges = {}
end

restoreAndClearAllWeaponCache = function()
    restoreAllTimings()
    restoreAllLaunchSpeeds()
    restoreAllLifeTimes()
    restoreAllLockonValues()
    restoreAllWeaponRanges()
    restoreLazerNerf()
    restoreOppressorNerf()
    if restoreAllRocketsNerf then restoreAllRocketsNerf() end
    if titanCannonTune then
        titanCannonTune.restoreRange()
        titanCannonTune.restoreRate()
        titanCannonTune.restoreProbe()
    end
end

local CANNON_RANGE_VALUE = 5000.0
local function cannonRangeOnTick(f)
    if not f:IsToggled() then
        restoreAllWeaponRanges()
        titanCannonTune.restoreRange()
        titanCannonTune.restoreProbe()
        return
    end
    if not isPlayerReady() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        titanCannonTune.restoreRange()
        titanCannonTune.restoreProbe()
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh ~= 0 and ENTITY.GET_ENTITY_MODEL(veh) == titanCannonTune.MODEL then
        for _, c in ipairs(titanCannonTune.cannonInfos(veh)) do
            if weaponState.originalWeaponRanges[c.cwi] == nil then
                local orig = Memory.ReadFloat(c.cwi + OFF.WEAPON_RANGE)
                if orig == orig and orig > 0.0 and orig <= 10000.0 and orig < CANNON_RANGE_VALUE - 1.0 then
                    weaponState.originalWeaponRanges[c.cwi] = orig
                end
            end
            if weaponState.originalWeaponRanges[c.cwi] then
                Memory.WriteFloat(c.cwi + OFF.WEAPON_RANGE, CANNON_RANGE_VALUE)
            end
            if titanCannonTune.origProbe[c.w] == nil then
                local pd = Memory.ReadFloat(c.w + 0xA0)
                if pd == pd and pd > 0.0 and pd < CANNON_RANGE_VALUE - 1.0 then
                    titanCannonTune.origProbe[c.w] = pd
                end
            end
            if titanCannonTune.origProbe[c.w] then
                Memory.WriteFloat(c.w + 0xA0, CANNON_RANGE_VALUE)
            end
        end
        return
    end

    local weaponInfoAddr = getVehicleWeaponInfoAddr()
    if not weaponInfoAddr then return end

    local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
    if not titanCannonTune.HASHES[nameHash] then
        local ammoAddr = readPtr(weaponInfoAddr + OFF.AMMO_INFO)
        if not ammoAddr then return end
        if isProjectileAmmo(ammoAddr) then return end
    end

    if not weaponState.originalWeaponRanges[weaponInfoAddr] then
        local orig = Memory.ReadFloat(weaponInfoAddr + OFF.WEAPON_RANGE)
        if orig ~= orig or orig <= 0.0 or orig > 10000.0 then return end
        if orig >= CANNON_RANGE_VALUE - 1.0 then return end
        weaponState.originalWeaponRanges[weaponInfoAddr] = orig
    end

    Memory.WriteFloat(weaponInfoAddr + OFF.WEAPON_RANGE, CANNON_RANGE_VALUE)
end

titanCannonTune = {
    scanned      = false,
    MODEL        = Utils.Joaat("titan2"),
    HASHES       = {},
    rangeAddrs   = {},
    tbsAddrs     = {},
    reloadAddrs  = {},
    origRange    = {},
    origRate     = {},
    origProbe    = {},
    rangeApplied = false,
    rateApplied  = false,
}

do
    local function u32(x)
        if x < 0 then return x + 0x100000000 end
        return x
    end

    local function ripTarget(movssStart)
        local t = Memory.Rip(movssStart + 4)
        if not t or t <= 0x10000000000 or t >= 0x7FFFFFFFFFFF then return nil end
        return t
    end

    local function collect(hit, movOffs, out)
        for _, off in ipairs(movOffs) do
            local a = ripTarget(hit + off)
            if a then out[#out + 1] = a end
        end
    end

    function titanCannonTune.ensure()
        if titanCannonTune.scanned then return end
        titanCannonTune.scanned = true
        titanCannonTune.MODEL = u32(Utils.Joaat("titan2"))
        titanCannonTune.HASHES = {
            [u32(Utils.Joaat("VEHICLE_WEAPON_TITAN2_25MM"))]  = true,
            [u32(Utils.Joaat("VEHICLE_WEAPON_TITAN2_40MM"))]  = true,
            [u32(Utils.Joaat("VEHICLE_WEAPON_TITAN2_105MM"))] = true,
        }
        if IS_ENHANCED then
            local rHit = Memory.Scan(
                "3B 0D ? ? ? ? 75 ? F3 0F 10 0D ? ? ? ? 0F 57 D2 0F 2E CA 77 ? " ..
                "3B 0D ? ? ? ? 75 ? F3 0F 10 0D ? ? ? ?")
            if rHit and rHit ~= 0 then collect(rHit, {8, 32}, titanCannonTune.rangeAddrs) end
            local tHit = Memory.Scan(
                "8B 47 10 3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 57 C9 0F 2E C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 57 C9 0F 2E C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ?")
            if tHit and tHit ~= 0 then collect(tHit, {11, 35, 59}, titanCannonTune.tbsAddrs) end
            local rlHit = Memory.Scan(
                "8B 48 10 3B 0D ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 57 C9 0F 2E C1 0F 87 ? ? ? ? " ..
                "3B 0D ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 57 C9 0F 2E C1 0F 87 ? ? ? ? " ..
                "3B 0D ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ?")
            if rlHit and rlHit ~= 0 then collect(rlHit, {11, 39, 67}, titanCannonTune.reloadAddrs) end
        else
            local rHit = Memory.Scan(
                "8B 41 10 0F 57 C9 3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? F3 0F 10 81 8C 02 00 00")
            if rHit and rHit ~= 0 then collect(rHit, {14, 35}, titanCannonTune.rangeAddrs) end
            local tHit = Memory.Scan(
                "8B 43 10 0F 57 C9 3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? F3 0F 10 83 3C 01 00 00")
            if tHit and tHit ~= 0 then collect(tHit, {14, 35, 56}, titanCannonTune.tbsAddrs) end
            local rlHit = Memory.Scan(
                "8B 41 10 0F 57 C9 3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? " ..
                "3B 05 ? ? ? ? 75 ? F3 0F 10 05 ? ? ? ? 0F 2F C1 77 ? F3 0F 10 81 30 01 00 00")
            if rlHit and rlHit ~= 0 then collect(rlHit, {14, 35, 56}, titanCannonTune.reloadAddrs) end
        end

        local lo, hi
        for _, set in ipairs({titanCannonTune.rangeAddrs, titanCannonTune.tbsAddrs, titanCannonTune.reloadAddrs}) do
            for _, a in ipairs(set) do
                if not lo or a < lo then lo = a end
                if not hi or a > hi then hi = a end
            end
        end
        if lo and hi - lo > 0x4000 then
            titanCannonTune.rangeAddrs  = {}
            titanCannonTune.tbsAddrs    = {}
            titanCannonTune.reloadAddrs = {}
            log("[TitanCannon] override span sanity failed - discarded")
        end

        log(("[TitanCannon] %s overrides: range=%d tbs=%d reload=%d"):format(
            IS_ENHANCED and "enh" or "leg",
            #titanCannonTune.rangeAddrs, #titanCannonTune.tbsAddrs, #titanCannonTune.reloadAddrs))
    end

    function titanCannonTune.cannonInfos(veh)
        titanCannonTune.ensure()
        local out = {}
        local phys = GTA.HandleToPointer(veh)
        local vehAddr = phys and phys:GetAddress()
        if not vehAddr or vehAddr <= 0x10000 then return out end
        local mgr = readPtr(vehAddr + 0xC80)
        if not mgr then return out end
        local nW = Memory.ReadInt(mgr + 0x114)
        if not nW or nW < 1 or nW > 6 then return out end
        for i = 0, nW - 1 do
            local w = readPtr(mgr + 0x68 + i * 8)
            local cwpn = w and readPtr(w + 0x18)
            local cwi = cwpn and readPtr(cwpn + 0x40)
            if cwi then
                local h = Memory.ReadUInt(cwi + 0x10) & 0xFFFFFFFF
                if titanCannonTune.HASHES[h] then out[#out + 1] = { w = w, cwi = cwi } end
            end
        end
        return out
    end

    function titanCannonTune.restoreProbe()
        for w, orig in pairs(titanCannonTune.origProbe) do
            local cur = Memory.ReadFloat(w + 0xA0)
            if cur and cur == cur and math.abs(cur - CANNON_RANGE_VALUE) < 1.0 then
                Memory.WriteFloat(w + 0xA0, orig)
            end
        end
        titanCannonTune.origProbe = {}
    end

    function titanCannonTune.applyRange()
        titanCannonTune.ensure()
        for _, addr in ipairs(titanCannonTune.rangeAddrs) do
            local cur = Memory.ReadFloat(addr)
            if cur and cur == cur and cur < CANNON_RANGE_VALUE - 1.0 then
                if titanCannonTune.origRange[addr] == nil then
                    titanCannonTune.origRange[addr] = cur
                end
                Memory.WriteFloat(addr, CANNON_RANGE_VALUE)
                titanCannonTune.rangeApplied = true
            end
        end
    end

    function titanCannonTune.restoreRange()
        if not titanCannonTune.rangeApplied then return end
        for addr, orig in pairs(titanCannonTune.origRange) do
            Memory.WriteFloat(addr, orig)
        end
        titanCannonTune.origRange = {}
        titanCannonTune.rangeApplied = false
    end

    local function fast(addr)
        local cur = Memory.ReadFloat(addr)
        if not (cur and cur == cur and cur > 0.001 and cur < 100.0) then return end
        if titanCannonTune.origRate[addr] == nil then
            titanCannonTune.origRate[addr] = cur
        end
        local v = titanCannonTune.origRate[addr] * TIMING_MULTIPLIER
        if v < 0.004 then v = 0.004 end
        Memory.WriteFloat(addr, v)
        titanCannonTune.rateApplied = true
    end

    function titanCannonTune.applyRate()
        titanCannonTune.ensure()
        for _, addr in ipairs(titanCannonTune.tbsAddrs)    do fast(addr) end
        for _, addr in ipairs(titanCannonTune.reloadAddrs) do fast(addr) end
    end

    function titanCannonTune.restoreRate()
        if not titanCannonTune.rateApplied then return end
        for addr, orig in pairs(titanCannonTune.origRate) do
            Memory.WriteFloat(addr, orig)
        end
        titanCannonTune.origRate = {}
        titanCannonTune.rateApplied = false
    end
end

local function instantLockonOnTick(f)
    if not f:IsToggled() then
        restoreAllLockonValues()
        return
    end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        restoreAndClearAllWeaponCache()
        weaponState.lastVehicle = 0
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end
    if weaponVehicleChanged(veh) then return end

    local weaponInfoAddr = getVehicleWeaponInfoAddr()
    if not weaponInfoAddr then return end
    local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
    if nameHash == 0 or nameHash == weaponState.UNARMED_HASH then return end

    applyInstantLockon(weaponInfoAddr, nameHash)
end


local function autoLockonFireOnTick(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then return end
    if not VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then return end

    local lockState = VEHICLE.GET_VEHICLE_HOMING_LOCKON_STATE(veh)
    if lockState < 1 then return end

    Memory.WriteInt(autoLockBuf, 0)
    local hasTarget = VEHICLE.GET_VEHICLE_LOCK_ON_TARGET(veh, autoLockBuf)
    if not hasTarget then return end

    local targetEnt = Memory.ReadInt(autoLockBuf)
    if targetEnt == 0 or not ENTITY.DOES_ENTITY_EXIST(targetEnt) then return end

    local tgtPos = ENTITY.GET_ENTITY_COORDS(targetEnt, true)
    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(ped, targetEnt, tgtPos.x, tgtPos.y, tgtPos.z)
end

local infLockonRange = {
    applied = false,
    cache = {},
    weaponRangeCache = {},
    INF_VALUE = 99999.0,
    H_SET_PLAYER_LOCKON_RANGE_OVERRIDE = 0x29961D490E5814FD,
    iv = function(hash, ...) return Natives.InvokeVoid(hash, ...) end,
    lastVeh = nil,
    vehInitTick = 0,
}

infLockonRange.applyToLockonRange = function(weaponInfoAddr, label)
    if not weaponInfoAddr or weaponInfoAddr == 0 then return end
    local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH) or 0
    if not infLockonRange.cache[weaponInfoAddr] then
        local cur = Memory.ReadFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE)
        if cur ~= cur then
            logf("[InfLockRange] %s NaN at addr=0x%X+0x%X (offset wrong on this build?)",
                label or "?", weaponInfoAddr, OFF.LOCK_ON_RANGE)
            return
        end
        if cur >= infLockonRange.INF_VALUE - 1.0 then return end
        infLockonRange.cache[weaponInfoAddr] = cur
        Memory.WriteFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE, infLockonRange.INF_VALUE)
        local verify = Memory.ReadFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE)
        logf("[InfLockRange] %s patched hash=0x%08X addr=0x%X was=%.2f wrote=%.2f verify=%.2f",
            label or "?", nameHash, weaponInfoAddr, cur,
            infLockonRange.INF_VALUE, verify)
        return
    end
    Memory.WriteFloat(weaponInfoAddr + OFF.LOCK_ON_RANGE, infLockonRange.INF_VALUE)
end

infLockonRange.restoreAllLockonRanges = function()
    for addr, fallback in pairs(infLockonRange.cache) do
        local realOrig = nil
        for _, data in pairs(weaponState.originalLockonValues) do
            if data.weaponAddr == addr then
                realOrig = data.lockOnRange
                break
            end
        end
        if not realOrig and onFootRapidFire and onFootRapidFire.lockons then
            for _, data in pairs(onFootRapidFire.lockons) do
                if data.weaponAddr == addr then
                    realOrig = data.lockOnRange
                    break
                end
            end
        end
        Memory.WriteFloat(addr + OFF.LOCK_ON_RANGE, realOrig or fallback)
    end
    infLockonRange.cache = {}
end


infLockonRange.applyToWeaponRange = function(weaponInfoAddr, label)
    if not weaponInfoAddr or weaponInfoAddr == 0 then return end
    local nameHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH) or 0
    if not infLockonRange.weaponRangeCache[weaponInfoAddr] then
        local cur = Memory.ReadFloat(weaponInfoAddr + OFF.WEAPON_RANGE)
        if cur ~= cur then
            logf("[InfLockRange] %s WeaponRange NaN at addr=0x%X+0x%X",
                label or "?", weaponInfoAddr, OFF.WEAPON_RANGE)
            return
        end
        if cur >= infLockonRange.INF_VALUE - 1.0 then return end
        infLockonRange.weaponRangeCache[weaponInfoAddr] = cur
        Memory.WriteFloat(weaponInfoAddr + OFF.WEAPON_RANGE, infLockonRange.INF_VALUE)
        local verify = Memory.ReadFloat(weaponInfoAddr + OFF.WEAPON_RANGE)
        logf("[InfLockRange] %s patched WeaponRange hash=0x%08X addr=0x%X was=%.2f wrote=%.2f verify=%.2f",
            label or "?", nameHash, weaponInfoAddr, cur,
            infLockonRange.INF_VALUE, verify)
        return
    end
    Memory.WriteFloat(weaponInfoAddr + OFF.WEAPON_RANGE, infLockonRange.INF_VALUE)
end

infLockonRange.restoreAllWeaponRanges = function()
    for addr, fallback in pairs(infLockonRange.weaponRangeCache) do
        local realOrig = weaponState.originalWeaponRanges
            and weaponState.originalWeaponRanges[addr]
        Memory.WriteFloat(addr + OFF.WEAPON_RANGE, realOrig or fallback)
    end
    infLockonRange.weaponRangeCache = {}
end

infLockonRange.restore = function()
    if infLockonRange.applied then
        local localPid = GTA.GetLocalPlayerId()
        infLockonRange.iv(
            infLockonRange.H_SET_PLAYER_LOCKON_RANGE_OVERRIDE, localPid, 250.0)
        infLockonRange.applied = false
    end
    infLockonRange.restoreAllLockonRanges()
    infLockonRange.restoreAllWeaponRanges()
end

infLockonRange.onTick = function(f)
    if not f:IsToggled() then
        if infLockonRange.applied then
            infLockonRange.restore()
            logf("[InfLockRange] disabled, native + caches restored")
        end
        return
    end
    if not isPlayerReady() then return end
    local localPid = GTA.GetLocalPlayerId()
    infLockonRange.iv(
        infLockonRange.H_SET_PLAYER_LOCKON_RANGE_OVERRIDE, localPid, 99999999.0)
    if not infLockonRange.applied then
        logf("[InfLockRange] enabled, OFF.LOCK_ON_RANGE=0x%X", OFF.LOCK_ON_RANGE)
    end
    infLockonRange.applied = true

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(localPid)
    if not ped or ped == 0 then return end
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end
        if veh ~= infLockonRange.lastVeh then
            infLockonRange.lastVeh = veh
            infLockonRange.vehInitTick = 0
            return
        end
        infLockonRange.vehInitTick = infLockonRange.vehInitTick + 1
        if infLockonRange.vehInitTick <= weaponState.VEH_INIT_DELAY then return end

        local weaponInfoAddr = getVehicleWeaponInfoAddr()
        if weaponInfoAddr then
            infLockonRange.applyToLockonRange(weaponInfoAddr, "vehicle")
            local ammoAddr = readPtr(weaponInfoAddr + OFF.AMMO_INFO)
            if ammoAddr and isProjectileAmmo(ammoAddr) then
                infLockonRange.applyToWeaponRange(weaponInfoAddr, "vehicle-homing")
            end
        end
    else
        infLockonRange.lastVeh = nil
        local weaponMgr = getWeaponManagerAddr()
        if weaponMgr then
            local weaponInfoAddr = readPtr(weaponMgr + 0x68)
            if weaponInfoAddr then
                infLockonRange.applyToLockonRange(weaponInfoAddr, "on-foot")
            end
        end
    end
end

lockOntoPlayers = {
    MAX_DIST_SQ = 400.0 * 400.0,
    added = {},
    attackFriendlySet = false,
    localFriendlySet = false,
    lockonSet = false,
    H_ADD_PLAYER_TARGETABLE_ENTITY     = 0x9097EB6D4BB9A12A,
    H_REMOVE_PLAYER_TARGETABLE_ENTITY  = 0x9F260BFB59ADBCA3,
    H_SET_ENTITY_IS_TARGET_PRIORITY    = 0xEA02E132F5C68722,
    H_SET_CAN_ATTACK_FRIENDLY          = 0xB3B1CB349FF9C75D,
    H_SET_PED_CONFIG_FLAG              = 0x1913FE4CBF41C463,
    H_SET_PED_RESET_FLAG               = 0xC1E8A365BF3B29F2,
    H_SET_ALLOW_LOCKON_IF_FRIENDLY     = 0x061CB768363D6424,
    H_SET_PED_CAN_BE_TARGETTED         = 0x63F58F7C80513AAD,
    H_SET_PED_CAN_BE_TARGETTED_BY_PLR  = 0x66B57B72E0836A76,
    H_SET_PLAYER_LOCKON                = 0x5C8B2F450EE4328E,
    H_SET_PLAYER_LOCKON_RANGE_OVERRIDE = 0x29961D490E5814FD,
    H_NETWORK_SET_FRIENDLY_FIRE_OPTION = 0xF808475FA571D823,
    PCF_NEVER_EVER_TARGET              = 9,
    PCF_TARGETTABLE_WITH_NO_LOS        = 11,
    PCF_PED_IS_ENEMY_TO_PLAYER         = 38,
    PCF_DISABLE_PLAYER_LOCKON          = 43,
    PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS  = 45,
    PCF_TREAT_AS_FRIENDLY_TARGETING    = 423,
    PCF_TREAT_AS_FRIENDLY_NONSYNC      = 425,
    PCF_DISABLE_HOMING_MISSILE_LOCKON  = 434,
    PRF_ALLOW_HOMING_IN_VEHICLE        = 349,
    PRF_DISABLE_MP_FRIENDLY_LOCKON     = 356,
    PRF_PREVENT_LOCKON_FRIENDLY        = 455,
    OFF_PED_NET_OBJECT                 = 0xD0,
    OFF_NETOBJ_FLAG_BYTE               = 0x4AB,
    MASK_IS_PASSIVE                    = 0x80,
    MASK_FRIENDLY_FIRE_ALLOWED         = 0x40,
}
lockOntoPlayers.iv = function(hash, ...) return Natives.InvokeVoid(hash, ...) end

lockOntoPlayers.addTargetableEntity = function(localPid, ped)
    if PLAYER and PLAYER.ADD_PLAYER_TARGETABLE_ENTITY then
        PLAYER.ADD_PLAYER_TARGETABLE_ENTITY(localPid, ped)
        return true
    end
    lockOntoPlayers.iv(lockOntoPlayers.H_ADD_PLAYER_TARGETABLE_ENTITY, localPid, ped)
    return true
end

lockOntoPlayers.removeTargetableEntity = function(localPid, ped)
    if PLAYER and PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY then
        PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY(localPid, ped)
        return true
    end
    lockOntoPlayers.iv(lockOntoPlayers.H_REMOVE_PLAYER_TARGETABLE_ENTITY, localPid, ped)
    return true
end

lockOntoPlayers.setTargetPriority = function(ped, enabled)
    if ENTITY and ENTITY.SET_ENTITY_IS_TARGET_PRIORITY then
        ENTITY.SET_ENTITY_IS_TARGET_PRIORITY(ped, enabled, 400.0)
        return true
    end
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ENTITY_IS_TARGET_PRIORITY, ped, enabled, 400.0)
    return true
end

lockOntoPlayers.clearPassiveBit = function(cped)
    if not cped then return false end
    local pedAddr = cped:GetAddress()
    if not pedAddr or pedAddr == 0 then return false end
    local netObjPtr = readPtr(pedAddr + lockOntoPlayers.OFF_PED_NET_OBJECT)
    if not netObjPtr then return false end
    local flagAddr = netObjPtr + lockOntoPlayers.OFF_NETOBJ_FLAG_BYTE
    local b = Memory.ReadByte(flagAddr)
    local newB = (b & (~lockOntoPlayers.MASK_IS_PASSIVE & 0xFF))
                    | lockOntoPlayers.MASK_FRIENDLY_FIRE_ALLOWED
    if newB ~= b then Memory.WriteByte(flagAddr, newB) end
    return true
end

lockOntoPlayers.restorePassiveBit = function(cped)
    if not cped then return end
    local pedAddr = cped:GetAddress()
    if not pedAddr or pedAddr == 0 then return end
    local netObjPtr = readPtr(pedAddr + lockOntoPlayers.OFF_PED_NET_OBJECT)
    if not netObjPtr then return end
    local flagAddr = netObjPtr + lockOntoPlayers.OFF_NETOBJ_FLAG_BYTE
    local b = Memory.ReadByte(flagAddr)
    local newB = b & (~lockOntoPlayers.MASK_FRIENDLY_FIRE_ALLOWED & 0xFF)
    if newB ~= b then Memory.WriteByte(flagAddr, newB) end
end

lockOntoPlayers.H_TREAT_AS_AMBIENT_FOR_DRIVER_LO= 0x2F3C3D9F50681DE4
lockOntoPlayers.H_PED_CAN_BE_TARGETED_NO_LOS    = 0x4328652AE5769C71
lockOntoPlayers.H_SET_ENTITY_CAN_BE_TARGETED_NOLOS = 0xD3997889736FD899
lockOntoPlayers.H_GET_VEHICLE_PED_IS_IN         = 0x9A9112A0FE9A4713
lockOntoPlayers.OFF_VEH_ALLOW_HOMING_LOCKON     = 0x0AEE

lockOntoPlayers.isDisableLOSActive = function()
    local f = FeatureMgr.GetFeature(H.DISABLE_LOS)
    if f then return f:IsToggled() end
    return false
end

lockOntoPlayers.isLockOntoNPCsActive = function()
    local f = FeatureMgr.GetFeature(H.LOCK_ONTO_NPCS)
    if f then return f:IsToggled() end
    return false
end

lockOntoPlayers.isLockOntoPlayersActive = function()
    local f = FeatureMgr.GetFeature(H.LOCK_ONTO_PLAYERS)
    if f then return f:IsToggled() end
    return false
end

lockOntoPlayers.INF_LOCK_DIST = 99999.0
lockOntoPlayers.isInfLockonRangeActive = function()
    local f = FeatureMgr.GetFeature(H.INF_LOCKON_RANGE)
    if f then return f:IsToggled() end
    return false
end
lockOntoPlayers.effectiveMaxDistSq = function()
    if lockOntoPlayers.isInfLockonRangeActive() then
        return lockOntoPlayers.INF_LOCK_DIST * lockOntoPlayers.INF_LOCK_DIST
    end
    return lockOntoPlayers.MAX_DIST_SQ
end

lockOntoPlayers.H_GET_INTERIOR_FROM_ENTITY = 0x2107BA504071A6BB
lockOntoPlayers.GPBD_BASE            = IS_ENHANCED and 2658296 or 2658293
lockOntoPlayers.GPBD_STRIDE          = 468
lockOntoPlayers.GPBD_INTERIOR        = 249
lockOntoPlayers.GPBD_SIMPLE_INTERIOR = 325 + 8
lockOntoPlayers.GPBD_FM_BASE         = IS_ENHANCED and 1845347 or 1845298
lockOntoPlayers.GPBD_FM_STRIDE       = IS_ENHANCED and 884 or 881
lockOntoPlayers.GPBD_PROPERTY        = 260 + 39

lockOntoPlayers.bdInterior = function(pid)
    local v = ScriptGlobal.GetInt(lockOntoPlayers.GPBD_BASE + 1 + pid * lockOntoPlayers.GPBD_STRIDE + lockOntoPlayers.GPBD_INTERIOR)
    return v or 0
end
lockOntoPlayers.bdSimpleInterior = function(pid)
    local v = ScriptGlobal.GetInt(lockOntoPlayers.GPBD_BASE + 1 + pid * lockOntoPlayers.GPBD_STRIDE + lockOntoPlayers.GPBD_SIMPLE_INTERIOR)
    return v or -1
end
lockOntoPlayers.bdSimpleInstance = function(pid)
    local v = ScriptGlobal.GetInt(lockOntoPlayers.GPBD_BASE + 1 + pid * lockOntoPlayers.GPBD_STRIDE + lockOntoPlayers.GPBD_SIMPLE_INTERIOR + 1)
    return v or 0
end
lockOntoPlayers.bdProperty = function(pid)
    local v = ScriptGlobal.GetInt(lockOntoPlayers.GPBD_FM_BASE + 1 + pid * lockOntoPlayers.GPBD_FM_STRIDE + lockOntoPlayers.GPBD_PROPERTY)
    return v or -1
end

lockOntoPlayers.isPlayerInInterior = function(pid, ped)
    if not ped or ped == 0 then return false end
    local interior = Natives.InvokeInt(lockOntoPlayers.H_GET_INTERIOR_FROM_ENTITY, ped)
    if interior ~= nil and interior ~= 0 then return true end
    if pid and pid >= 0 and pid <= 31 then
        if lockOntoPlayers.bdInterior(pid)       ~= 0  then return true end
        if lockOntoPlayers.bdSimpleInterior(pid) ~= -1 then return true end
        if lockOntoPlayers.bdProperty(pid)       ~= -1 then return true end
    end
    return false
end

lockOntoPlayers.patchTargetVehicle = function(vehHandle)
    if not vehHandle or vehHandle == 0 then return false end
    local vehPhys = GTA.HandleToPointer(vehHandle)
    if not vehPhys then return false end
    local vehAddr = vehPhys:GetAddress()
    if not vehAddr or vehAddr == 0 then return false end
    local flagAddr = vehAddr + lockOntoPlayers.OFF_VEH_ALLOW_HOMING_LOCKON
    if Memory.ReadByte(flagAddr) == 0 then
        Memory.WriteByte(flagAddr, 1)
    end
    return true
end

lockOntoPlayers.reticleDrawPatch = {
    AOB        = "88 95 68 09 00 00 45 84 FF 0F 84 EB 00 00 00",
    PATCH_OFF  = 9,
    ORIG_BYTES = { 0x0F, 0x84, 0xEB, 0x00, 0x00, 0x00 },
    NEW_BYTES  = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 },
    E_AOB        = "40 F6 C5 01 75 0B C6 44 24 ? 00 8B 6C 24 ? EB ? 4D 85 ED",
    E_PATCH_OFF  = 4,
    E_ORIG_BYTES = { 0x75, 0x0B },
    E_NEW_BYTES  = { 0xEB, 0x0B },
    addr = nil, applied = false, scanned = false, resolveFailLogged = false,
}
lockOntoPlayers.reticleDrawPatch.resolve = function()
    local p = lockOntoPlayers.reticleDrawPatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        p.AOB = p.E_AOB; p.PATCH_OFF = p.E_PATCH_OFF
        p.ORIG_BYTES = p.E_ORIG_BYTES; p.NEW_BYTES = p.E_NEW_BYTES
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        local site = hit + p.PATCH_OFF
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(site + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        p.addr = site
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] DisableLOS: reticle-draw AOB not resolved; patch disabled")
    end
    return p.addr ~= nil
end
lockOntoPlayers.reticleDrawPatch.apply = function()
    local p = lockOntoPlayers.reticleDrawPatch
    if p.applied then return true end
    if not p.resolve() then return false end
    local runBody = function()
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(p.addr + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        for i = 1, #p.NEW_BYTES do Memory.WriteByte(p.addr + (i - 1), p.NEW_BYTES[i]) end
        p.applied = true
    end
    runBody()
    return p.applied
end
lockOntoPlayers.reticleDrawPatch.restore = function()
    local p = lockOntoPlayers.reticleDrawPatch
    if not p.applied or not p.addr then p.applied = false; return end
    do
        for i = 1, #p.ORIG_BYTES do Memory.WriteByte(p.addr + (i - 1), p.ORIG_BYTES[i]) end
    end
    p.applied = false
end

lockOntoPlayers.occludedLockSoundPatch = {
    AOB        = "38 4C 24 58 74 71 4D 85 FF 74 6C 41 8A 47 28 41 B8 02 00 00 00 2C 03",
    PATCH_OFF  = 4,
    ORIG_BYTES = { 0x74, 0x71 },
    NEW_BYTES  = { 0x90, 0x90 },
    E_AOB        = "89 E8 24 01 0F 84 ? ? ? ? 0F B6 47 28 04 FD 3C 02",
    E_PATCH_OFF  = 4,
    E_ORIG_BYTES = { 0x0F, 0x84, 0xD8, 0xE6, 0xFF, 0xFF },
    E_NEW_BYTES  = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 },
    addr = nil, applied = false, scanned = false, resolveFailLogged = false,
}
lockOntoPlayers.occludedLockSoundPatch.resolve = function()
    local p = lockOntoPlayers.occludedLockSoundPatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        p.AOB = p.E_AOB; p.PATCH_OFF = p.E_PATCH_OFF
        p.ORIG_BYTES = p.E_ORIG_BYTES; p.NEW_BYTES = p.E_NEW_BYTES
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        local site = hit + p.PATCH_OFF
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(site + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        p.addr = site
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] DisableLOS: occluded-lock-sound AOB not resolved; patch off")
    end
    return p.addr ~= nil
end
lockOntoPlayers.occludedLockSoundPatch.apply = function()
    local p = lockOntoPlayers.occludedLockSoundPatch
    if p.applied then return true end
    if not p.resolve() then return false end
    local runBody = function()
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(p.addr + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        for i = 1, #p.NEW_BYTES do Memory.WriteByte(p.addr + (i - 1), p.NEW_BYTES[i]) end
        p.applied = true
    end
    runBody()
    return p.applied
end
lockOntoPlayers.occludedLockSoundPatch.restore = function()
    local p = lockOntoPlayers.occludedLockSoundPatch
    if not p.applied or not p.addr then p.applied = false; return end
    do
        for i = 1, #p.ORIG_BYTES do Memory.WriteByte(p.addr + (i - 1), p.ORIG_BYTES[i]) end
    end
    p.applied = false
end

lockOntoPlayers.nativePlayerLockPatch = {
    AOB        = "48 8B CF E8 ? ? ? ? 84 C0 74 09 4C 39 AB A8 10 00 00 75 56",
    PATCH_OFF  = 0x13,
    ORIG_BYTES = { 0x75, 0x56 },
    NEW_BYTES  = { 0x90, 0x90 },
    E_AOB        = "80 3D ? ? ? ? 00 74 1A 48 89 F1 E8 ? ? ? ? 84 C0 74 0E 49 83 BF A8 10 00 00 00 0F 85",
    E_PATCH_OFF  = 0x1D,
    E_ORIG_BYTES = { 0x0F, 0x85, 0xD6, 0x08, 0x00, 0x00 },
    E_NEW_BYTES  = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 },
    addr = nil, applied = false, scanned = false, resolveFailLogged = false,
}
lockOntoPlayers.nativePlayerLockPatch.resolve = function()
    local p = lockOntoPlayers.nativePlayerLockPatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        p.AOB = p.E_AOB; p.PATCH_OFF = p.E_PATCH_OFF
        p.ORIG_BYTES = p.E_ORIG_BYTES; p.NEW_BYTES = p.E_NEW_BYTES
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        local site = hit + p.PATCH_OFF
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(site + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        p.addr = site
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        if VIBESCRIPT_VERBOSE then
            Logger.LogInfo("[VibeScript] LockOntoPlayers: native-lock AOB not resolved; engine player-lock patch off (Legacy AOB miss / Enhanced; targetable-marking still runs)")
        end
    end
    return p.addr ~= nil
end
lockOntoPlayers.nativePlayerLockPatch.apply = function()
    local p = lockOntoPlayers.nativePlayerLockPatch
    if p.applied then return true end
    if not p.resolve() then return false end
    local runBody = function()
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(p.addr + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        for i = 1, #p.NEW_BYTES do Memory.WriteByte(p.addr + (i - 1), p.NEW_BYTES[i]) end
        p.applied = true
    end
    runBody()
    return p.applied
end
lockOntoPlayers.nativePlayerLockPatch.restore = function()
    local p = lockOntoPlayers.nativePlayerLockPatch
    if not p.applied or not p.addr then p.applied = false; return end
    do
        for i = 1, #p.ORIG_BYTES do Memory.WriteByte(p.addr + (i - 1), p.ORIG_BYTES[i]) end
    end
    p.applied = false
end

lockOntoPlayers.pedThreatGatePatch = {
    AOB           = "44 38 2D ? ? ? ? 74 40 48 8B 8F A0 10 00 00",
    ORIG_BYTES    = { 0x44, 0x38, 0x2D, 0xC0, 0x95, 0x45, 0x01, 0x74, 0x40 },
    PLAYER_BYTES  = { 0x4C, 0x39, 0xAB, 0xA8, 0x10, 0x00, 0x00, 0x75, 0x40 },
    BLANKET_BYTES = { 0x44, 0x38, 0x2D, 0xC0, 0x95, 0x45, 0x01, 0xEB, 0x40 },
    E_AOB         = "80 3D ? ? ? ? 00 0F 84 ? ? ? ? 48 8B 8E A0 10 00 00 C6 44 24 20 00",
    E_CAVE_SHELL  = { 0x49,0x83,0xBF,0xA8,0x10,0x00,0x00,0x00,
                      0x0F,0x85,0x00,0x00,0x00,0x00,
                      0xE9,0x00,0x00,0x00,0x00 },
    addr = nil, mode = "original", scanned = false, resolveFailLogged = false,
    _cave = 0, _caveOrig = nil, _player13 = nil,
}
lockOntoPlayers.pedThreatGatePatch.resolve = function()
    local p = lockOntoPlayers.pedThreatGatePatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        local runBody = function()
            local hit = Memory.Scan(p.E_AOB)
            if not hit or hit == 0 then return end
            if Memory.ReadUByte(hit + 0) ~= 0x80 or Memory.ReadUByte(hit + 1) ~= 0x3D
               or Memory.ReadUByte(hit + 6) ~= 0x00
               or Memory.ReadUByte(hit + 7) ~= 0x0F or Memory.ReadUByte(hit + 8) ~= 0x84 then return end
            local orig13 = {}
            for i = 0, 12 do orig13[i + 1] = Memory.ReadUByte(hit + i) end
            local jzRel = orig13[10] | (orig13[11] << 8) | (orig13[12] << 16) | (orig13[13] << 24)
            if jzRel >= 0x80000000 then jzRel = jzRel - 0x100000000 end
            local fallThrough = hit + 13
            local skipThreat  = fallThrough + jzRel
            local jmpRel = jzRel + 1
            local blanket13 = { orig13[1],orig13[2],orig13[3],orig13[4],orig13[5],orig13[6],orig13[7],
                                0xE9, jmpRel & 0xFF, (jmpRel >> 8) & 0xFF, (jmpRel >> 16) & 0xFF, (jmpRel >> 24) & 0xFF,
                                0x90 }
            p.addr         = hit
            p._site        = hit
            p._skipThreat  = skipThreat
            p._fallThrough = fallThrough
            p._orig        = orig13
            p._blanket     = blanket13
            p._player      = blanket13
        end
        runBody()
        if not p.addr and not p.resolveFailLogged then
            p.resolveFailLogged = true
            Logger.LogInfo("[VibeScript] LockOntoPlayers: ped-threat-gate AOB not resolved; patch off")
        end
        return p.addr ~= nil
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        if Memory.ReadUByte(hit + 0) ~= 0x44 or Memory.ReadUByte(hit + 1) ~= 0x38
           or Memory.ReadUByte(hit + 2) ~= 0x2D or Memory.ReadUByte(hit + 7) ~= 0x74
           or Memory.ReadUByte(hit + 8) ~= 0x40 then return end
        local orig = {}
        for i = 0, 8 do orig[i + 1] = Memory.ReadUByte(hit + i) end
        local blanket = {}
        for i = 1, 9 do blanket[i] = orig[i] end
        blanket[8] = 0xEB
        p._orig = orig
        p._player = p.PLAYER_BYTES
        p._blanket = blanket
        p.ORIG_BYTES = orig
        p.BLANKET_BYTES = blanket
        p.addr = hit
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] LockOntoPlayers: ped-threat-gate AOB not resolved; patch off")
    end
    return p.addr ~= nil
end
lockOntoPlayers.pedThreatGatePatch.ensurePlayerCave = function()
    local p = lockOntoPlayers.pedThreatGatePatch
    if p._player13 then return true end
    if not IS_ENHANCED or not p._site then return false end
    local runBody = function()
        local caveBase = 0
        for _, zeros in ipairs({ 1024, 400, 200, 100 }) do
            for _, prefix in ipairs({ "CC", "C3" }) do
                local pat = prefix
                for _ = 1, zeros do pat = pat .. " 00" end
                local hit = Memory.Scan(pat)
                if hit and hit ~= 0 then caveBase = hit + 1; break end
            end
            if caveBase ~= 0 then break end
        end
        if caveBase == 0 then return end
        local caveOrig = {}
        for i = 0, 18 do
            local b = Memory.ReadUByte(caveBase + i)
            if b ~= 0 then return end
            caveOrig[i + 1] = b
        end
        local shell = {}
        for i = 1, #p.E_CAVE_SHELL do shell[i] = p.E_CAVE_SHELL[i] end
        local relJnz = p._skipThreat  - (caveBase + 14)
        local relJmp = p._fallThrough - (caveBase + 19)
        shell[11] =  relJnz        & 0xFF
        shell[12] = (relJnz >> 8)  & 0xFF
        shell[13] = (relJnz >> 16) & 0xFF
        shell[14] = (relJnz >> 24) & 0xFF
        shell[16] =  relJmp        & 0xFF
        shell[17] = (relJmp >> 8)  & 0xFF
        shell[18] = (relJmp >> 16) & 0xFF
        shell[19] = (relJmp >> 24) & 0xFF
        for i = 0, #shell - 1 do Memory.WriteByte(caveBase + i, shell[i + 1]) end
        local relSite = caveBase - (p._site + 5)
        p._player13 = { 0xE9, relSite & 0xFF, (relSite >> 8) & 0xFF, (relSite >> 16) & 0xFF, (relSite >> 24) & 0xFF,
                        0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 }
        p._player   = p._player13
        p._cave     = caveBase
        p._caveOrig = caveOrig
        if VIBESCRIPT_VERBOSE then
            Logger.LogInfo(string.format("[VibeScript] LockOntoPlayers: player-test cave @ 0x%X", caveBase))
        end
    end
    runBody()
    return (p._player13 ~= nil)
end
lockOntoPlayers.pedThreatGatePatch.setMode = function(mode)
    local p = lockOntoPlayers.pedThreatGatePatch
    if p.mode == mode then return true end
    if not p.resolve() then
        if not p.addr then p.mode = "original" end
        return false
    end
    if mode == "player" and IS_ENHANCED then
        lockOntoPlayers.pedThreatGatePatch.ensurePlayerCave()
    end
    local bytes = (mode == "blanket" and p._blanket)
               or (mode == "player"  and p._player)
               or p._orig
    for i = 1, #bytes do Memory.WriteByte(p.addr + (i - 1), bytes[i]) end
    p.mode = mode
    return true
end
lockOntoPlayers.pedThreatGatePatch.restore = function()
    lockOntoPlayers.pedThreatGatePatch.setMode("original")
end
lockOntoPlayers.pedThreatGatePatch.restoreCave = function()
    local p = lockOntoPlayers.pedThreatGatePatch
    if p._cave == 0 or not p._caveOrig then return end
    do
        for i = 1, #p._caveOrig do Memory.WriteByte(p._cave + (i - 1), p._caveOrig[i]) end
    end
    p._cave = 0; p._caveOrig = nil; p._player13 = nil
    p._player = p._blanket
end

lockOntoPlayers.updatePedThreatGate = function()
    local npcsOn    = lockOntoPlayers.isLockOntoNPCsActive()
    local playersOn = lockOntoPlayers.isLockOntoPlayersActive()
    local mode = npcsOn and "blanket" or (playersOn and "player" or "original")
    lockOntoPlayers.pedThreatGatePatch.setMode(mode)
end

lockOntoPlayers.vehicleHomingFlagPatch = {
    AOB        = "F6 83 83 09 00 00 20 0F 84 ? ? ? ? 44 38 AB EE 0A 00 00 0F 84 ? ? ? ? 8A 83 D8 00 00 00",
    PATCH_OFF  = 0,
    ORIG_BYTES = { 0xF6,0x83,0x83,0x09,0x00,0x00,0x20, 0x0F,0x84,0xE3,0xFA,0xFF,0xFF, 0x44,0x38,0xAB,0xEE,0x0A,0x00,0x00, 0x0F,0x84,0xD6,0xFA,0xFF,0xFF },
    NEW_BYTES  = { 0xF6,0x83,0x83,0x09,0x00,0x00,0x20, 0x90,0x90,0x90,0x90,0x90,0x90, 0x44,0x38,0xAB,0xEE,0x0A,0x00,0x00, 0x90,0x90,0x90,0x90,0x90,0x90 },
    E_AOB        = "41 83 BF 28 0C 00 00 0E 0F 84 ? ? ? ? 41 F6 87 83 09 00 00 20 0F 84 ? ? ? ? 41 80 BF EE 0A 00 00 00",
    E_SITE_OFF   = 0x16,
    addr = nil, applied = false, scanned = false, resolveFailLogged = false,
}
lockOntoPlayers.vehicleHomingFlagPatch.resolve = function()
    local p = lockOntoPlayers.vehicleHomingFlagPatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        local runBody = function()
            local hit = Memory.Scan(p.E_AOB)
            if not hit or hit == 0 then return end
            local site = hit + p.E_SITE_OFF
            if Memory.ReadUByte(site + 0) ~= 0x0F or Memory.ReadUByte(site + 1) ~= 0x84 then return end
            local cmp = { 0x41, 0x80, 0xBF, 0xEE, 0x0A, 0x00, 0x00, 0x00 }
            for i = 1, #cmp do
                if Memory.ReadUByte(site + 5 + i) ~= cmp[i] then return end
            end
            if Memory.ReadUByte(site + 14) ~= 0x0F or Memory.ReadUByte(site + 15) ~= 0x85 then return end
            local jnzRel = Memory.ReadUByte(site + 16) | (Memory.ReadUByte(site + 17) << 8)
                         | (Memory.ReadUByte(site + 18) << 16) | (Memory.ReadUByte(site + 19) << 24)
            local jmpRel = (jnzRel + 1) & 0xFFFFFFFF
            local orig = {}
            for i = 0, 19 do orig[i + 1] = Memory.ReadUByte(site + i) end
            local newb = { 0x90,0x90,0x90,0x90,0x90,0x90,
                           cmp[1],cmp[2],cmp[3],cmp[4],cmp[5],cmp[6],cmp[7],cmp[8],
                           0xE9, jmpRel & 0xFF, (jmpRel >> 8) & 0xFF, (jmpRel >> 16) & 0xFF, (jmpRel >> 24) & 0xFF,
                           0x90 }
            p.addr = site
            p.ORIG_BYTES = orig
            p.NEW_BYTES  = newb
        end
        runBody()
        if not p.addr and not p.resolveFailLogged then
            p.resolveFailLogged = true
            Logger.LogInfo("[VibeScript] LockOntoNPCs: vehicle-homing-flag AOB not resolved; patch off")
        end
        return p.addr ~= nil
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        local site = hit + (p.PATCH_OFF or 0)
        if Memory.ReadUByte(site + 0) ~= 0xF6 or Memory.ReadUByte(site + 1) ~= 0x83
           or Memory.ReadUByte(site + 6) ~= 0x20
           or Memory.ReadUByte(site + 7) ~= 0x0F or Memory.ReadUByte(site + 8) ~= 0x84
           or Memory.ReadUByte(site + 13) ~= 0x44 or Memory.ReadUByte(site + 14) ~= 0x38
           or Memory.ReadUByte(site + 15) ~= 0xAB
           or Memory.ReadUByte(site + 20) ~= 0x0F or Memory.ReadUByte(site + 21) ~= 0x84 then return end
        local orig, newb = {}, {}
        for i = 0, 25 do
            local b = Memory.ReadUByte(site + i)
            orig[i + 1] = b
            newb[i + 1] = b
        end
        for i = 8, 13 do newb[i] = 0x90 end
        for i = 21, 26 do newb[i] = 0x90 end
        p.ORIG_BYTES = orig
        p.NEW_BYTES = newb
        p.addr = site
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] LockOntoNPCs: vehicle-homing-flag AOB not resolved; patch off")
    end
    return p.addr ~= nil
end
lockOntoPlayers.vehicleHomingFlagPatch.apply = function()
    local p = lockOntoPlayers.vehicleHomingFlagPatch
    if p.applied then return true end
    if not p.resolve() then return false end
    local runBody = function()
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(p.addr + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        for i = 1, #p.NEW_BYTES do Memory.WriteByte(p.addr + (i - 1), p.NEW_BYTES[i]) end
        p.applied = true
    end
    runBody()
    return p.applied
end
lockOntoPlayers.vehicleHomingFlagPatch.restore = function()
    local p = lockOntoPlayers.vehicleHomingFlagPatch
    if not p.applied or not p.addr then p.applied = false; return end
    do
        for i = 1, #p.ORIG_BYTES do Memory.WriteByte(p.addr + (i - 1), p.ORIG_BYTES[i]) end
    end
    p.applied = false
end

lockOntoPlayers.vehicleOccupantGatePatch = {
    AOB        = "48 85 F6 0F 84 ? ? ? ? 44 38 3D ? ? ? ? 74 ? 8B 87 CC 14 00 00",
    ACCEPT_AOB = "41 BC 01 00 00 00 41 8A C4 E9 ? ? ? ?",
    PATCH_OFF  = 9,
    ORIG_BYTES = { 0x44, 0x38, 0x3D, 0x01, 0xFE, 0x2E, 0x02 },
    NEW_BYTES  = { 0xE9, 0x74, 0x03, 0x00, 0x00, 0x90, 0x90 },
    E_AOB        = "84 C0 0F 84 ? ? ? ? 80 3D ? ? ? ? 00 74 13 48 89 F1 4C 89 F2",
    E_SITE_OFF   = 0x08,
    addr = nil, applied = false, scanned = false, resolveFailLogged = false,
}
lockOntoPlayers.vehicleOccupantGatePatch.resolve = function()
    local p = lockOntoPlayers.vehicleOccupantGatePatch
    if p.addr then return true end
    if p.scanned then return false end
    p.scanned = true
    if IS_ENHANCED then
        if not p.E_AOB then return false end
        local runBody = function()
            local hit = Memory.Scan(p.E_AOB)
            if not hit or hit == 0 then return end
            local site = hit + p.E_SITE_OFF
            if Memory.ReadUByte(hit + 2) ~= 0x0F or Memory.ReadUByte(hit + 3) ~= 0x84 then return end
            if Memory.ReadUByte(site + 0) ~= 0x80 or Memory.ReadUByte(site + 1) ~= 0x3D
               or Memory.ReadUByte(site + 6) ~= 0x00 then return end
            local jzRel = Memory.ReadUByte(hit + 4) | (Memory.ReadUByte(hit + 5) << 8)
                        | (Memory.ReadUByte(hit + 6) << 16) | (Memory.ReadUByte(hit + 7) << 24)
            if jzRel >= 0x80000000 then jzRel = jzRel - 0x100000000 end
            local rejectEpilogue = (hit + 8) + jzRel
            local commonReturn   = rejectEpilogue + 2
            local orig = {}
            for i = 0, 8 do orig[i + 1] = Memory.ReadUByte(site + i) end
            local jmpRel = commonReturn - (site + 8)
            local newb = { 0x40, 0xB7, 0x01,
                           0xE9, jmpRel & 0xFF, (jmpRel >> 8) & 0xFF, (jmpRel >> 16) & 0xFF, (jmpRel >> 24) & 0xFF,
                           0x90 }
            p.addr = site
            p.ORIG_BYTES = orig
            p.NEW_BYTES  = newb
        end
        runBody()
        if not p.addr and not p.resolveFailLogged then
            p.resolveFailLogged = true
            Logger.LogInfo("[VibeScript] LockOntoNPCs: vehicle-occupant-gate AOB not resolved; patch off")
        end
        return p.addr ~= nil
    end
    local runBody = function()
        local hit = Memory.Scan(p.AOB)
        if not hit or hit == 0 then return end
        local site = hit + p.PATCH_OFF
        if Memory.ReadUByte(hit + 0) ~= 0x48 or Memory.ReadUByte(hit + 1) ~= 0x85
           or Memory.ReadUByte(hit + 2) ~= 0xF6
           or Memory.ReadUByte(hit + 3) ~= 0x0F or Memory.ReadUByte(hit + 4) ~= 0x84
           or Memory.ReadUByte(site + 0) ~= 0x44 or Memory.ReadUByte(site + 1) ~= 0x38
           or Memory.ReadUByte(site + 2) ~= 0x3D then return end
        local accept = Memory.Scan(p.ACCEPT_AOB)
        if not accept or accept == 0 then return end
        local orig = {}
        for i = 0, 6 do orig[i + 1] = Memory.ReadUByte(site + i) end
        local jmpRel = accept - (site + 5)
        p.ORIG_BYTES = orig
        p.NEW_BYTES = { 0xE9, jmpRel & 0xFF, (jmpRel >> 8) & 0xFF,
                        (jmpRel >> 16) & 0xFF, (jmpRel >> 24) & 0xFF, 0x90, 0x90 }
        p.addr = site
    end
    runBody()
    if not p.addr and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] LockOntoNPCs: vehicle-occupant-gate AOB not resolved; patch off")
    end
    return p.addr ~= nil
end
lockOntoPlayers.vehicleOccupantGatePatch.apply = function()
    local p = lockOntoPlayers.vehicleOccupantGatePatch
    if p.applied then return true end
    if not p.resolve() then return false end
    local runBody = function()
        for i = 1, #p.ORIG_BYTES do
            if Memory.ReadUByte(p.addr + (i - 1)) ~= p.ORIG_BYTES[i] then return end
        end
        for i = 1, #p.NEW_BYTES do Memory.WriteByte(p.addr + (i - 1), p.NEW_BYTES[i]) end
        p.applied = true
    end
    runBody()
    return p.applied
end
lockOntoPlayers.vehicleOccupantGatePatch.restore = function()
    local p = lockOntoPlayers.vehicleOccupantGatePatch
    if not p.applied or not p.addr then p.applied = false; return end
    do
        for i = 1, #p.ORIG_BYTES do Memory.WriteByte(p.addr + (i - 1), p.ORIG_BYTES[i]) end
    end
    p.applied = false
end

lockOntoPlayers.lockOntoNPCs = {}
lockOntoPlayers.lockOntoNPCs.onTick = function(f)
    lockOntoPlayers.updatePedThreatGate()
    if f and f:IsToggled() then
        lockOntoPlayers.vehicleHomingFlagPatch.apply()
        lockOntoPlayers.vehicleOccupantGatePatch.apply()
    else
        lockOntoPlayers.vehicleHomingFlagPatch.restore()
        lockOntoPlayers.vehicleOccupantGatePatch.restore()
    end
end

lockOntoPlayers.onTick = function(f)
    local localPid = GTA.GetLocalPlayerId()
    if not f:IsToggled() then
        if next(lockOntoPlayers.added) then
            for p, ped in pairs(lockOntoPlayers.added) do
                lockOntoPlayers.removeTargetableEntity(localPid, ped)
                lockOntoPlayers.setTargetPriority(ped, false)
                lockOntoPlayers.iv(lockOntoPlayers.H_SET_ALLOW_LOCKON_IF_FRIENDLY, ped, false)
                lockOntoPlayers.iv(lockOntoPlayers.H_TREAT_AS_AMBIENT_FOR_DRIVER_LO, ped, false)
                lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                      lockOntoPlayers.PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS, false)
                lockOntoPlayers.restorePassiveBit(Players.GetCPed(p))
            end
            lockOntoPlayers.added = {}
        end
        if lockOntoPlayers.attackFriendlySet or lockOntoPlayers.localFriendlySet then
            local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(localPid)
            if myPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(myPed) then
                lockOntoPlayers.iv(lockOntoPlayers.H_SET_CAN_ATTACK_FRIENDLY, myPed, false, false)
                if lockOntoPlayers.localFriendlySet then
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, myPed,
                          lockOntoPlayers.PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS, false)
                end
            end
            lockOntoPlayers.attackFriendlySet = false
            lockOntoPlayers.localFriendlySet = false
        end
        lockOntoPlayers.nativePlayerLockPatch.restore()
        lockOntoPlayers.updatePedThreatGate()
        lockOntoPlayers.lockonSet = false
        return
    end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local myPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(localPid)
    if myPed == 0 or not ENTITY.DOES_ENTITY_EXIST(myPed) then return end

    lockOntoPlayers.nativePlayerLockPatch.apply()
    lockOntoPlayers.updatePedThreatGate()

    lockOntoPlayers.iv(lockOntoPlayers.H_SET_CAN_ATTACK_FRIENDLY, myPed, true, false)
    lockOntoPlayers.attackFriendlySet = true
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, myPed,
          lockOntoPlayers.PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS, true)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_RESET_FLAG, myPed,
          lockOntoPlayers.PRF_PREVENT_LOCKON_FRIENDLY, false)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_RESET_FLAG, myPed,
          lockOntoPlayers.PRF_DISABLE_MP_FRIENDLY_LOCKON, false)
    lockOntoPlayers.localFriendlySet = true

    if not lockOntoPlayers.lockonSet then
        lockOntoPlayers.iv(lockOntoPlayers.H_SET_PLAYER_LOCKON, localPid, true)
        lockOntoPlayers.iv(lockOntoPlayers.H_SET_PLAYER_LOCKON_RANGE_OVERRIDE, localPid, 400.0)
        lockOntoPlayers.iv(lockOntoPlayers.H_NETWORK_SET_FRIENDLY_FIRE_OPTION, true)
        lockOntoPlayers.lockonSet = true
    end

    local myPos = ENTITY.GET_ENTITY_COORDS(myPed, true)


    local maxDistSq = lockOntoPlayers.effectiveMaxDistSq()
    for p = 0, 31 do
        if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(p)
            if ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) then
                local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
                local dx, dy, dz = pos.x - myPos.x, pos.y - myPos.y, pos.z - myPos.z
                local within = (dx*dx + dy*dy + dz*dz < maxDistSq)
                if within and lockOntoPlayers.isPlayerInInterior(p, ped) then
                    within = false
                end
                if within then
                    lockOntoPlayers.addTargetableEntity(localPid, ped)
                    lockOntoPlayers.setTargetPriority(ped, true)

                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ALLOW_LOCKON_IF_FRIENDLY, ped, true)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CAN_BE_TARGETTED, ped, true)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CAN_BE_TARGETTED_BY_PLR, ped, localPid, true)
                    lockOntoPlayers.iv(lockOntoPlayers.H_TREAT_AS_AMBIENT_FOR_DRIVER_LO, ped, true)

                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS, true)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_PED_IS_ENEMY_TO_PLAYER, true)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_NEVER_EVER_TARGET, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_DISABLE_PLAYER_LOCKON, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_DISABLE_HOMING_MISSILE_LOCKON, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_TREAT_AS_FRIENDLY_TARGETING, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_TREAT_AS_FRIENDLY_NONSYNC, false)

                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_RESET_FLAG, ped,
                          lockOntoPlayers.PRF_PREVENT_LOCKON_FRIENDLY, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_RESET_FLAG, ped,
                          lockOntoPlayers.PRF_DISABLE_MP_FRIENDLY_LOCKON, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_RESET_FLAG, ped,
                          lockOntoPlayers.PRF_ALLOW_HOMING_IN_VEHICLE, true)

                    lockOntoPlayers.clearPassiveBit(Players.GetCPed(p))

                    local targetVeh = Natives.InvokeInt(
                        lockOntoPlayers.H_GET_VEHICLE_PED_IS_IN, ped, false)
                    if targetVeh and targetVeh ~= 0 then
                        lockOntoPlayers.patchTargetVehicle(targetVeh)
                    end

                    lockOntoPlayers.added[p] = ped
                elseif lockOntoPlayers.added[p] then
                    lockOntoPlayers.removeTargetableEntity(localPid, ped)
                    lockOntoPlayers.setTargetPriority(ped, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ALLOW_LOCKON_IF_FRIENDLY, ped, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_TREAT_AS_AMBIENT_FOR_DRIVER_LO, ped, false)
                    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
                          lockOntoPlayers.PCF_ALLOW_LOCKON_FRIENDLY_PLAYERS, false)
                    lockOntoPlayers.restorePassiveBit(Players.GetCPed(p))
                    lockOntoPlayers.added[p] = nil
                end
            elseif lockOntoPlayers.added[p] then
                lockOntoPlayers.removeTargetableEntity(localPid, lockOntoPlayers.added[p])
                lockOntoPlayers.setTargetPriority(lockOntoPlayers.added[p], false)
                lockOntoPlayers.restorePassiveBit(Players.GetCPed(p))
                lockOntoPlayers.added[p] = nil
            end
        end
    end
end



lockOntoPlayers.disableLOS = {
    firstTickLogged  = false,
    toggleOnLogged   = false,
    lastCountLog     = 0,
    lastVc           = -1,
    lastPc           = -1,
    pedCount         = 0,
    vehCount         = 0,
    flaggedPeds = {},
    flaggedVehs = {},
}

lockOntoPlayers.disableLOS.applyToPed = function(ped)
    if not ped or ped == 0 then return end
    lockOntoPlayers.iv(lockOntoPlayers.H_PED_CAN_BE_TARGETED_NO_LOS, ped, true)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ENTITY_CAN_BE_TARGETED_NOLOS, ped, true)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
          lockOntoPlayers.PCF_TARGETTABLE_WITH_NO_LOS, true)
end

lockOntoPlayers.disableLOS.applyToVehicle = function(veh)
    if not veh or veh == 0 then return end
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ENTITY_CAN_BE_TARGETED_NOLOS, veh, true)
end

lockOntoPlayers.disableLOS.removeFromPed = function(ped)
    if not ped or ped == 0 then return end
    lockOntoPlayers.iv(lockOntoPlayers.H_PED_CAN_BE_TARGETED_NO_LOS, ped, false)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ENTITY_CAN_BE_TARGETED_NOLOS, ped, false)
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_PED_CONFIG_FLAG, ped,
          lockOntoPlayers.PCF_TARGETTABLE_WITH_NO_LOS, false)
end

lockOntoPlayers.disableLOS.removeFromVehicle = function(veh)
    if not veh or veh == 0 then return end
    lockOntoPlayers.iv(lockOntoPlayers.H_SET_ENTITY_CAN_BE_TARGETED_NOLOS, veh, false)
end

lockOntoPlayers.disableLOS.onTick = function(f)
    local d = lockOntoPlayers.disableLOS
    if not d.firstTickLogged then
        d.firstTickLogged = true
    end
    if not f:IsToggled() then
        if d.toggleOnLogged then
            d.toggleOnLogged = false
            local rv, rp = 0, 0
            for pid, ped in pairs(d.flaggedPeds) do
                d.removeFromPed(ped)
                rp = rp + 1
            end
            for pid, veh in pairs(d.flaggedVehs) do
                d.removeFromVehicle(veh)
                rv = rv + 1
            end
            d.flaggedPeds = {}
            d.flaggedVehs = {}
            lockOntoPlayers.reticleDrawPatch.restore()
            lockOntoPlayers.occludedLockSoundPatch.restore()
        end
        return
    end
    if not isPlayerReady() then return end

    if not d.toggleOnLogged then
        d.toggleOnLogged = true
    end

    lockOntoPlayers.reticleDrawPatch.apply()
    lockOntoPlayers.occludedLockSoundPatch.apply()

    local vc, pc = 0, 0
    local localPid     = GTA.GetLocalPlayerId()
    local localPed     = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(localPid)
    local localVeh     = (localPed ~= 0 and PED.IS_PED_IN_ANY_VEHICLE(localPed, false))
                            and PED.GET_VEHICLE_PED_IS_IN(localPed, false) or 0

    do
        for pid = 0, 31 do
            if pid ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped ~= 0 and ped ~= localPed and ENTITY.DOES_ENTITY_EXIST(ped) then
                    if lockOntoPlayers.isPlayerInInterior(pid, ped) then
                        if d.flaggedPeds[pid] then
                            d.removeFromPed(ped)
                            d.flaggedPeds[pid] = nil
                        end
                        if d.flaggedVehs[pid] then
                            d.removeFromVehicle(d.flaggedVehs[pid])
                            d.flaggedVehs[pid] = nil
                        end
                    else
                    d.applyToPed(ped)
                    d.flaggedPeds[pid] = ped
                    pc = pc + 1
                    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                        if veh ~= 0 and veh ~= localVeh then
                            d.applyToVehicle(veh)
                            d.flaggedVehs[pid] = veh
                            vc = vc + 1
                        end
                    end
                    end
                end
            end
        end
    end

    d.vehCount = vc
    d.pedCount = pc

    local now = MISC.GET_GAME_TIMER()
    if vc ~= d.lastVc or pc ~= d.lastPc or (now - d.lastCountLog > 30000) then
        d.lastVc, d.lastPc = vc, pc
        d.lastCountLog = now
    end
end

local function enginePowerOnTick(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end
    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end
    local multF = FeatureMgr.GetFeature(H.ENGINE_POWER_MULT)
    local mult = (multF and multF:GetFloatValue()) or 1.0
    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(veh, mult * 10.0)
end

local function superDriveOnTick(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end
    if isGameChatOpen() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, true) then return end
    if not ENTITY.DOES_ENTITY_EXIST(ped) then return end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then return end

    local kbm = true
    do
        kbm = PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    end
    local gasAmount
    if kbm then
        if GUI.IsOpen() and (superDriveKey.vk == 0x01 or superDriveKey.vk == 0x02) then
            gasAmount = 0
        else
            gasAmount = isAnyKeyDown(superDriveKey.vk) and 1.0 or 0.0
        end
    elseif superDriveKey.controlId > 0 then
        local val = PAD.GET_DISABLED_CONTROL_NORMAL(0, superDriveKey.controlId)
        gasAmount = (val) or 0
    else
        gasAmount = 0
    end
    if gasAmount == 0 then return end

    local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
    local camFeature = FeatureMgr.GetFeature(H.SUPERDRIVE_CAM)
    if camFeature and camFeature:IsToggled() then
        local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
        forward = rotationToDirection(camRot)
    end
    if not forward then return end

    local force = speedMultiplier * gasAmount
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
        forward.x * force, forward.y * force, forward.z * force,
        true, false, true, true)
end


wheelie.onTick = function(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end
    if isGameChatOpen() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, true) then return end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then return end

    local model = ENTITY.GET_ENTITY_MODEL(veh)
    local isCar = Natives.InvokeBool(0x7F6DB52EEFC96DF8, model)
    if not isCar then return end

    local kbm = true
    do
        kbm = PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    end
    local amount
    if kbm then
        if GUI.IsOpen() and (wheelie.vk == 0x01 or wheelie.vk == 0x02) then
            amount = 0
        else
            amount = isAnyKeyDown(wheelie.vk) and 1.0 or 0.0
        end
    elseif wheelie.controlId > 0 then
        local val = PAD.GET_DISABLED_CONTROL_NORMAL(0, wheelie.controlId)
        amount = (val) or 0
    else
        amount = 0
    end
    if amount <= 0 then return end

    local force = (wheelie.strength) * amount * 0.05
    local arm = 2.5
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1,
        0.0, 0.0,  force,
        0.0,  arm, 0.0,
        0, true, true, true, false, true)
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1,
        0.0, 0.0, -force,
        0.0, -arm, 0.0,
        0, true, true, true, false, true)


end


local function gravityGunOnTick(f)
    if not f:IsToggled() then
        releaseGravTarget()
        grav.yeeted = 0
        return
    end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then
        releaseGravTarget()
        return
    end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)

    local inVehicle = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
    if inVehicle then
        local vehFeature = FeatureMgr.GetFeature(H.GRAV_IN_VEH)
        if not vehFeature or not vehFeature:IsToggled() then
            releaseGravTarget()
            return
        end
    end

    local aiming, attacking
    if inVehicle then
        aiming    = PAD.IS_CONTROL_PRESSED(0, INPUT.AIM)
                 or PAD.IS_CONTROL_PRESSED(0, INPUT.VEH_AIM)
                 or PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.AIM)
                 or PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.VEH_AIM)
        attacking = PAD.IS_CONTROL_JUST_PRESSED(0, INPUT.ATTACK)
                 or PAD.IS_CONTROL_JUST_PRESSED(0, INPUT.VEH_ATTACK)
                 or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, INPUT.ATTACK)
                 or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, INPUT.VEH_ATTACK)
    else
        aiming    = PAD.IS_CONTROL_PRESSED(0, INPUT.AIM)
        attacking = PAD.IS_CONTROL_JUST_PRESSED(0, INPUT.ATTACK)
    end

    if grav.target ~= 0 then
        if not ENTITY.DOES_ENTITY_EXIST(grav.target) then
            grav.target = 0
            return
        end

        if attacking then
            local hasControl = NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(grav.target)
            if not hasControl then
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(grav.target)
                hasControl = NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(grav.target)
            end

            local entPos = ENTITY.GET_ENTITY_COORDS(grav.target, true)
            local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
            local dir = rotationToDirection(camRot)
            local throwForce = 1000.0 * grav.forceMult

            local isVeh = ENTITY.IS_ENTITY_A_VEHICLE(grav.target)
            local isPed = ENTITY.IS_ENTITY_A_PED(grav.target)
            local entType = isVeh and "vehicle" or (isPed and "ped" or "object")


            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
                grav.target, 1,
                dir.x * throwForce, dir.y * throwForce, dir.z * throwForce,
                true, false, true, true)

            local throwSpeed = 500.0 * grav.forceMult
            ENTITY.SET_ENTITY_VELOCITY(grav.target,
                dir.x * throwSpeed, dir.y * throwSpeed, dir.z * throwSpeed)

            grav.yeeted = grav.target
            releaseGravTarget()
            return
        end

        PAD.DISABLE_CONTROL_ACTION(0, 14, true)
        PAD.DISABLE_CONTROL_ACTION(0, 15, true)
        PAD.DISABLE_CONTROL_ACTION(0, 16, true)
        PAD.DISABLE_CONTROL_ACTION(0, 37, true)
        PAD.DISABLE_CONTROL_ACTION(0, 44, true)
        PAD.DISABLE_CONTROL_ACTION(0, 45, true)
        PAD.DISABLE_CONTROL_ACTION(0, 46, true)
        PAD.DISABLE_CONTROL_ACTION(0, 99, true)
        PAD.DISABLE_CONTROL_ACTION(0, 100, true)
        PAD.DISABLE_CONTROL_ACTION(0, 241, true)
        PAD.DISABLE_CONTROL_ACTION(0, 242, true)
        if inVehicle then
            PAD.DISABLE_CONTROL_ACTION(0, INPUT.VEH_ATTACK, true)
            PAD.DISABLE_CONTROL_ACTION(0, INPUT.VEH_FLY_ATTACK, true)
        end

        if PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.CURSOR_SCROLL_UP) then
            grav.distance = grav.distance + 3.0
        end
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.CURSOR_SCROLL_DOWN) then
            grav.distance = math.max(2.0, grav.distance - 3.0)
        end

        if aiming then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(grav.target)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(grav.target) then return end

            local collisionFeature = FeatureMgr.GetFeature(H.GRAV_COLLISION)
            local keepCollision = collisionFeature and collisionFeature:IsToggled()

            if keepCollision then
                ENTITY.SET_ENTITY_COLLISION(grav.target, true, false)
            else
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(grav.target, false, false)
            end
            ENTITY.SET_ENTITY_HAS_GRAVITY(grav.target, false)

            local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
            local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
            local dir    = rotationToDirection(camRot)

            local desiredX = camPos.x + dir.x * grav.distance
            local desiredY = camPos.y + dir.y * grav.distance
            local desiredZ = camPos.z + dir.z * grav.distance

            local entPos = ENTITY.GET_ENTITY_COORDS(grav.target, true)
            local dx = desiredX - entPos.x
            local dy = desiredY - entPos.y
            local dz = desiredZ - entPos.z

            local contrivedF = FeatureMgr.GetFeature(H.GRAV_CONTRIVED)
            if contrivedF and contrivedF:IsToggled() then
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                if dist > 0.01 then
                    local step = (dist / 8.944) * grav.forceMult
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(grav.target,
                        entPos.x + (dx/dist) * step,
                        entPos.y + (dy/dist) * step,
                        entPos.z + (dz/dist) * step,
                        false, false, false)
                end
                ENTITY.SET_ENTITY_VELOCITY(grav.target, 0.0, 0.0, 0.0)
            else
                local speed = 3.0 * grav.forceMult
                ENTITY.SET_ENTITY_VELOCITY(grav.target,
                    dx * speed, dy * speed, dz * speed)
            end

            if Utils.IsKeyDown(grav.VK_E) then
                grav.spinning = true
                grav.spinAngle = (grav.spinAngle + 6.0) % 360.0
                ENTITY.SET_ENTITY_ROTATION(grav.target,
                    0.0, 0.0, grav.spinAngle, 2, true)
            else
                if grav.spinning then
                    grav.spinning = false
                end
            end
        else
            releaseGravTarget()
        end
    else
        if aiming then
            local hitEntity = 0

            if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(playerId, grav.buf) then
                hitEntity = Memory.ReadInt(grav.buf)
            end

            if hitEntity == 0 then
                local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
                local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
                local dir    = rotationToDirection(camRot)
                local endX = camPos.x + dir.x * grav.HITSCAN_RANGE
                local endY = camPos.y + dir.y * grav.HITSCAN_RANGE
                local endZ = camPos.z + dir.z * grav.HITSCAN_RANGE
                local excludeEntity = inVehicle
                    and PED.GET_VEHICLE_PED_IS_IN(ped, false) or ped
                local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
                    camPos.x, camPos.y, camPos.z, endX, endY, endZ,
                    14, excludeEntity, 7)
                SHAPETEST.GET_SHAPE_TEST_RESULT(handle,
                    grav.rayBuf, grav.rayBuf + 8, grav.rayBuf + 32, grav.rayBuf + 56)
                if Memory.ReadByte(grav.rayBuf) ~= 0 then
                    hitEntity = Memory.ReadInt(grav.rayBuf + 56)
                end
            end
            if hitEntity ~= 0 and ENTITY.DOES_ENTITY_EXIST(hitEntity) then
                if ENTITY.IS_ENTITY_A_PED(hitEntity) then
                    if PED.IS_PED_IN_ANY_VEHICLE(hitEntity, false) then
                        hitEntity = PED.GET_VEHICLE_PED_IS_IN(hitEntity, false)
                    end
                end

                if ENTITY.IS_ENTITY_A_PED(hitEntity) and PED.IS_PED_A_PLAYER(hitEntity) then
                    return
                end
                if ENTITY.IS_ENTITY_A_VEHICLE(hitEntity) then
                    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(hitEntity, -1, false)
                    if driver ~= 0 and driver == ped then return end
                end

                if hitEntity == grav.yeeted and ENTITY.DOES_ENTITY_EXIST(grav.yeeted) then
                    return
                end

                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(hitEntity)
                grav.target = hitEntity
                grav.distance = 10.0
                grav.spinAngle = 0.0
                local gType = ENTITY.IS_ENTITY_A_VEHICLE(hitEntity) and "vehicle"
                           or (ENTITY.IS_ENTITY_A_PED(hitEntity) and "ped" or "object")
            end
        else
            grav.yeeted = 0
        end
    end
end


driftState.MIN_SPEED = 2.0
driftState.MIN_ANGLE = 10.0
driftState.MAX_ANGLE = 90.0

local function drawDriftScore(score, alpha, best)
    local a = math.floor(math.max(0, math.min(1, alpha)) * 255)
    if a <= 0 then return end

    do
        HUD.SET_TEXT_FONT(4)
        HUD.SET_TEXT_SCALE(0.0, 0.6)
        HUD.SET_TEXT_COLOUR(255, 165, 0, a)
        HUD.SET_TEXT_CENTRE(true)
        HUD.SET_TEXT_OUTLINE()
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("DRIFT")
        HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.5, 0.30, 0)

        HUD.SET_TEXT_FONT(4)
        HUD.SET_TEXT_SCALE(0.0, 1.2)
        HUD.SET_TEXT_COLOUR(255, 220, 50, a)
        HUD.SET_TEXT_CENTRE(true)
        HUD.SET_TEXT_OUTLINE()
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(tostring(score))
        HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.5, 0.34, 0)

        if best > 0 then
            HUD.SET_TEXT_FONT(4)
            HUD.SET_TEXT_SCALE(0.0, 0.35)
            HUD.SET_TEXT_COLOUR(200, 200, 200, math.floor(a * 0.6))
            HUD.SET_TEXT_CENTRE(true)
            HUD.SET_TEXT_OUTLINE()
            HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
            HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("BEST: " .. tostring(math.floor(best)))
            HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.5, 0.40, 0)
        end
    end
end

local function driftResetPower()
    if driftState.lastVeh ~= 0 then
        do
            if ENTITY.DOES_ENTITY_EXIST(driftState.lastVeh) then
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(driftState.lastVeh, 1.0)
            end
        end
        driftState.lastVeh = 0
    end
end

local function driftAssistOnTick(f)
    if not f:IsToggled() then
        if driftState.active then
            driftState.active = false
            driftState.score = 0.0
        end
        driftResetPower()
        return
    end
    if not isPlayerReady() then return end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then return end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        if driftState.active then
            driftState.scoreShow = driftState.score
            driftState.scoreExpiry = os.clock() + 3.0
            if driftState.score > driftState.bestScore then driftState.bestScore = driftState.score end
            driftState.active = false
            driftState.score = 0.0
        end
        driftResetPower()
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end

    if driftState.lastVeh ~= veh then
        driftResetPower()
        driftState.lastVeh = veh
    end

    local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
    local vel = ENTITY.GET_ENTITY_VELOCITY(veh)

    local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y)

    local scoreFeature = FeatureMgr.GetFeature(H.DRIFT_SCORE)
    if scoreFeature and scoreFeature:IsToggled() then
        if driftState.active and driftState.score > 0 then
            drawDriftScore(math.floor(driftState.score), 1.0, driftState.bestScore)
        elseif driftState.scoreShow > 0 and os.clock() < driftState.scoreExpiry then
            local fade = (driftState.scoreExpiry - os.clock()) / 3.0
            drawDriftScore(math.floor(driftState.scoreShow), fade, driftState.bestScore)
        end
    end

    if speed < driftState.MIN_SPEED then
        if driftState.active then
            driftState.scoreShow = driftState.score
            driftState.scoreExpiry = os.clock() + 3.0
            if driftState.score > driftState.bestScore then driftState.bestScore = driftState.score end
            driftState.active = false
            driftState.score = 0.0
        end
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(veh, 1.0)
        return
    end

    local velNX = vel.x / speed
    local velNY = vel.y / speed
    local dot = math.max(-1.0, math.min(1.0, fwd.x * velNX + fwd.y * velNY))
    local slipAngle = math.deg(math.acos(dot))

    local cross = fwd.x * velNY - fwd.y * velNX

    if slipAngle >= driftState.MIN_ANGLE and slipAngle < driftState.MAX_ANGLE then
        driftState.active = true
        driftState.score = driftState.score + slipAngle * speed * 0.01

        if not ENTITY.IS_ENTITY_IN_AIR(veh) then
            local basePower = driftState.powerMult

            local angleFactor = math.min((slipAngle - driftState.MIN_ANGLE)
                / (driftState.MAX_ANGLE - driftState.MIN_ANGLE), 1.0)

            local speedFeedback = math.max(1.0 - (speed - 20.0) / 20.0, 0.0)

            local torqueMult = 1.0 + (basePower * angleFactor * speedFeedback)
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(veh, torqueMult)
        end

        if not ENTITY.IS_ENTITY_IN_AIR(veh) then
            local rightX = fwd.y
            local rightY = -fwd.x
            local slideDir = cross < 0 and 1.0 or -1.0
            local traction = driftState.tractionMult
            local speedFactor = math.min(speed / 25.0, 1.0)
            local force = driftState.forceMult
            local fwdForce = traction * 0.25 * speedFactor * force
            local latForce = traction * 0.15 * speedFactor * force

            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
                fwd.x * fwdForce + rightX * latForce * slideDir,
                fwd.y * fwdForce + rightY * latForce * slideDir,
                0.0,
                true, false, true, true)
        end

        driftState.smokeTick = driftState.smokeTick + 1
        local smokeFeature = FeatureMgr.GetFeature(H.DRIFT_SMOKE)
        if smokeFeature and smokeFeature:IsToggled() and driftState.smokeTick % 4 == 0 then
            do
                if not driftState.ptfxReady then
                    STREAMING.REQUEST_NAMED_PTFX_ASSET("core")
                    if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") then
                        driftState.ptfxReady = true
                    end
                end
                if driftState.ptfxReady then
                    local vehCoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                    local rearX = vehCoords.x - fwd.x * 2.5
                    local rearY = vehCoords.y - fwd.y * 2.5
                    local rearZ = vehCoords.z - 0.5
                    GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                    GRAPHICS.START_PARTICLE_FX_NON_LOOPED_AT_COORD(
                        "veh_burnout_tyre", rearX, rearY, rearZ,
                        0.0, 0.0, 0.0, 0.8, false, false, false)
                end
            end
        end
    else
        if driftState.active then
            driftState.scoreShow = driftState.score
            driftState.scoreExpiry = os.clock() + 3.0
            if driftState.score > driftState.bestScore then driftState.bestScore = driftState.score end

            local boostFeature = FeatureMgr.GetFeature(H.DRIFT_EXIT_BOOST)
            if boostFeature and boostFeature:IsToggled() and driftState.score > 10 then
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
                    fwd.x * 3.0, fwd.y * 3.0, 0.0,
                    true, false, true, true)
            end

            driftState.active = false
            driftState.score = 0.0
            driftState.smokeTick = 0
        end
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(veh, 1.0)
    end
end


local function vehicleGunDeleteEntity(handle)
    if not ENTITY.DOES_ENTITY_EXIST(handle) then return end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(handle)
    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(handle) then
        NETWORK.NETWORK_UNREGISTER_NETWORKED_ENTITY(handle)
    end
    Memory.WriteInt(vehGun.delBuf, handle)
    ENTITY.DELETE_ENTITY(vehGun.delBuf)
    if ENTITY.DOES_ENTITY_EXIST(handle) then
        Memory.WriteInt(vehGun.delBuf, handle)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(vehGun.delBuf)
    end
end

local function vehicleGunReleaseModel(hash)
    if hash == 0 then return end
    if hash == vehGun.modelHash then return end
    for _, entry in ipairs(vehGun.pool) do
        if entry.modelHash == hash then return end
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end

local function vehicleGunNetRegister(veh)
    NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(veh)
    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then return true end

    for i, entry in ipairs(vehGun.pool) do
        if entry.networked then
            vehicleGunDeleteEntity(entry.handle)
            local entryHash = entry.modelHash or 0
            table.remove(vehGun.pool, i)
            vehicleGunReleaseModel(entryHash)

            NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(veh)
            if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
                return true
            end
            break
        end
    end

    Logger.Log(eLogColor.YELLOW,
        "[VibeScript] VehGun: net registration FAILED"
        .. " (ours=" .. #vehGun.pool
        .. ", netMax=" .. NETWORK.GET_MAX_NUM_NETWORK_VEHICLES() .. ")")
    return false
end

local function vehicleGunCleanupExpired()
    local now = Time.GetEpocheMs()
    local ped = PLAYER.PLAYER_PED_ID()
    local i = 1
    while i <= #vehGun.pool do
        local entry = vehGun.pool[i]
        local exists = ENTITY.DOES_ENTITY_EXIST(entry.handle)

        if not exists or (now - entry.spawnTime > vehGun.TIMEOUT) then
            if exists then vehicleGunDeleteEntity(entry.handle) end
            local entryHash = entry.modelHash or 0
            table.remove(vehGun.pool, i)
            vehicleGunReleaseModel(entryHash)
        else
            if now < entry.noCollisionUntil then
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(entry.handle, ped, false)
            end
            i = i + 1
        end
    end

    if #vehGun.pool > 0 and (now - (vehGun.lastPoolLogTime or 0)) > 12000 then
        local netCount = 0
        for _, e in ipairs(vehGun.pool) do
            if e.networked then netCount = netCount + 1 end
        end
        local localCount = #vehGun.pool - netCount
        if localCount > 0 then
            local msg = "[VibeScript] VehGun pool: " .. netCount .. " networked, "
                .. localCount .. " local-only (invisible to others)"
            if msg ~= vehGun.lastPoolLogMsg then
                Logger.Log(eLogColor.YELLOW, msg)
                vehGun.lastPoolLogMsg = msg
            end
        end
        vehGun.lastPoolLogTime = now
    end
end

local function vehicleGunCleanupAll()
    local hashes = {}
    for _, entry in ipairs(vehGun.pool) do
        if entry.modelHash and entry.modelHash ~= 0 then
            hashes[entry.modelHash] = true
        end
        if ENTITY.DOES_ENTITY_EXIST(entry.handle) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entry.handle)
            Memory.WriteInt(vehGun.delBuf, entry.handle)
            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(vehGun.delBuf)
        end
    end
    vehGun.pool = {}
    for hash, _ in pairs(hashes) do
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    end
    if vehGun.modelHash ~= 0 then
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehGun.modelHash)
    end
end

local function vehicleGunOnTick(f)
    if not f:IsToggled() then
        if #vehGun.pool > 0 then vehicleGunCleanupAll() end
        vehGun.lastClipAmmo = nil
        vehGun.lastWeaponHash = 0
        return
    end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        local vehFeature = FeatureMgr.GetFeature(H.VEH_GUN_IN_VEH)
        if not vehFeature or not vehFeature:IsToggled() then return end
    end
    if not isPlayerReady() then return end

    local ped = PLAYER.PLAYER_PED_ID()

    vehicleGunCleanupExpired()

    local randomFeat = FeatureMgr.GetFeature(H.VEH_GUN_RANDOM)
    local isRandom = randomFeat and randomFeat:IsToggled()

    if isRandom then
        if not vehGun.randomReady then
            local pool = {}
            for _, v in ipairs(randomPool.land) do pool[#pool + 1] = v end
            local airFeat = FeatureMgr.GetFeature(H.VEH_GUN_RAND_AIR)
            if airFeat and airFeat:IsToggled() then
                for _, v in ipairs(randomPool.air) do pool[#pool + 1] = v end
            end
            local seaFeat = FeatureMgr.GetFeature(H.VEH_GUN_RAND_SEA)
            if seaFeat and seaFeat:IsToggled() then
                for _, v in ipairs(randomPool.sea) do pool[#pool + 1] = v end
            end

            local name = pool[math.random(1, #pool)]
            vehGun.modelName = name
            vehGun.modelHash = Utils.Joaat(name)
            vehGun.randomReady = true
        end
    else
        local cls = VEH_CLASSES[vehGun.classIdx]
        if cls then
            local name = cls.vehicles[vehGun.vehIdx]
            if name and name ~= vehGun.modelName then
                local oldHash = vehGun.modelHash
                vehGun.modelName = name
                vehGun.modelHash = Utils.Joaat(name)
                vehicleGunReleaseModel(oldHash)
            end
        end
    end

    if vehGun.modelHash == 0 then
        vehGun.modelHash = Utils.Joaat(vehGun.modelName)
    end

    if not STREAMING.IS_MODEL_VALID(vehGun.modelHash) then
        if isRandom then
            Logger.Log(eLogColor.YELLOW, "[VibeScript] VehGun: model " .. vehGun.modelName .. " invalid, re-picking")
            vehGun.randomReady = false
            vehGun.modelRequestStart = 0
        end
        return
    end

    STREAMING.REQUEST_MODEL(vehGun.modelHash)
    if not STREAMING.HAS_MODEL_LOADED(vehGun.modelHash) then
        local now = Time.GetEpocheMs()
        if vehGun.modelRequestStart == 0 then
            vehGun.modelRequestStart = now
        elseif isRandom and (now - vehGun.modelRequestStart > vehGun.MODEL_LOAD_TIMEOUT) then
            Logger.Log(eLogColor.YELLOW,
                "[VibeScript] VehGun: model " .. vehGun.modelName .. " load timeout ("
                .. vehGun.MODEL_LOAD_TIMEOUT .. "ms), re-picking")
            vehGun.randomReady = false
            vehGun.modelRequestStart = 0
        end
        return
    end
    vehGun.modelRequestStart = 0

    local weaponHash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
    local bulletsFired = 0

    if weaponHash ~= 0 then
        local weaponGroup = WEAPON.GET_WEAPONTYPE_GROUP(weaponHash)
        if weaponGroup == weaponState.GROUP_THROWN then return end
    end

    if weaponHash ~= 0 then
        if weaponHash ~= vehGun.lastWeaponHash then
            vehGun.lastClipAmmo = nil
            vehGun.lastWeaponHash = weaponHash
            return
        end

        Memory.WriteInt(vehGun.ammoBuf, 0)
        local gotAmmo = WEAPON.GET_AMMO_IN_CLIP(ped, weaponHash, vehGun.ammoBuf)
        if gotAmmo then
            local clipAmmo = Memory.ReadInt(vehGun.ammoBuf)
            if vehGun.lastClipAmmo ~= nil and clipAmmo < vehGun.lastClipAmmo then
                bulletsFired = vehGun.lastClipAmmo - clipAmmo
            end
            vehGun.lastClipAmmo = clipAmmo
        end
    end

    if bulletsFired == 0 and PED.IS_PED_SHOOTING(ped) then
        local now = Time.GetEpocheMs()
        if now - vehGun.lastSpawnTime >= vehGun.SPAWN_INTERVAL then
            bulletsFired = 1
            vehGun.lastSpawnTime = now
        end
    end

    if bulletsFired == 0 then return end

    if bulletsFired > 3 then bulletsFired = 3 end

    local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
    local camRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
    local dir = rotationToDirection(camRot)

    local speed = 200.0
    local dist = 10.0
    local speedFeat = FeatureMgr.GetFeature(H.VEH_GUN_SPEED)
    if speedFeat then speed = speedFeat:GetFloatValue() end
    local distFeat = FeatureMgr.GetFeature(H.VEH_GUN_DIST)
    if distFeat then dist = distFeat:GetFloatValue() end

    local heading = -camRot.z
    local now = Time.GetEpocheMs()

    while #vehGun.pool >= vehGun.MAX do
        local oldest = table.remove(vehGun.pool, 1)
        if oldest then
            vehicleGunDeleteEntity(oldest.handle)
            vehicleGunReleaseModel(oldest.modelHash or 0)
        end
    end

    local HEADROOM = 10
    local gameVehCount = PoolMgr.GetCurrentVehicleCount()
    local gameVehMax = PoolMgr.GetMaxVehicleCount()
    while #vehGun.pool > 0 and (gameVehMax - gameVehCount) < HEADROOM do
        local oldest = table.remove(vehGun.pool, 1)
        if oldest then
            vehicleGunDeleteEntity(oldest.handle)
            vehicleGunReleaseModel(oldest.modelHash or 0)
        end
        gameVehCount = gameVehCount - 1
    end

    for _ = 1, bulletsFired do
        local spawnX = camPos.x + dir.x * dist
        local spawnY = camPos.y + dir.y * dist
        local spawnZ = camPos.z + dir.z * dist

        local veh = VEHICLE.CREATE_VEHICLE(
            vehGun.modelHash, spawnX, spawnY, spawnZ,
            heading, false, false, false)

        if veh and veh ~= 0 then
            local isNet = vehicleGunNetRegister(veh)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, spawnX, spawnY, spawnZ, false, false, false)
            ENTITY.SET_ENTITY_ROTATION(veh, camRot.x, 0.0, camRot.z, 2, true)
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(veh, ped, false)

            table.insert(vehGun.pool, {
                handle = veh,
                modelHash = vehGun.modelHash,
                networked = isNet,
                spawnTime = now,
                noCollisionUntil = now + vehGun.NOCOL_DURATION,
            })

            vehGun.spawnFailCount = 0
            vehGun.randomReady = false
        else
            local evicted = 0
            while #vehGun.pool > 0 and evicted < 5 do
                local oldest = table.remove(vehGun.pool, 1)
                if oldest then
                    vehicleGunDeleteEntity(oldest.handle)
                    vehicleGunReleaseModel(oldest.modelHash or 0)
                    evicted = evicted + 1
                end
            end

            if evicted > 0 then
                veh = VEHICLE.CREATE_VEHICLE(
                    vehGun.modelHash, spawnX, spawnY, spawnZ,
                    heading, false, false, false)

                if veh and veh ~= 0 then
                    local isNet = vehicleGunNetRegister(veh)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, spawnX, spawnY, spawnZ, false, false, false)
                    ENTITY.SET_ENTITY_ROTATION(veh, camRot.x, 0.0, camRot.z, 2, true)
                    VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(veh, ped, false)

                    table.insert(vehGun.pool, {
                        handle = veh,
                        modelHash = vehGun.modelHash,
                        networked = isNet,
                        spawnTime = now,
                        noCollisionUntil = now + vehGun.NOCOL_DURATION,
                    })

                    vehGun.spawnFailCount = 0
                    vehGun.randomReady = false
                    Logger.Log(eLogColor.YELLOW,
                        "[VibeScript] VehGun: spawn recovered after evicting " .. evicted)
                else
                    vehGun.spawnFailCount = vehGun.spawnFailCount + 1
                    local gc = PoolMgr.GetCurrentVehicleCount()
                    local gm = PoolMgr.GetMaxVehicleCount()
                    Logger.Log(eLogColor.YELLOW,
                        "[VibeScript] VehGun: spawn failed for " .. vehGun.modelName
                        .. " after evicting " .. evicted
                        .. " (ours=" .. #vehGun.pool
                        .. ", game=" .. gc .. "/" .. gm
                        .. ", netMax=" .. NETWORK.GET_MAX_NUM_NETWORK_VEHICLES() .. ")")
                    if isRandom and vehGun.spawnFailCount >= 3 then
                        vehGun.randomReady = false
                        vehGun.spawnFailCount = 0
                    end
                end
            else
                Logger.Log(eLogColor.YELLOW,
                    "[VibeScript] VehGun: spawn failed, no vehicles to evict"
                    .. " (game=" .. PoolMgr.GetCurrentVehicleCount()
                    .. "/" .. PoolMgr.GetMaxVehicleCount() .. ")")
            end
            break
        end
    end
end

local playerState = {
    vehGunTarget    = {},
    blackIceLastSent = {},
    phantomBrake    = {},
    steerInvert     = {},
    watchYoJetPending = {},
    wyjtSpawnerHash = Utils.Joaat("LUA_WYJTSpawner"),
    pauseTarget     = {},
    passivePending = {},
    passiveRunnerHash = Utils.Joaat("LUA_RemovePassiveRunner"),
    stripVehGodJob = nil,
    enterInteriorPending = {},
    kickInteriorPending = {},
    chimpSwarmPending = {},
    chimpSpawnerHash = Utils.Joaat("LUA_ChimpSwarmSpawner"),
    takeoverPending   = {},
    takeover          = nil,
    joinCeoActivePid = -1,
    joinCeoState    = nil,
    joinCeoPrev     = {},
}

playerState.speed = {
    last = {},
    done = {},
    attempt = {},
    cooldown = {},
    sync = { pid = nil, owned = false },
    ATTEMPT_TIMEOUT_MS = 6000,
    COOLDOWN_MS = 5000,
}

function playerState.speed.spectateFeat(pid)
    return FeatureMgr.GetFeatureByName("Spectate Player", pid)
end

function playerState.speed.forceSync(pid)
    local s = playerState.speed.sync
    if s.pid ~= nil then return end

    local feat = playerState.speed.spectateFeat(pid)
    if not feat then return end

    s.pid = pid
    s.owned = not feat:GetBoolValue()
    if s.owned then feat:SetValue(true):TriggerCallback() end
end

function playerState.speed.stopSync()
    local s = playerState.speed.sync
    if s.pid == nil then return end
    if s.owned then
        local feat = playerState.speed.spectateFeat(s.pid)
        if feat then feat:SetValue(false):TriggerCallback() end
    end
    s.pid, s.owned = nil, false
end

function playerState.speed.stopSyncFor(pid)
    if playerState.speed.sync.pid == pid then playerState.speed.stopSync() end
end

function playerState.speed.selfMult()
    local feat = FeatureMgr.GetFeature(H.ENGINE_POWER_MULT)
    if feat then return feat:GetFloatValue() end
    return 1.0
end

function playerState.speed.getTargetVehicle(pid)
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return 0 end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return 0 end
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return 0 end
    return PED.GET_VEHICLE_PED_IS_IN(ped, false)
end

function playerState.speed.requestControl(veh)
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then return true end

    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
        local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
        local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
        local me = Players.GetById(GTA.GetLocalPlayerId())
        if netObj and me then NetworkObjectMgr.ChangeOwner(netObj, me, 0) end
        Natives.InvokeBool(0xA670B3662FAFFBD0, netId)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh)
end

function playerState.speed.apply(pid, mult)
    if not mult then mult = 1.0 end
    mult = math.max(1.0, math.min(mult, 20.0))

    local now = Time.GetEpocheMs()

    local doneMult = playerState.speed.done[pid]
    if doneMult and math.abs(doneMult - mult) <= 0.001 then
        playerState.speed.stopSyncFor(pid)
        return true
    end

    local cd = playerState.speed.cooldown[pid]
    if cd and now < cd then return false end

    local deadline = playerState.speed.attempt[pid]
    if not deadline then
        deadline = now + playerState.speed.ATTEMPT_TIMEOUT_MS
        playerState.speed.attempt[pid] = deadline
    end
    if now >= deadline then
        playerState.speed.attempt[pid] = nil
        playerState.speed.cooldown[pid] = now + playerState.speed.COOLDOWN_MS
        playerState.speed.stopSyncFor(pid)
        return false
    end

    local veh = playerState.speed.getTargetVehicle(pid)
    if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then
        if PLAYER.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
            playerState.speed.forceSync(pid)
        end
        return false
    end

    if not playerState.speed.requestControl(veh) then
        return false
    end

    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(veh, mult * 10.0)
    playerState.speed.last[pid] = { veh = veh, mult = mult }
    playerState.speed.done[pid] = mult
    playerState.speed.attempt[pid] = nil
    playerState.speed.stopSyncFor(pid)
    return true
end

function playerState.speed.restore(pid)
    playerState.speed.done[pid] = nil
    playerState.speed.cooldown[pid] = nil
    playerState.speed.attempt[pid] = nil
    playerState.speed.stopSyncFor(pid)

    local last = playerState.speed.last[pid]
    if not last then return true end

    if not last.veh or last.veh == 0 or not ENTITY.DOES_ENTITY_EXIST(last.veh) then
        playerState.speed.last[pid] = nil
        return true
    end

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(last.veh) then
        VEHICLE.MODIFY_VEHICLE_TOP_SPEED(last.veh, 10.0)
    end
    playerState.speed.last[pid] = nil
    return true
end

function playerState.speed.restoreAll()
    for pid, _ in pairs(playerState.speed.last) do
        playerState.speed.restore(pid)
    end
    playerState.speed.stopSync()
end

function playerState.speed.syncSlider(pid)
    local speedFeat = FeatureMgr.GetFeature(H.PLAYER_SPEED_MULT, pid)
    if not speedFeat then return playerState.speed.selfMult() end

    local mult = playerState.speed.selfMult()
    if math.abs(speedFeat:GetFloatValue() - mult) > 0.001 then
        speedFeat:SetFloatValue(mult)
    end
    return mult
end

local VGT_MODEL_ROTATE_MS = 3000

vehGun.getRemoteAimDir = function(ped)
    vehGun.lastAimSrc = "none"
    local wObj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped, 0)
    if not wObj or wObj == 0 or not ENTITY.DOES_ENTITY_EXIST(wObj) then return nil end

    local mdir, muzzlePos
    local idx = -1
    for _, name in ipairs(vehGun.MUZZLE_BONES) do
        idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wObj, name)
        if idx and idx ~= -1 then break end
    end
    if idx and idx ~= -1 then
        local muzzle = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(wObj, idx)
        local base = ENTITY.GET_ENTITY_COORDS(wObj, true)
        local d, len = directionBetween(base, muzzle)
        if len >= 0.03 then mdir = d; muzzlePos = muzzle end
    end
    if not mdir then return nil end

    local buf = vehGun.matrixBuf
    ENTITY.GET_ENTITY_MATRIX(wObj, buf, buf + 24, buf + 48, buf + 72)
    local best, bestDot
    for _, off in ipairs({ 0, 24, 48 }) do
        local ax = Memory.ReadFloat(buf + off)
        local ay = Memory.ReadFloat(buf + off + 8)
        local az = Memory.ReadFloat(buf + off + 16)
        local dot = ax * mdir.x + ay * mdir.y + az * mdir.z
        local adot = dot < 0 and -dot or dot
        if not bestDot or adot > bestDot then
            bestDot = adot
            if dot < 0 then best = { x = -ax, y = -ay, z = -az }
            else best = { x = ax, y = ay, z = az } end
        end
    end
    vehGun.lastAimDot = bestDot or 0.0
    if best and bestDot and bestDot > 0.7 then
        vehGun.lastAimSrc = "matrix"
        return best, muzzlePos
    end
    vehGun.lastAimSrc = "muzzle"
    return mdir, muzzlePos
end

local function vehGunTargetOnTick(f)
    telemetryCountToggleEdge("VehicleGunTarget", f:GetPlayerIndex(), f:IsToggled())
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end

    local pid = f:GetPlayerIndex()
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if targetPed == 0 or not ENTITY.DOES_ENTITY_EXIST(targetPed) then return end

    local now = Time.GetEpocheMs()
    local state = playerState.vehGunTarget[pid]
    if not state then
        state = { lastSpawnTime = 0, modelHash = 0, modelName = "",
                  modelRequestStart = 0, lastModelSwap = 0, cachedPitch = 0 }
        playerState.vehGunTarget[pid] = state
    end

    local pedPos = ENTITY.GET_ENTITY_COORDS(targetPed, true)


    Memory.WriteInt(autoLockBuf, 0)
    if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(pid, autoLockBuf) then
        local aimEnt = Memory.ReadInt(autoLockBuf)
        if aimEnt ~= 0 and ENTITY.DOES_ENTITY_EXIST(aimEnt) then
            local aimPos = ENTITY.GET_ENTITY_COORDS(aimEnt, true)
            local dx = aimPos.x - pedPos.x
            local dy = aimPos.y - pedPos.y
            local dz = aimPos.z - pedPos.z
            local hLen = math.sqrt(dx * dx + dy * dy)
            if hLen > 1.0 then
                state.cachedPitch = math.deg(math.atan(dz, hLen))
            end
        end
    end

    if not PED.IS_PED_SHOOTING(targetPed) then return end

    if now - state.lastSpawnTime < vehGun.SPAWN_INTERVAL then return end
    state.lastSpawnTime = now

    if state.modelHash == 0 or now - state.lastModelSwap > VGT_MODEL_ROTATE_MS then
        local name = randomPool.all[math.random(1, #randomPool.all)]
        state.modelName = name
        state.modelHash = Utils.Joaat(name)
        state.modelRequestStart = 0
        state.lastModelSwap = now
    end

    STREAMING.REQUEST_MODEL(state.modelHash)
    if not STREAMING.HAS_MODEL_LOADED(state.modelHash) then
        if state.modelRequestStart == 0 then
            state.modelRequestStart = now
        elseif now - state.modelRequestStart > 5000 then
            local name = randomPool.all[math.random(1, #randomPool.all)]
            state.modelName = name
            state.modelHash = Utils.Joaat(name)
            state.modelRequestStart = 0
            state.lastModelSwap = now
        end
        return
    end
    if not STREAMING.IS_MODEL_VALID(state.modelHash) then
        state.lastModelSwap = 0
        return
    end
    state.modelRequestStart = 0

    local rotX, rotZ, dir
    local origin
    local aimDir, muzzlePos = vehGun.getRemoteAimDir(targetPed)
    if aimDir then
        origin = muzzlePos
        local dz = math.max(-1.0, math.min(1.0, aimDir.z))
        rotX = math.deg(math.asin(dz))
        rotZ = ENTITY.GET_ENTITY_ROTATION(targetPed, 2).z
        dir = rotationToDirection({ x = rotX, z = rotZ })
    else
        local pedRot = ENTITY.GET_ENTITY_ROTATION(targetPed, 2)
        rotZ = pedRot.z
        rotX = state.cachedPitch
        dir = rotationToDirection({ x = rotX, z = rotZ })
    end

    if now - (vehGun.lastAimDiagTime or 0) > 1000 then
        vehGun.lastAimDiagTime = now
        Logger.Log(eLogColor.YELLOW, string.format(
            "[VibeScript][VGTaim] src=%s dot=%.3f pitch=%.1f yaw=%.1f(body)",
            vehGun.lastAimSrc or "?", vehGun.lastAimDot or 0.0, rotX, rotZ))
    end

    local speed = 200.0
    local dist = 10.0
    local speedFeat = FeatureMgr.GetFeature(H.VEH_GUN_SPEED)
    if speedFeat then speed = speedFeat:GetFloatValue() end
    local distFeat = FeatureMgr.GetFeature(H.VEH_GUN_DIST)
    if distFeat then dist = distFeat:GetFloatValue() end

    while #vehGun.pool >= vehGun.MAX do
        local oldest = table.remove(vehGun.pool, 1)
        if oldest then
            vehicleGunDeleteEntity(oldest.handle)
            vehicleGunReleaseModel(oldest.modelHash or 0)
        end
    end

    local HEADROOM = 10
    local gameVehCount = PoolMgr.GetCurrentVehicleCount()
    local gameVehMax = PoolMgr.GetMaxVehicleCount()
    while #vehGun.pool > 0 and (gameVehMax - gameVehCount) < HEADROOM do
        local oldest = table.remove(vehGun.pool, 1)
        if oldest then
            vehicleGunDeleteEntity(oldest.handle)
            vehicleGunReleaseModel(oldest.modelHash or 0)
        end
        gameVehCount = gameVehCount - 1
    end

    local ox = origin and origin.x or pedPos.x
    local oy = origin and origin.y or pedPos.y
    local oz = origin and origin.z or (pedPos.z + 0.5)
    local spawnX = ox + dir.x * dist
    local spawnY = oy + dir.y * dist
    local spawnZ = oz + dir.z * dist

    local heading = -rotZ
    local useHash = state.modelHash
    local veh = VEHICLE.CREATE_VEHICLE(
        useHash, spawnX, spawnY, spawnZ,
        heading, false, false, false)

    if veh and veh ~= 0 then
        local isNet = vehicleGunNetRegister(veh)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, spawnX, spawnY, spawnZ, false, false, false)
        ENTITY.SET_ENTITY_ROTATION(veh, rotX, 0.0, rotZ, 2, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(veh, targetPed, false)

        table.insert(vehGun.pool, {
            handle = veh,
            modelHash = useHash,
            networked = isNet,
            spawnTime = now,
            noCollisionUntil = now + vehGun.NOCOL_DURATION,
        })
    else
        local evicted = 0
        while #vehGun.pool > 0 and evicted < 5 do
            local oldest = table.remove(vehGun.pool, 1)
            if oldest then
                vehicleGunDeleteEntity(oldest.handle)
                vehicleGunReleaseModel(oldest.modelHash or 0)
                evicted = evicted + 1
            end
        end
        if evicted > 0 then
            veh = VEHICLE.CREATE_VEHICLE(
                useHash, spawnX, spawnY, spawnZ,
                heading, false, false, false)
            if veh and veh ~= 0 then
                local isNet = vehicleGunNetRegister(veh)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, spawnX, spawnY, spawnZ, false, false, false)
                ENTITY.SET_ENTITY_ROTATION(veh, rotX, 0.0, rotZ, 2, true)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(veh, targetPed, false)

                table.insert(vehGun.pool, {
                    handle = veh,
                    modelHash = useHash,
                    networked = isNet,
                    spawnTime = now,
                    noCollisionUntil = now + vehGun.NOCOL_DURATION,
                })
            end
        end
    end
end


local function superMeleeLaunchPed(ped, playerPos, mult)
    local entPos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local dx = entPos.x - playerPos.x
    local dy = entPos.y - playerPos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then len = 1 end
    dx = dx / len
    dy = dy / len

    local force = mult * 25.0
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(ped, 1,
        dx * force, dy * force, -1.0,
        true, false, true, true)

    WEAPON.CLEAR_ENTITY_LAST_WEAPON_DAMAGE(ped)
    ENTITY.CLEAR_ENTITY_LAST_DAMAGE_ENTITY(ped)
end

local function superMeleeOnTick(f)
    local mult = f:GetIntValue()
    if mult <= 0 then
        if weaponState.superMeleeActive then
            PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER(
                GTA.GetLocalPlayerId(), 1.0, true)
            weaponState.superMeleeActive = false
        end
        return
    end
    if not isPlayerReady() then return end

    PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER(
        GTA.GetLocalPlayerId(), mult * 100.0, true)
    weaponState.superMeleeActive = true

    local ped = PLAYER.PLAYER_PED_ID()
    local playerPos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local meleeTarget = PED.GET_MELEE_TARGET_FOR_PED(ped)
    if meleeTarget and meleeTarget ~= 0 and ENTITY.DOES_ENTITY_EXIST(meleeTarget)
    and not ENTITY.IS_ENTITY_A_VEHICLE(meleeTarget)
    and not PED.IS_PED_A_PLAYER(meleeTarget) then
        if WEAPON.HAS_ENTITY_BEEN_DAMAGED_BY_WEAPON(meleeTarget, 0, 1)
        and ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(meleeTarget, ped, true) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(meleeTarget)
            superMeleeLaunchPed(meleeTarget, playerPos, mult)
        end
    end
end

local chimpFn = {}
do
    local chimpSwarm = {
        pool = {},
        MAX = 50,
        TTL = 60000,
        CLEANUP_DIST_SQ = 200.0 * 200.0,
        modelHash = Utils.Joaat("a_c_chimp"),
        wrenchHash = Utils.Joaat("WEAPON_WRENCH"),
        groupHash = Utils.Joaat("ARMY"),
        groupInit = false,
        delBuf = Memory.Alloc(4),
        zBuf = Memory.Alloc(4),
        focusSet = false,
        spawnQueue = {},
        SPAWN_SPREAD_MS = 800,
        MAX_SPAWN_PER_TICK = 2,
        ARM_DELAY_MS = 50,
        modelHeld = false,
    }

    local function releaseAll()
        for i = #chimpSwarm.pool, 1, -1 do
            local h = chimpSwarm.pool[i].handle
            if ENTITY.DOES_ENTITY_EXIST(h) then
                Memory.WriteInt(chimpSwarm.delBuf, h)
                ENTITY.DELETE_ENTITY(chimpSwarm.delBuf)
            end
            chimpSwarm.pool[i] = nil
        end
    end

    local function invokeVoidByHash(shim, hash, ...)
        if shim then return shim(...) end
        if Natives and Natives.InvokeVoid then
            return Natives.InvokeVoid(hash, ...)
        end
    end
    local function invokeBoolByHash(shim, hash, ...)
        if shim then return shim(...) end
        if Natives and Natives.InvokeBool then
            return Natives.InvokeBool(hash, ...)
        end
        return false
    end

    local N_SET_RELATIONSHIP_BETWEEN_GROUPS = 0xBF25EB89375A37AD
    local N_SET_PED_RELATIONSHIP_GROUP_HASH = 0xC80A74AC829DDD92
    local N_GET_PED_RELATIONSHIP_GROUP_HASH = 0x7DBDD04862D95F04
    local N_SET_PED_AS_ENEMY                = 0x02A0C9720B854BFA
    local N_SET_PED_COMBAT_ATTRIBUTES       = 0x9F7794730795E019
    local N_SET_PED_COMBAT_ABILITY          = 0xC7622C0D36B2FDA8
    local N_SET_PED_COMBAT_MOVEMENT         = 0x4D9CA1009AFBD057
    local N_SET_PED_COMBAT_RANGE            = 0x3C606747B23E497B
    local N_SET_PED_KEEP_TASK               = 0x971D38760FBC02EF
    local N_SET_PED_CONFIG_FLAG             = 0x1913FE4CBF41C463
    local N_SET_PED_RESET_FLAG              = 0xC1E8A365BF3B29F2
    local N_SET_PED_TARGET_LOSS_RESPONSE    = 0x0703B9079823DA4A
    local N_SET_PED_MAX_HEALTH              = 0xF5F6378C4F3419D3
    local N_SET_ENTITY_HEALTH               = 0x6B76DC1F3AE6E6A3
    local N_SET_PED_SEEING_RANGE            = 0xF29CF591C4BF6CEE
    local N_SET_PED_HEARING_RANGE           = 0x33A8F7F7D5F7F33C
    local N_REGISTER_TARGET                 = 0x2F25D9AEFA34FBA2
    local N_TASK_COMBAT_PED                 = 0xF166E48407BAC484
    local N_TASK_COMBAT_HATED_AROUND        = 0x7BF835BB9E2698C8
    local N_TASK_BLOCK_NONTEMP              = 0x90D2156198831D69
    local N_CLEAR_PED_TASKS                 = 0xE1EF3C1216AFF2CD
    local N_CREATE_PED                      = 0xD49F9B0955C367DE
    local N_IS_ENTITY_DEAD                  = 0x5F9532F3B5CC2551
    local N_SET_ENTITY_VELOCITY             = 0x1C99BB7B6E96D16F
    local N_GET_GROUND_Z                    = 0xC906A7DAB05C8D2B
    local N_GIVE_WEAPON_TO_PED              = 0xBF0FD6E56C964FCB
    local N_SET_CURRENT_PED_WEAPON          = 0xADF692B254977C0C
    local N_SET_PED_MOVE_RATE_OVERRIDE        = 0x085BF80FA50A39D1
    local N_SET_ANIM_RATE                     = 0x032D49C5E359C847
    local N_SET_PED_NO_TIME_DELAY_BEFORE_SHOT = 0xA52D5247A4227E14
    local N_SET_ENTITY_AS_MISSION_ENTITY                 = 0xAD738C3085FE7E11
    local N_SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION = 0x3910051CCECDB00C
    local N_NETWORK_GET_NETWORK_ID_FROM_ENTITY           = 0xA11700682F3AD45C
    local N_SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES        = 0xE05E81A888FA63C8
    local N_SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER      = 0xA8A024587329F36A
    local N_SET_NETWORK_ID_CAN_MIGRATE                   = 0x299EEB23175895FC

    local CHIMP_SPEED_MULT = 3.0

    local CA_USE_COVER, CA_USE_VEHICLE   = 0, 1
    local CA_ALWAYS_FIGHT, CA_AGGRESSIVE = 5, 13
    local CA_CAN_CHASE_TARGET_ON_FOOT    = 21
    local CA_PERFECT_ACCURACY            = 27
    local CA_CAN_FIGHT_ARMED_NOT_ARMED   = 46
    local CA_CAN_CHARGE                  = 50
    local CA_DISABLE_FLEE_FROM_COMBAT    = 58
    local PCF_WILL_FLY_THROUGH_WINDSCREEN = 32
    local PCF_DISABLE_HURT                = 188
    local PCF_DISABLE_EXPLOSION_REACTIONS = 208
    local PCF_AVOID_TEAR_GAS              = 279
    local PCF_DISABLE_SHOCKING_EVENTS     = 294
    local PRF_IGNORE_COMBAT_MANAGER       = 440
    local COMBAT_PED_PREVENT_CHANGING_TARGET = 67108864
    local TASK_THREAT_CAN_FIGHT_ARMED_UNARMED = 16
    local TLR_NEVER_LOSE_TARGET = 1
    local PED_TYPE_ANIMAL = 28
    local PED_TYPE_ARMY   = 29
    local REL_HATE = 5

    local function initGroup()
        if chimpSwarm.groupInit then return end
        local localPed = PLAYER and PLAYER.PLAYER_PED_ID and PLAYER.PLAYER_PED_ID() or 0
        local playerGrp
        if localPed ~= 0 then
            if PED and PED.GET_PED_RELATIONSHIP_GROUP_HASH then
                playerGrp = PED.GET_PED_RELATIONSHIP_GROUP_HASH(localPed)
            elseif Natives and Natives.InvokeInt then
                playerGrp = Natives.InvokeInt(N_GET_PED_RELATIONSHIP_GROUP_HASH, localPed)
            else
                playerGrp = 0
            end
        end
        for _, pg in ipairs({ Utils.Joaat("PLAYER"), playerGrp }) do
            if pg and pg ~= 0 then
                invokeVoidByHash(PED and PED.SET_RELATIONSHIP_BETWEEN_GROUPS,
                    N_SET_RELATIONSHIP_BETWEEN_GROUPS, REL_HATE, chimpSwarm.groupHash, pg)
                invokeVoidByHash(PED and PED.SET_RELATIONSHIP_BETWEEN_GROUPS,
                    N_SET_RELATIONSHIP_BETWEEN_GROUPS, REL_HATE, pg, chimpSwarm.groupHash)
            end
        end
        chimpSwarm.groupInit = true
    end

    local function invokeIntByHash(shim, hash, ...)
        if shim then return shim(...) end
        if Natives and Natives.InvokeInt then
            return Natives.InvokeInt(hash, ...)
        end
        return 0
    end

    local function applyCombatFlags(handle)
        local setAttr  = PED and PED.SET_PED_COMBAT_ATTRIBUTES
        local setReset = PED and PED.SET_PED_RESET_FLAG
        invokeVoidByHash(setAttr, N_SET_PED_COMBAT_ATTRIBUTES,
            handle, CA_ALWAYS_FIGHT, true)
        invokeVoidByHash(setAttr, N_SET_PED_COMBAT_ATTRIBUTES,
            handle, CA_AGGRESSIVE, true)
        invokeVoidByHash(setAttr, N_SET_PED_COMBAT_ATTRIBUTES,
            handle, CA_CAN_CHASE_TARGET_ON_FOOT, true)
        invokeVoidByHash(setAttr, N_SET_PED_COMBAT_ATTRIBUTES,
            handle, CA_CAN_CHARGE, true)
        invokeVoidByHash(setAttr, N_SET_PED_COMBAT_ATTRIBUTES,
            handle, CA_DISABLE_FLEE_FROM_COMBAT, true)
        invokeVoidByHash(setReset, N_SET_PED_RESET_FLAG,
            handle, PRF_IGNORE_COMBAT_MANAGER, true)

        invokeVoidByHash(PED and PED.SET_PED_MOVE_RATE_OVERRIDE,
            N_SET_PED_MOVE_RATE_OVERRIDE, handle, CHIMP_SPEED_MULT)
        local animRate = TASK and TASK.SET_ANIM_RATE
        for prio = 0, 3 do
            invokeVoidByHash(animRate, N_SET_ANIM_RATE,
                handle, CHIMP_SPEED_MULT, prio, false)
        end
    end

    local function configurePed(handle)
        local setRelGrp = PED and PED.SET_PED_RELATIONSHIP_GROUP_HASH
        local setEnemy  = PED and PED.SET_PED_AS_ENEMY
        local setAbil   = PED and PED.SET_PED_COMBAT_ABILITY
        local setMove   = PED and PED.SET_PED_COMBAT_MOVEMENT
        local setRange  = PED and PED.SET_PED_COMBAT_RANGE
        local setKeep   = PED and PED.SET_PED_KEEP_TASK
        local setCfg    = PED and PED.SET_PED_CONFIG_FLAG
        local setLoss   = PED and PED.SET_PED_TARGET_LOSS_RESPONSE
        local setMaxHp  = PED and PED.SET_PED_MAX_HEALTH
        local setHp     = ENTITY and ENTITY.SET_ENTITY_HEALTH
        local taskBlock = TASK and TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS

        invokeVoidByHash(setRelGrp, N_SET_PED_RELATIONSHIP_GROUP_HASH,
            handle, chimpSwarm.groupHash)
        invokeVoidByHash(setEnemy, N_SET_PED_AS_ENEMY, handle, true)

        invokeVoidByHash(setMaxHp, N_SET_PED_MAX_HEALTH, handle, 200)
        invokeVoidByHash(setHp,    N_SET_ENTITY_HEALTH, handle, 200, 0, 0)

        invokeVoidByHash(setCfg, N_SET_PED_CONFIG_FLAG,
            handle, PCF_DISABLE_HURT, true)
        invokeVoidByHash(setCfg, N_SET_PED_CONFIG_FLAG,
            handle, PCF_DISABLE_EXPLOSION_REACTIONS, true)
        invokeVoidByHash(setCfg, N_SET_PED_CONFIG_FLAG,
            handle, PCF_DISABLE_SHOCKING_EVENTS, true)

        invokeVoidByHash(setAbil,  N_SET_PED_COMBAT_ABILITY, handle, 2)
        invokeVoidByHash(setMove,  N_SET_PED_COMBAT_MOVEMENT, handle, 2)
        invokeVoidByHash(setRange, N_SET_PED_COMBAT_RANGE, handle, 3)
        invokeVoidByHash(setLoss,  N_SET_PED_TARGET_LOSS_RESPONSE,
            handle, TLR_NEVER_LOSE_TARGET)

        invokeVoidByHash(taskBlock, N_TASK_BLOCK_NONTEMP, handle, true)
        invokeVoidByHash(setKeep, N_SET_PED_KEEP_TASK, handle, true)

        invokeVoidByHash(WEAPON and WEAPON.GIVE_WEAPON_TO_PED,
            N_GIVE_WEAPON_TO_PED, handle, chimpSwarm.wrenchHash, 1, false, true)
        invokeVoidByHash(WEAPON and WEAPON.SET_CURRENT_PED_WEAPON,
            N_SET_CURRENT_PED_WEAPON, handle, chimpSwarm.wrenchHash, true)

        invokeVoidByHash(PED and PED.SET_PED_NO_TIME_DELAY_BEFORE_SHOT,
            N_SET_PED_NO_TIME_DELAY_BEFORE_SHOT, handle)

        applyCombatFlags(handle)
    end

    local function createPedNative(pedType, modelHash, x, y, z, heading, isNet, isScriptHost)
        if PED and PED.CREATE_PED then
            return PED.CREATE_PED(pedType, modelHash, x, y, z, heading, isNet, isScriptHost)
        end
        if Natives and Natives.InvokeInt then
            return Natives.InvokeInt(N_CREATE_PED, pedType, modelHash,
                x + 0.0, y + 0.0, z + 0.0, heading + 0.0, isNet, isScriptHost)
        end
        return 0
    end

    local function isEntityDead(handle)
        if ENTITY and ENTITY.IS_ENTITY_DEAD then
            return ENTITY.IS_ENTITY_DEAD(handle, false)
        end
        return invokeBoolByHash(nil, N_IS_ENTITY_DEAD, handle, false)
    end

    local N_SET_ENTITY_COORDS_NO_OFFSET = 0x239A3351AC1DA385

    local function teleportPed(handle, x, y, z)
        local shim = ENTITY and ENTITY.SET_ENTITY_COORDS_NO_OFFSET
        invokeVoidByHash(shim, N_SET_ENTITY_COORDS_NO_OFFSET,
            handle, x + 0.0, y + 0.0, z + 0.0, true, true, true)
    end

    local function retask(handle, targetPed)
        local shim = TASK and TASK.TASK_COMBAT_PED
        invokeVoidByHash(shim, N_TASK_COMBAT_PED,
            handle, targetPed,
            COMBAT_PED_PREVENT_CHANGING_TARGET,
            TASK_THREAT_CAN_FIGHT_ARMED_UNARMED)
    end

    local function syncToNetwork(handle)
        invokeVoidByHash(ENTITY and ENTITY.SET_ENTITY_AS_MISSION_ENTITY,
            N_SET_ENTITY_AS_MISSION_ENTITY, handle, false, false)
        invokeVoidByHash(
            ENTITY and ENTITY.SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION,
            N_SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION, handle, false)
        local netId = invokeIntByHash(
            NETWORK and NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY,
            N_NETWORK_GET_NETWORK_ID_FROM_ENTITY, handle)
        if not netId or netId == 0 then return end
        invokeVoidByHash(
            NETWORK and NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES,
            N_SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES, netId, true)
        local localPid = (PLAYER and PLAYER.PLAYER_ID) and PLAYER.PLAYER_ID() or 0
        invokeVoidByHash(
            NETWORK and NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER,
            N_SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER, netId, localPid, true)
        invokeVoidByHash(
            NETWORK and NETWORK.SET_NETWORK_ID_CAN_MIGRATE,
            N_SET_NETWORK_ID_CAN_MIGRATE, netId, false)
    end

    local function planBurst(targetPid, targetPos, count, dist)
        initGroup()
        STREAMING.SET_FOCUS_POS_AND_VEL(
            targetPos.x, targetPos.y, targetPos.z, 0.0, 0.0, 0.0)
        STREAMING.REQUEST_COLLISION_AT_COORD(
            targetPos.x, targetPos.y, targetPos.z)
        chimpSwarm.focusSet = true
        local now = Time.GetEpocheMs()
        local twoPi = 6.28318530717959
        local interval = chimpSwarm.SPAWN_SPREAD_MS / math.max(1, count)
        local queued = 0
        for i = 1, count do
            local angle = (twoPi * (i - 1) / count) + (math.random() - 0.5) * 0.5
            local radius = dist + (math.random() - 0.5) * 8.0
            chimpSwarm.spawnQueue[#chimpSwarm.spawnQueue + 1] = {
                targetPid = targetPid,
                angle = angle,
                radius = radius,
                dueMs = now + math.floor((i - 1) * interval),
            }
            queued = queued + 1
        end
        return queued
    end

    local function spawnOne(entry, now)
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(entry.targetPid)
        if not targetPed or targetPed == 0
                or not ENTITY.DOES_ENTITY_EXIST(targetPed) then
            logf("Chimp Swarm: target pid %d gone, dropping queued spawn", entry.targetPid)
            return
        end
        local tp = ENTITY.GET_ENTITY_COORDS(targetPed, true)
        local sx = tp.x + math.cos(entry.angle) * entry.radius
        local sy = tp.y + math.sin(entry.angle) * entry.radius
        local heading = (entry.angle * 180.0 / math.pi) + 180.0

        local reqNet = true
        local ped = createPedNative(PED_TYPE_ARMY, chimpSwarm.modelHash,
            tp.x, tp.y, tp.z, heading, true, false)
        if not ped or ped == 0 then
            reqNet = false
            ped = createPedNative(PED_TYPE_ARMY, chimpSwarm.modelHash,
                tp.x, tp.y, tp.z, heading, false, false)
        end
        if not ped or ped == 0 then
            logf("Chimp Swarm: createPed returned 0")
            return
        elseif not ENTITY.DOES_ENTITY_EXIST(ped) then
            logf("Chimp Swarm: ped %d does not exist after create", ped)
            return
        end

        NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(ped)
        syncToNetwork(ped)
        local isNet = false
        do
            isNet = NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(ped) and true or false
        end
        logf("Chimp Swarm: spawned ped %d reqNet=%s networked=%s pid %d",
            ped, tostring(reqNet), tostring(isNet), entry.targetPid)

        teleportPed(ped, sx, sy, tp.z)
        chimpSwarm.pool[#chimpSwarm.pool + 1] = {
            handle = ped,
            spawnTime = now,
            targetPid = entry.targetPid,
            armAtMs = now + chimpSwarm.ARM_DELAY_MS,
            armed = false,
        }
    end

    local function processSpawnQueue(now)
        local q = chimpSwarm.spawnQueue
        if #q == 0 then
            if chimpSwarm.modelHeld then
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(chimpSwarm.modelHash)
                chimpSwarm.modelHeld = false
            end
            return
        end
        STREAMING.REQUEST_MODEL(chimpSwarm.modelHash)
        if not STREAMING.HAS_MODEL_LOADED(chimpSwarm.modelHash) then return end
        chimpSwarm.modelHeld = true

        local due = {}
        for i = 1, #q do
            if now >= q[i].dueMs then
                due[#due + 1] = i
                if #due >= chimpSwarm.MAX_SPAWN_PER_TICK then break end
            end
        end
        for j = 1, #due do
            if #chimpSwarm.pool < chimpSwarm.MAX then
                spawnOne(q[due[j]], now)
            end
        end
        for j = #due, 1, -1 do
            table.remove(q, due[j])
        end
    end

    function chimpFn.deleteAll()
        chimpSwarm.spawnQueue = {}
        releaseAll()
        if chimpSwarm.modelHeld then
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(chimpSwarm.modelHash)
            chimpSwarm.modelHeld = false
        end
        if chimpSwarm.focusSet then
            STREAMING.CLEAR_FOCUS()
            chimpSwarm.focusSet = false
        end
    end

    function chimpFn.onTick(f)
        if not f:IsToggled() then return end

        local pending = playerState.chimpSwarmPending
        if pending and #pending > 0 then
            if STREAMING.IS_MODEL_VALID
                    and not STREAMING.IS_MODEL_VALID(chimpSwarm.modelHash) then
                logf("Chimp Swarm: a_c_chimp model invalid, abandoning queue")
                playerState.chimpSwarmPending = {}
                chimpSwarm.loadStart = nil
                return
            end
            if not chimpSwarm.loadStart then
                chimpSwarm.loadStart = Time.GetEpocheMs()
                logf("Chimp Swarm: requesting a_c_chimp model")
            end
            STREAMING.REQUEST_MODEL(chimpSwarm.modelHash)
            if not STREAMING.HAS_MODEL_LOADED(chimpSwarm.modelHash) then
                if Time.GetEpocheMs() - chimpSwarm.loadStart > 5000 then
                    logf("Chimp Swarm: a_c_chimp failed to load after 5s")
                    playerState.chimpSwarmPending = {}
                    chimpSwarm.loadStart = nil
                end
                return
            end
            logf("Chimp Swarm: model loaded in %dms, draining %d req",
                Time.GetEpocheMs() - chimpSwarm.loadStart, #pending)
            chimpSwarm.loadStart = nil
            playerState.chimpSwarmPending = {}

            local count = 12
            local dist = 35.0
            local countFeat = FeatureMgr.GetFeature(H.CHIMP_COUNT)
            if countFeat then count = countFeat:GetIntValue() end
            local distFeat = FeatureMgr.GetFeature(H.CHIMP_DIST)
            if distFeat then dist = distFeat:GetFloatValue() end

            for _, req in ipairs(pending) do
                local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(req.pid)
                if not targetPed or targetPed == 0
                        or not ENTITY.DOES_ENTITY_EXIST(targetPed) then
                    logf("Chimp Swarm: no ped for pid %d", req.pid)
                else
                    local targetPos = ENTITY.GET_ENTITY_COORDS(targetPed, true)
                    local queued = planBurst(req.pid, targetPos, count, dist)
                    logf("Chimp Swarm: pid %d -> queued %d spawns over %dms",
                        req.pid, queued or 0, chimpSwarm.SPAWN_SPREAD_MS)
                end
            end
            chimpSwarm.modelHeld = true
        end

        local now = Time.GetEpocheMs()
        processSpawnQueue(now)

        local focusPos = nil
        for _, entry in ipairs(chimpSwarm.pool) do
            local h = entry.handle
            if ENTITY.DOES_ENTITY_EXIST(h) and not isEntityDead(h) then
                local tPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(entry.targetPid)
                if tPed and tPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(tPed)
                        and not isEntityDead(tPed) then
                    if not entry.armed then
                        if now >= entry.armAtMs then
                            configurePed(h)
                            retask(h, tPed)
                            entry.armed = true
                        end
                    else
                        applyCombatFlags(h)
                        retask(h, tPed)
                    end
                    if not focusPos then
                        focusPos = ENTITY.GET_ENTITY_COORDS(tPed, true)
                    end
                end
            end
        end
        if focusPos then
            STREAMING.SET_FOCUS_POS_AND_VEL(
                focusPos.x, focusPos.y, focusPos.z, 0.0, 0.0, 0.0)
            chimpSwarm.focusSet = true
        end

        if #chimpSwarm.pool == 0 and #chimpSwarm.spawnQueue == 0 then
            if chimpSwarm.focusSet then
                STREAMING.CLEAR_FOCUS()
                chimpSwarm.focusSet = false
            end
            return
        end

        local localPed = PLAYER.PLAYER_PED_ID()
        local localAnchor = (localPed and localPed ~= 0)
            and ENTITY.GET_ENTITY_COORDS(localPed, true) or nil
        local anchorCache = {}
        for i = #chimpSwarm.pool, 1, -1 do
            local entry = chimpSwarm.pool[i]
            local h = entry.handle
            local exists = ENTITY.DOES_ENTITY_EXIST(h)
            local dead = exists and isEntityDead(h)
            local stale = (now - entry.spawnTime) > chimpSwarm.TTL
            local far = false
            if exists and not dead then
                local anchor = anchorCache[entry.targetPid]
                if anchor == nil then
                    local tPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(entry.targetPid)
                    if tPed and tPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(tPed) then
                        anchor = ENTITY.GET_ENTITY_COORDS(tPed, true)
                    else
                        anchor = localAnchor
                    end
                    anchorCache[entry.targetPid] = anchor or false
                elseif anchor == false then
                    anchor = nil
                end
                if anchor then
                    local p = ENTITY.GET_ENTITY_COORDS(h, true)
                    local dx, dy, dz = p.x - anchor.x, p.y - anchor.y, p.z - anchor.z
                    if dx * dx + dy * dy + dz * dz > chimpSwarm.CLEANUP_DIST_SQ then
                        far = true
                    end
                end
            end
            if (not exists) or dead or stale or far then
                if exists then
                    Memory.WriteInt(chimpSwarm.delBuf, h)
                    ENTITY.DELETE_ENTITY(chimpSwarm.delBuf)
                end
                table.remove(chimpSwarm.pool, i)
            end
        end
    end
end

local patchFn = {}

do
    local FLAG_WILL_FLY_THROUGH_WINDSCREEN = 32
    local SET_PED_CONFIG_FLAG = 0x1913FE4CBF41C463
    local GET_PED_CONFIG_FLAG = 0x7EE53118C892B513
    local flagVerified = false

    local function addPatch(addr, len)
        local orig = {}
        for i = 0, len - 1 do orig[i] = Memory.ReadByte(addr + i) end
        windscreen.patches[#windscreen.patches + 1] = {addr = addr, orig = orig, len = len}
    end

    local function resolve()
        if windscreen.useConfigFlag or #windscreen.patches > 0 then return true end

        local scanResult
        if not IS_ENHANCED then
            scanResult = Memory.Scan(
                "E8 ? ? ? ? 84 C0 0F 84 ? ? ? ? 65 48 8B 0C 25 ? ? ? ? 8B 05 ? ? ? ? BA ? ? ? ? 48 8B 04 C1 48 83 3C 02 ? 75 0C")
            if scanResult and scanResult ~= 0 then
                local callTarget = Memory.Rip(scanResult + 1)
                if callTarget and callTarget ~= 0 then
                    addPatch(callTarget + 0x2A, 7)
                    log(VIBESCRIPT_LOADER and ("[FlyWindscreen] Legacy patch resolved: 0x%X"):format(callTarget + 0x2A) or "[FlyWindscreen] Pattern found.")
                    return true
                end
            end
        else
            scanResult = Memory.Scan(
                "E8 ? ? ? ? 89 C5 84 C0 0F 84 ? ? ? ? 8B 05 ? ? ? ? 65 48 8B 0C 25")
        end
        if scanResult and scanResult ~= 0 then
            local callTarget = Memory.Rip(scanResult + 1)
            if callTarget and callTarget ~= 0 then
                for off = 0, 0x58 do
                    if Memory.ReadUByte(callTarget + off) == 0x80 and
                       Memory.ReadUByte(callTarget + off + 1) == 0x3D then
                        local disp = Memory.ReadInt(callTarget + off + 2)
                        local resolved = callTarget + off + 7 + disp
                        local jmpByte = Memory.ReadUByte(callTarget + off + 7)
                        local patchAddr = callTarget + off + 7
                        local patchLen = 2
                        if jmpByte == 0x74 then
                            addPatch(patchAddr, 1)
                            windscreen.patches[#windscreen.patches].bytes = { 0xEB }
                        elseif jmpByte == 0x0F then
                            patchLen = 6
                            addPatch(patchAddr, patchLen)
                        else
                            addPatch(patchAddr, 2)
                        end
                        windscreen.useConfigFlag = true
                        log(VIBESCRIPT_LOADER and ("[FlyWindscreen] Enhanced: patched JZ->JMP at 0x%X (CheckForThroughWindow 0x%X +0x%X, jmp=0x%02X)"):format(
                            patchAddr, callTarget, off + 7, jmpByte) or "[FlyWindscreen] Pattern found.")
                        return true
                    end
                end
                if VIBESCRIPT_LOADER then log(("[FlyWindscreen] Enhanced: CALL target 0x%X has no CMP in first 0x60 bytes"):format(callTarget)) end
            end
        end

        windscreen.useConfigFlag = true
        log("[FlyWindscreen] Enhanced fallback: SET_PED_CONFIG_FLAG(32) only")
        return true
    end

    local function apply()
        if not resolve() then return end
        if not windscreen.patched and #windscreen.patches > 0 then
            for _, p in ipairs(windscreen.patches) do
                for i = 0, p.len - 1 do
                    Memory.WriteByte(p.addr + i, p.bytes and p.bytes[i + 1] or 0x90)
                end
            end
            windscreen.patched = true
        end
        if windscreen.useConfigFlag then
            local ped = PLAYER.PLAYER_PED_ID()
            if ped and ped ~= 0 then
                Natives.InvokeVoid(SET_PED_CONFIG_FLAG, ped, FLAG_WILL_FLY_THROUGH_WINDSCREEN, 1)
            end
        end
    end

    patchFn.windscreenRestorePatch = function()
        if windscreen.patched and #windscreen.patches > 0 then
            for _, p in ipairs(windscreen.patches) do
                for i = 0, p.len - 1 do Memory.WriteByte(p.addr + i, p.orig[i]) end
            end
            windscreen.patched = false
        end
        if windscreen.useConfigFlag then
            local ped = PLAYER.PLAYER_PED_ID()
            if ped and ped ~= 0 then
                Natives.InvokeVoid(SET_PED_CONFIG_FLAG, ped, FLAG_WILL_FLY_THROUGH_WINDSCREEN, 0)
            end
        end
    end

    patchFn.flyWindscreenOnTick = function(f)
        if not resolve() then return end
        if f:IsToggled() then apply() else patchFn.windscreenRestorePatch() end
    end
end

do
    local function addPatch(addr, len)
        local orig = {}
        for i = 0, len - 1 do orig[i] = Memory.ReadByte(addr + i) end
        weaponWheel.patches[#weaponWheel.patches + 1] = {addr = addr, orig = orig, len = len}
    end

    local function resolve()
        if weaponWheel.patchAddr or #weaponWheel.patches > 0 then return true end

        local scanResult
        if not IS_ENHANCED then
            scanResult = Memory.Scan("74 09 41 B5 01 44 88 6D E0")
            if scanResult and scanResult ~= 0 then
                weaponWheel.patchAddr = scanResult + 4
                weaponWheel.originalByte = Memory.ReadByte(scanResult + 4)
                log(VIBESCRIPT_LOADER and ("[WeaponWheel] Legacy patch resolved: 0x%X"):format(scanResult + 4) or "[WeaponWheel] Pattern found.")
                return true
            end
        else
            scanResult = Memory.Scan(
                "C0 E8 06 49 8B 8D 30 15 00 00 48 85 C9 41 0F 95 C4")
            if scanResult and scanResult ~= 0 then
                addPatch(scanResult + 13, 4)
                weaponWheel.patches[#weaponWheel.patches].bytes = { 0x45, 0x31, 0xE4, 0x90 }
                weaponWheel.isEnhanced = true
                log(VIBESCRIPT_LOADER and ("[WeaponWheel] Enhanced patch resolved: SETNZ at 0x%X"):format(scanResult + 13) or "[WeaponWheel] Pattern found.")
                return true
            end
        end

        log("[WeaponWheel] No pattern matched - feature unavailable")
        return false
    end

    local function apply()
        if weaponWheel.patched then
            if weaponWheel.isEnhanced then
                local p = weaponWheel.patches[1]
                if p and Memory.ReadByte(p.addr) == p.bytes[1] then return end
            else
                if weaponWheel.patchAddr and Memory.ReadByte(weaponWheel.patchAddr) == 0x00 then return end
            end
            weaponWheel.patched = false
        end
        if not resolve() then return end
        if weaponWheel.isEnhanced then
            for _, p in ipairs(weaponWheel.patches) do
                for i = 0, p.len - 1 do
                        Memory.WriteByte(p.addr + i, p.bytes and p.bytes[i + 1] or 0x90)
                    end
            end
        else
            Memory.WriteByte(weaponWheel.patchAddr, 0x00)
        end
        weaponWheel.patched = true
    end

    patchFn.weaponWheelRestorePatch = function()
        if not weaponWheel.patched then return end
        if weaponWheel.isEnhanced then
            for _, p in ipairs(weaponWheel.patches) do
                for i = 0, p.len - 1 do Memory.WriteByte(p.addr + i, p.orig[i]) end
            end
        else
            if weaponWheel.patchAddr and weaponWheel.originalByte then
                Memory.WriteByte(weaponWheel.patchAddr, weaponWheel.originalByte)
            end
        end
        weaponWheel.patched = false
    end

    patchFn.weaponWheelOnTick = function(f)
        if f:IsToggled() then apply() else patchFn.weaponWheelRestorePatch() end
    end
end





local eventCapture = {
    enabled = false,
    targetPid = -1,
    targetName = "All",
}

EventMgr.RegisterHandler(eLuaEvent.SCRIPTED_GAME_EVENT, function(sender, args)
    if not eventCapture.enabled or not sender then return false end
    if eventCapture.targetPid ~= -1 and sender.PlayerId ~= eventCapture.targetPid then return false end
    local parts = {}
    for i, v in ipairs(args) do parts[i] = tostring(v) end
    log(string.format("[EventCapture] from=%s hash=%d nargs=%d args=[%s]",
        sender:GetName(), args[1], #args, table.concat(parts, ", ")))
    return false
end)

patchFn.pausedSpoofActive = false

do
    local SE_PAUSING       = 786145470
    local SE_PAUSING_RESET = -1133455371
    local nextSend = -1
    local sendErrorLogged = false

    local function sendPausedEvent(mask, eventHash, localPid)
        local ok, err = pcall(GTA.TriggerScriptEvent, mask,
            {eventHash, localPid, mask, 0, math.random(0, 9999)})
        if not ok and not sendErrorLogged then
            sendErrorLogged = true
            pcall(Logger.LogInfo,
                "[VibeScript] PausedSpoof TriggerScriptEvent failed: " .. tostring(err))
        end
        return ok
    end

    patchFn.pausedSpoofOnTick = function(f)
        local wanted = f:IsToggled()

        if wanted ~= patchFn.pausedSpoofActive then
            patchFn.pausedSpoofActive = wanted
            nextSend = 0
            sendErrorLogged = false
            if wanted then
                log("[PausedSpoof] Enabled")
            end
        end

        if wanted then
            local now = Time.GetEpocheMs()
            if now >= nextSend then
                local localPid = GTA.GetLocalPlayerId()
                local allPlayers = 0
                for p = 0, 31 do
                    if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                        allPlayers = allPlayers + (1 << p)
                    end
                end
                if allPlayers ~= 0 then
                    sendPausedEvent(allPlayers, SE_PAUSING, localPid)
                end
                nextSend = now + 2000
            end
        elseif nextSend ~= -1 then
            local localPid = GTA.GetLocalPlayerId()
            local allPlayers = 0
            for p = 0, 31 do
                if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                    allPlayers = allPlayers + (1 << p)
                end
            end
            if allPlayers ~= 0 then
                sendPausedEvent(allPlayers, SE_PAUSING_RESET, localPid)
            end
            nextSend = -1
            log("[PausedSpoof] Disabled")
        end
    end
end

local passiveSpoof = {
    useSetPassive    = false,
    useFriendlyFire  = false,
    useLocalGhost    = false,
    useLocalAlpha    = false,
    useSyncPassive   = true,
    useSyncGhost     = true,
    useGpbdPassive   = true,
    useNoVehCollide  = true,
}
do
    local active = false
    local eventId = nil
    local SE_PASSIVE       = 947746716
    local SE_PASSIVE_RESET = -1552848514
    local nextOhdSend = -1

    passiveSpoofOnTick = function(f)
        local wanted = f:IsToggled()

        if wanted ~= active then
            active = wanted

            if wanted then
                if passiveSpoof.useSetPassive then
                    NETWORK.NETWORK_SET_PLAYER_IS_PASSIVE(true)
                end
                if passiveSpoof.useFriendlyFire then
                    NETWORK.NETWORK_SET_FRIENDLY_FIRE_OPTION(false)
                end
                if passiveSpoof.useLocalGhost then
                    NETWORK.SET_LOCAL_PLAYER_AS_GHOST(true, true)
                end
                if passiveSpoof.useLocalAlpha then
                    ENTITY.SET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID(), 128, false)
                end
            else
                NETWORK.NETWORK_SET_PLAYER_IS_PASSIVE(false)
                NETWORK.NETWORK_SET_FRIENDLY_FIRE_OPTION(true)
                NETWORK.SET_LOCAL_PLAYER_AS_GHOST(false, true)
                NETWORK.RESET_GHOST_ALPHA()
                ENTITY.RESET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID())
                ScriptGlobal.SetBool(
                    GPBD_FM_3_BASE + 1 + GTA.GetLocalPlayerId() * GPBD_FM_3_SIZE + 8,
                    false)
            end
            nextOhdSend = 0
        end

        if wanted then
            local now = Time.GetEpocheMs()
            if now >= nextOhdSend then
                local localPid = GTA.GetLocalPlayerId()
                local allPlayers = 0
                for p = 0, 31 do
                    if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                        allPlayers = allPlayers + (1 << p)
                    end
                end
                if allPlayers ~= 0 then
                    GTA.TriggerScriptEvent(allPlayers,
                        {SE_PASSIVE, localPid, allPlayers, 0, math.random(0, 9999)})
                end
                nextOhdSend = now + 1000
            end
        elseif active == false and nextOhdSend ~= -1 then
            local localPid = GTA.GetLocalPlayerId()
            local allPlayers = 0
            for p = 0, 31 do
                if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                    allPlayers = allPlayers + (1 << p)
                end
            end
            if allPlayers ~= 0 then
                GTA.TriggerScriptEvent(allPlayers,
                    {SE_PASSIVE_RESET, localPid, allPlayers, 0, math.random(0, 9999)})
            end
            nextOhdSend = -1
        end

        if wanted and passiveSpoof.useGpbdPassive then
            ScriptGlobal.SetBool(
                GPBD_FM_3_BASE + 1 + GTA.GetLocalPlayerId() * GPBD_FM_3_SIZE + 8,
                true)
        end

        if wanted and passiveSpoof.useNoVehCollide then
            local myPed = PLAYER.PLAYER_PED_ID()
            if myPed ~= 0 then
                local myVeh = 0
                if PED.IS_PED_IN_ANY_VEHICLE(myPed, false) then
                    myVeh = PED.GET_VEHICLE_PED_IS_IN(myPed, false) or 0
                end
                local localPid = GTA.GetLocalPlayerId()
                for p = 0, 31 do
                    if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                        local rp = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(p)
                        if rp and rp ~= 0 and PED.IS_PED_IN_ANY_VEHICLE(rp, false) then
                            local rv = PED.GET_VEHICLE_PED_IS_IN(rp, false) or 0
                            if rv ~= 0 then
                                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(myPed, rv, true)
                                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(rv, myPed, true)
                                if myVeh ~= 0 and myVeh ~= rv then
                                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(myVeh, rv, true)
                                    ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(rv, myVeh, true)
                                end
                            end
                        end
                    end
                end
            end
        end

        if wanted then
            if not eventId then
                eventId = EventMgr.RegisterHandler(
                    eLuaEvent.ON_SYNC_DATA_NODE,
                    function(nodeType, node)
                        if nodeType == eSyncDataNode.CPlayerGameStateDataNode then
                            if passiveSpoof.useSyncPassive then node.bIsPassiveMode = true end
                            if passiveSpoof.useSyncGhost then node.bGhost = true end
                        end
                    end)
                everEnabled = true
                log("[PassiveSpoof] Enabled")
            end
        else
            if eventId then
                EventMgr.RemoveHandler(eventId)
                eventId = nil
            end
            if everEnabled then
                everEnabled = false
                log("[PassiveSpoof] Disabled")
            end
        end
    end
end

do
    local OPP1_MISSILE = Utils.Joaat("VEHICLE_WEAPON_OPPRESSOR_MISSILE")
    local OPP2_MISSILE = Utils.Joaat("VEHICLE_WEAPON_OPPRESSOR2_MISSILE")
    local OPP1_MODEL   = Utils.Joaat("oppressor")
    local OPP2_MODEL   = Utils.Joaat("oppressor2")

    local DESIRED_TURN_RATE = 4.0
    local DESIRED_CLAMP     = 8.5

    local HP = {
        USE_PARAMS    = 0x19C,
        IGNORE_COMBAT = 0x19D,
        TIME_START    = 0x1A0,
        TIME_BREAK    = 0x1A4,
        TURN_RATE     = 0x1A8,
        CLAMP         = 0x1AC,
        BREAK_ANGLE   = 0x1B0,
        BREAK_CLOSE   = 0x1B4,
        BREAK_DIST    = 0x1B8,
    }

    local saved = {}

    local tunClamp     = nil
    local tunRate      = nil
    local origTunClamp = nil
    local origTunRate  = nil

    local tunablesResolved = false

    local cachedMissileAmmo = {}
    local probeState = nil
    local probeFrameCounter = 0
    local nextProbeFrame = 0
    local PROBE_COOLDOWN = 120

    local function validateHomingOffsets(ammoAddr)
        local useP   = Memory.ReadByte(ammoAddr + HP.USE_PARAMS)
        local ignCB  = Memory.ReadByte(ammoAddr + HP.IGNORE_COMBAT)
        local tStart = Memory.ReadFloat(ammoAddr + HP.TIME_START)
        local tBreak = Memory.ReadFloat(ammoAddr + HP.TIME_BREAK)
        local rate   = Memory.ReadFloat(ammoAddr + HP.TURN_RATE)
        local clamp  = Memory.ReadFloat(ammoAddr + HP.CLAMP)
        local brkA   = Memory.ReadFloat(ammoAddr + HP.BREAK_ANGLE)
        local brkC   = Memory.ReadFloat(ammoAddr + HP.BREAK_CLOSE)
        local brkD   = Memory.ReadFloat(ammoAddr + HP.BREAK_DIST)

        log(("[OppNerf] sHomingRocketParams @ ammo 0x%X:"):format(ammoAddr))
        log(("  Use=%d Ign=%d TStart=%.3f TBreak=%.3f Rate=%.3f Clamp=%.3f"):format(
            useP, ignCB, tStart, tBreak, rate, clamp))
        log(("  BreakAngle=%.3f BreakClose=%.3f BreakDist=%.3f"):format(brkA, brkC, brkD))

        if useP > 1 or ignCB > 1 then
            log("[OppNerf] WARNING: bool > 1, offsets likely wrong")
            return false
        end
        for _, v in ipairs({tStart, tBreak, rate, clamp, brkA, brkC, brkD}) do
            if v ~= v then
                log("[OppNerf] WARNING: NaN in homing params, offsets wrong")
                return false
            end
        end
        if math.abs(rate) > 100 or math.abs(clamp) > 100 then
            log("[OppNerf] WARNING: extreme homing values, offsets suspect")
            return false
        end
        return true
    end

    local function resolveTunables()
        tunablesResolved = true

        local tc = ScriptGlobal.GetTunableByHash(0xBC857F81)
        if tc and tc ~= 0 then
            tunClamp = tc
            origTunClamp = Memory.ReadFloat(tc)
            log(("[OppNerf] tunable clamp ptr=0x%X val=%.4f"):format(tc, origTunClamp))
        end
        local tr = ScriptGlobal.GetTunableByHash(0x794AFEEA)
        if tr and tr ~= 0 then
            tunRate = tr
            origTunRate = Memory.ReadFloat(tr)
            log(("[OppNerf] tunable rate ptr=0x%X val=%.4f"):format(tr, origTunRate))
        end
    end

    function restoreOppressorNerf()
        for addr, orig in pairs(saved) do
            if orig then
                Memory.WriteByte(addr + HP.USE_PARAMS, orig[1])
                Memory.WriteByte(addr + HP.IGNORE_COMBAT, orig[2])
                Memory.WriteFloat(addr + HP.TIME_START, orig[3])
                Memory.WriteFloat(addr + HP.TIME_BREAK, orig[4])
                Memory.WriteFloat(addr + HP.TURN_RATE, orig[5])
                Memory.WriteFloat(addr + HP.CLAMP, orig[6])
                Memory.WriteFloat(addr + HP.BREAK_ANGLE, orig[7])
                Memory.WriteFloat(addr + HP.BREAK_CLOSE, orig[8])
                Memory.WriteFloat(addr + HP.BREAK_DIST, orig[9])
            end
        end
        saved = {}
        cachedMissileAmmo = {}
        probeState = nil
        if tunClamp and origTunClamp then Memory.WriteFloat(tunClamp, origTunClamp) end
        if tunRate  and origTunRate  then Memory.WriteFloat(tunRate, origTunRate) end
    end

    function oppressorNerfOnTick(f)
        if not f:IsToggled() then
            restoreOppressorNerf()
            return
        end
        if not isPlayerReady() then return end

        probeFrameCounter = probeFrameCounter + 1

        local playerId = GTA.GetLocalPlayerId()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            probeState = nil
            return
        end

        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end

        local model = ENTITY.GET_ENTITY_MODEL(veh)
        if model ~= OPP1_MODEL and model ~= OPP2_MODEL then
            probeState = nil
            return
        end

        if not tunablesResolved then resolveTunables() end

        local targetMissile = (model == OPP1_MODEL) and OPP1_MISSILE or OPP2_MISSILE

        if model == OPP2_MODEL then
            if tunClamp then Memory.WriteFloat(tunClamp, 0.0) end
            if tunRate  then Memory.WriteFloat(tunRate, 0.0) end
        end

        local weaponInfo = getVehicleWeaponInfoAddr()
        if not weaponInfo then return end

        local weaponHash = Memory.ReadUInt(weaponInfo + OFF.WEAPON_NAME_HASH)

        local ammoAddr = nil

        if weaponHash == OPP1_MISSILE or weaponHash == OPP2_MISSILE then
            ammoAddr = readPtr(weaponInfo + OFF.AMMO_INFO)
            if ammoAddr then
                cachedMissileAmmo[weaponHash] = ammoAddr
            end
            if probeState and probeState.veh == veh then
                WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, probeState.origHash)
                probeState = nil
            end
        else
            ammoAddr = cachedMissileAmmo[targetMissile]

            if not ammoAddr then
                if probeState and probeState.veh == veh then
                    probeState.framesLeft = probeState.framesLeft - 1
                    if probeState.framesLeft <= 0 then
                        probeState = nil
                        nextProbeFrame = probeFrameCounter + PROBE_COOLDOWN
                    end
                    return
                end
                if probeFrameCounter < nextProbeFrame then return end
                local ok = WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, targetMissile)
                if ok then
                    probeState = {
                        veh = veh,
                        origHash = weaponHash,
                        framesLeft = 5,
                    }
                else
                    nextProbeFrame = probeFrameCounter + PROBE_COOLDOWN
                end
                return
            end
        end

        if not ammoAddr then return end

        if saved[ammoAddr] == nil then
            if not validateHomingOffsets(ammoAddr) then
                saved[ammoAddr] = false
                return
            end
            saved[ammoAddr] = {
                Memory.ReadByte(ammoAddr + HP.USE_PARAMS),
                Memory.ReadByte(ammoAddr + HP.IGNORE_COMBAT),
                Memory.ReadFloat(ammoAddr + HP.TIME_START),
                Memory.ReadFloat(ammoAddr + HP.TIME_BREAK),
                Memory.ReadFloat(ammoAddr + HP.TURN_RATE),
                Memory.ReadFloat(ammoAddr + HP.CLAMP),
                Memory.ReadFloat(ammoAddr + HP.BREAK_ANGLE),
                Memory.ReadFloat(ammoAddr + HP.BREAK_CLOSE),
                Memory.ReadFloat(ammoAddr + HP.BREAK_DIST),
            }
        end
        if not saved[ammoAddr] then return end

        Memory.WriteByte(ammoAddr + HP.USE_PARAMS, 1)
        Memory.WriteByte(ammoAddr + HP.IGNORE_COMBAT, 1)
        Memory.WriteFloat(ammoAddr + HP.TIME_START, 0.0)
        Memory.WriteFloat(ammoAddr + HP.TIME_BREAK, 0.5)
        Memory.WriteFloat(ammoAddr + HP.TURN_RATE, DESIRED_TURN_RATE)
        Memory.WriteFloat(ammoAddr + HP.CLAMP, DESIRED_CLAMP)
        Memory.WriteFloat(ammoAddr + HP.BREAK_ANGLE, -2.0)
        Memory.WriteFloat(ammoAddr + HP.BREAK_CLOSE, -2.0)
        Memory.WriteFloat(ammoAddr + HP.BREAK_DIST, 0.0)
    end
end

do
    local TARGET_HASHES = {}
    for _, name in ipairs({
        "VEHICLE_WEAPON_OPPRESSOR_MISSILE",
        "VEHICLE_WEAPON_OPPRESSOR2_MISSILE",
        "VEHICLE_WEAPON_SPACE_ROCKET",
        "VEHICLE_WEAPON_PLANE_ROCKET",
        "VEHICLE_WEAPON_RUINER_ROCKET",
        "VEHICLE_WEAPON_HUNTER_MISSILE",
        "VEHICLE_WEAPON_AKULA_MISSILE",
        "VEHICLE_WEAPON_SAVAGE_MISSILE",
        "VEHICLE_WEAPON_PLAYER_BUZZARD",
        "VEHICLE_WEAPON_AVENGER_MISSILE",
        "VEHICLE_WEAPON_BOMBUSHKA_MISSILE",
        "VEHICLE_WEAPON_APC_MISSILE",
        "VEHICLE_WEAPON_TAMPA_MISSILE",
        "VEHICLE_WEAPON_CHERNO_MISSILE",
        "VEHICLE_WEAPON_TRAILER_MISSILE",
        "VEHICLE_WEAPON_THRUSTER_MISSILE",
        "VEHICLE_WEAPON_VIGILANTE_MISSILE",
        "VEHICLE_WEAPON_ROGUE_MISSILE",
        "VEHICLE_WEAPON_SEABREEZE_MISSILE",
    }) do
        TARGET_HASHES[Utils.Joaat(name)] = true
    end

    local HP = {
        USE_PARAMS    = 0x19C,
        IGNORE_COMBAT = 0x19D,
        TIME_START    = 0x1A0,
        TIME_BREAK    = 0x1A4,
        TURN_RATE     = 0x1A8,
        CLAMP         = 0x1AC,
        BREAK_ANGLE   = 0x1B0,
        BREAK_CLOSE   = 0x1B4,
        BREAK_DIST    = 0x1B8,
    }

    local DESIRED_TURN_RATE = 4.0
    local DESIRED_CLAMP     = 8.5

    local saved      = {}
    local cachedAmmo = {}
    local arLastVeh, arVehInitTick = nil, 0

    local function validateHomingOffsets(ammoAddr)
        local useP   = Memory.ReadByte(ammoAddr + HP.USE_PARAMS)
        local ignCB  = Memory.ReadByte(ammoAddr + HP.IGNORE_COMBAT)
        local tStart = Memory.ReadFloat(ammoAddr + HP.TIME_START)
        local tBreak = Memory.ReadFloat(ammoAddr + HP.TIME_BREAK)
        local rate   = Memory.ReadFloat(ammoAddr + HP.TURN_RATE)
        local clamp  = Memory.ReadFloat(ammoAddr + HP.CLAMP)
        local brkA   = Memory.ReadFloat(ammoAddr + HP.BREAK_ANGLE)
        local brkC   = Memory.ReadFloat(ammoAddr + HP.BREAK_CLOSE)
        local brkD   = Memory.ReadFloat(ammoAddr + HP.BREAK_DIST)
        if useP > 1 or ignCB > 1 then return false end
        for _, v in ipairs({tStart, tBreak, rate, clamp, brkA, brkC, brkD}) do
            if v ~= v then return false end
        end
        if math.abs(rate) > 100 or math.abs(clamp) > 100 then return false end
        return true
    end

    local function looksAlreadyPatched(ammoAddr)
        if Memory.ReadByte(ammoAddr + HP.USE_PARAMS)    ~= 1 then return false end
        if Memory.ReadByte(ammoAddr + HP.IGNORE_COMBAT) ~= 1 then return false end
        if Memory.ReadFloat(ammoAddr + HP.TURN_RATE)    ~= DESIRED_TURN_RATE then return false end
        if Memory.ReadFloat(ammoAddr + HP.CLAMP)        ~= DESIRED_CLAMP then return false end
        return true
    end

    local function captureOriginals(ammoAddr)
        return {
            Memory.ReadByte(ammoAddr + HP.USE_PARAMS),
            Memory.ReadByte(ammoAddr + HP.IGNORE_COMBAT),
            Memory.ReadFloat(ammoAddr + HP.TIME_START),
            Memory.ReadFloat(ammoAddr + HP.TIME_BREAK),
            Memory.ReadFloat(ammoAddr + HP.TURN_RATE),
            Memory.ReadFloat(ammoAddr + HP.CLAMP),
            Memory.ReadFloat(ammoAddr + HP.BREAK_ANGLE),
            Memory.ReadFloat(ammoAddr + HP.BREAK_CLOSE),
            Memory.ReadFloat(ammoAddr + HP.BREAK_DIST),
        }
    end

    local function writeDeluxoValues(ammoAddr)
        Memory.WriteByte(ammoAddr + HP.USE_PARAMS, 1)
        Memory.WriteByte(ammoAddr + HP.IGNORE_COMBAT, 1)
        Memory.WriteFloat(ammoAddr + HP.TIME_START, 0.0)
        Memory.WriteFloat(ammoAddr + HP.TIME_BREAK, 0.5)
        Memory.WriteFloat(ammoAddr + HP.TURN_RATE, DESIRED_TURN_RATE)
        Memory.WriteFloat(ammoAddr + HP.CLAMP, DESIRED_CLAMP)
        Memory.WriteFloat(ammoAddr + HP.BREAK_ANGLE, -2.0)
        Memory.WriteFloat(ammoAddr + HP.BREAK_CLOSE, -2.0)
        Memory.WriteFloat(ammoAddr + HP.BREAK_DIST, 0.0)
    end

    function restoreAllRocketsNerf()
        for addr, orig in pairs(saved) do
            if type(orig) == "table" then
                Memory.WriteByte(addr + HP.USE_PARAMS,    orig[1])
                Memory.WriteByte(addr + HP.IGNORE_COMBAT, orig[2])
                Memory.WriteFloat(addr + HP.TIME_START,   orig[3])
                Memory.WriteFloat(addr + HP.TIME_BREAK,   orig[4])
                Memory.WriteFloat(addr + HP.TURN_RATE,    orig[5])
                Memory.WriteFloat(addr + HP.CLAMP,        orig[6])
                Memory.WriteFloat(addr + HP.BREAK_ANGLE,  orig[7])
                Memory.WriteFloat(addr + HP.BREAK_CLOSE,  orig[8])
                Memory.WriteFloat(addr + HP.BREAK_DIST,   orig[9])
            end
        end
        saved = {}
        cachedAmmo = {}
    end

    function allRocketsNerfOnTick(f)
        if not f:IsToggled() then
            restoreAllRocketsNerf()
            return
        end
        if not isPlayerReady() then return end

        local playerId = GTA.GetLocalPlayerId()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end

        if veh ~= arLastVeh then
            arLastVeh = veh
            arVehInitTick = 0
            return
        end
        arVehInitTick = arVehInitTick + 1
        if arVehInitTick <= weaponState.VEH_INIT_DELAY then return end

        local weaponInfo = getVehicleWeaponInfoAddr()
        if weaponInfo then
            local weaponHash = Memory.ReadUInt(weaponInfo + OFF.WEAPON_NAME_HASH)
            if TARGET_HASHES[weaponHash] and not cachedAmmo[weaponHash] then
                local ammoAddr = readPtr(weaponInfo + OFF.AMMO_INFO)
                if ammoAddr then
                    cachedAmmo[weaponHash] = true
                    if saved[ammoAddr] == nil then
                        if not validateHomingOffsets(ammoAddr) then
                            saved[ammoAddr] = false
                            log(("[AllRockets] validation failed hash=0x%08X ammo=0x%X"):format(weaponHash, ammoAddr))
                        elseif looksAlreadyPatched(ammoAddr) then
                            saved[ammoAddr] = "skip"
                            log(("[AllRockets] deferred hash=0x%08X ammo=0x%X (already patched)"):format(weaponHash, ammoAddr))
                        else
                            saved[ammoAddr] = captureOriginals(ammoAddr)
                            log(("[AllRockets] cached hash=0x%08X ammo=0x%X"):format(weaponHash, ammoAddr))
                        end
                    end
                end
            end
        end

        for ammoAddr, s in pairs(saved) do
            if s == "skip" then
                if not looksAlreadyPatched(ammoAddr) and validateHomingOffsets(ammoAddr) then
                    saved[ammoAddr] = captureOriginals(ammoAddr)
                    writeDeluxoValues(ammoAddr)
                end
            elseif type(s) == "table" then
                writeDeluxoValues(ammoAddr)
            end
        end
    end
end

do
    local function u32(x)
        if x < 0 then return x + 0x100000000 end
        return x
    end
    local LAZER_HASH   = u32(Utils.Joaat("lazer"))
    local HYDRA_HASH   = u32(Utils.Joaat("hydra"))
    local CANNON_HASH  = u32(Utils.Joaat("VEHICLE_WEAPON_PLAYER_LAZER"))

    local balancedTBS      = nil
    local balancedAWT      = nil
    local origBalancedTBS  = nil
    local origBalancedAWT  = nil
    local enhTBSSites      = {}
    local enhAWTSites      = {}
    local enhTBSOverrideAddr = nil
    local enhTBSOverrideOrig = nil
    local enhAWTOverrideAddr = nil
    local enhAWTOverrideOrig = nil
    local cannonCmpSites   = {}
    local enhCannonExpTagSites = {}
    local legacyCannonExpTagAddr = nil
    local legacyCannonExpTagOrig = nil

    local function tryResolveFromCall(callAddr)
        if not callAddr or callAddr == 0 then return nil end
        if (Memory.ReadByte(callAddr) & 0xFF) ~= 0xE8 then return nil end
        local funcAddr = Memory.Rip(callAddr + 1)
        if not funcAddr or funcAddr <= 0 or funcAddr >= 0x800000000000 then return nil end
        for _, off in ipairs({0x30, 0x28, 0x34, 0x38, 0x20, 0x24, 0x2C, 0x3C, 0x40}) do
            local ptr = Memory.Rip(funcAddr + off)
            if ptr and ptr > 0 and ptr < 0x800000000000 then
                local val = Memory.ReadFloat(ptr)
                if val and val > 0.05 and val < 0.5 then
                    return ptr, val, off
                end
            end
        end
        return nil
    end

    local function resolveAllFromCall(callAddr)
        local results = {}
        if not callAddr or callAddr == 0 then return results end
        if (Memory.ReadByte(callAddr) & 0xFF) ~= 0xE8 then return results end
        local funcAddr = Memory.Rip(callAddr + 1)
        if not funcAddr or funcAddr <= 0 or funcAddr >= 0x800000000000 then return results end
        local seen = {}
        for _, off in ipairs({0x30, 0x28, 0x34, 0x38, 0x20, 0x24, 0x2C, 0x3C, 0x40, 0x44, 0x48}) do
            local ptr = Memory.Rip(funcAddr + off)
            if ptr and ptr > 0 and ptr < 0x800000000000 and not seen[ptr] then
                local val = Memory.ReadFloat(ptr)
                if val and val > 0.05 and val < 0.5 then
                    seen[ptr] = true
                    results[#results + 1] = {ptr = ptr, val = val, off = off}
                end
            end
        end
        return results
    end

    local function isRipRelModrm(b)
        return b == 0x05 or b == 0x0D or b == 0x15 or b == 0x1D
            or b == 0x25 or b == 0x2D or b == 0x35 or b == 0x3D
    end
    local function isDisp32Modrm(b)
        local mod = (b >> 6) & 0x03
        local rm  = b & 0x07
        return mod == 2 and rm ~= 4
    end
    local function modrmXmmIdx(b) return (b >> 3) & 0x07 end
    local ripRelXmmIdx = modrmXmmIdx
    local function resolveRipRelFloat(instrStart)
        local target = Memory.Rip(instrStart + 4)
        if not target or target <= 0 or target >= 0x800000000000 then return nil end
        local val = Memory.ReadFloat(target)
        if not val or val <= 0.05 or val >= 0.5 then return nil end
        return target, val
    end
    local function findCapMovssBefore(anchor, maxBack, xmmFilter)
        for back = 8, maxBack do
            local a = anchor - back
            if Memory.ReadUByte(a) == 0xF3
               and Memory.ReadUByte(a + 1) == 0x0F
               and Memory.ReadUByte(a + 2) == 0x10 then
                local modrm = Memory.ReadUByte(a + 3)
                if isRipRelModrm(modrm) and (not xmmFilter or ripRelXmmIdx(modrm) == xmmFilter) then
                    local target, val = resolveRipRelFloat(a)
                    if target then return { ptr = target, val = val, addr = a } end
                end
            end
        end
        return nil
    end
    local function findCapMaxssAfter(anchor, maxForward, xmmFilter)
        for fwd = 0, maxForward do
            local a = anchor + fwd
            if Memory.ReadUByte(a) == 0xF3
               and Memory.ReadUByte(a + 1) == 0x0F
               and Memory.ReadUByte(a + 2) == 0x5F then
                local modrm = Memory.ReadUByte(a + 3)
                if isRipRelModrm(modrm) and (not xmmFilter or ripRelXmmIdx(modrm) == xmmFilter) then
                    local target, val = resolveRipRelFloat(a)
                    if target then return { ptr = target, val = val, addr = a } end
                end
            end
        end
        return nil
    end
    local function dumpBytesHex(addr, before, after)
        local parts = {}
        for i = -before, after do
            parts[#parts + 1] = ("%02X"):format(Memory.ReadUByte(addr + i))
        end
        return table.concat(parts, " ")
    end

    local function scanAllClampSites(disp32Bytes, label)
        local sites = {}
        local seen  = {}
        for xmmIdx = 0, 7 do
            for baseIdx = 0, 7 do
                if baseIdx ~= 4 then
                    local modrm = 0x80 + (xmmIdx << 3) + baseIdx
                    local pat = ("F3 0F 5F %02X %s F3 0F 11 %02X %s"):format(
                        modrm, disp32Bytes, modrm, disp32Bytes)
                    local hit = Memory.Scan(pat)
                    if hit and hit ~= 0 and not seen[hit] then
                        seen[hit] = true
                        local patchAddr = hit + 2
                        local origByte = Memory.ReadUByte(patchAddr)
                        sites[#sites + 1] = {
                            patchAddr = patchAddr, origByte = origByte,
                            modrm = modrm, anchor = hit,
                        }
                    end
                end
            end
        end
        return sites
    end
    local function findCannonOverrideAfter(hit, maxFwd)
        for off = 7, maxFwd do
            local a = hit + off
            if Memory.ReadUByte(a) == 0xF3
               and Memory.ReadUByte(a + 1) == 0x0F
               and Memory.ReadUByte(a + 2) == 0x10 then
                local modrm = Memory.ReadUByte(a + 3)
                if isRipRelModrm(modrm) then
                    local target = Memory.Rip(a + 4)
                    if target and target > 0x10000000000 and target < 0x7FFFFFFFFFFF then
                        local val = Memory.ReadFloat(target)
                        if val and val > 0.001 and val < 10.0 then
                            return { addr = target, val = val }
                        end
                    end
                end
            end
        end
        return nil
    end
    local function scanCannonTBSOverride()
        local patterns = {}
        for _, modrm in ipairs({0x78, 0x79, 0x7A, 0x7B, 0x7D, 0x7E, 0x7F}) do
            patterns[#patterns + 1] = {
                pat = ("81 %02X 10 29 2A 82 E2"):format(modrm),
                immOff = 3,
            }
        end
        for _, modrm in ipairs({0xB8, 0xB9, 0xBA, 0xBB, 0xBD, 0xBE, 0xBF}) do
            patterns[#patterns + 1] = {
                pat = ("81 %02X 10 00 00 00 29 2A 82 E2"):format(modrm),
                immOff = 6,
            }
        end
        local seen = {}
        for _, p in ipairs(patterns) do
            local hit = Memory.Scan(p.pat)
            if hit and hit ~= 0 and not seen[hit] then
                seen[hit] = true
                local immAddr = hit + p.immOff
                cannonCmpSites[#cannonCmpSites + 1] = {
                    hitAddr = hit,
                    immAddr = immAddr,
                    origImm = Memory.ReadUInt(immAddr),
                }
                local found = findCannonOverrideAfter(hit, 0x200)
                if found and not enhTBSOverrideAddr then
                    enhTBSOverrideAddr = found.addr
                    enhTBSOverrideOrig = found.val
                    enhAWTOverrideAddr = found.addr + 4
                    enhAWTOverrideOrig = Memory.ReadFloat(enhAWTOverrideAddr)
                end
            end
        end
    end

    local CANNON_EXP_TAG_ORIG = 85
    local function collectCannonExpTagImms(cmpHit, maxFwd, out)
        for off = 7, maxFwd do
            local a = cmpHit + off
            local b0 = Memory.ReadUByte(a)
            if b0 and b0 >= 0xB8 and b0 <= 0xBF then
                if Memory.ReadInt(a + 1) == CANNON_EXP_TAG_ORIG then
                    out[#out + 1] = a + 1
                end
            end
            if b0 == 0x41 then
                local b1 = Memory.ReadUByte(a + 1)
                if b1 and b1 >= 0xB8 and b1 <= 0xBF then
                    if Memory.ReadInt(a + 2) == CANNON_EXP_TAG_ORIG then
                        out[#out + 1] = a + 2
                    end
                end
            end
        end
    end
    local function scanCannonExplosionTag()
        local seen = {}
        for _, s in ipairs(cannonCmpSites) do
            local found = {}
            collectCannonExpTagImms(s.hitAddr, 0x40, found)
            for _, immAddr in ipairs(found) do
                if not seen[immAddr] then
                    seen[immAddr] = true
                    enhCannonExpTagSites[#enhCannonExpTagSites + 1] = {
                        immAddr = immAddr,
                        origImm = Memory.ReadInt(immAddr),
                    }
                end
            end
        end
    end

    local function scanBalancedCannonsEnhanced()
        enhTBSSites = scanAllClampSites("3C 01 00 00", "TBS")
        enhAWTSites = scanAllClampSites("50 01 00 00", "AWT")
        scanCannonTBSOverride()
        scanCannonExplosionTag()
    end

    local function scanCannonLegacyExpTag()
        for _, modrm in ipairs({0x78, 0x79, 0x7A, 0x7B, 0x7D, 0x7E, 0x7F}) do
            local pat = ("81 %02X 10 29 2A 82 E2 ? ? 38 05 ? ? ? ? B8"):format(modrm)
            local hit = Memory.Scan(pat)
            if hit and hit ~= 0 then
                local immAddr = hit + 16
                local imm = Memory.ReadInt(immAddr)
                if imm == 85 then
                    legacyCannonExpTagAddr = immAddr
                    legacyCannonExpTagOrig = imm
                    return
                end
            end
        end
    end

    local function scanBalancedCannons()
        local scan1 = Memory.Scan("E8 ? ? ? ? 49 8B CD 0F 28 F8")
        if scan1 and scan1 ~= 0 then
            local ptr, val = tryResolveFromCall(scan1)
            if ptr then
                balancedTBS = ptr
                origBalancedTBS = val
            end
        end

        if not balancedAWT then
            local scan2 = Memory.Scan("E8 ? ? ? ? 8B 15 ? ? ? ? 8B 0D ? ? ? ? 0F 2F")
            if scan2 and scan2 ~= 0 then
                local ptr, val = tryResolveFromCall(scan2)
                if ptr then
                    balancedAWT = ptr
                    origBalancedAWT = val
                end
            end
        end

        if not balancedAWT then
            local scan2b = Memory.Scan("E8 ? ? ? ? 8B 15 ? ? ? ? 8B 0D ? ? ? ? 44")
            if scan2b and scan2b ~= 0 then
                local ptr, val = tryResolveFromCall(scan2b)
                if ptr and ptr ~= balancedTBS then
                    balancedAWT = ptr
                    origBalancedAWT = val
                end
            end
        end

        if balancedTBS and not balancedAWT then
            local all = resolveAllFromCall(
                Memory.Scan("E8 ? ? ? ? 49 8B CD 0F 28 F8"))
            for _, r in ipairs(all) do
                if r.ptr ~= balancedTBS then
                    balancedAWT = r.ptr
                    origBalancedAWT = r.val
                    break
                end
            end
        end

        if balancedTBS and not balancedAWT then
            for _, delta in ipairs({4, -4, 8, -8}) do
                local adj = balancedTBS + delta
                local val = Memory.ReadFloat(adj)
                if val and val > 0.05 and val < 0.5 then
                    balancedAWT = adj
                    origBalancedAWT = val
                    break
                end
            end
        end

        if not balancedTBS or not balancedAWT then
            scanBalancedCannonsEnhanced()
        end

        if not IS_ENHANCED then
            scanCannonLegacyExpTag()
        end

        local tbsOk = balancedTBS or enhTBSOverrideAddr or #enhTBSSites > 0
        local awtOk = balancedAWT or enhAWTOverrideAddr or #enhAWTSites > 0
        local expCount = #enhCannonExpTagSites + (legacyCannonExpTagAddr and 1 or 0)
        log(("[LazerNerf] Scan: TBS=%s AWT=%s expTag=%d sites"):format(
            tbsOk and "ok" or "MISS",
            awtOk and "ok" or "MISS",
            expCount))
        if not tbsOk then
            GUI.AddToast("VibeScript", "Lazer nerf: TBS clamp not found", 5000)
        end
    end

    scanBalancedCannons()

    local PRE_NERF_TBS = 0.04
    local PRE_NERF_AWT = 0.0
    local DAMAGE_MULT  = 3.0
    local cannonInfo   = nil

    local function resolveCannonInfo(ped)
        local weaponInfoAddr = getVehicleWeaponInfoAddr()
        if weaponInfoAddr then
            local h = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
            if h == CANNON_HASH then return weaponInfoAddr end
        end
        local origWeaponHash = weaponInfoAddr and Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH) or 0
        if WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, CANNON_HASH) then
            weaponInfoAddr = getVehicleWeaponInfoAddr()
            if weaponInfoAddr then
                local h = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
                if h == CANNON_HASH then
                    if origWeaponHash ~= 0 then
                        WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, origWeaponHash)
                    end
                    return weaponInfoAddr
                end
            end
            if origWeaponHash ~= 0 then
                WEAPON.SET_CURRENT_PED_VEHICLE_WEAPON(ped, origWeaponHash)
            end
        end
        return nil
    end

    function restoreLazerNerf()
        if cannonInfo then
            Memory.WriteFloat(cannonInfo.addr + OFF.TIME_BETWEEN_SHOTS, cannonInfo.tbs)
            Memory.WriteFloat(cannonInfo.addr + OFF.ALT_WAIT_TIME, cannonInfo.awt)
            Memory.WriteFloat(cannonInfo.addr + OFF.DAMAGE, cannonInfo.damage)
            cannonInfo = nil
        end
        if balancedTBS and origBalancedTBS then Memory.WriteFloat(balancedTBS, origBalancedTBS) end
        if balancedAWT and origBalancedAWT then Memory.WriteFloat(balancedAWT, origBalancedAWT) end
        for _, s in ipairs(enhTBSSites) do
            Memory.WriteByte(s.patchAddr, s.origByte)
        end
        for _, s in ipairs(enhAWTSites) do
            Memory.WriteByte(s.patchAddr, s.origByte)
        end
        if enhTBSOverrideAddr and enhTBSOverrideOrig then
            Memory.WriteFloat(enhTBSOverrideAddr, enhTBSOverrideOrig)
        end
        if enhAWTOverrideAddr and enhAWTOverrideOrig then
            Memory.WriteFloat(enhAWTOverrideAddr, enhAWTOverrideOrig)
        end
        for _, s in ipairs(enhCannonExpTagSites) do
            Memory.WriteInt(s.immAddr, s.origImm)
        end
        if legacyCannonExpTagAddr and legacyCannonExpTagOrig then
            Memory.WriteInt(legacyCannonExpTagAddr, legacyCannonExpTagOrig)
        end
    end

    function lazerNerfOnTick(f)
        if not f:IsToggled() then
            restoreLazerNerf()
            return
        end
        if not isPlayerReady() then return end

        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            restoreLazerNerf()
            return
        end

        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end
        local model = u32(ENTITY.GET_ENTITY_MODEL(veh))
        if model ~= LAZER_HASH and model ~= HYDRA_HASH then return end

        if balancedTBS then Memory.WriteFloat(balancedTBS, 0.0) end
        if balancedAWT then Memory.WriteFloat(balancedAWT, 0.0) end
        for _, s in ipairs(enhTBSSites) do
            if Memory.ReadUByte(s.patchAddr) == 0x5F then
                Memory.WriteByte(s.patchAddr, 0x10)
            end
        end
        for _, s in ipairs(enhAWTSites) do
            if Memory.ReadUByte(s.patchAddr) == 0x5F then
                Memory.WriteByte(s.patchAddr, 0x10)
            end
        end

        if not cannonInfo then
            local addr = resolveCannonInfo(ped)
            if addr then
                cannonInfo = {
                    addr    = addr,
                    tbs     = Memory.ReadFloat(addr + OFF.TIME_BETWEEN_SHOTS),
                    awt     = Memory.ReadFloat(addr + OFF.ALT_WAIT_TIME),
                    damage  = Memory.ReadFloat(addr + OFF.DAMAGE),
                }
            end
        end

        if cannonInfo then
            Memory.WriteFloat(cannonInfo.addr + OFF.TIME_BETWEEN_SHOTS, PRE_NERF_TBS)
            Memory.WriteFloat(cannonInfo.addr + OFF.ALT_WAIT_TIME, PRE_NERF_AWT)
            Memory.WriteFloat(cannonInfo.addr + OFF.DAMAGE, cannonInfo.damage * DAMAGE_MULT)
        end

        if enhTBSOverrideAddr then
            Memory.WriteFloat(enhTBSOverrideAddr, PRE_NERF_TBS)
        end
        if enhAWTOverrideAddr then
            Memory.WriteFloat(enhAWTOverrideAddr, PRE_NERF_AWT)
        end
        if #enhCannonExpTagSites > 0 then
            local newTag = lazerExpTag.values[lazerExpTag.idx] or 85
            for _, s in ipairs(enhCannonExpTagSites) do
                if Memory.ReadInt(s.immAddr) ~= newTag then
                    Memory.WriteInt(s.immAddr, newTag)
                end
            end
        end

        if not IS_ENHANCED and legacyCannonExpTagAddr then
            local newTag = lazerExpTag.values[lazerExpTag.idx] or legacyCannonExpTagOrig
            if Memory.ReadInt(legacyCannonExpTagAddr) ~= newTag then
                Memory.WriteInt(legacyCannonExpTagAddr, newTag)
            end
        end
    end
end

H.DETACH_WING        = Utils.Joaat("LUA_DetachWing")
H.BREAK_TAIL_BOOM    = Utils.Joaat("LUA_BreakTailBoom")
H.DESTROY_AIR_PROPS  = Utils.Joaat("LUA_DestroyAircraftPropellers")
H.DISMANTLE_VEHICLE  = Utils.Joaat("LUA_DismantleVehicle")

aircraftSabotage = {
    queue       = {},
    runnerHash  = Utils.Joaat("LUA_AircraftSabotageRunner"),
    wingFlip    = math.random(0, 1),

    H_IS_PLANE          = 0xA0948AB42D7BA0DE,
    H_IS_HELI           = 0xDCE4334788AF94EA,
    H_TAIL_BOOM_BREAK   = 0x3EC8BF18AA453FE9,
    H_MAIN_ROTOR_HEALTH = 0x4056EA1105F5ABD7,
    H_TAIL_ROTOR_HEALTH = 0xFE205F38AAA58E5B,
    H_ENGINE_HEALTH     = 0x45F6D8EEF34ABEF1,

    PROPCOLL_OFFSET     = 0x1d20,

    boomFn = {
        addr = nil,
        enh  = "56 57 53 48 83 EC 20 48 89 CE 85 D2 74 ? 89 D3 48 89 F1 E8 ? ? ? ? 85 C0 0F 8F ? ? ? ? 48 8D BE 90 1B 00 00",
        leg  = "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 48 83 EC 20 8B DA 48 8B F9 85 D2 74 ? E8 ? ? ? ? 85 C0 7E ? 88 9F 94 1C 00 00",
    },

    DMG_OFFSET = 0x1dd0,
    sectionFn = {
        addr = nil,
        enh  = "41 57 41 56 41 55 41 54 56 57 55 53 48 83 EC 28 44 89 CB 45 89 C6 48 89 D7 49 89 CD 48 85 D2 74 ? 48 8B 8F D0 00 00 00 48 85 C9 74 ? 80 79 4B 00",
        leg  = "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 41 54 41 55 41 56 41 57 48 83 EC 20 33 DB 45 8A F1 45 8B E8 48 8B FA 4C 8B E1 BD 01 00 00 00 48 85 D2 74 ? 48 8B 82 D0 00 00 00",
    },

    NUM_PROPS = 8,
    rotorFn = {
        addr = nil,
        enh  = "56 57 53 48 83 EC 20 48 89 CE 48 63 C2 48 8D 0C 40 0F BE BC 0E 20 1D 00 00 85 FF 0F 88 ? ? ? ? 48 83 BE C0 09 00 00 00",
        leg  = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 48 83 B9 C0 09 00 00 00 48 63 FA 48 8B D9 48 8D 04 79 0F BE B4 07 20 1D 00 00",
    },
}

function aircraftSabotage.toast(msg)
    GUI.AddToast("Aircraft Sabotage", msg, 3500)
end

function aircraftSabotage.planeHasProps(vehAddr)
    for i = 0, aircraftSabotage.NUM_PROPS - 1 do
        local b = Memory.ReadByte(vehAddr + aircraftSabotage.PROPCOLL_OFFSET + i * 3)
        if b and b >= 0 then return true end
    end
    return false
end

function aircraftSabotage.killEngine(veh)
    Natives.InvokeVoid(aircraftSabotage.H_ENGINE_HEALTH, veh, 0.0)
end

function aircraftSabotage.resolveBoomFn()
    local b = aircraftSabotage.boomFn
    if b.addr then return b.addr end
    local pat = IS_ENHANCED and b.enh or b.leg
    local hit = Memory.Scan(pat)
    if hit and hit > 0x10000 then
        b.addr = hit
        log(("[AircraftSabotage] BreakOffTailBoom @ 0x%X (%s)")
            :format(hit, IS_ENHANCED and "Enhanced" or "Legacy"))
    else
        log("[AircraftSabotage] BreakOffTailBoom pattern not found (will retry next use)")
    end
    return b.addr
end

function aircraftSabotage.resolveSectionFn()
    local s = aircraftSabotage.sectionFn
    if s.addr then return s.addr end
    local pat = IS_ENHANCED and s.enh or s.leg
    local hit = Memory.Scan(pat)
    if hit and hit > 0x10000 then
        s.addr = hit
        log(("[AircraftSabotage] BreakOffSection @ 0x%X (%s)")
            :format(hit, IS_ENHANCED and "Enhanced" or "Legacy"))
    else
        log("[AircraftSabotage] BreakOffSection pattern not found (will retry next use)")
    end
    return s.addr
end

function aircraftSabotage.resolveRotorFn()
    local r = aircraftSabotage.rotorFn
    if r.addr then return r.addr end
    local pat = IS_ENHANCED and r.enh or r.leg
    local hit = Memory.Scan(pat)
    if hit and hit > 0x10000 then
        r.addr = hit
        log(("[AircraftSabotage] BreakOffRotor @ 0x%X (%s)")
            :format(hit, IS_ENHANCED and "Enhanced" or "Legacy"))
    else
        log("[AircraftSabotage] BreakOffRotor pattern not found (will retry next use)")
    end
    return r.addr
end

function aircraftSabotage.getVehAddr(veh)
    local vehPhys = GTA.HandleToPointer(veh)
    if not vehPhys then return nil end
    local a = vehPhys:GetAddress()
    if a and a > 0x10000 then return a end
    return nil
end

function aircraftSabotage.getVehicle(pid)
    if not isPlayerReady() then
        aircraftSabotage.toast("You aren't ready (cutscene / switch / not playing).")
        return nil
    end
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
        aircraftSabotage.toast("Player not connected.")
        return nil
    end
    if PLAYER.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
        aircraftSabotage.toast("Player's vehicle isn't streamed in. Spectate them first, then try again.")
        return nil
    end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then
        aircraftSabotage.toast("Player is too far away (not streamed in). Spectate them first, then try again.")
        return nil
    end
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        aircraftSabotage.toast("Player isn't in a vehicle.")
        return nil
    end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if not veh or veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then
        aircraftSabotage.toast("Couldn't find the player's vehicle.")
        return nil
    end
    local model = ENTITY.GET_ENTITY_MODEL(veh)
    return veh, model,
        Natives.InvokeBool(aircraftSabotage.H_IS_PLANE, model),
        Natives.InvokeBool(aircraftSabotage.H_IS_HELI, model)
end

function aircraftSabotage.takeControl(veh)
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then return true end
    local netId = Natives.InvokeInt(0xA11700682F3AD45C, veh)
    if Natives.InvokeBool(0xC7827959479DCC78, veh) then
        local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
        local me = Players.GetById(GTA.GetLocalPlayerId())
        if netObj and me then NetworkObjectMgr.ChangeOwner(netObj, me, 0) end
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
    if netId ~= 0 then
        Natives.InvokeBool(0xA670B3662FAFFBD0, netId)
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh)
end

function aircraftSabotage.run(pid, action)
    local veh, model, isPlane, isHeli = aircraftSabotage.getVehicle(pid)
    if not veh then return "done" end

    if action == "wing" and not isPlane then
        aircraftSabotage.toast("Detach Wing only works while the player is in a plane.")
        return "done"
    elseif action == "boom" and not isHeli then
        aircraftSabotage.toast("Break Off Tail Boom only works while the player is in a helicopter.")
        return "done"
    elseif action == "props" and not isPlane and not isHeli then
        aircraftSabotage.toast("Destroy Propellers / Rotors requires a plane or helicopter.")
        return "done"
    end

    if not aircraftSabotage.takeControl(veh) then
        return "retry"
    end

    if action == "props" then
        if isPlane then
            local vehAddr = aircraftSabotage.getVehAddr(veh)
            if not vehAddr then
                aircraftSabotage.toast("Couldn't resolve the plane's memory address.")
                return "done"
            end
            if aircraftSabotage.planeHasProps(vehAddr) then
                local fn = aircraftSabotage.resolveRotorFn()
                if not fn then
                    aircraftSabotage.toast("Propeller break-off unavailable (couldn't locate the game function).")
                    return "done"
                end
                for i = 0, aircraftSabotage.NUM_PROPS - 1 do
                    Memory.LuaCallCFunction(fn, vehAddr, i)
                end
                aircraftSabotage.toast("Plane propellers broken off.")
            else
                aircraftSabotage.killEngine(veh)
                aircraftSabotage.toast("Jet engine destroyed.")
            end
        else
            Natives.InvokeVoid(aircraftSabotage.H_MAIN_ROTOR_HEALTH, veh, -100.0)
            Natives.InvokeVoid(aircraftSabotage.H_TAIL_ROTOR_HEALTH, veh, -100.0)
            aircraftSabotage.toast("Helicopter rotors destroyed.")
        end
        return "ok"
    end

    if action == "wing" then
        local fn = aircraftSabotage.resolveSectionFn()
        if not fn then
            aircraftSabotage.toast("Wing detach unavailable (couldn't locate the game function).")
            return "done"
        end
        local vehAddr = aircraftSabotage.getVehAddr(veh)
        if not vehAddr then
            aircraftSabotage.toast("Couldn't resolve the plane's memory address.")
            return "done"
        end
        local section = aircraftSabotage.wingFlip
        aircraftSabotage.wingFlip = 1 - aircraftSabotage.wingFlip
        if pcall(Memory.LuaCallCFunction, fn,
                 vehAddr + aircraftSabotage.DMG_OFFSET, vehAddr, section, 0) then
            aircraftSabotage.toast(("%s wing broken off."):format(section == 0 and "Left" or "Right"))
            return "ok"
        end
        aircraftSabotage.toast("Wing detach call failed; check the Cherax log.")
        logErr("[AircraftSabotage] LuaCallCFunction(BreakOffSection) failed")
        return "done"
    else
        local fn = aircraftSabotage.resolveBoomFn()
        if not fn then
            aircraftSabotage.toast("Tail boom break unavailable (couldn't locate the game function).")
            return "done"
        end
        Natives.InvokeBool(aircraftSabotage.H_TAIL_BOOM_BREAK, veh, true)
        local vehAddr = aircraftSabotage.getVehAddr(veh)
        if not vehAddr then
            aircraftSabotage.toast("Couldn't resolve the helicopter's memory address.")
            return "done"
        end
        if pcall(Memory.LuaCallCFunction, fn, vehAddr, 0) then
            aircraftSabotage.toast("Tail boom broken off.")
            return "ok"
        end
        aircraftSabotage.toast("Tail boom break call failed; check the Cherax log.")
        logErr("[AircraftSabotage] LuaCallCFunction(BreakOffTailBoom) failed")
        return "done"
    end
end

function aircraftSabotage.dismantleExtras(veh, vehAddr, isPlane, isHeli)
    if isPlane then
        local sfn = aircraftSabotage.resolveSectionFn()
        if sfn then
            local this = vehAddr + aircraftSabotage.DMG_OFFSET
            for section = 0, 10 do
                Memory.LuaCallCFunction(sfn, this, vehAddr, section, 0)
            end
        end
        local rfn = aircraftSabotage.resolveRotorFn()
        if rfn then
            for i = 0, aircraftSabotage.NUM_PROPS - 1 do
                Memory.LuaCallCFunction(rfn, vehAddr, i)
            end
        end
        if not aircraftSabotage.planeHasProps(vehAddr) then
            aircraftSabotage.killEngine(veh)
        end
        return "Plane"
    elseif isHeli then
        local bfn = aircraftSabotage.resolveBoomFn()
        if bfn then
            Natives.InvokeBool(aircraftSabotage.H_TAIL_BOOM_BREAK, veh, true)
            Memory.LuaCallCFunction(bfn, vehAddr, 0)
        end
        Natives.InvokeVoid(aircraftSabotage.H_MAIN_ROTOR_HEALTH, veh, -100.0)
        Natives.InvokeVoid(aircraftSabotage.H_TAIL_ROTOR_HEALTH, veh, -100.0)
        return "Helicopter"
    end
    return nil
end

function aircraftSabotage.telemetryKey(action)
    return action == "wing" and "DetachWing"
        or action == "boom" and "BreakOffTailBoom"
        or "DestroyPropellerRotor"
end

function aircraftSabotage.onTick(f)
    if not f:IsToggled() or #aircraftSabotage.queue == 0 then return end
    local q = aircraftSabotage.queue
    aircraftSabotage.queue = {}
    local now = MISC.GET_GAME_TIMER()
    for i = 1, #q do
        local job = q[i]
        job.started = job.started or now
        if job.nextTry and now < job.nextTry then
            aircraftSabotage.queue[#aircraftSabotage.queue + 1] = job
        else
            local result = aircraftSabotage.run(job.pid, job.action)
            if result == "retry" and now - job.started < 3000 then
                job.nextTry = now + 100
                aircraftSabotage.queue[#aircraftSabotage.queue + 1] = job
            elseif result == "retry" then
                aircraftSabotage.toast(
                    "Couldn't get control of the player's aircraft after 3 seconds.")
            elseif result == "ok" then
                telemetryCountAction(aircraftSabotage.telemetryKey(job.action))
            end
        end
    end
end

function aircraftSabotage.addButton(hash, name, description, action)
    for _, featureHash in ipairs(FeatureMgr.AddPlayerFeature(
        hash, name, eFeatureType.Button, description,
        function(f)
            aircraftSabotage.queue[#aircraftSabotage.queue + 1] = {
                pid = f:GetPlayerIndex(), action = action
            }
        end)) do
        FeatureMgr.GetFeature(featureHash):SetSaveable(false)
    end
end

aircraftSabotage.addButton(H.DETACH_WING, "Detach Wing",
    "Snaps a wing off the player's plane.",
    "wing")
aircraftSabotage.addButton(H.BREAK_TAIL_BOOM, "Break Off Tail Boom",
    "Snaps the tail boom off the player's helicopter.",
    "boom")
aircraftSabotage.addButton(H.DESTROY_AIR_PROPS, "Destroy Propeller/Rotor",
    "Snaps every propeller/rotor off the airframe. On jets (no propeller) it destroys the engine instead.",
    "props")

centralOnTick(FeatureMgr.AddFeature(aircraftSabotage.runnerHash, "##AircraftSabotageRunner",
    eFeatureType.Toggle, "", aircraftSabotage.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(aircraftSabotage.runnerHash):Toggle()


H.VEHICLE_DISMANTLE_RUNNER = Utils.Joaat("LUA_VehicleDismantleRunner")

vehicleDismantle = {
    queue       = {},
    runnerHash  = H.VEHICLE_DISMANTLE_RUNNER,

    DMG_OFFSET    = 0x420,
    PARENT_REL    = 0x408,
    NUMWHEELS_OFF = 0xc38,
    BLOWUP_PASSES = 6,

    H_DOOR_BROKEN      = 0xD4D4F6A4AB575A33,
    H_WHEELS_CAN_BREAK = 0xA37B9A517B133349,

    blowUpFn = {
        addr = nil,
        enh  = "41 57 41 56 41 55 41 54 56 57 55 53 48 81 EC 08 01 00 00 44 0F 29 B4 24 F0 00 00 00 44 0F 29 AC 24 E0 00 00 00 44 0F 29 A4 24 D0 00 00 00 44 0F 29 9C 24 C0 00 00 00 44 0F 29 94 24 B0 00 00 00 44 0F 29 8C 24 A0 00 00 00 44 0F 29 84 24 90 00 00 00 0F 29 BC 24 80 00 00 00 0F 29 74 24 70 F3 0F 10 05 ? ? ? ? 0F 2E 05 ? ? ? ? 0F 83 ? ? ? ? 44 89 C6 49 89 CC 45 85 C0 74 15 49 8B 8C 24 08 04 00 00",
        leg  = "48 8B C4 48 89 58 08 48 89 50 10 55 56 57 41 54 41 55 41 56 41 57 48 81 EC D0 00 00 00 F3 0F 10 05 ? ? ? ? 0F 29 70 B8 44 0F 29 40 A8 F3 44 0F 10 05 ? ? ? ?",
    },

    wheelFn = {
        addr = nil,
        enh  = "41 57 41 56 41 55 41 54 56 57 55 53 48 83 EC 48 0F 29 7C 24 30 0F 29 74 24 20 0F 28 FB 0F 28 F2 89 D7 48 89 CB 80 3D ? ? ? ? 00",
        leg  = "48 8B C4 48 89 58 08 48 89 68 10 48 89 70 18 57 41 56 41 57 48 83 EC 40 80 3D ? ? ? ? 00 0F 29 78 D8 44 0F 29 40 C8 4C 63 F2 48 8B F1 44 0F 28 C2 0F 28 FB",
    },
}

function vehicleDismantle.toast(msg)
    GUI.AddToast("Dismantle Vehicle", msg, 3500)
end

function vehicleDismantle.resolveFn(slot, label)
    if slot.addr then return slot.addr end
    local pat = IS_ENHANCED and slot.enh or slot.leg
    local hit = Memory.Scan(pat)
    if hit and hit > 0x10000 then
        slot.addr = hit
        log(("[VehicleDismantle] %s @ 0x%X (%s)")
            :format(label, hit, IS_ENHANCED and "Enhanced" or "Legacy"))
    else
        log(("[VehicleDismantle] %s pattern not found (will retry next use)"):format(label))
    end
    return slot.addr
end

function vehicleDismantle.getVehicle(pid)
    if not isPlayerReady() then
        vehicleDismantle.toast("You aren't ready (cutscene / switch / not playing).")
        return nil
    end
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
        vehicleDismantle.toast("Player not connected.")
        return nil
    end
    if PLAYER.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
        vehicleDismantle.toast("Player's vehicle isn't streamed in. Spectate them first, then try again.")
        return nil
    end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then
        vehicleDismantle.toast("Player is too far away (not streamed in). Spectate them first, then try again.")
        return nil
    end
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        vehicleDismantle.toast("Player isn't in a vehicle.")
        return nil
    end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if not veh or veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then
        vehicleDismantle.toast("Couldn't find the player's vehicle.")
        return nil
    end
    local model = ENTITY.GET_ENTITY_MODEL(veh)
    return veh,
        Natives.InvokeBool(aircraftSabotage.H_IS_PLANE, model),
        Natives.InvokeBool(aircraftSabotage.H_IS_HELI, model)
end

function vehicleDismantle.run(pid)
    local veh, isPlane, isHeli = vehicleDismantle.getVehicle(pid)
    if not veh then return "done" end

    if not aircraftSabotage.takeControl(veh) then
        return "retry"
    end

    local vehAddr = aircraftSabotage.getVehAddr(veh)
    if not vehAddr then
        vehicleDismantle.toast("Couldn't resolve the vehicle's memory address.")
        return "done"
    end

    local dmg = vehAddr + vehicleDismantle.DMG_OFFSET
    local parent = Memory.ReadLong(dmg + vehicleDismantle.PARENT_REL)
    if parent ~= vehAddr then
        vehicleDismantle.toast("Vehicle layout check failed; dismantle unavailable on this build.")
        logErr("[VehicleDismantle] m_pParent mismatch (CVehicleDamage offset invalid?)")
        return "done"
    end

    Natives.InvokeVoid(vehicleDismantle.H_WHEELS_CAN_BREAK, veh, true)

    local bfn = vehicleDismantle.resolveFn(vehicleDismantle.blowUpFn, "BlowUpCarParts")
    if bfn then
        for _ = 1, vehicleDismantle.BLOWUP_PASSES do
            Memory.LuaCallCFunction(bfn, dmg, 0, 0)
        end
    end

    for door = 0, 5 do
        Natives.InvokeVoid(vehicleDismantle.H_DOOR_BROKEN, veh, door, false)
    end

    local wfn = vehicleDismantle.resolveFn(vehicleDismantle.wheelFn, "BreakOffWheel")
    if wfn then
        local n = Memory.ReadInt(vehAddr + vehicleDismantle.NUMWHEELS_OFF)
        if n and n > 0 and n <= 10 then
            for i = 0, n - 1 do
                Memory.LuaCallCFunction(wfn, dmg, i)
            end
        end
    elseif bfn then
        vehicleDismantle.toast("Wheel break-off unavailable (couldn't locate the game function).")
    end

    local kind = aircraftSabotage.dismantleExtras(veh, vehAddr, isPlane, isHeli)

    if bfn then
        vehicleDismantle.toast((kind or "Vehicle") .. " dismantled.")
        return "ok"
    end
    vehicleDismantle.toast("Dismantle unavailable (couldn't locate the game function).")
    return "done"
end

function vehicleDismantle.onTick(f)
    if not f:IsToggled() or #vehicleDismantle.queue == 0 then return end
    local q = vehicleDismantle.queue
    vehicleDismantle.queue = {}
    local now = MISC.GET_GAME_TIMER()
    for i = 1, #q do
        local job = q[i]
        job.started = job.started or now
        if job.nextTry and now < job.nextTry then
            vehicleDismantle.queue[#vehicleDismantle.queue + 1] = job
        else
            local result = vehicleDismantle.run(job.pid)
            if result == "retry" and now - job.started < 3000 then
                job.nextTry = now + 100
                vehicleDismantle.queue[#vehicleDismantle.queue + 1] = job
            elseif result == "retry" then
                vehicleDismantle.toast("Couldn't get control of the player's vehicle after 3 seconds.")
            elseif result == "ok" then
                telemetryCountAction("DismantleVehicle")
            end
        end
    end
end

for _, featureHash in ipairs(FeatureMgr.AddPlayerFeature(
    H.DISMANTLE_VEHICLE, "Dismantle Vehicle", eFeatureType.Button,
    "Breaks off as much as the vehicle has in one go - doors, bumpers, fenders, wheels, panels and more, plus wings/tail/props on planes and the tail boom/rotors on helis. Works on any vehicle.",
    function(f)
        vehicleDismantle.queue[#vehicleDismantle.queue + 1] = { pid = f:GetPlayerIndex() }
    end)) do
    FeatureMgr.GetFeature(featureHash):SetSaveable(false)
end

centralOnTick(FeatureMgr.AddFeature(vehicleDismantle.runnerHash, "##VehicleDismantleRunner",
    eFeatureType.Toggle, "", vehicleDismantle.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(vehicleDismantle.runnerHash):Toggle()



centralOnTick(FeatureMgr.AddFeature(H.RAPID_FIRE, "Vehicle Rapid Fire", eFeatureType.Toggle,
    "Makes vehicle weapons fire much faster by modifying reload timing in memory",
    rapidFireOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.VEH_INF_AMMO, "Vehicle Infinite Ammo", eFeatureType.Toggle,
    "Gives personal weaponized vehicles and aircraft infinite missiles and bombs, and auto-refills chaff/flares",
    vehInfiniteAmmoOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.ROCKET_SPEED, "Rocket Speed", eFeatureType.SliderFloatToggle,
    "Multiplies vehicle rocket/projectile launch speed",
    function(f)
        weaponState.rocketSpeedMult = f:GetFloatValue()
        rocketSpeedOnTick(f)
    end))
    :SetNoCallbackOnPress(true)
    :SetLimitValues(0.0, 30.0)
    :SetDefaultValue(1.0)
    :SetSaveable(false)
    :Reset()

centralOnTick(FeatureMgr.AddFeature(H.INSTANT_ROCKET, "Instant Rocket", eFeatureType.Toggle,
    "Instant vehicle rocket damage - explodes directly on lock-on targets or raycasts to impact point when free-aiming",
    instantRocketOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.INFINITE_RANGE, "Rocket Range", eFeatureType.SliderFloatToggle,
    "Multiplies projectile lifetime (2x = 2x range)",
    function(f)
        weaponState.rangeMult = f:GetFloatValue()
        infiniteRangeOnTick(f)
    end))
    :SetNoCallbackOnPress(true)
    :SetLimitValues(1.0, 30.0)
    :SetDefaultValue(1.0)
    :SetSaveable(false)
    :Reset()

centralOnTick(FeatureMgr.AddFeature(H.INSTANT_LOCKON, "Instant Lockon", eFeatureType.Toggle,
    "Removes homing missile lock-on delay and extends lock-on range",
    instantLockonOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.AUTO_LOCKON_FIRE, "Auto Lock-On Fire", eFeatureType.Toggle,
    "Automatically fires vehicle weapons when locked onto a target. Works with Rapid Fire for maximum spam.",
    autoLockonFireOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


centralOnTick(FeatureMgr.AddFeature(H.INF_LOCKON_RANGE, "Infinite Lock-On Range", eFeatureType.Toggle,
    "Maxes vehicle rocket lock-on range.",
    infLockonRange.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


centralOnTick(FeatureMgr.AddFeature(H.LOCK_ONTO_PLAYERS, "Lock Onto Players", eFeatureType.Toggle,
    "Vehicle rockets target on foot players. Works with on foot homing launcher.",
    lockOntoPlayers.onTick, true))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
if VIBESCRIPT_VERBOSE then
    Logger.LogInfo(string.format(
        "[VibeScript] LockOntoPlayers registered (build=%s)",
        IS_ENHANCED and "Enhanced" or "Legacy"))
end

centralOnTick(FeatureMgr.AddFeature(H.LOCK_ONTO_NPCS, "Lock Onto NPCs", eFeatureType.Toggle,
    "Lets vehicle homing missiles lock onto on-foot NPCs (not just threats like cops). Works independently of Lock Onto Players.",
    lockOntoPlayers.lockOntoNPCs.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.DISABLE_LOS, "Disable Line Of Sight", eFeatureType.Toggle,
    "Lets vehicle homing missiles lock onto targets through walls and buildings. Works with on foot homing launcher.",
    lockOntoPlayers.disableLOS.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


centralOnTick(FeatureMgr.AddFeature(H.OPP_NERF, "Oppressor Rockets", eFeatureType.Toggle,
    "Restores Deluxo-level missile tracking for MK1 and MK2",
    oppressorNerfOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.LAZER_NERF, "Lazer/Hydra Cannons", eFeatureType.Toggle,
    "Restores pre-nerf cannon fire rate (0.04), damage, and explosion radius",
    lazerNerfOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.CANNON_RANGE, "Cannon Range", eFeatureType.Toggle,
    "Extends hitscan vehicle weapon range to 5000m",
    cannonRangeOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.ALL_ROCKETS, "Buff All Rockets", eFeatureType.Toggle,
    "Gives every vehicle missile weapon Deluxo-level homing",
    allRocketsNerfOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


centralOnTick(FeatureMgr.AddFeature(H.FLY_WINDSCREEN, "Fly Through Windscreen", eFeatureType.Toggle,
    "Throws you out of the vehicle on high-speed frontal collisions like in Story Mode",
    patchFn.flyWindscreenOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)



centralOnTick(FeatureMgr.AddFeature(H.PAUSED_SPOOF, "Paused Spoofing", eFeatureType.Toggle,
    "Makes you appear paused to other players while you can still move around",
    patchFn.pausedSpoofOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.PASSIVE_SPOOF, "Passive Mode Spoof", eFeatureType.Toggle,
    "Others see you in passive mode (crossed-out circle, untargetable) but you can still attack",
    passiveSpoofOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

do
    local p = { PATCHED = 0xC3, addr = nil, retryIn = 0, missLogged = false }
    if IS_ENHANCED then
        p.ANCHOR   = "48 81 EC 30 09 00 00 48 89 CE 03 15"
        p.SITE_OFF = -1
        p.ORIG     = 0x56
    else
        p.ANCHOR   = "89 91 1C 83 02 00 E9"
        p.SITE_OFF = -6
        p.ORIG     = 0x03
    end

    p.resolve = function()
        if p.addr then return true end
        if p.retryIn > 0 then p.retryIn = p.retryIn - 1; return false end
        p.retryIn = 120
        local runBody = function()
            local hit = Memory.Scan(p.ANCHOR)
            if not hit or hit == 0 then
                if not p.missLogged then
                    p.missLogged = true
                    Logger.LogInfo("[VibeScript] Better Escape: anchor not found yet (retrying)")
                end
                return
            end
            local site = hit + p.SITE_OFF
            local b = Memory.ReadUByte(site)
            if b ~= p.ORIG and b ~= p.PATCHED then
                Logger.LogInfo(string.format(
                    "[VibeScript] Better Escape: unexpected site byte 0x%02X @0x%X; aborting", b or 0, site))
                return
            end
            p.addr = site
            logf("Better Escape: resolved @0x%X (cur=0x%02X)", site, b)
        end
        runBody()
        return p.addr ~= nil
    end

    p.ensure = function(wantPatched)
        if not p.resolve() then return end
        do
            local cur = Memory.ReadUByte(p.addr)
            if wantPatched then
                if cur == p.ORIG then Memory.WriteByte(p.addr, p.PATCHED) end
            else
                if cur == p.PATCHED then Memory.WriteByte(p.addr, p.ORIG) end
            end
        end
    end

    EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function() pcall(p.ensure, false) end)

    centralOnTick(FeatureMgr.AddFeature(H.BETTER_ESC_ENGINE, "Better Escape", eFeatureType.Toggle,
        "Removes the short delay before Escape can reopen the pause menu after closing it.",
        function(f)
            p.ensure(f:IsToggled())
        end))
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end

centralOnTick(FeatureMgr.AddFeature(H.WP_INTERIOR, "Allow Exterior Waypoint", eFeatureType.Toggle,
    "Lets you set a waypoint from the pause map while inside interiors.",
    function(f)
        if not f:IsToggled() then return end
        if not HUD.IS_PAUSE_MENU_ACTIVE() then return end
        local interior = Natives.InvokeInt(0x2107BA504071A6BB, PLAYER.PLAYER_PED_ID())
        if not interior or interior == 0 then return end
        Natives.InvokeVoid(0x58FADDED207897DC, false)
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


do
    local yogaRun = {
        H_RUN    = 0xC5286FFC176F28A2,
        H_SPRINT = 0x57E457CD2C0FC168,
        H_MOVE   = 0x085BF80FA50A39D1,
        H_WATER  = 0x0B3E35AC043707D9,
        MULT     = 1.15,
    }
    centralOnTick(FeatureMgr.AddFeature(H.YOGA_RUN, "Yoga Run", eFeatureType.Toggle,
        "Reproduces GTA Online's mansion Yoga speed buff. Provides a 15% speed increase on land and water.",
        function(f)
            if not f:IsToggled() then return end
            local ped = PLAYER.PLAYER_PED_ID()
            if Natives.InvokeBool(yogaRun.H_RUN, ped) or Natives.InvokeBool(yogaRun.H_SPRINT, ped) then
                Natives.InvokeVoid(yogaRun.H_MOVE,  ped, yogaRun.MULT + 0.0)
                Natives.InvokeVoid(yogaRun.H_WATER, ped, yogaRun.MULT + 0.0)
            end
        end))
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end


patchFn.wpInsideInterior = {
    LEGACY_SITES = {
        { AOB = "38 0D ?? ?? ?? ?? 75 ?? 38 0D ?? ?? ?? ?? 75 ?? 38 0D ?? ?? ?? ?? 75 ?? B9 01 00 00 00",
          PATCH_OFF = 6, ORIG_BYTES = { 0x75, 0x15 }, NEW_BYTES = { 0x90, 0x90 } },
    },
    ENHANCED_SITES = {
        { AOB = "08 C1 80 F9 01 0F 85 ?? ?? ?? ?? 80 3D ?? ?? ?? ?? 00 0F 85 ?? ?? ?? ?? 80 3D ?? ?? ?? ?? 00 0F 85 ?? ?? ?? ?? 80 3D ?? ?? ?? ?? 00 0F 85 ?? ?? ?? ?? 84 DB",
          PATCH_OFF = 18, ORIG_BYTES = { 0x0F, 0x85, 0x86, 0x02, 0x00, 0x00 },
          VERIFY_BYTES = { 0x0F, 0x85 }, CAPTURE_LEN = 6,
          NEW_BYTES = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 } },
        { AOB = "84 C8 75 ?? 80 3D ?? ?? ?? ?? 00 75 ?? 80 3D ?? ?? ?? ?? 00 75 ?? 0F B6 1D",
          PATCH_OFF = 11, ORIG_BYTES = { 0x75, 0x32 }, NEW_BYTES = { 0x90, 0x90 },
          VERIFY_BYTES = { 0x75 }, CAPTURE_LEN = 2,
        },
    },
    sites = nil, scanned = false, applied = false, resolveFailLogged = false,
    rayBuf = Memory.Alloc(64),
}
patchFn.wpInsideInterior.resolve = function()
    local p = patchFn.wpInsideInterior
    if p.sites then return #p.sites > 0 end
    if p.scanned then return false end
    p.scanned = true
    local defs = IS_ENHANCED and p.ENHANCED_SITES or p.LEGACY_SITES
    local resolved = {}
    for i = 1, #defs do
        local d = defs[i]
        local site, orig = nil, nil
        local runBody = function()
            local hit = Memory.Scan(d.AOB)
            if not hit or hit == 0 then return end
            local s = hit + d.PATCH_OFF
            local verify = d.VERIFY_BYTES or d.ORIG_BYTES
            for j = 1, #verify do
                if Memory.ReadUByte(s + (j - 1)) ~= verify[j] then return end
            end
            if d.CAPTURE_LEN then
                orig = {}
                for j = 1, d.CAPTURE_LEN do
                    orig[j] = Memory.ReadUByte(s + (j - 1))
                end
            else
                orig = d.ORIG_BYTES
            end
            site = s
        end
        runBody()
        if site then
            resolved[#resolved + 1] = { addr = site, ORIG_BYTES = orig, NEW_BYTES = d.NEW_BYTES }
        end
    end
    p.sites = resolved
    if #resolved == 0 and not p.resolveFailLogged then
        p.resolveFailLogged = true
        Logger.LogInfo("[VibeScript] WaypointsInsideInteriors: no patch sites resolved; feature off")
    end
    return #resolved > 0
end
patchFn.wpInsideInterior.apply = function()
    local p = patchFn.wpInsideInterior
    if p.applied then return true end
    if not p.resolve() then return false end
    local anyOk = false
    for i = 1, #p.sites do
        local s = p.sites[i]
        local runBody = function()
            for j = 1, #s.ORIG_BYTES do
                if Memory.ReadUByte(s.addr + (j - 1)) ~= s.ORIG_BYTES[j] then return end
            end
            for j = 1, #s.NEW_BYTES do Memory.WriteByte(s.addr + (j - 1), s.NEW_BYTES[j]) end
            anyOk = true
        end
        runBody()
    end
    p.applied = anyOk
    return p.applied
end
patchFn.wpInsideInterior.restore = function()
    local p = patchFn.wpInsideInterior
    if not p.sites then p.applied = false; return end
    do
        for i = 1, #p.sites do
            local s = p.sites[i]
            for j = 1, #s.ORIG_BYTES do Memory.WriteByte(s.addr + (j - 1), s.ORIG_BYTES[j]) end
        end
    end
    p.applied = false
end

patchFn.wpInsideInterior.CHERAX_AUTO_TP_HASH = 0xD13C7A27
patchFn.wpInsideInterior.resolveCheraxAutoTp = function()
    local p = patchFn.wpInsideInterior
    if p.cheraxAutoTp then return p.cheraxAutoTp end

    local ft = FeatureMgr.GetFeature(p.CHERAX_AUTO_TP_HASH)
    if ft then
        local gotHash = ft:GetHash()
        local isToggle = ft:IsToggleFeature()
        if gotHash == p.CHERAX_AUTO_TP_HASH and isToggle then
            p.cheraxAutoTp = ft
            if not p.cheraxLogged then
                p.cheraxLogged = true
                log(("[WPautoTP] resolved Cherax auto-teleport by hash=0x%X"):format(p.CHERAX_AUTO_TP_HASH))
            end
        end
    end
    if p.cheraxAutoTp then return p.cheraxAutoTp end

    if p.heuristicTried then return nil end
    p.heuristicTried = true
    local feats = FeatureMgr.GetAllFeatures()
    if feats then
        local toggles, chosen = {}, nil
        for _, ft in pairs(feats) do
            local name = ft:GetName(false)
            if name then
                local n = name:lower()
                if n:find("waypoint") and (n:find("teleport") or n:find("tp")) then
                    local isToggle = ft:IsToggleFeature()
                    log(("[WPautoTP] candidate '%s' toggle=%s"):format(name, tostring(isToggle)))
                    if isToggle then
                        toggles[#toggles + 1] = ft
                        if n:find("auto") then chosen = ft end
                    end
                end
            end
        end
        if not chosen and #toggles == 1 then chosen = toggles[1] end
        p.cheraxAutoTp = chosen
        if chosen then
            log(("[WPautoTP] using Cherax auto-teleport feature (name heuristic) hash=0x%X"):format(chosen:GetHash()))
        else
            log("[WPautoTP] no Cherax auto-teleport feature found (hash + name heuristic both failed); leaving teleport alone")
        end
    end
    return p.cheraxAutoTp
end
patchFn.wpInsideInterior.probeFloorZ = function(x, y, nearZ)
    local p = patchFn.wpInsideInterior
    if not p.rayBuf then return nil end
    local belowBest, aboveBest = nil, nil
    do
        local ped = PLAYER.PLAYER_PED_ID()
        local bottom = nearZ - 30.0
        local thresh = nearZ + 1.0
        local aboveCap = nearZ + 2.0
        local z = nearZ + 12.0
        for _ = 1, 16 do
            local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
                x, y, z, x, y, bottom, -1, ped, 7)
            SHAPETEST.GET_SHAPE_TEST_RESULT(handle, p.rayBuf, p.rayBuf + 8, p.rayBuf + 32, p.rayBuf + 56)
            if Memory.ReadByte(p.rayBuf) == 0 then break end
            local hz = Memory.ReadFloat(p.rayBuf + 24)
            local nz = Memory.ReadFloat(p.rayBuf + 48)
            if nz > 0.5 then
                if hz <= thresh then
                    if belowBest == nil or hz > belowBest then belowBest = hz end
                elseif hz <= aboveCap then
                    if aboveBest == nil or hz < aboveBest then aboveBest = hz end
                end
            end
            z = hz - 0.5
            if z <= bottom then break end
        end
    end
    if belowBest ~= nil then return belowBest end
    return aboveBest
end
patchFn.wpInsideInterior.tickRoomFix = function()
    local p = patchFn.wpInsideInterior
    if not p.roomFixTicks or p.roomFixTicks <= 0 then return end
    local paused = HUD.IS_PAUSE_MENU_ACTIVE()
    if not paused then p.roomFixTicks = p.roomFixTicks - 1 end
    local runBody = function()
        local ped = PLAYER.PLAYER_PED_ID()
        local ent = ped
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if veh and veh ~= 0 then ent = veh end
        end
        local entInt  = Natives.InvokeInt(0x2107BA504071A6BB, ent)
        local entRoom = Natives.InvokeInt(0x399685DB942336BC, ent)
        if entInt ~= 0 and entRoom ~= 0 then
            if not p.roomFixResolvedLogged then
                p.roomFixResolvedLogged = true
                log(("[WPautoTP] roomfix: entity self-resolved interior=%d room=%d"):format(entInt, entRoom))
            end
            p.roomFixTicks = 0
            return
        end
        if not paused and (p.roomFixGrace or 0) > 0 then p.roomFixGrace = p.roomFixGrace - 1; return end
        Natives.InvokeVoid(0x405DC2AEF6AF95B9, 0)
        local vpRoom = Natives.InvokeInt(0xA6575914D2A0B450)
        if vpRoom == 0 or vpRoom == -1 then return end
        local cam = V3.New(Natives.InvokeV3(0xA200EB1EE790F448))
        local camInt = cam and Natives.InvokeInt(0xB0F7F8663821D9C3, cam.x, cam.y, cam.z) or 0
        if camInt == 0 then camInt = p.roomFixDestInt or 0 end
        if camInt == 0 then return end
        if not Natives.InvokeBool(0x6726BDCCC1932F0E, camInt) then return end
        p.roomFixTries = (p.roomFixTries or 0) + 1
        Natives.InvokeVoid(0x52923C4710DD9907, ent, camInt, vpRoom)
        local newRoom = Natives.InvokeInt(0x399685DB942336BC, ent)
        log(("[WPautoTP] roomfix force try=%d camInt=%d vpRoom=%d -> entityRoom=%d"):format(p.roomFixTries, camInt, vpRoom, newRoom))
        if newRoom ~= 0 then
            p.roomFixTicks = 0
        elseif p.roomFixTries >= 5 then
            p.roomFixTicks = 0
            log("[WPautoTP] roomfix: gave up after 5 force tries (entity still outside)")
        end
    end
    runBody()
end
patchFn.wpInsideInterior.autoTeleportTick = function()
    local p = patchFn.wpInsideInterior
    if not Natives.InvokeBool(0x1DD1F58F493F1DA5) then
        p.lastWpX = nil
        return
    end
    local runBody = function()
        local blip = Natives.InvokeInt(0x1BEDE233E6CD2A1F, 8)
        if not blip or blip == 0 then return end
        local c = V3.New(Natives.InvokeV3(0xFA7C7F0AADF25D09, blip))
        if not c then return end
        if p.lastWpX and math.abs(c.x - p.lastWpX) < 1.0 and math.abs(c.y - p.lastWpY) < 1.0 then
            return
        end
        p.lastWpX, p.lastWpY = c.x, c.y
        local ped = PLAYER.PLAYER_PED_ID()
        local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
        local interior = Natives.InvokeInt(0x2107BA504071A6BB, ped)
        local targetZ
        if interior ~= 0 and math.abs(c.x - pos.x) < 300.0 and math.abs(c.y - pos.y) < 300.0 then
            local fz = p.probeFloorZ(c.x, c.y, pos.z)
            if not fz then
                Natives.InvokeVoid(0xA7E4E2D361C2627F)
                p.lastWpX, p.lastWpY = nil, nil
                log(("[WPautoTP] no floor under (%.2f, %.2f) inside interior; cleared waypoint, no teleport"):format(c.x, c.y))
                return
            end
            targetZ = fz + 1.0
            p.roomFixDestInt = Natives.InvokeInt(0xB0F7F8663821D9C3, c.x, c.y, targetZ)
            p.roomFixTicks, p.roomFixGrace, p.roomFixTries = 90, 12, 0
            p.roomFixResolvedLogged = false
        else
            targetZ = c.z
            p.roomFixTicks = 0
        end
        local entity = ped
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if veh and veh ~= 0 then entity = veh end
        end
        STREAMING.REQUEST_COLLISION_AT_COORD(c.x, c.y, targetZ)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, c.x, c.y, targetZ, false, false, false)
        Natives.InvokeVoid(0xA7E4E2D361C2627F)
        p.lastWpX, p.lastWpY = nil, nil
        log(("[WPautoTP] teleported to (%.2f, %.2f, %.2f) [playerZ=%.2f] interior=%s"):format(c.x, c.y, targetZ, pos.z, tostring(interior ~= 0)))
    end
    runBody()
end
patchFn.wpInsideInterior.releaseCheraxAutoTp = function(keepLastWp)
    local p = patchFn.wpInsideInterior
    if p.cheraxWasOn and p.cheraxAutoTp then
        p.cheraxAutoTp:Toggle(true)
    end
    p.tookOver = false
    p.cheraxWasOn = false
    if not keepLastWp then p.lastWpX = nil end
end

centralOnTick(FeatureMgr.AddFeature(H.WP_INSIDE_INT, "Allow Interior Waypoint", eFeatureType.Toggle,
    "Drop a waypoint directly on the interior floorplan map and teleport to it. While you are inside an interior on the floorplan view, replaces Cherax's auto-teleport-on-waypoint with an interior-aware version (lands at the interior floor instead of the surface above). Outside interiors, or when you zoom the pause map out to the full world map, Cherax's normal auto-teleport stays in charge. Restores your Cherax setting when turned off.",
    function(f)
        local p = patchFn.wpInsideInterior
        if not f:IsToggled() then
            p.roomFixTicks = 0
            if p.applied then p.restore() end
            if p.tookOver or p.cheraxWasOn then p.releaseCheraxAutoTp() end
            return
        end
        p.apply()
        p.tickRoomFix()

        local ped = PLAYER.PLAYER_PED_ID()
        local interior = Natives.InvokeInt(0x2107BA504071A6BB, ped)
        local inInterior = interior ~= 0
        local pauseActive = HUD.IS_PAUSE_MENU_ACTIVE()
        if inInterior and pauseActive then
            Natives.InvokeVoid(0x58FADDED207897DC, false)
        end

        local onFullMap = false
        if inInterior and pauseActive then
            local inIntMode = Natives.InvokeBool(0x9049FE339D5F6F6F)
            onFullMap = not inIntMode
        end
        local wantOwn = inInterior and not onFullMap

        local feat = p.resolveCheraxAutoTp()
        if feat then
            if wantOwn then
                local isOn = feat:IsToggled()
                if isOn and not p.tookOver then
                    p.cheraxWasOn = true
                    feat:Toggle(false)
                    p.tookOver = true
                    log("[WPautoTP] took over Cherax auto-teleport (interior-aware)")
                elseif p.tookOver and isOn then
                    feat:Toggle(false)
                end
                if p.tookOver then p.autoTeleportTick() end
            elseif p.tookOver or p.cheraxWasOn then
                p.releaseCheraxAutoTp(true)
                log("[WPautoTP] handed auto-teleport back to Cherax (outside interior / full map)")
            end
        end
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


patchFn.autoTpObjective = {
    SCAN_SEC      = 0.4,
    SUPPRESS_DIST = 3.0,
    KOSATKA_SPRITE = 760,
    Z_OFFSET      = 6.0,
    WHITE_COLOURS = { [0] = true, [4] = true },
    SPRITES = {
        {535,-1},{536,-1},{537,-1},{538,-1},{539,-1},{540,-1},{541,-1},{542,-1},
        {1,-1},
        {432,-1},
        {568,-1},
        {64,57},{501,57},{556,57},{225,57},{280,57},{631,57},
        {760,60},
        {765,2},{459,2},
    },
    lastBlip = nil,
    lastTpX = nil, lastTpY = nil,
    nextScan = 0.0,
}
patchFn.autoTpObjective.teleportTo = function(x, y, z, sprite)
    local p = patchFn.autoTpObjective
    local ped = PLAYER.PLAYER_PED_ID()
    local entity = ped
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh and veh ~= 0 then entity = veh end
    end
    local off = (sprite == p.KOSATKA_SPRITE) and p.Z_OFFSET or 0.0
    local tz = (z or 0.0) + off
    STREAMING.REQUEST_COLLISION_AT_COORD(x, y, tz)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, x, y, tz, false, false, false)
end
patchFn.autoTpObjective.findObjectiveCoord = function()
    local p = patchFn.autoTpObjective
    local ped = PLAYER.PLAYER_PED_ID()
    local pp = ENTITY.GET_ENTITY_COORDS(ped, true)
    local bestX, bestY, bestZ, bestSprite, bestBlip, bestColour, bestDsq
    for _, s in ipairs(p.SPRITES) do
        local sprite, colour = s[1], s[2]
        local blip = Natives.InvokeInt(0x1BEDE233E6CD2A1F, sprite)
        while blip and blip ~= 0 do
            local bc = Natives.InvokeInt(0xDF729E8D20CF7327, blip)
            if (colour == -1 or bc == colour) and not p.WHITE_COLOURS[bc] then
                local ent = Natives.InvokeInt(0x4BA4E2553AFEDC2C, blip)
                if not (ent ~= 0 and ENTITY.IS_ENTITY_A_PED(ent) and PED.IS_PED_A_PLAYER(ent)) then
                    local c = V3.New(Natives.InvokeV3(0xFA7C7F0AADF25D09, blip))
                    if c then
                        local dx, dy = c.x - pp.x, c.y - pp.y
                        local dsq = dx * dx + dy * dy
                        if not bestDsq or dsq < bestDsq then
                            bestX, bestY, bestZ, bestSprite, bestBlip, bestColour, bestDsq = c.x, c.y, c.z, sprite, blip, bc, dsq
                        end
                    end
                end
            end
            blip = Natives.InvokeInt(0x14F96AA50D6FBEA7, sprite)
        end
    end
    return bestX, bestY, bestZ, bestSprite, bestBlip, bestColour
end
patchFn.autoTpObjectiveOnTick = function(f)
    if scriptUnloading then return end
    local p = patchFn.autoTpObjective
    if not f:IsToggled() then
        p.lastBlip, p.lastTpX, p.lastTpY = nil, nil, nil
        return
    end
    local now = os.clock()
    if now < p.nextScan then return end
    p.nextScan = now + p.SCAN_SEC

    local ox, oy, oz, osprite, oblip, ocolour = p.findObjectiveCoord()
    if not oblip then return end

    if oblip == p.lastBlip then return end
    if p.lastTpX then
        local dx, dy = ox - p.lastTpX, oy - p.lastTpY
        if dx * dx + dy * dy < (p.SUPPRESS_DIST * p.SUPPRESS_DIST) then return end
    end

    p.lastBlip = oblip
    p.lastTpX, p.lastTpY = ox, oy
    p.teleportTo(ox, oy, oz, osprite)
    logf("[AutoTPObj] teleported to objective (%.1f, %.1f, %.1f) sprite=%d colour=%d blip=%d", ox, oy, oz or 0.0, osprite or 0, ocolour or -1, oblip)
end

centralOnTick(FeatureMgr.AddFeature(H.AUTO_TP_OBJECTIVE, "Auto Teleport To Objective", eFeatureType.Toggle,
    "Automatically teleport to objectives, including mission blips.",
    patchFn.autoTpObjectiveOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


rickHorn = {
    SET_VEHICLE_MOD_KIT      = 0x1F2AA07F00B3217A,
    SET_VEHICLE_MOD          = 0x6AF0636DDEDCB6DD,
    GET_VEHICLE_MOD          = 0x772960298DA26FDB,
    REMOVE_VEHICLE_MOD       = 0x92D619E420858204,
    GET_VEHICLE_DEFAULT_HORN = 0x02165D55000219AC,
    OVERRIDE_VEH_HORN        = 0x3CDC1E622CCE0356,
    SET_VEH_IN_CAR_MOD_SHOP  = 0x9D44FCCE98450843,
    START_VEHICLE_HORN       = 0x9C8C6504B5B63D2C,
    SET_HORN_ENABLED         = 0x76D683C108594D0E,
    IS_HORN_ACTIVE           = 0x9D6BFC12B05C6121,
    HORN_MOD_TYPE  = 14,
    SCALE_BASE_MOD = 16,
    HORN_TYPE_HELD = 0x839504CB,
    INPUT_VEH_HORN = 86,
    GAP_MS         = 40,
    song = {
        tempo = 265,
        notes = {
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{5,1.5},{5,1.5},{4,3},
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{4,1.5},{4,1.5},{3,1.5},{2,0.5},{1,1},
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{3,2},{4,1},{2,1.5},{1,0.5},
            {0,2},{0,1},{4,2},{3,4},
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{5,1.5},{5,1.5},{4,3},
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{7,2},{2,1},{3,1.5},{2,0.5},{1,1},
            {0,0.5},{1,0.5},{3,0.5},{1,0.5},{3,2},{4,1},{2,1.5},{1,0.5},
            {0,2},{0,1},{4,2},{3,4},
        },
    },
    active = false, done = false, noteIdx = 0, veh = 0, origMod = nil,
    curIdx = -1, noteStart = 0, slotMs = 0, gapMs = 0, attackStarted = false,
    modShopPulseActive = false, modShopSawAttackTick = false,
    cachedHash = {}, warmVeh = 0, warmOrigMod = nil, warmIdx = 0, warmSet = false,
}

function rickHorn.cacheReady()
    for i = 0, 7 do
        if not rickHorn.cachedHash[i] or rickHorn.cachedHash[i] == 0 then
            return false
        end
    end
    return true
end

function rickHorn.finishWarmup()
    local s = rickHorn
    local veh = s.warmVeh
    if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) and s.warmOrigMod ~= nil then
        if s.warmOrigMod >= 0 then
            Natives.InvokeVoid(s.SET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE, s.warmOrigMod, false)
        else
            Natives.InvokeVoid(s.REMOVE_VEHICLE_MOD, veh, s.HORN_MOD_TYPE)
        end
    end
    s.warmVeh     = 0
    s.warmOrigMod = nil
    s.warmIdx     = 0
    s.warmSet     = false
end

function rickHorn.warmCache(veh)
    local s = rickHorn
    if s.cacheReady() then return true end
    if s.warmVeh ~= 0 and s.warmVeh ~= veh then s.finishWarmup() end
    if s.warmVeh == 0 then
        s.warmVeh     = veh
        s.warmOrigMod = Natives.InvokeInt(s.GET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE)
        s.warmIdx     = 0
        s.warmSet     = false
        Natives.InvokeVoid(s.SET_VEHICLE_MOD_KIT, veh, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
    end
    if not s.warmSet then
        Natives.InvokeVoid(s.SET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE,
            s.SCALE_BASE_MOD + s.warmIdx, false)
        s.warmSet = true
    else
        local h = Natives.InvokeInt(s.GET_VEHICLE_DEFAULT_HORN, veh)
        if h and h ~= 0 then
            s.cachedHash[s.warmIdx] = h
            s.warmIdx = s.warmIdx + 1
        end
        s.warmSet = false
        if s.warmIdx > 7 then
            s.finishWarmup()
            return true
        end
    end
    return false
end

function rickHorn.stop()
    local s = rickHorn
    local veh = s.veh
    if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
        Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, false)
        Natives.InvokeVoid(s.SET_VEH_IN_CAR_MOD_SHOP, veh, false)
        Natives.InvokeVoid(s.OVERRIDE_VEH_HORN, veh, false, 0)
        if s.origMod ~= nil then
            if s.origMod >= 0 then
                Natives.InvokeVoid(s.SET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE, s.origMod, false)
            else
                Natives.InvokeVoid(s.REMOVE_VEHICLE_MOD, veh, s.HORN_MOD_TYPE)
            end
        end
        Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, true)
    end
    s.active    = false
    s.done      = false
    s.noteIdx   = 0
    s.veh       = 0
    s.curIdx    = -1
    s.noteStart = 0
    s.slotMs    = 0
    s.gapMs     = 0
    s.origMod   = nil
    s.modShopPulseActive = false
    s.modShopSawAttackTick = false
    s.attackStarted = false
end

function rickHorn.advanceNote(veh, now)
    local s = rickHorn
    s.noteIdx = s.noteIdx + 1
    local note = s.song.notes[s.noteIdx]
    if not note then return false end
    s.curIdx    = note[1]
    s.slotMs    = math.floor(note[2] * s.song.tempo)
    s.gapMs     = math.min(s.GAP_MS, math.floor(s.slotMs * 0.35))
    s.noteStart = now
    s.attackStarted = false
    Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, false)
    if s.curIdx >= 0 then
        Natives.InvokeVoid(s.SET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE,
            s.SCALE_BASE_MOD + s.curIdx, false)
        Natives.InvokeVoid(s.SET_VEH_IN_CAR_MOD_SHOP, veh, true)
        s.modShopPulseActive = true
        s.modShopSawAttackTick = false
    end
    return true
end

rickHorn.onTick = function(f)
    local s = rickHorn
    if not f:IsToggled() or not isPlayerReady() then
        if s.active then s.stop() end
        if s.warmVeh ~= 0 then s.finishWarmup() end
        return
    end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    if ped == 0 or not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        if s.active then s.stop() end
        if s.warmVeh ~= 0 then s.finishWarmup() end
        return
    end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then
        if s.active then s.stop() end
        if s.warmVeh ~= 0 then s.finishWarmup() end
        return
    end

    local hornHeld = PAD.IS_DISABLED_CONTROL_PRESSED(0, s.INPUT_VEH_HORN)

    if not s.active then
        PAD.DISABLE_CONTROL_ACTION(0, s.INPUT_VEH_HORN, true)
        if not s.warmCache(veh) then return end
        if not hornHeld then return end
    elseif not hornHeld then
        s.stop()
        return
    end

    if not s.active or s.veh ~= veh then
        if s.active then s.stop() end
        s.active    = true
        s.veh       = veh
        s.noteIdx   = 0
        s.noteStart = 0
        s.slotMs    = 0
        s.origMod   = Natives.InvokeInt(s.GET_VEHICLE_MOD, veh, s.HORN_MOD_TYPE)
        Natives.InvokeVoid(s.SET_VEHICLE_MOD_KIT, veh, 0)
        Natives.InvokeVoid(s.OVERRIDE_VEH_HORN, veh, false, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
    end

    if s.done then
        PAD.DISABLE_CONTROL_ACTION(0, s.INPUT_VEH_HORN, true)
        return
    end

    local now = MISC.GET_GAME_TIMER()

    if s.noteStart == 0 or (now - s.noteStart) >= s.slotMs then
        if not s.advanceNote(veh, now) then
            s.done = true
            Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, false)
            PAD.DISABLE_CONTROL_ACTION(0, s.INPUT_VEH_HORN, true)
            return
        end
    end

    local elapsed = now - s.noteStart
    if s.curIdx < 0 or elapsed < s.gapMs then
        PAD.DISABLE_CONTROL_ACTION(0, s.INPUT_VEH_HORN, true)
        Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, false)
    else
        Natives.InvokeVoid(s.SET_HORN_ENABLED, veh, true)
        if not s.attackStarted then
            if not Natives.InvokeBool(s.IS_HORN_ACTIVE, veh) then
                Natives.InvokeVoid(s.START_VEHICLE_HORN, veh, 100, s.HORN_TYPE_HELD, true)
            end
            s.attackStarted = true
        end
    end
    if s.modShopPulseActive and elapsed >= s.gapMs then
        if s.modShopSawAttackTick then
            Natives.InvokeVoid(s.SET_VEH_IN_CAR_MOD_SHOP, veh, false)
            s.modShopPulseActive = false
            s.modShopSawAttackTick = false
        else
            s.modShopSawAttackTick = true
        end
    end
end

centralOnTick(FeatureMgr.AddFeature(H.RICK_ROLL_HORN, "Rick Roll Horn", eFeatureType.Toggle,
    "Hold the vehicle horn to play Never Gonna Give You Up.",
    rickHorn.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


centralOnTick(FeatureMgr.AddFeature(H.WEAPON_WHEEL, "Weapon Wheel In Vehicles", eFeatureType.Toggle,
    "Opens the full weapon wheel while in a vehicle. Scroll wheel still cycles vehicle weapons.",
    patchFn.weaponWheelOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.SUPERDRIVE, "SuperDrive", eFeatureType.Toggle,
    "Apply force when driving for extra speed",
    superDriveOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.SUPERDRIVE_MULT, "Speed Multiplier", eFeatureType.SliderFloat,
    "SuperDrive force multiplier (1.0 = default)",
    function(f) speedMultiplier = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.1, 10.0)
    :SetDefaultValue(1.0)
    :Reset()

FeatureMgr.AddFeature(H.SUPERDRIVE_CAM, "Use Camera Direction", eFeatureType.Toggle,
    "Drive toward camera direction instead of vehicle forward")
    :SetDefaultValue(false)
    :Reset()

centralOnTick(FeatureMgr.AddFeature(H.WHEELIE, "Wheelie", eFeatureType.Toggle,
    "Hold bind to lift the front. Stick deflection scales force; key/button = full force.",
    wheelie.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.WHEELIE_STRENGTH, "Wheelie Strength", eFeatureType.SliderFloat,
    "Pitch force multiplier",
    function(f) wheelie.strength = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.0, 5.0)
    :SetDefaultValue(1.0)
    :Reset()

FeatureMgr.AddFeature(H.ENGINE_POWER_MULT, "Power Multiplier", eFeatureType.SliderFloat,
    "Engine power multiplier (1.0 = default, 20.0 = max)")
    :SetLimitValues(1.0, 20.0)
    :SetDefaultValue(1.0)
    :Reset()

centralOnTick(FeatureMgr.AddFeature(H.ENGINE_POWER, "Engine Power Multiplier", eFeatureType.Toggle,
    "Multiply vehicle top speed (applies every tick, persists on vehicle)", enginePowerOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.GRAV_FORCE, "Force Multiplier", eFeatureType.SliderInt,
    "Scales gravity gun hold/throw force (1 = default)",
    function(f) grav.forceMult = f:GetIntValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(1, 10)
    :SetDefaultValue(1)
    :Reset()

FeatureMgr.AddFeature(H.GRAV_CONTRIVED, "Contrived Physics", eFeatureType.Toggle,
    "Teleport entity to crosshair instead of using velocity (rigid, no wobble)")
    :SetDefaultValue(false)
    :Reset()

FeatureMgr.AddFeature(H.GRAV_COLLISION, "Keep Collision", eFeatureType.Toggle,
    "Keep collision enabled while holding entity")
    :SetDefaultValue(true)
    :Reset()

FeatureMgr.AddFeature(H.GRAV_IN_VEH, "Use In Vehicle", eFeatureType.Toggle,
    "Allow gravity gun while driving")
    :SetDefaultValue(true)
    :Reset()

centralOnTick(FeatureMgr.AddFeature(H.GRAVITY_GUN, "Improved Gravity Gun", eFeatureType.Toggle,
    "Aim to grab entities, scroll to adjust distance, attack to throw",
    gravityGunOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.VEH_GUN_RANDOM, "Random Vehicle", eFeatureType.Toggle,
    "Spawn a random vehicle each time instead of the selected one")
    :SetSaveable(false)

FeatureMgr.AddFeature(H.VEH_GUN_RAND_AIR, "Include Aircraft", eFeatureType.Toggle,
    "Include helicopters and planes in random vehicle pool")
    :SetSaveable(false)

FeatureMgr.AddFeature(H.VEH_GUN_RAND_SEA, "Include Boats", eFeatureType.Toggle,
    "Include boats in random vehicle pool")
    :SetSaveable(false)

FeatureMgr.AddFeature(H.VEH_GUN_SPEED, "Speed", eFeatureType.SliderFloat,
    "Speed of launched vehicles (m/s)")
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(20.0, 200.0)
    :SetDefaultValue(200.0)
    :Reset()

FeatureMgr.AddFeature(H.VEH_GUN_DIST, "Spawn Distance", eFeatureType.SliderFloat,
    "Distance ahead of camera to spawn vehicle")
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(10.0, 30.0)
    :SetDefaultValue(10.0)
    :Reset()

FeatureMgr.AddFeature(H.VEH_GUN_IN_VEH, "Use In Vehicle", eFeatureType.Toggle,
    "Allow vehicle gun while driving")
    :SetDefaultValue(true)
    :Reset()
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.VEH_GUN, "Vehicle Gun", eFeatureType.Toggle,
    "Shoot vehicles instead of bullets - spawns configurable vehicles in aim direction",
    vehicleGunOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.SUPER_MELEE, "Super Melee", eFeatureType.SliderInt,
    "Launches vehicles (incl. player-owned and NPC-occupied) and flings NPC peds when you melee them (0 = off, 10 = max)",
    superMeleeOnTick))
    :SetNoCallbackOnPress(true)
    :SetLimitValues(0, 10)
    :SetDefaultValue(0)
    :Reset()

FeatureMgr.AddFeature(H.CHIMP_COUNT, "Chimp Count", eFeatureType.SliderInt,
    "How many wrench chimps to spawn per burst")
    :SetLimitValues(1, 50)
    :SetDefaultValue(12)
    :Reset()

FeatureMgr.AddFeature(H.CHIMP_DIST, "Chimp Spawn Distance", eFeatureType.SliderFloat,
    "Distance from you (meters) for the chimp ring spawn")
    :SetLimitValues(15.0, 80.0)
    :SetDefaultValue(35.0)
    :Reset()

do
    local function getPlayerNameSafe(playerId)
        local name = Players.GetName(playerId)
        if name and name ~= "" then return name end

        name = PLAYER.GET_PLAYER_NAME(playerId)
        if name and name ~= "" then return name end

        return ("Player %d"):format(playerId)
    end

    local SEND_TU_SCRIPT_EVENT_NEW = 0x71A6F836422FDD2B

    local function formatScriptEventArgs(eventData)
        local parts = {}
        for i = 1, #eventData do
            parts[i] = tostring(eventData[i] or 0)
        end
        return table.concat(parts, ", ")
    end

    local function invokeTuScriptEventNew(targetMask, eventData)
        if not Memory or not Natives or not Natives.InvokeVoid then
            return false, "Memory/Natives API unavailable"
        end

        local size = #eventData
        local bytes = size * 8
        logf("ScriptEvent: TSE hash=%d size=%d mask=%d args=[%s]",
            eventData[1] or 0, size, targetMask, formatScriptEventArgs(eventData))

        local ptr = Memory.Alloc(bytes)
        if not ptr or ptr == 0 then
            return false, "Memory.Alloc failed: " .. tostring(ptr)
        end

        Memory.MemSet(ptr, 0, bytes)
        for i = 1, size do
            Memory.WriteLong(ptr + ((i - 1) * 8), eventData[i] or 0)
        end

        local function sendNative()
            Natives.InvokeVoid(SEND_TU_SCRIPT_EVENT_NEW, 1, ptr, size, targetMask, eventData[1])
        end

        if Script and Script.ExecuteAsScript then
            local execOk = pcall(Script.ExecuteAsScript, "freemode", sendNative)
            if not execOk then
                sendNative()
            end
        else
            sendNative()
        end

        Memory.Free(ptr)
        return true
    end

    local function triggerStandStyleScriptEvent(targetMask, standArgs)
        if not standArgs or #standArgs < 2 then
            return false, "missing Stand-style script event args"
        end

        local converted = { standArgs[1], GTA.GetLocalPlayerId(), targetMask }
        for i = 3, #standArgs do
            converted[#converted + 1] = standArgs[i]
        end

        return invokeTuScriptEventNew(targetMask, converted)
    end

    local function allRemotePlayersMask()
        local localPid = GTA.GetLocalPlayerId()
        local mask = 0
        for p = 0, 31 do
            if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                mask = mask + (1 << p)
            end
        end
        return mask
    end

    local function localPlayerMask()
        local localPid = GTA.GetLocalPlayerId()
        if not localPid or localPid < 0 or localPid > 31 then return 0 end
        return 1 << localPid
    end

    local SE_INVITE_ONTO_MISSION = 1541018842
    local SE_FORCE_ONTO_MISSION  = -366707054
    local SE_CONFIRM_LAUNCH      = 1757622014

    local function forceOntoMission(playerId)
        local sender     = GTA.GetLocalPlayerId()
        local targetMask = 1 << playerId
        local okInvite, errInvite = triggerStandStyleScriptEvent(targetMask,
            {
                SE_INVITE_ONTO_MISSION, sender, 49, 0, 0, 48,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                -1, 0, 0, 0, 0, 0, 0
            })
        local okForce, errForce = triggerStandStyleScriptEvent(targetMask,
            {
                SE_FORCE_ONTO_MISSION, sender, 49, 0, 0, 48,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                -1, 0, 0, 0, 0, 0, 0
            })
        local okConfirm, errConfirm = triggerStandStyleScriptEvent(targetMask,
            {
                SE_CONFIRM_LAUNCH, sender, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0
            })
        return (okInvite and okForce and okConfirm),
            ("invite=%s force=%s confirm=%s"):format(
                tostring(errInvite), tostring(errForce), tostring(errConfirm))
    end
    playerState.forceOntoMission = forceOntoMission

    local function removePassiveForPlayer(playerId)
        if not playerId or playerId < 0 or playerId > 31 then
            GUI.AddToast("VibeScript", "No valid player selected.", 3000)
            return
        end
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(playerId) then
            GUI.AddToast("VibeScript", "Selected player is not connected.", 3000)
            return
        end

        local playerName = getPlayerNameSafe(playerId)
        local gpbdBase = GPBD_FM_3_BASE + 1 + playerId * GPBD_FM_3_SIZE
        local passive = ScriptGlobal.GetInt(gpbdBase + 8)
        local tempPassive = ScriptGlobal.GetInt(gpbdBase + 9)
        Logger.LogInfo(("[VibeScript] Remove Passive: pid=%d passive+8=%s temp+9=%s")
            :format(playerId, tostring(passive), tostring(tempPassive)))

        if passive == 0 and tempPassive == 0 then
            GUI.AddToast("VibeScript",
                ("%s isn't in passive mode."):format(playerName), 3000)
            return
        end

        local uniqueHash = ScriptGlobal.GetInt(gpbdBase + 517)
        Logger.LogInfo(("[VibeScript] Remove Passive: pid=%d unique+517=%s sendingCapturedUnique=0")
            :format(playerId, tostring(uniqueHash)))

        local okAll, errStr = forceOntoMission(playerId)
        if okAll then
            GUI.AddToast("VibeScript",
                ("Removed passive from %s."):format(playerName), 3000)
        else
            logErr("Remove Passive failed: " .. errStr)
        end
    end

    local removePassiveFeatures = FeatureMgr.AddPlayerFeature(
        H.REMOVE_PASSIVE, "Remove Passive", eFeatureType.Button,
        "Removes this player from passive mode.",
        function(f)
            playerState.passivePending[#playerState.passivePending + 1] =
                { pid = f:GetPlayerIndex() }
            telemetryCountAction("RemovePassive")
        end)
    for _, hash in ipairs(removePassiveFeatures) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end


    playerState.stripVehGodApply = function(veh)
        local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
        if netId and netId ~= 0 then
            NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netId, true)
        end
        Natives.InvokeVoid(0x3882114BDE571AD4, veh, false)
        Natives.InvokeVoid(0x1760FFA8AB074D66, veh, true)
        Natives.InvokeVoid(0xFAEE099C6F890BB8, veh,
            false, false, false, false, false, false, 0, false)
        Natives.InvokeVoid(0x3E8C8727991A8A0B, veh, false)
        Natives.InvokeVoid(0x4C7028F78FFD3681, veh, true)
        Natives.InvokeVoid(0x983765856F2564F9, veh, true)
        Natives.InvokeVoid(0xEB9DC3C7D8596C46, veh, true)
        Natives.InvokeVoid(0x465BF26AB9684352, veh, false)
        Natives.InvokeVoid(0x37C8252A7C92D017, veh, false)
        local doors = Natives.InvokeInt(0x92922A607497B14D, veh)
        if doors and doors > 0 then
            for i = 0, doors - 1 do
                Natives.InvokeVoid(0x2FA133A4A9D37ED8, veh, i, true)
            end
        end
        Natives.InvokeVoid(0x143921E45EC44D62, false)
        return (doors) or nil
    end

    playerState.stripVehGodStart = function(pid)
        if not pid or pid < 0 or pid > 31 then return end
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
            GUI.AddToast("VibeScript", "Player not connected.", 3000)
            return
        end
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if ped == 0 then return end
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 or not ENTITY.DOES_ENTITY_EXIST(veh) then
            GUI.AddToast("VibeScript", "Player not in a vehicle.", 3000)
            return
        end
        playerState.stripVehGodJob = {
            pid = pid, veh = veh, name = getPlayerNameSafe(pid),
            acquireDeadline = Time.GetEpocheMs() + 3000,
            gotControl = false, holdUntil = nil, lastDoors = nil,
        }
    end

    playerState.stripVehGodFinish = function(job, gotControl)
        local msg = gotControl
            and ("Stripped god mode from %s's vehicle."):format(job.name)
            or ("No control of %s's vehicle, stripped what we could."):format(job.name)
        GUI.AddToast("VibeScript", msg, 3000)
        Logger.LogInfo(("[VibeScript] StripVehGod: pid=%d veh=%d control=%s doors=%s")
            :format(job.pid, job.veh, tostring(gotControl), tostring(job.lastDoors or "?")))
        playerState.stripVehGodJob = nil
    end

    playerState.stripVehGodStep = function()
        local job = playerState.stripVehGodJob
        if not job then return end
        local veh, now = job.veh, Time.GetEpocheMs()

        if not ENTITY.DOES_ENTITY_EXIST(veh) then
            playerState.stripVehGodJob = nil
            return
        end

        if not job.gotControl then
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                job.gotControl = true
            else
                if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
                    local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
                    local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
                    local localPlayer = Players.GetById(GTA.GetLocalPlayerId())
                    if netObj and localPlayer then
                        NetworkObjectMgr.ChangeOwner(netObj, localPlayer, 0)
                    end
                end
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then job.gotControl = true end
            end

            if job.gotControl then
                job.holdUntil = now + 1500
                job.lastDoors = playerState.stripVehGodApply(veh) or job.lastDoors
            elseif now >= job.acquireDeadline then
                job.lastDoors = playerState.stripVehGodApply(veh) or job.lastDoors
                playerState.stripVehGodFinish(job, false)
            end
            return
        end

        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
        job.lastDoors = playerState.stripVehGodApply(veh) or job.lastDoors
        if now >= job.holdUntil or not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
            playerState.stripVehGodFinish(job, true)
        end
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.STRIP_VEH_GOD, "Remove Vehicle God Mode", eFeatureType.Button,
        "Requests control of this player's current vehicle and clears the synced damage flags Cherax-style spawners set (tire burst, door break, engine degrade, petrol tank, body invincibility). Useful when they took your spawned-god-mode car.",
        function(f)
            playerState.passivePending[#playerState.passivePending + 1] =
                { pid = f:GetPlayerIndex(), stripVehGod = true }
            telemetryCountAction("RemoveVehGod")
        end)) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    local joinCeo = {
        SE      = -627920584,
        SECLEAR = Utils.Joaat("Globals.MP_Event_Enums15.sch.SCRIPT_EVENT_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP"),
        SE_LIMO_LOCKS  = 936332224,
        SE_GANG_STATUS = -972329058,
        ORG = 10,
        BOSS = 0,
        FLAGS = 4,
        MEMBERS = 12,
        MISSION_TO_LAUNCH = 33,
        ACTIVE_MISSION = 34,
        TYPE_CANDIDATES = { 433 },
        TYPE_COPY_DELTAS = { 37 },
        BIT_ACCEPTED = 7,
        GANG_TO_JOIN = 27,

        WAIT_CANONICAL_TICKS = 180,
        LEAVE_REASON_TERMINATED = 6,
        WAIT_LEAVE_TICKS = 60,
        SETTLE_AFTER_LEAVE_TICKS = 150,
        END_GOON_REASON_IDX = IS_ENHANCED
            and (2733326 + 3989 + 227)
            or  (2733190 + 3988 + 227),
    }
    joinCeo.idx = function(pid, off)
        return GPBD_FM_3_BASE + 1 + pid * GPBD_FM_3_SIZE + joinCeo.ORG + off
    end
    joinCeo.readInt = function(pid, off)
        return ScriptGlobal.GetInt(joinCeo.idx(pid, off))
    end
    joinCeo.readBoss = function(pid)
        return joinCeo.readInt(pid, joinCeo.BOSS) or -1
    end
    joinCeo.triggerCanonicalAccept = function(bossPid)
        local localPid = GTA.GetLocalPlayerId()
        ScriptGlobal.SetInt(
            joinCeo.idx(localPid, joinCeo.GANG_TO_JOIN), bossPid)
    end
    joinCeo.collectNonOrgPlayers = function(bossPid)
        local out = {}
        local localPid = GTA.GetLocalPlayerId()
        for p = 0, 31 do
            if p ~= bossPid and p ~= localPid
                and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p)
                and joinCeo.readBoss(p) == -1
            then
                out[#out + 1] = p
                if #out >= 4 then break end
            end
        end
        return out
    end
    joinCeo.probeTypeOffset = function(bossPid)
        local nonOrg = joinCeo.collectNonOrgPlayers(bossPid)
        local function offsetReadsMinusOneOnAnyNonOrg(off)
            if #nonOrg == 0 then return true end
            for _, np in ipairs(nonOrg) do
                local nv = ScriptGlobal.GetInt(joinCeo.idx(np, off))
                if nv == -1 then return true end
            end
            return false
        end
        for _, cand in ipairs(joinCeo.TYPE_CANDIDATES) do
            local v = ScriptGlobal.GetInt(joinCeo.idx(bossPid, cand))
            if (v == 0 or v == 1)
                and offsetReadsMinusOneOnAnyNonOrg(cand)
            then
                local copyOff = nil
                for _, delta in ipairs(joinCeo.TYPE_COPY_DELTAS) do
                    local cOff = cand + delta
                    local cv = ScriptGlobal.GetInt(
                        joinCeo.idx(bossPid, cOff))
                    if cv == v
                        and offsetReadsMinusOneOnAnyNonOrg(cOff)
                    then
                        copyOff = cOff
                        break
                    end
                end
                return cand, v, copyOff
            end
        end
        return nil, -1, nil
    end
    joinCeo.sendGraceful = function(bossPid)
        if bossPid < 0 or bossPid > 31 then return false, "bad boss pid" end
        return triggerStandStyleScriptEvent(1 << bossPid,
            { joinCeo.SE, 0, 0 })
    end
    joinCeo.broadcastGangStatus = function()
        local mask = allRemotePlayersMask()
        if mask == 0 then return end
        triggerStandStyleScriptEvent(mask,
            { joinCeo.SE_LIMO_LOCKS, 0 })
        triggerStandStyleScriptEvent(mask,
            { joinCeo.SE_GANG_STATUS, 0, 0 })
    end
    joinCeo.forceApply = function(bossPid)
        local localPid = GTA.GetLocalPlayerId()
        local flagsIdx = joinCeo.idx(localPid, joinCeo.FLAGS)
        local flags = ScriptGlobal.GetInt(flagsIdx)
        if flags then
            ScriptGlobal.SetInt(flagsIdx,
                flags | (1 << joinCeo.BIT_ACCEPTED))
        end
    end
    joinCeo.forceMaintain = function(bossPid, typeOff, typeVal, typeCopyOff)
        local localPid = GTA.GetLocalPlayerId()
        ScriptGlobal.SetInt(joinCeo.idx(localPid, joinCeo.BOSS), bossPid)
        ScriptGlobal.SetInt(
            joinCeo.idx(bossPid, joinCeo.MEMBERS), localPid)
        if typeOff and (typeVal == 0 or typeVal == 1) then
            ScriptGlobal.SetInt(
                joinCeo.idx(localPid, typeOff), typeVal)
            if typeCopyOff then
                ScriptGlobal.SetInt(
                    joinCeo.idx(localPid, typeCopyOff), typeVal)
            end
        end
    end
    joinCeo.triggerCanonicalLeave = function(bossPid)
        if bossPid < 0 or bossPid > 31 then return false, "bad boss pid" end
        local localPid = GTA.GetLocalPlayerId()
        local cur = ScriptGlobal.GetInt(joinCeo.END_GOON_REASON_IDX)
        if cur == -1 or cur == 0 or cur == 5 or cur == 6 then
            ScriptGlobal.SetInt(joinCeo.END_GOON_REASON_IDX,
                joinCeo.LEAVE_REASON_TERMINATED)
        else
            logErr(("[JoinCEO] end-goon-reason idx %d read %s (unexpected); " ..
                "skipping direct write"):format(
                joinCeo.END_GOON_REASON_IDX, tostring(cur)))
        end
        return invokeTuScriptEventNew(1 << localPid, {
            joinCeo.SECLEAR,
            bossPid,
            0,
            0,
            joinCeo.LEAVE_REASON_TERMINATED,
        })
    end

    joinCeo.KILL_SCRIPTS = {
        "gb_assault", "gb_airfreight", "gb_bellybeast", "gb_carjacking",
        "gb_cashing_out", "gb_collect_money", "gb_deathmatch", "gb_delivery",
        "gb_finderskeepers", "gb_fivestar", "gb_fragile_goods",
        "gb_headhunter", "gb_hunt_the_boss", "gb_point_to_point",
        "gb_rob_shop", "gb_salvage", "gb_sightseer", "gb_terminate",
        "gb_yacht_rob",
        "gb_contraband_buy", "gb_contraband_sell", "gb_contraband_defend",
        "gb_amphibious_assault", "gb_fortified", "gb_fully_loaded",
        "gb_ploughed", "gb_ramped_up", "gb_stockpiling", "gb_transporter",
        "gb_velocity", "gb_vehicle_export",
        "gb_biker_bad_deal", "gb_biker_burn_assets",
        "gb_biker_contraband_defend", "gb_biker_contraband_sell",
        "gb_biker_contract_killing", "gb_biker_criminal_mischief",
        "gb_biker_destroy_vans", "gb_biker_driveby_assassin",
        "gb_biker_free_prisoner", "gb_biker_joust", "gb_biker_last_respects",
        "gb_biker_race_p2p", "gb_biker_rescue_contact",
        "gb_biker_rippin_it_up", "gb_biker_safecracker",
        "gb_biker_search_and_destroy", "gb_biker_shuttle",
        "gb_biker_stand_your_ground", "gb_biker_steal_bikes",
        "gb_biker_target_rival", "gb_biker_unload_weapons",
        "gb_biker_wheelie_rider", "gb_illicit_goods_resupply",
        "gb_gunrunning", "gb_gunrunning_defend", "gb_gunrunning_delivery",
        "gb_smuggler", "gb_gangops",
        "business_battles_sell", "business_battles_defend",
        "gb_security_van", "gb_target_pursuit", "gb_jewel_store_grab",
        "gb_bank_job", "gb_data_hack", "gb_infiltration",
        "gb_casino", "gb_casino_heist",
        "fm_content_island_heist", "fm_content_island_dj",
        "fm_content_tuner_robbery", "fm_content_auto_shop_delivery",
        "fm_content_vip_contract_1", "fm_content_security_contract",
        "fm_content_payphone_hit",
        "fm_content_bar_resupply", "fm_content_bike_shop_delivery",
        "fm_content_clubhouse_contracts", "fm_content_cargo",
        "fm_content_export_cargo", "fm_content_ammunation",
        "fm_content_gunrunning", "fm_content_source_research",
        "fm_content_club_management", "fm_content_club_odd_jobs",
        "fm_content_club_source",
        "fm_content_acid_lab_setup", "fm_content_acid_lab_source",
        "fm_content_acid_lab_sell", "fm_content_drug_lab_work",
        "fm_content_stash_house", "fm_content_taxi_driver",
        "fm_content_smuggler_sell", "fm_content_smuggler_resupply",
        "fm_content_smuggler_ops", "fm_content_arms_trafficking",
        "fm_content_chop_shop_delivery", "fm_content_tow_truck_work",
        "fm_content_vehrob_scoping", "fm_content_vehrob_task",
        "fm_content_vehrob_prep", "fm_content_vehrob_disrupt",
        "fm_content_vehrob_cargo_ship", "fm_content_vehrob_police",
        "fm_content_vehrob_arena", "fm_content_vehrob_casino_prize",
        "fm_content_vehrob_submarine",
        "fm_content_bounty_targets", "fm_content_daily_bounty",
        "fm_content_dispatch_work",
        "fm_content_kortz_scoping", "fm_content_kortz_entry",
        "fm_content_kortz_equipment", "fm_content_kortz_disruption",
        "fm_content_kortz_task",
        "fm_content_hacker_cargo_prep", "fm_content_hacker_cargo_finale",
        "fm_content_hacker_house_prep", "fm_content_hacker_house_finale",
        "fm_content_hacker_whistle_prep", "fm_content_hacker_whistle_fin",
        "fm_content_hacker_zancudo_prep", "fm_content_hacker_zancudo_fin",
        "fm_content_weed_shop_work", "fm_content_weed_shop_delivery",
        "fm_content_car_wash_work", "fm_content_car_wash_detailing",
        "fm_content_helitours_work", "fm_content_helitours_tour",
        "fm_content_tycoon_odd_jobs",
    }
    joinCeo.FORCE_CLEANUP_FLAGS = 2 | 16 | 64
    joinCeo.countRunning = function(name)
        return SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(
            Utils.Joaat(name)) or 0
    end

    joinCeo.killPassRequest = nil
    joinCeo.cleanupMissionState = function(force)
        AUDIO.TRIGGER_MUSIC_EVENT("GLOBAL_KILL_MUSIC_FADEIN_RADIO")
        AUDIO.TRIGGER_MUSIC_EVENT("GLOBAL_KILL_MUSIC")
        AUDIO.TRIGGER_MUSIC_EVENT("MP_MC_STOP")
        AUDIO.STOP_AUDIO_SCENES()
        HUD.CLEAR_PRINTS()
        HUD.CLEAR_HELP(false)
        HUD.CLEAR_BRIEF()
        MISC.SET_MISSION_FLAG(false)
        local running = {}
        for _, name in ipairs(joinCeo.KILL_SCRIPTS) do
            if joinCeo.countRunning(name) > 0 then
                running[#running + 1] = name
            end
        end
        if #running > 0 then
            joinCeo.killPassRequest = {
                names = running,
                graceMs = force and 0 or 4000,
                force = force and true or false,
            }
        end
        return true
    end

    Script.RegisterLooped(function()
        if scriptUnloading then return end
        if joinCeo.manualCleanRequested then
            joinCeo.manualCleanRequested = false
            joinCeo.cleanupMissionState(true)
            GUI.AddToast("VibeScript", "Mission state cleared.", 2000)
        end
        local req = joinCeo.killPassRequest
        if not req then
            Script.Yield(250)
            return
        end
        joinCeo.killPassRequest = nil
        if req.graceMs > 0 then Script.Yield(req.graceMs) end
        if scriptUnloading then return end
        if not req.force
            and joinCeo.readBoss(GTA.GetLocalPlayerId()) ~= -1 then
            return
        end
        local pending = {}
        for _, name in ipairs(req.names) do
            if joinCeo.countRunning(name) > 0 then
                PLAYER.FORCE_CLEANUP_FOR_ALL_THREADS_WITH_THIS_NAME(
                    name, joinCeo.FORCE_CLEANUP_FLAGS)
                pending[#pending + 1] = name
            end
        end
        if #pending == 0 then return end
        Script.Yield(1500)
        if scriptUnloading then return end
        if not req.force
            and joinCeo.readBoss(GTA.GetLocalPlayerId()) ~= -1 then
            return
        end
        local killed = 0
        for _, name in ipairs(pending) do
            if joinCeo.countRunning(name) > 0 then
                MISC.TERMINATE_ALL_SCRIPTS_WITH_THIS_NAME(name)
                killed = killed + 1
            end
        end
        if killed > 0 then
            GUI.AddToast("VibeScript",
                ("Killed %d lingering boss-event script(s)."):format(killed),
                2500)
        end
    end)

    joinCeo.clearAll = function(bossPid, typeOff, typeCopyOff)
        local localPid = GTA.GetLocalPlayerId()
        ScriptGlobal.SetInt(joinCeo.idx(localPid, joinCeo.BOSS), -1)
        ScriptGlobal.SetInt(
            joinCeo.idx(localPid, joinCeo.MISSION_TO_LAUNCH), -1)
        ScriptGlobal.SetInt(
            joinCeo.idx(localPid, joinCeo.ACTIVE_MISSION), -1)
        ScriptGlobal.SetInt(
            joinCeo.idx(localPid, joinCeo.GANG_TO_JOIN), -1)
        if typeOff then
            ScriptGlobal.SetInt(
                joinCeo.idx(localPid, typeOff), -1)
            if typeCopyOff then
                ScriptGlobal.SetInt(
                    joinCeo.idx(localPid, typeCopyOff), -1)
            end
        end
        local flagsIdx = joinCeo.idx(localPid, joinCeo.FLAGS)
        local flags = ScriptGlobal.GetInt(flagsIdx)
        if flags then
            ScriptGlobal.SetInt(flagsIdx,
                flags & ~(1 << joinCeo.BIT_ACCEPTED))
        end
        if bossPid and bossPid >= 0 and bossPid <= 31 then
            ScriptGlobal.SetInt(
                joinCeo.idx(bossPid, joinCeo.MEMBERS), -1)
        end
        triggerStandStyleScriptEvent(1 << localPid,
            { joinCeo.SECLEAR, 0 })
        joinCeo.broadcastGangStatus()
    end
    joinCeo.armCanonicalJoin = function(pid, bossPid)
        local typeOff, typeVal, typeCopyOff = joinCeo.probeTypeOffset(bossPid)
        playerState.joinCeoActivePid = pid
        playerState.joinCeoState = {
            boss = bossPid,
            typeOff = typeOff,
            typeVal = typeVal,
            typeCopyOff = typeCopyOff,
            phase = "wait_canonical",
            tickCount = 0,
        }
        joinCeo.triggerCanonicalAccept(bossPid)
        local ok, err = joinCeo.sendGraceful(bossPid)
        if not ok then
            logErr("[JoinCEO] graceful send failed: " .. tostring(err))
        end
        GUI.AddToast("VibeScript",
            ("Joining %s's CEO/MC..."):format(getPlayerNameSafe(pid)), 2000)
    end
    joinCeo.onTick = function(f)
        local pid = f:GetPlayerIndex()
        local toggled = f:IsToggled()
        telemetryCountToggleEdge("JoinCEOMC", pid, toggled)
        local prev = playerState.joinCeoPrev[pid] or false
        if not toggled and not prev and playerState.joinCeoActivePid ~= pid then
            return
        end
        if not isPlayerReady() then return end

        if toggled and not prev then
            if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                GUI.AddToast("VibeScript",
                    "Join CEO/MC: player not connected.", 3000)
                f:Toggle(false)
                playerState.joinCeoPrev[pid] = false
                return
            end
            local boss = joinCeo.readBoss(pid)
            if boss < 0 or boss > 31 then
                GUI.AddToast("VibeScript",
                    ("Join CEO/MC: %s is not in a CEO/MC."):format(getPlayerNameSafe(pid)),
                    3000)
                f:Toggle(false)
                playerState.joinCeoPrev[pid] = false
                return
            end
            local other = playerState.joinCeoActivePid
            if other >= 0 and other ~= pid then
                FeatureMgr.ResetFeature(H.JOIN_CEO, other)
            end
            local localPid0 = GTA.GetLocalPlayerId()
            local myBoss = joinCeo.readBoss(localPid0)
            if myBoss >= 0 and myBoss <= 31 and myBoss ~= boss then
                playerState.joinCeoActivePid = pid
                playerState.joinCeoState = {
                    boss = boss,
                    leaveBoss = myBoss,
                    phase = "leaving_before_join",
                    tickCount = 0,
                }
                joinCeo.triggerCanonicalLeave(myBoss)
                joinCeo.cleanupMissionState()
                GUI.AddToast("VibeScript",
                    "Leaving current CEO/MC first...", 1500)
                playerState.joinCeoPrev[pid] = true
                return
            end
            joinCeo.armCanonicalJoin(pid, boss)
            playerState.joinCeoPrev[pid] = true
            return
        end

        if prev and not toggled then
            local st = playerState.joinCeoState
            local localPidEdge = GTA.GetLocalPlayerId()
            if st and st.boss and st.boss >= 0 and st.boss <= 31
                and joinCeo.readInt(localPidEdge, joinCeo.BOSS) == st.boss
                and NETWORK.NETWORK_IS_PLAYER_CONNECTED(st.boss)
            then
                joinCeo.triggerCanonicalLeave(st.boss)
                st.phase = "leaving_canonical"
                st.tickCount = 0
                GUI.AddToast("VibeScript",
                    ("Leaving %s's CEO/MC..."):format(getPlayerNameSafe(pid)),
                    1500)
                playerState.joinCeoPrev[pid] = false
                return
            end
            joinCeo.clearAll(st and st.boss or -1,
                st and st.typeOff or nil, st and st.typeCopyOff or nil)
            joinCeo.cleanupMissionState()
            if playerState.joinCeoActivePid == pid then
                playerState.joinCeoActivePid = -1
                playerState.joinCeoState = nil
            end
            playerState.joinCeoPrev[pid] = false
            return
        end

        if not toggled then
            if playerState.joinCeoActivePid ~= pid then return end
            local stOff = playerState.joinCeoState
            if not stOff or stOff.phase ~= "leaving_canonical" then return end
        end

        if playerState.joinCeoActivePid ~= pid then return end
        local st = playerState.joinCeoState
        if not st then return end

        if st.phase ~= "leaving_canonical" and st.phase ~= "leaving_before_join" and (
            not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid)
            or joinCeo.readBoss(st.boss) ~= st.boss
        ) then
            joinCeo.clearAll(st.boss, st.typeOff, st.typeCopyOff)
            joinCeo.cleanupMissionState()
            playerState.joinCeoActivePid = -1
            playerState.joinCeoState = nil
            f:Toggle(false)
            playerState.joinCeoPrev[pid] = false
            return
        end

        local localPid = GTA.GetLocalPlayerId()
        if st.phase == "leaving_before_join" then
            if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid)
                or joinCeo.readBoss(st.boss) ~= st.boss
            then
                joinCeo.clearAll(st.leaveBoss, nil, nil)
                joinCeo.cleanupMissionState()
                playerState.joinCeoActivePid = -1
                playerState.joinCeoState = nil
                f:Toggle(false)
                playerState.joinCeoPrev[pid] = false
                return
            end
            if joinCeo.readInt(localPid, joinCeo.BOSS) == -1 then
                st.phase = "settling_before_join"
                st.tickCount = 0
                return
            end
            st.tickCount = st.tickCount + 1
            if st.tickCount >= joinCeo.WAIT_LEAVE_TICKS then
                joinCeo.clearAll(st.leaveBoss, nil, nil)
                joinCeo.cleanupMissionState()
                st.phase = "settling_before_join"
                st.tickCount = 0
            end
            return
        end
        if st.phase == "settling_before_join" then
            st.tickCount = st.tickCount + 1
            if st.tickCount >= joinCeo.SETTLE_AFTER_LEAVE_TICKS then
                joinCeo.armCanonicalJoin(pid, st.boss)
            end
            return
        end
        if st.phase == "leaving_canonical" then
            if joinCeo.readInt(localPid, joinCeo.BOSS) == -1 then
                joinCeo.cleanupMissionState()
                GUI.AddToast("VibeScript",
                    ("Left %s's CEO/MC (canonical)."):format(getPlayerNameSafe(pid)),
                    2000)
                playerState.joinCeoActivePid = -1
                playerState.joinCeoState = nil
                playerState.joinCeoPrev[pid] = false
                return
            end
            st.tickCount = st.tickCount + 1
            if st.tickCount >= joinCeo.WAIT_LEAVE_TICKS then
                joinCeo.clearAll(st.boss, st.typeOff, st.typeCopyOff)
                joinCeo.cleanupMissionState()
                GUI.AddToast("VibeScript",
                    ("Left %s's CEO/MC (fallback)."):format(getPlayerNameSafe(pid)),
                    2000)
                playerState.joinCeoActivePid = -1
                playerState.joinCeoState = nil
                playerState.joinCeoPrev[pid] = false
            end
            return
        end

        if st.phase == "wait_canonical" then
            if joinCeo.readInt(localPid, joinCeo.BOSS) == st.boss then
                st.phase = "joined_canonical"
                GUI.AddToast("VibeScript",
                    ("Joined %s's CEO/MC (canonical)."):format(getPlayerNameSafe(pid)),
                    2000)
                return
            end
            st.tickCount = st.tickCount + 1
            if st.tickCount >= joinCeo.WAIT_CANONICAL_TICKS then
                joinCeo.forceApply(st.boss)
                joinCeo.forceMaintain(st.boss, st.typeOff, st.typeVal, st.typeCopyOff)
                joinCeo.broadcastGangStatus()
                st.phase = "joined_fallback"
                GUI.AddToast("VibeScript",
                    ("Joined %s's CEO/MC (fallback)."):format(getPlayerNameSafe(pid)),
                    2000)
            end
            return
        end

        if st.phase == "joined_fallback" then
            joinCeo.forceMaintain(st.boss, st.typeOff, st.typeVal, st.typeCopyOff)
        elseif st.phase == "joined_canonical" then
            if joinCeo.readInt(localPid, joinCeo.BOSS) ~= st.boss then
                if st.boss >= 0 and st.boss <= 31 then
                    ScriptGlobal.SetInt(
                        joinCeo.idx(st.boss, joinCeo.MEMBERS), -1)
                end
                playerState.joinCeoActivePid = -1
                playerState.joinCeoState = nil
                f:Toggle(false)
                playerState.joinCeoPrev[pid] = false
                GUI.AddToast("VibeScript",
                    ("Left %s's CEO/MC (left via game)."):format(getPlayerNameSafe(pid)),
                    2000)
                return
            end
            ScriptGlobal.SetInt(
                joinCeo.idx(st.boss, joinCeo.MEMBERS), localPid)
        end
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.JOIN_CEO, "Join CEO/MC", eFeatureType.Toggle,
        "Joins the target's CEO or Motorcycle Club. Only one player can be active at a time.",
        joinCeo.onTick)) do
        FeatureMgr.GetFeature(hash)
            :SetNoCallbackOnPress(true)
            :SetSaveable(false)
    end
    centralPlayerOnTick(H.JOIN_CEO, joinCeo.onTick)

    local joinWatch = {
        on = false,
        last = nil,
        from = 0,
        to   = 80,
    }
    joinWatch.tick = function(f)
        if not f:IsToggled() then
            if joinWatch.on then
                joinWatch.on = false
                joinWatch.last = nil
                Logger.LogInfo("[VibeScript][JoinWatch] off")
            end
            return
        end
        if not isPlayerReady() then return end
        local localPid = GTA.GetLocalPlayerId()
        if not joinWatch.on then
            joinWatch.on = true
            joinWatch.last = {}
            for off = joinWatch.from, joinWatch.to do
                joinWatch.last[off] = joinCeo.readInt(localPid, off)
            end
            Logger.LogInfo(("[VibeScript][JoinWatch] on, baseline established for ORG ints +%d..+%d (abs +%d..+%d)")
                :format(joinWatch.from, joinWatch.to,
                joinCeo.ORG + joinWatch.from, joinCeo.ORG + joinWatch.to))
            return
        end
        for off = joinWatch.from, joinWatch.to do
            local v = joinCeo.readInt(localPid, off)
            local prev = joinWatch.last[off]
            if v ~= prev then
                Logger.LogInfo(("[VibeScript][JoinWatch] sMag+%d (abs+%d): %s -> %s (0x%08x)")
                    :format(off, joinCeo.ORG + off,
                        tostring(prev), tostring(v),
                        (v or 0) & 0xffffffff))
                joinWatch.last[off] = v
            end
        end
    end
    centralOnTick(FeatureMgr.AddFeature(H.JOIN_CEO_WATCH,
        "Debug: Watch ORG ints", eFeatureType.Toggle,
        "Logs every per-tick change to your own GPBD_FM_3 ORG ints +0..+80.",
        joinWatch.tick))
        :SetSaveable(false)

    FeatureMgr.AddFeature(H.CLEAN_MISSION_STATE,
        "Debug: Force Clean Mission State", eFeatureType.Button,
        "Triggers freemode's own mission-end music events, nukes audio scenes, clears HUD prints/help/brief/floating-help, resets the mission flag, then runs the staged boss-event kill pass immediately (FORCE_CLEANUP each running boss-event script, then terminate anything that ignored it 1.5s later). Only touches known boss-triggered event scripts that are currently running. Use to unstick blips/music/objectives left over from an org event.",
        function(f)
            joinCeo.manualCleanRequested = true
        end)
        :SetSaveable(false)


    centralOnTick(FeatureMgr.AddFeature(playerState.passiveRunnerHash, "##RemovePassiveRunner",
        eFeatureType.Toggle, "", function(f)
            if not f:IsToggled() then return end
            if playerState.stripVehGodJob then
                playerState.stripVehGodStep()
            end
            if #playerState.passivePending == 0 then return end
            local pending = playerState.passivePending
            playerState.passivePending = {}
            for _, req in ipairs(pending) do
                if req.stripVehGod then
                    playerState.stripVehGodStart(req.pid)
                else
                    removePassiveForPlayer(req.pid)
                end
            end
        end, true))
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
    FeatureMgr.GetFeature(playerState.passiveRunnerHash):Toggle()




    local function listAllSimpleInteriors()
        local SI_BASE   = lockOntoPlayers.GPBD_BASE
        local SI_STRIDE = lockOntoPlayers.GPBD_STRIDE
        local SI_OFF    = lockOntoPlayers.GPBD_SIMPLE_INTERIOR
        local function readSlot(abs)
            return ScriptGlobal.GetInt(abs)
        end
        local siNames = {
            [-1]="INVALID (freemode)", [2]="WAREHOUSE_3", [70]="BUNKER", [81]="MOC",
            [83]="HANGAR", [85]="HANGAR (Zancudo A2)", [88]="AVENGER", [89]="FACILITY",
            [117]="HACKER_TRUCK", [123]="CASINO", [124]="CASINO_APT", [128]="ARCADE",
            [146]="NIGHTCLUB", [147]="SUBMARINE (Kosatka)", [148]="MUSIC_STUDIO",
            [149]="AUTO_SHOP", [154]="CAR_MEET", [155]="AGENCY", [159]="ACID_LAB",
            [160]="JUGGALO_HIDEOUT",
        }
        local inInterior, freemode, uninit = {}, {}, {}
        for pid = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                local siNew = readSlot(SI_BASE + 1 + pid * SI_STRIDE + SI_OFF)
                local siInst = readSlot(SI_BASE + 1 + pid * SI_STRIDE + SI_OFF + 1)
                local name  = getPlayerNameSafe(pid)
                local entry = { pid = pid, name = name, si = siNew, inst = siInst }
                if siNew and siNew >= 1 and siNew <= 250 then
                    inInterior[#inInterior+1] = entry
                elseif siNew == -1 then
                    freemode[#freemode+1] = entry
                else
                    uninit[#uninit+1] = entry
                end
            end
        end
        Logger.LogInfo(("[VibeScript][SIList] build=%s base=%d stride=%d off=%d: %d in interior, %d freemode, %d unknown")
            :format(IS_ENHANCED and "Enhanced" or "Legacy", SI_BASE, SI_STRIDE, SI_OFF,
                #inInterior, #freemode, #uninit))
        if #inInterior > 0 then
            Logger.LogInfo("[VibeScript][SIList] === IN SIMPLE INTERIOR (kickable) ===")
            for _, e in ipairs(inInterior) do
                Logger.LogInfo(("[VibeScript][SIList]   pid=%-2d %s  si=%d (%s)  inst=%s")
                    :format(e.pid, e.name, e.si, siNames[e.si] or "?", tostring(e.inst)))
            end
        end
        if #freemode > 0 then
            local names = {}
            for _, e in ipairs(freemode) do names[#names+1] = ("%d:%s"):format(e.pid, e.name) end
            Logger.LogInfo("[VibeScript][SIList] freemode (siNEW=-1): " .. table.concat(names, ", "))
        end
        if #uninit > 0 then
            local names = {}
            for _, e in ipairs(uninit) do
                names[#names+1] = ("%d:%s(si=%s)"):format(e.pid, e.name, tostring(e.si))
            end
            Logger.LogInfo("[VibeScript][SIList] unknown/uninit: " .. table.concat(names, ", "))
        end
        GUI.AddToast("VibeScript",
            ("SI List: %d in interior, %d freemode, %d unknown (see log)"):format(
                #inInterior, #freemode, #uninit), 4500)
    end

    FeatureMgr.AddFeature(H.SI_LIST_ALL, "Debug: List All SimpleInteriors",
        eFeatureType.Button,
        "Reads eCurrentSimpleInterior for every connected player and logs who is actually in a simple interior (kickable), who is in freemode, and who has uninitialized BD. Run this before Kick From Interior to find a target whose read pins correctly.",
        function()
            listAllSimpleInteriors()
        end, true):SetSaveable(false)

end


do
    local FM_EVENTS_BASE = IS_ENHANCED and 1923118 or 1922845
    local UNIQUE_HASH0   = FM_EVENTS_BASE + 9
    local UNIQUE_HASH1   = FM_EVENTS_BASE + 10
    local SE_SET_BOUNTY  = Utils.Joaat("Globals.MP_Event_Enums15.sch.SCRIPT_EVENT_SET_BOUNTY_ON_PLAYER")

    FeatureMgr.AddFeature(H.BOUNTY_AMOUNT, "Bounty Amount", eFeatureType.SliderInt,
        "Cash value of the bounty to place on the player.")
        :SetLimitValues(1, 10000)
        :SetStepSize(100)
        :SetDefaultValue(9000)
        :Reset()

    local function sendBounty(playerID, anonymous, quiet)
        if not playerID or playerID < 0 or playerID > 31 then return false end
        local localPid = GTA.GetLocalPlayerId()
        if playerID == localPid then return false end
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(playerID) then
            if not quiet then GUI.AddToast("VibeScript", "That player is not connected.", 3000) end
            return false
        end

        local amount = 9000
        local amtFeat = FeatureMgr.GetFeature(H.BOUNTY_AMOUNT)
        if amtFeat then amount = amtFeat:GetIntValue() end
        if amount < 1 then amount = 1 elseif amount > 10000 then amount = 10000 end

        local h0 = ScriptGlobal.GetInt(UNIQUE_HASH0) or 0
        local h1 = ScriptGlobal.GetInt(UNIQUE_HASH1) or 0

        GTA.TriggerScriptEvent(0xFFFFFFFF, {
            SE_SET_BOUNTY,
            localPid,
            1 << playerID,
            playerID,
            1,
            amount,
            0,
            anonymous and 1 or 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            h0, h1,
        })

        local name = Players.GetName(playerID)
        if not (name and name ~= "") then name = "Player " .. playerID end

        if not quiet then
            GUI.AddToast("VibeScript",
                string.format("Placed a $%d %s bounty on %s.",
                    amount, anonymous and "anonymous" or "owned", name), 3000)
        end
        telemetryCountAction(anonymous and "SetBountyNpc" or "SetBountyOwned")
        return true
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.SET_BOUNTY_NPC, "Set NPC Bounty", eFeatureType.Button,
        "Places an anonymous bounty on this player (appears as a generic / NPC-placed bounty). Amount is set by the Bounty Amount slider.",
        function(f) sendBounty(f:GetPlayerIndex(), true) end)) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.SET_BOUNTY_OWNED, "Set Owned Bounty", eFeatureType.Button,
        "Places a bounty on this player under your name. Amount is set by the Bounty Amount slider.",
        function(f) sendBounty(f:GetPlayerIndex(), false) end)) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    local function sendBountyEveryone(anonymous)
        local localPid = GTA.GetLocalPlayerId()
        local count = 0
        for p = 0, 31 do
            if p ~= localPid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(p) then
                if sendBounty(p, anonymous, true) then count = count + 1 end
            end
        end
        local amount = 9000
        local amtFeat = FeatureMgr.GetFeature(H.BOUNTY_AMOUNT)
        if amtFeat then amount = amtFeat:GetIntValue() end
        if amount < 1 then amount = 1 elseif amount > 10000 then amount = 10000 end
        GUI.AddToast("VibeScript",
            string.format("Placed a $%d %s bounty on %d player(s).",
                amount, anonymous and "anonymous" or "owned", count), 4000)
    end

    FeatureMgr.AddFeature(H.SET_BOUNTY_ALL_NPC, "Set NPC Bounty on Everyone",
        eFeatureType.Button,
        "Places an anonymous bounty on every other player in the session. Amount is set by the Bounty Amount slider.",
        function() sendBountyEveryone(true) end)
        :SetSaveable(false)

    FeatureMgr.AddFeature(H.SET_BOUNTY_ALL_OWNED, "Set Owned Bounty on Everyone",
        eFeatureType.Button,
        "Places a bounty under your name on every other player in the session. Amount is set by the Bounty Amount slider.",
        function() sendBountyEveryone(false) end)
        :SetSaveable(false)
end


do
    local G_SI_BASE = IS_ENHANCED and 1951218 or 1950702
    local G_SI = {
        override = G_SI_BASE + (IS_ENHANCED and 3934 or 3892),
        accepted = G_SI_BASE + (IS_ENHANCED and 4301 or 4257),
        active   = G_SI_BASE + (IS_ENHANCED and 4292 or 4248),
        siId     = G_SI_BASE + (IS_ENHANCED and 4293 or 4249),
        setIn    = G_SI_BASE + (IS_ENHANCED and 4299 or 4255),
    }
    local SE_KICK_INTERIOR   = -1496371358
    local SE_PROPERTY_INVITE = -1321657966
    local SE_GANG_LEAVE_HELI =   247853458
    local YACHT_PROPERTY_ID  = 86

    local function nameOf(pid)
        local n = Players.GetName(pid)
        if n and n ~= "" then return n end
        return ("Player %d"):format(pid)
    end

    local function readSimpleInterior(pid) return lockOntoPlayers.bdSimpleInterior(pid) end

    local function readProperty(pid) return lockOntoPlayers.bdProperty(pid) end

    local function readSimpleInstance(pid) return lockOntoPlayers.bdSimpleInstance(pid) end

    local function localMask()
        local p = GTA.GetLocalPlayerId()
        if not p or p < 0 or p > 31 then return 0 end
        return 1 << p
    end

    local function localInSimpleInterior()
        local lp = GTA.GetLocalPlayerId()
        if not lp or lp < 0 or lp > 31 then return false end
        local si = readSimpleInterior(lp)
        return si ~= nil and si >= 1 and si <= 250
    end

    local function ejectFromInterior(pid)
        local tm         = 1 << pid
        local lp         = GTA.GetLocalPlayerId()
        local simpleId   = readSimpleInterior(pid)
        local simpleInst = readSimpleInstance(pid)
        local propertyId = readProperty(pid)
        if simpleId ~= -1 then
            GTA.TriggerScriptEvent(tm, { SE_KICK_INTERIOR, lp, tm, simpleId, simpleInst, 0, 0, 0, -1 })
            return "simple"
        elseif propertyId ~= -1 then
            GTA.TriggerScriptEvent(tm, { SE_PROPERTY_INVITE, lp, tm, -1, -1, 1, propertyId, 0, 0, 1, 0 })
            GTA.TriggerScriptEvent(tm, { SE_GANG_LEAVE_HELI, lp, tm, pid, pid, tm })
            return "property"
        end
        return "none"
    end

    local function doEnter(pid)
        if not pid or pid < 0 or pid > 31 then return end
        if pid == GTA.GetLocalPlayerId() then
            GUI.AddToast("VibeScript", "Pick another player.", 3000); return
        end
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
            GUI.AddToast("VibeScript", "Player not connected.", 3000); return
        end
        local name       = nameOf(pid)
        local simpleId   = readSimpleInterior(pid)
        local propertyId = readProperty(pid)
        Logger.LogInfo(("[VibeScript] Enter Interior: pid=%d name=%s simple=%d property=%d")
            :format(pid, name, simpleId, propertyId))
        if simpleId == -1 and propertyId == -1 then
            GUI.AddToast("VibeScript", name .. " is not in an interior.", 3000); return
        end

        if localInSimpleInterior() then
            GUI.AddToast("VibeScript",
                "You're in a bunker/nightclub-type interior -- step out to the street first.", 4500)
            return
        end

        if simpleId ~= -1 then
            ScriptGlobal.SetInt(G_SI.accepted, 1)
            ScriptGlobal.SetInt(G_SI.override, pid)
            ScriptGlobal.SetInt(G_SI.siId, simpleId)
            ScriptGlobal.SetInt(G_SI.active, 1)
            ScriptGlobal.SetInt(G_SI.setIn, 1)
            GUI.AddToast("VibeScript", ("Entering %s's interior."):format(name), 3000)
        elseif propertyId == YACHT_PROPERTY_ID then
            GUI.AddToast("VibeScript",
                name .. " is on a yacht - entering yachts is a known limitation, work in progress.", 4500)
        elseif propertyId ~= -1 then
            local sm = localMask()
            if sm == 0 then return end
            GTA.TriggerScriptEvent(sm, {
                SE_PROPERTY_INVITE, GTA.GetLocalPlayerId(), sm,
                pid,
                -1,
                1,
                propertyId,
                0, 0, 0, 0,
            })
            GUI.AddToast("VibeScript", ("Entering %s's interior."):format(name), 3000)
        end
    end

    local function doKick(pid)
        if not pid or pid < 0 or pid > 31 then return end
        if pid == GTA.GetLocalPlayerId() then
            GUI.AddToast("VibeScript", "Pick another player.", 3000); return
        end
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
            GUI.AddToast("VibeScript", "Player not connected.", 3000); return
        end
        local name       = nameOf(pid)
        local simpleId   = readSimpleInterior(pid)
        local simpleInst = readSimpleInstance(pid)
        local propertyId = readProperty(pid)
        Logger.LogInfo(("[VibeScript][KickInterior] pid=%d name=%s simple=%d inst=%d property=%d")
            :format(pid, name, simpleId, simpleInst, propertyId))
        if simpleId == -1 and propertyId == YACHT_PROPERTY_ID then
            local evict = playerState.forceOntoMission
            if not evict then
                GUI.AddToast("VibeScript",
                    name .. " is on a yacht -- yacht kick is unavailable right now.", 4500)
                return
            end
            local ok = evict(pid)
            GUI.AddToast("VibeScript",
                ok and ("Kicking %s off their yacht..."):format(name)
                    or (name .. " is on a yacht -- yacht kick failed to send."), 4500)
            return
        end
        if ejectFromInterior(pid) == "none" then
            GUI.AddToast("VibeScript", name .. " is not in an interior.", 3000); return
        end
        GUI.AddToast("VibeScript",
            ("Kick From Interior: %s (simple=%d property=%d)"):format(name, simpleId, propertyId), 3000)
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.ENTER_INTERIOR, "Enter Interior", eFeatureType.Button,
        "Warps into this player's current interior using the captured request-to-warp flow.",
        function(f)
            playerState.enterInteriorPending[#playerState.enterInteriorPending + 1] =
                { pid = f:GetPlayerIndex() }
        end)) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
        H.KICK_INTERIOR, "Kick From Interior", eFeatureType.Button,
        "Kicks this player out of their current interior.",
        function(f)
            playerState.kickInteriorPending[#playerState.kickInteriorPending + 1] =
                { pid = f:GetPlayerIndex() }
        end)) do
        FeatureMgr.GetFeature(hash):SetSaveable(false)
    end

    local dispatcherTicked = false
    Script.RegisterLooped(function()
        if not dispatcherTicked then
            dispatcherTicked = true
            if VIBESCRIPT_VERBOSE then Logger.LogInfo("[VibeScript] interior dispatcher is ticking") end
        end
        if scriptUnloading then
            playerState.enterInteriorPending = {}
            playerState.kickInteriorPending = {}
            Script.Yield(100)
            return
        end
        if #playerState.kickInteriorPending > 0 then
            local req = table.remove(playerState.kickInteriorPending, 1)
            doKick(req.pid)
            Script.Yield()
            return
        end
        if #playerState.enterInteriorPending == 0 then
            Script.Yield(100)
            return
        end
        local req = table.remove(playerState.enterInteriorPending, 1)
        doEnter(req.pid)
        Script.Yield()
    end)

    if VIBESCRIPT_VERBOSE then
        Logger.LogInfo(("[VibeScript] Interior module ready (build=%s); enter/kick dispatcher registered")
            :format(IS_ENHANCED and "Enhanced" or "Legacy"))
    end
end


local chimpSwarmFeatures = FeatureMgr.AddPlayerFeature(
    H.CHIMP_SWARM, "Chimp Swarm", eFeatureType.Button,
    "Spawns a ring of wrench-wielding chimps around this player. They charge in and swing.",
    function(f)
        playerState.chimpSwarmPending[#playerState.chimpSwarmPending + 1] =
            { pid = f:GetPlayerIndex() }
        telemetryCountAction("ChimpSwarm")
    end)
for _, hash in ipairs(chimpSwarmFeatures) do
    FeatureMgr.GetFeature(hash):SetSaveable(false)
end

for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
    H.CHIMP_DEL, "Delete All Chimps", eFeatureType.Button,
    "Removes every wrench chimp currently spawned.",
    function(f)
        playerState.chimpSwarmPending = {}
        chimpFn.deleteAll()
    end)) do
    FeatureMgr.GetFeature(hash):SetSaveable(false)
end

centralOnTick(FeatureMgr.AddFeature(playerState.chimpSpawnerHash, "##ChimpSwarmSpawner",
    eFeatureType.Toggle, "", chimpFn.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(playerState.chimpSpawnerHash):Toggle()


centralOnTick(FeatureMgr.AddFeature(H.DRIFT_ASSIST, "Drift Assist", eFeatureType.Toggle,
    "Boosts engine power and applies forces during drifts - counters GTA's power cut",
    driftAssistOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.DRIFT_TRACTION, "Traction Reduction", eFeatureType.SliderFloat,
    "How aggressively the assist sustains drifts (0 = off, 1 = maximum)",
    function(f) driftState.tractionMult = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.0, 1.0)
    :SetDefaultValue(0.5)
    :Reset()

FeatureMgr.AddFeature(H.DRIFT_FORCE, "Drift Force", eFeatureType.SliderFloat,
    "Extra force multiplier applied during drifts (1 = normal, higher = stronger)",
    function(f) driftState.forceMult = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.1, 5.0)
    :SetDefaultValue(1.0)
    :Reset()

FeatureMgr.AddFeature(H.DRIFT_POWER, "Power Boost", eFeatureType.SliderFloat,
    "Engine torque boost during drifts - counters GTA's power cut (0 = off, 3 = aggressive)",
    function(f) driftState.powerMult = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.0, 3.0)
    :SetDefaultValue(1.5)
    :Reset()

FeatureMgr.AddFeature(H.DRIFT_SCORE, "Drift Score Display", eFeatureType.Toggle,
    "Show on-screen drift score and session best")
    :SetDefaultValue(true)
    :Reset()

FeatureMgr.AddFeature(H.DRIFT_SMOKE, "Tire Smoke", eFeatureType.Toggle,
    "Spawn tire smoke particles at the rear during drifts")
    :SetDefaultValue(true)
    :Reset()

FeatureMgr.AddFeature(H.DRIFT_EXIT_BOOST, "Exit Boost", eFeatureType.Toggle,
    "Burst of speed when cleanly ending a drift")
    :SetDefaultValue(true)
    :Reset()


local function quickTurnOnTick(f, angle, dir)
    if not f:IsToggled() then
        if quickTurn.activeFeature == f then
            if quickTurn.veh ~= 0 then
                ENTITY.FREEZE_ENTITY_POSITION(quickTurn.veh, false)
            end
            quickTurn.tick = 0
            quickTurn.totalRotation = 0
            quickTurn.settleStart = 0
            quickTurn.startHeading = 0
            quickTurn.entrySpeed = 0
            quickTurn.boostStart = 0
            quickTurn.veh = 0
            quickTurn.activeFeature = nil
        end
        return
    end

    if quickTurn.activeFeature ~= nil and quickTurn.activeFeature ~= f then
        f:Toggle()
        return
    end

    if not isPlayerReady() or NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then
        f:Toggle()
        return
    end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then f:Toggle() return end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then f:Toggle() return end

    quickTurn.activeFeature = f
    quickTurn.targetAngle = angle
    quickTurn.veh = veh
    quickTurn.tick = quickTurn.tick + 1
    local heading = ENTITY.GET_ENTITY_HEADING(veh)

    if quickTurn.tick == 1 then
        quickTurn.startHeading = heading
        quickTurn.prevHeading = heading
        quickTurn.totalRotation = 0
        quickTurn.direction = dir

        local vel = ENTITY.GET_ENTITY_VELOCITY(veh)
        local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
        local fwdSpeed = vel.x * fwd.x + vel.y * fwd.y + vel.z * fwd.z
        quickTurn.entrySpeed = math.abs(fwdSpeed)
        return
    end

    local frameDelta = heading - quickTurn.prevHeading
    frameDelta = ((frameDelta + 180) % 360) - 180
    quickTurn.totalRotation = quickTurn.totalRotation + math.abs(frameDelta)
    quickTurn.prevHeading = heading

    local spinThreshold = angle * 0.94
    local maxTicks = math.max(30, math.floor(angle / 3))
    local spinning = quickTurn.totalRotation < spinThreshold
        and quickTurn.tick <= maxTicks
        and quickTurn.settleStart == 0

    if spinning then
        local speedScale = math.max(0.3, math.min(quickTurn.entrySpeed / 25.0, 1.0))
        local progress = math.min(quickTurn.totalRotation / spinThreshold, 1.0)
        local sf = quickTurn.spinForce
        local spinMag = sf * speedScale * (1.0 - progress * 0.5) * quickTurn.direction
        local leverArm = 1.5 + sf * 0.4

        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1,
            spinMag, 0.0, 0.0,
            0.0, -leverArm, 0.0,
            0, true, true, true, false, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1,
            -spinMag, 0.0, 0.0,
            0.0, leverArm, 0.0,
            0, true, true, true, false, true)

        local vel = ENTITY.GET_ENTITY_VELOCITY(veh)
        local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
        local rightX = fwd.y
        local rightY = -fwd.x
        local slideRate = sf * 0.15 * speedScale * (1.0 - progress) * -quickTurn.direction
        ENTITY.SET_ENTITY_VELOCITY(veh,
            vel.x + rightX * slideRate,
            vel.y + rightY * slideRate,
            vel.z)

        if quickTurn.tick <= 3 and angle >= 180 and quickTurn.popForce > 0 then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
                0.0, 0.0, quickTurn.popForce,
                true, false, true, true)
        end

        local brakeMag = (sf / 3.0) * 1.5 * (1.0 - progress * 0.7)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
            fwd.x * -brakeMag, fwd.y * -brakeMag, 0.0,
            true, false, true, true)
    elseif quickTurn.boostStart == 0 then
        local targetHeading = (quickTurn.startHeading + quickTurn.direction * angle) % 360.0

        if quickTurn.settleStart == 0 then
            quickTurn.settleStart = quickTurn.tick
            ENTITY.FREEZE_ENTITY_POSITION(veh, true)
            ENTITY.SET_ENTITY_HEADING(veh, targetHeading)
        end

        if quickTurn.tick - quickTurn.settleStart >= 2 then
            ENTITY.FREEZE_ENTITY_POSITION(veh, false)
            ENTITY.SET_ENTITY_HEADING(veh, targetHeading)

            VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, quickTurn.entrySpeed * 0.5)
            quickTurn.boostStart = quickTurn.tick
        end
    else
        local targetHeading = (quickTurn.startHeading
            + quickTurn.direction * quickTurn.targetAngle) % 360.0
        ENTITY.SET_ENTITY_HEADING(veh, targetHeading)

        local currentSpeed = ENTITY.GET_ENTITY_SPEED(veh)
        local deficit = quickTurn.entrySpeed - currentSpeed
        local boostTicks = quickTurn.tick - quickTurn.boostStart

        if deficit > 0.5 and boostTicks < 60 then
            local boostForce = math.min(deficit * quickTurn.boostForce, 10.0)
            local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
                fwd.x * boostForce, fwd.y * boostForce, 0.0,
                true, false, true, true)
        else
            if currentSpeed < quickTurn.entrySpeed * 0.6 and quickTurn.entrySpeed > 3.0 then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, quickTurn.entrySpeed * 0.8)
            end
            ENTITY.SET_ENTITY_HEADING(veh, targetHeading)
            f:Toggle()
            quickTurn.tick = 0
            quickTurn.totalRotation = 0
            quickTurn.settleStart = 0
            quickTurn.startHeading = 0
            quickTurn.entrySpeed = 0
            quickTurn.boostStart = 0
            quickTurn.veh = 0
            quickTurn.activeFeature = nil
            return
        end
    end
end

centralOnTick(FeatureMgr.AddFeature(H.JTURN, "J-Turn", eFeatureType.Toggle,
    "Spin your vehicle 180 deg - hold A or D to pick direction",
    function(f)
        telemetryCountToggleEdge("JTurn", 0, f:IsToggled())
        local dir
        if Utils.IsKeyDown(0x41) then dir = 1
        else dir = -1 end
        quickTurnOnTick(f, 180, dir)
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.LTURN, "L-Turn", eFeatureType.Toggle,
    "Quick 90 deg turn - hold A or D to pick direction",
    function(f)
        telemetryCountToggleEdge("LTurn", 0, f:IsToggled())
        local dir
        if Utils.IsKeyDown(0x41) then dir = 1
        else dir = -1 end
        quickTurnOnTick(f, 90, dir)
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.TURN_LEFT, "Turn Left 90 deg", eFeatureType.Toggle,
    "Quick 90 deg left turn with speed preservation",
    function(f) telemetryCountToggleEdge("TurnLeft90", 0, f:IsToggled()) quickTurnOnTick(f, 90, 1) end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

centralOnTick(FeatureMgr.AddFeature(H.TURN_RIGHT, "Turn Right 90 deg", eFeatureType.Toggle,
    "Quick 90 deg right turn with speed preservation",
    function(f) telemetryCountToggleEdge("TurnRight90", 0, f:IsToggled()) quickTurnOnTick(f, 90, -1) end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.TURN_SPIN_FORCE, "Spin Force", eFeatureType.SliderFloat,
    "How aggressively the car rotates during turns (higher = faster spin)",
    function(f) quickTurn.spinForce = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.5, 8.0)
    :SetDefaultValue(3.0)
    :Reset()

FeatureMgr.AddFeature(H.TURN_BOOST_FORCE, "Exit Boost", eFeatureType.SliderFloat,
    "How quickly speed is restored after the turn completes (0 = no restore)",
    function(f) quickTurn.boostForce = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.0, 1.0)
    :SetDefaultValue(0.4)
    :Reset()

FeatureMgr.AddFeature(H.TURN_POP, "J-Turn Pop", eFeatureType.SliderFloat,
    "Upward lift at the start of a J-Turn for flair (0 = flat)",
    function(f) quickTurn.popForce = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.0, 5.0)
    :SetDefaultValue(2.0)
    :Reset()


if VIBESCRIPT_LOADER then

local function driftTargetOnTick(f)
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end

    local pid = f:GetPlayerIndex()
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end

    local tractionFeat = FeatureMgr.GetFeature(H.DRIFT_TARGET_TR, pid)
    local traction = tractionFeat and tractionFeat:GetFloatValue() or 0.5
    local forceFeat = FeatureMgr.GetFeature(H.DRIFT_TARGET_F, pid)
    local power = forceFeat and forceFeat:GetFloatValue() or 1.0

    local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
    local vel = ENTITY.GET_ENTITY_VELOCITY(veh)
    local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y)

    if speed < driftState.MIN_SPEED then return end

    local velNX, velNY = vel.x / speed, vel.y / speed
    local dot = math.max(-1.0, math.min(1.0, fwd.x * velNX + fwd.y * velNY))
    local slipAngle = math.deg(math.acos(dot))

    if slipAngle < driftState.MIN_ANGLE or slipAngle >= driftState.MAX_ANGLE then return end
    if ENTITY.IS_ENTITY_IN_AIR(veh) then return end
    local gotControl = false
    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
        local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
        local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
        local localPlayer = Players.GetById(GTA.GetLocalPlayerId())
        if netObj and localPlayer then
            NetworkObjectMgr.ChangeOwner(netObj, localPlayer, 0)
            gotControl = true
        end
    end
    if not gotControl then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
        gotControl = NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh)
    end
    if not gotControl then return end

    local angleFactor = math.min((slipAngle - driftState.MIN_ANGLE)
        / (driftState.MAX_ANGLE - driftState.MIN_ANGLE), 1.0)
    local speedFeedback = math.max(1.0 - (speed - 20.0) / 20.0, 0.0)
    local torqueMult = 1.0 + (power * angleFactor * speedFeedback)
    VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(veh, torqueMult)

    local cross = fwd.x * velNY - fwd.y * velNX
    local slideDir = cross < 0 and 1.0 or -1.0
    local rightX, rightY = fwd.y, -fwd.x
    local speedFactor = math.min(speed / 25.0, 1.0)
    local fwdForce = traction * 0.25 * speedFactor * power
    local latForce = traction * 0.15 * speedFactor * power
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1,
        fwd.x * fwdForce + rightX * latForce * slideDir,
        fwd.y * fwdForce + rightY * latForce * slideDir,
        0.0, true, false, true, true)

    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
        local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
        local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
        local targetPlayer = Players.GetById(pid)
        if netObj and targetPlayer then
            NetworkObjectMgr.ChangeOwner(netObj, targetPlayer, 0)
        end
    end

end

local driftTargetFeatures = FeatureMgr.AddPlayerFeature(
    H.DRIFT_TARGET, "Drift Assist", eFeatureType.Toggle,
    "Boosts power and applies drift forces to this player's vehicle",
    driftTargetOnTick)
for _, hash in ipairs(driftTargetFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.DRIFT_TARGET, driftTargetOnTick)

local driftTargetTrFeatures = FeatureMgr.AddPlayerFeature(
    H.DRIFT_TARGET_TR, "Traction", eFeatureType.SliderFloat,
    "Drift force strength (0 = off, 1 = maximum)")
for _, hash in ipairs(driftTargetTrFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetLimitValues(0.0, 1.0)
        :SetDefaultValue(0.5)
        :SetSaveable(false)
        :Reset()
end

local driftTargetFFeatures = FeatureMgr.AddPlayerFeature(
    H.DRIFT_TARGET_F, "Power Boost", eFeatureType.SliderFloat,
    "Engine torque boost during slides (counters GTA's power cut)")
for _, hash in ipairs(driftTargetFFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetLimitValues(0.1, 5.0)
        :SetDefaultValue(1.5)
        :SetSaveable(false)
        :Reset()
end

end

local vehGunTargetFeatures = FeatureMgr.AddPlayerFeature(
    H.VEH_GUN_TARGET, "Vehicle Gun", eFeatureType.Toggle,
    "When this player shoots, random vehicles (land, air & sea) spawn from their gun following their aim direction",
    vehGunTargetOnTick)
for _, hash in ipairs(vehGunTargetFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.VEH_GUN_TARGET, vehGunTargetOnTick)


local function blackIceOnTick(f)
    telemetryCountToggleEdge("BlackIce", f:GetPlayerIndex(), f:IsToggled())
    if not f:IsToggled() then return end
    if not isPlayerReady() then return end

    local pid = f:GetPlayerIndex()
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

    local now = Time.GetEpocheMs()
    if playerState.blackIceLastSent[pid] and (now - playerState.blackIceLastSent[pid]) < 5000 then return end
    playerState.blackIceLastSent[pid] = now

    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 67, 1.0, false, true, 0.0, true)
end

local blackIceFeatures = FeatureMgr.AddPlayerFeature(
    H.BLACK_ICE, "Black Ice", eFeatureType.Toggle,
    "Makes the player's vehicle tyres have zero grip (slippery surface effect)",
    blackIceOnTick)
for _, hash in ipairs(blackIceFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.BLACK_ICE, blackIceOnTick)


function playerState.speed.onTick(f)
    local pid = f:GetPlayerIndex()
    telemetryCountToggleEdge("EnginePowerTarget", pid, f:IsToggled())

    if not f:IsToggled() then
        playerState.speed.restore(pid)
        return
    end
    if not isPlayerReady() then return end
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
        playerState.speed.restore(pid)
        return
    end

    local syncFeat = FeatureMgr.GetFeature(H.PLAYER_SPEED_SYNC, pid)
    local multFeat = FeatureMgr.GetFeature(H.PLAYER_SPEED_MULT, pid)
    local mult = (multFeat and multFeat:GetFloatValue()) or 1.0
    if syncFeat and syncFeat:IsToggled() then
        mult = playerState.speed.syncSlider(pid)
    end

    playerState.speed.apply(pid, mult)
end

function playerState.speed.syncOnTick(f)
    if not f:IsToggled() then return end

    local pid = f:GetPlayerIndex()
    local mult = playerState.speed.syncSlider(pid)
    local speedFeat = FeatureMgr.GetFeature(H.PLAYER_SPEED, pid)
    if speedFeat and speedFeat:IsToggled()
        and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid)
    then
        playerState.speed.apply(pid, mult)
    end
end

for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
    H.PLAYER_SPEED, "Engine Power Multiplier", eFeatureType.Toggle,
    "Applies a Stand-style engine power multiplier to this player's current vehicle",
    playerState.speed.onTick)) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.PLAYER_SPEED, playerState.speed.onTick)

for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
    H.PLAYER_SPEED_MULT, "Power Multiplier", eFeatureType.SliderFloat,
    "Vehicle engine power multiplier (1.0 = default, 20.0 = max)")) do
    FeatureMgr.GetFeature(hash)
        :SetLimitValues(1.0, 20.0)
        :SetDefaultValue(1.0)
        :SetSaveable(false)
        :Reset()
end

for _, hash in ipairs(FeatureMgr.AddPlayerFeature(
    H.PLAYER_SPEED_SYNC, "Sync To Self", eFeatureType.Toggle,
    "Keeps this player's vehicle speed multiplier matched to your Engine Power multiplier",
    playerState.speed.syncOnTick)) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.PLAYER_SPEED_SYNC, playerState.speed.syncOnTick)


local function phantomBrakeOnTick(f)
    telemetryCountToggleEdge("PhantomBrake", f:GetPlayerIndex(), f:IsToggled())
    if not f:IsToggled() then
        playerState.phantomBrake[f:GetPlayerIndex()] = nil
        return
    end
    if not isPlayerReady() then return end

    local pid = f:GetPlayerIndex()
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if veh == 0 then return end

    if not playerState.phantomBrake[pid] then
        local minFeat = FeatureMgr.GetFeature(H.PHANTOM_MIN, pid)
        local maxFeat = FeatureMgr.GetFeature(H.PHANTOM_MAX, pid)
        local minSec = minFeat and minFeat:GetFloatValue() or 5.0
        local maxSec = maxFeat and maxFeat:GetFloatValue() or 10.0
        if minSec > maxSec then minSec = maxSec end
        playerState.phantomBrake[pid] = {
            nextBrake = math.random(math.floor(minSec * 60), math.floor(maxSec * 60)),
            braking = false,
            brakeTicks = 0,
            maxTicks = 0,
        }
    end
    local st = playerState.phantomBrake[pid]

    if not st.braking then
        st.nextBrake = st.nextBrake - 1
        if st.nextBrake <= 0 then
            st.braking = true
            st.brakeTicks = 0
            local durFeat = FeatureMgr.GetFeature(H.PHANTOM_DUR, pid)
            local durSec = durFeat and durFeat:GetFloatValue() or 0.07
            local baseTicks = math.max(3, math.floor(durSec * 60))
            local jitter = math.floor(baseTicks * 0.2)
            st.maxTicks = baseTicks + math.random(-jitter, jitter)

            if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
                local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
                local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
                local localPlayer = Players.GetById(GTA.GetLocalPlayerId())
                if netObj and localPlayer then
                    NetworkObjectMgr.ChangeOwner(netObj, localPlayer, 0)
                end
            end
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
        end
    else
        st.brakeTicks = st.brakeTicks + 1

        if st.brakeTicks <= st.maxTicks then
            do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                VEHICLE.SET_VEHICLE_BRAKE(veh, true)
                VEHICLE.SET_VEHICLE_HANDBRAKE(veh, true)
                local v = ENTITY.GET_ENTITY_VELOCITY(veh)
                ENTITY.SET_ENTITY_VELOCITY(veh, v.x * 0.75, v.y * 0.75, v.z)
            end
        else
            VEHICLE.SET_VEHICLE_BRAKE(veh, false)
            VEHICLE.SET_VEHICLE_HANDBRAKE(veh, false)

            if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
                local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
                local netObj = NetworkObjectMgr.GetNetworkObject(netId, true)
                local targetPlayer = Players.GetById(pid)
                if netObj and targetPlayer then
                    NetworkObjectMgr.ChangeOwner(netObj, targetPlayer, 0)
                end
            end

            st.braking = false
            local minF = FeatureMgr.GetFeature(H.PHANTOM_MIN, pid)
            local maxF = FeatureMgr.GetFeature(H.PHANTOM_MAX, pid)
            local lo = minF and math.floor(minF:GetFloatValue() * 60) or 300
            local hi = maxF and math.floor(maxF:GetFloatValue() * 60) or 600
            if lo > hi then lo = hi end
            st.nextBrake = math.random(lo, hi)
        end
    end
end

local phantomBrakeFeatures = FeatureMgr.AddPlayerFeature(
    H.PHANTOM_BRAKE, "Phantom Brake", eFeatureType.Toggle,
    "Randomly taps the target's brakes - feels like lag or a broken controller",
    phantomBrakeOnTick)
for _, hash in ipairs(phantomBrakeFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end
centralPlayerOnTick(H.PHANTOM_BRAKE, phantomBrakeOnTick)

local phantomMinFeatures = FeatureMgr.AddPlayerFeature(
    H.PHANTOM_MIN, "Min Interval (sec)", eFeatureType.SliderFloat,
    "Minimum seconds between brake taps")
for _, hash in ipairs(phantomMinFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetLimitValues(0.5, 30.0)
        :SetDefaultValue(5.0)
        :SetSaveable(false)
        :Reset()
end

local phantomMaxFeatures = FeatureMgr.AddPlayerFeature(
    H.PHANTOM_MAX, "Max Interval (sec)", eFeatureType.SliderFloat,
    "Maximum seconds between brake taps")
for _, hash in ipairs(phantomMaxFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetLimitValues(0.5, 30.0)
        :SetDefaultValue(10.0)
        :SetSaveable(false)
        :Reset()
end







local function watchYoJetDeleteEntity(handle)
    if not ENTITY.DOES_ENTITY_EXIST(handle) then return end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(handle)
    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(handle) then
        NETWORK.NETWORK_UNREGISTER_NETWORKED_ENTITY(handle)
    end
    Memory.WriteInt(watchYoJet.delBuf, handle)
    ENTITY.DELETE_ENTITY(watchYoJet.delBuf)
    if ENTITY.DOES_ENTITY_EXIST(handle) then
        Memory.WriteInt(watchYoJet.delBuf, handle)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(watchYoJet.delBuf)
    end
end

local function watchYoJetCleanupAll()
    for _, entry in ipairs(watchYoJet.pool) do
        if ENTITY.DOES_ENTITY_EXIST(entry.jet) then
            watchYoJetDeleteEntity(entry.jet)
        end
    end
    watchYoJet.pool = {}
    playerState.watchYoJetPending = {}
    if watchYoJet.focusSet then
        STREAMING.CLEAR_FOCUS()
        watchYoJet.focusSet = false
    end
    if watchYoJet.jetHash ~= 0 then
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(watchYoJet.jetHash)
    end
end

watchYoJet.jetHash = Utils.Joaat("lazer")

local function watchYoJetSpawn(pid, persistent, far)
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if targetPed == 0 or not ENTITY.DOES_ENTITY_EXIST(targetPed) then return end

    if not STREAMING.HAS_MODEL_LOADED(watchYoJet.jetHash) then return end

    local targetPos = ENTITY.GET_ENTITY_COORDS(targetPed, true)
    local targetHeading = ENTITY.GET_ENTITY_HEADING(targetPed)
    local spawnDist = 100.0
    local spawnAlt = 20.0
    local angles = { 90, -90, 180, 0, 45, -45, 135, -135 }
    local spawnX, spawnY, spawnZ
    local clear = false

    for _, offset in ipairs(angles) do
        local rad = math.rad(targetHeading + offset)
        local sx = targetPos.x - math.sin(rad) * spawnDist
        local sy = targetPos.y + math.cos(rad) * spawnDist
        local sz = targetPos.z + spawnAlt
        local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            sx, sy, sz,
            targetPos.x, targetPos.y, targetPos.z,
            1, targetPed, 7)
        SHAPETEST.GET_SHAPE_TEST_RESULT(handle,
            grav.rayBuf, grav.rayBuf + 8, grav.rayBuf + 32, grav.rayBuf + 56)
        if Memory.ReadByte(grav.rayBuf) == 0 then
            spawnX, spawnY, spawnZ = sx, sy, sz
            clear = true
            break
        end
    end

    if not clear then
        spawnX = targetPos.x
        spawnY = targetPos.y
        spawnZ = targetPos.z + 100.0
    end

    local dx = targetPos.x - spawnX
    local dy = targetPos.y - spawnY
    local heading = math.deg(math.atan(-dx, dy)) % 360.0

    local jet = VEHICLE.CREATE_VEHICLE(
        watchYoJet.jetHash, spawnX, spawnY, spawnZ,
        heading, false, false, false)
    if not jet or jet == 0 then return end

    NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(jet)
    VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(jet)
    VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(jet, 4)

    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(jet, true, true)

    local dz = targetPos.z - spawnZ
    local totalDist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if totalDist > 0 then
        local speed = watchYoJet.SPEED
        ENTITY.SET_ENTITY_VELOCITY(jet,
            dx / totalDist * speed,
            dy / totalDist * speed,
            dz / totalDist * speed)
    end

    watchYoJet.pool[#watchYoJet.pool + 1] = {
        jet = jet,
        targetPed = targetPed,
        persistent = persistent or false,
        collisionOn = false,
        spawnTime = Time.GetEpocheMs(),
        far = far or false,
    }
end


local watchYoJetFeatures = FeatureMgr.AddPlayerFeature(
    H.WATCH_YO_JET, "Watch Yo Jet", eFeatureType.Button,
    "Sends a guided fighter jet at the player (one hit then flies off)",
    function(f)
        playerState.watchYoJetPending[#playerState.watchYoJetPending + 1] = { pid = f:GetPlayerIndex(), persistent = false }
        telemetryCountAction("WatchYoJet")
    end)
for _, hash in ipairs(watchYoJetFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetSaveable(false)
end

local watchYoJetFUFeatures = FeatureMgr.AddPlayerFeature(
    H.WATCH_YO_JET_FU, "Fuck You Jet", eFeatureType.Button,
    "Same jet, but it keeps coming back for more",
    function(f)
        playerState.watchYoJetPending[#playerState.watchYoJetPending + 1] = { pid = f:GetPlayerIndex(), persistent = true }
        telemetryCountAction("FuckYouJet")
    end)
for _, hash in ipairs(watchYoJetFUFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetSaveable(false)
end

local watchYoJetDelFeatures = FeatureMgr.AddPlayerFeature(
    H.WATCH_YO_JET_DEL, "Delete All Jets", eFeatureType.Button,
    "Deletes all active Watch Yo Jet jets",
    function(f) watchYoJetCleanupAll() end)
for _, hash in ipairs(watchYoJetDelFeatures) do
    FeatureMgr.GetFeature(hash)
        :SetSaveable(false)
end

centralOnTick(FeatureMgr.AddFeature(playerState.wyjtSpawnerHash, "##WYJTSpawner", eFeatureType.Toggle, "",
    function(f)
        if not f:IsToggled() then return end
        local pending = playerState.watchYoJetPending
        if #pending == 0 then return end

        if not STREAMING.HAS_MODEL_LOADED(watchYoJet.jetHash) then
            STREAMING.REQUEST_MODEL(watchYoJet.jetHash)
        end

        local req = pending[1]
        if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(req.pid) then
            table.remove(pending, 1)
            return
        end
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(req.pid)
        local hasClone = targetPed and targetPed ~= 0
            and ENTITY.DOES_ENTITY_EXIST(targetPed)
        if hasClone then req.lastPos = ENTITY.GET_ENTITY_COORDS(targetPed, true) end

        if not req.toasted then
            req.toasted = true
            local farAway = not hasClone
            if hasClone and req.lastPos then
                local lp = PLAYER.PLAYER_PED_ID()
                if lp and lp ~= 0 and ENTITY.DOES_ENTITY_EXIST(lp) then
                    local b = ENTITY.GET_ENTITY_COORDS(lp, true)
                    local dx = req.lastPos.x - b.x
                    local dy = req.lastPos.y - b.y
                    local dz = req.lastPos.z - b.z
                    farAway = (dx * dx + dy * dy + dz * dz) > watchYoJet.NEAR_DIST_SQ
                end
            end
            local spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE()
            if not spectating then
                local sf = FeatureMgr.GetFeatureByName("Spectate Player", req.pid)
                if sf then spectating = sf:GetBoolValue() end
            end
            local nowMs = Time.GetEpocheMs()
            if farAway and not spectating
            and (nowMs - (watchYoJet.lastToastMs or 0)) > 5000 then
                watchYoJet.lastToastMs = nowMs
                GUI.AddToast("Watch Yo Jet",
                    "Player is far away, you should probably spectate for higher accuracy...", 5000)
            end
        end

        if not req.waitStart then req.waitStart = Time.GetEpocheMs() end
        local waited = Time.GetEpocheMs() - req.waitStart
        if not req.lastPos then
            if waited > watchYoJet.SPAWN_WAIT_MS then table.remove(pending, 1) end
            return
        end
        local tpos = req.lastPos

        if req.far == nil then
            local far = true
            local localPed = PLAYER.PLAYER_PED_ID()
            if localPed and localPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(localPed) then
                local lpos = ENTITY.GET_ENTITY_COORDS(localPed, true)
                local dx, dy, dz = tpos.x - lpos.x, tpos.y - lpos.y, tpos.z - lpos.z
                far = (dx * dx + dy * dy + dz * dz) > watchYoJet.NEAR_DIST_SQ
            end
            req.far = far
        end

        if req.far then
            STREAMING.SET_FOCUS_POS_AND_VEL(
                tpos.x, tpos.y, tpos.z, 0.0, 0.0, 0.0)
            STREAMING.REQUEST_COLLISION_AT_COORD(tpos.x, tpos.y, tpos.z)
            watchYoJet.focusSet = true
            if not req.focusStart then req.focusStart = Time.GetEpocheMs() end
            local focusedMs = Time.GetEpocheMs() - req.focusStart
            local ready = hasClone
                and STREAMING.HAS_COLLISION_LOADED_AROUND_ENTITY(targetPed)
                and focusedMs >= watchYoJet.FOCUS_MIN_MS
            if not ready and waited < watchYoJet.SPAWN_WAIT_MS then
                return
            end
            if not hasClone then
                table.remove(pending, 1)
                return
            end
        end

        if not STREAMING.HAS_MODEL_LOADED(watchYoJet.jetHash) then return end

        table.remove(pending, 1)
        watchYoJetSpawn(req.pid, req.persistent, req.far)
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(playerState.wyjtSpawnerHash):Toggle()

centralOnTick(FeatureMgr.AddFeature(Utils.Joaat("LUA_WYJTGuide"), "##WYJTGuide", eFeatureType.Toggle, "",
    function(f)
    if not f:IsToggled() then return end
    if #watchYoJet.pool == 0 then
        if watchYoJet.focusSet and #playerState.watchYoJetPending == 0 then
            STREAMING.CLEAR_FOCUS()
            watchYoJet.focusSet = false
        end
        return
    end
    local now = Time.GetEpocheMs()
    local speed = watchYoJet.SPEED
    local focusPos = nil
    local i = 1
    while i <= #watchYoJet.pool do
        local entry = watchYoJet.pool[i]
        local jetExists = ENTITY.DOES_ENTITY_EXIST(entry.jet)
        local tgtExists = ENTITY.DOES_ENTITY_EXIST(entry.targetPed)

        local timeout = entry.persistent and 60000 or watchYoJet.TIMEOUT
        if not jetExists or not tgtExists
        or (now - entry.spawnTime > timeout) then
            if jetExists then watchYoJetDeleteEntity(entry.jet) end
            table.remove(watchYoJet.pool, i)
        else
            local jetPos = ENTITY.GET_ENTITY_COORDS(entry.jet, true)
            local tgtPos = ENTITY.GET_ENTITY_COORDS(entry.targetPed, true)

            if entry.far and not entry.done and not focusPos then focusPos = tgtPos end

            local tgtVel = ENTITY.GET_ENTITY_VELOCITY(entry.targetPed)
            local dx = tgtPos.x - jetPos.x
            local dy = tgtPos.y - jetPos.y
            local dz = tgtPos.z - jetPos.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            local horizDist = math.sqrt(dx * dx + dy * dy)

            local colDist = watchYoJet.COLLISION_DIST
            if dist < colDist then
                if not entry.collisionOn then
                    ENTITY.SET_ENTITY_COLLISION(entry.jet, true, true)
                    entry.collisionOn = true
                end
            else
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(
                    entry.jet, true, true)
                if entry.persistent and entry.collisionOn then
                    entry.collisionOn = false
                end
            end

            if dist < 10.0 and not entry.exploded then
                FIRE.ADD_EXPLOSION(
                    tgtPos.x, tgtPos.y, tgtPos.z,
                    EXP_TAG.PLANE_ROCKET, 1.0, true, false, 1.0, false)
                if entry.persistent then
                    entry.exploded = true
                end
            end
            if entry.persistent and entry.exploded and dist > colDist then
                entry.exploded = false
            end

            if not entry.done and entry.collisionOn
            and not entry.persistent and dist < 10.0 then
                entry.done = true
            end

            if not entry.done then
                if not entry.blockedFrames then entry.blockedFrames = 0 end
                if not entry.diveBomb then
                    local rh = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
                        jetPos.x, jetPos.y, jetPos.z,
                        tgtPos.x, tgtPos.y, tgtPos.z,
                        1, entry.jet, 7)
                    SHAPETEST.GET_SHAPE_TEST_RESULT(rh,
                        grav.rayBuf, grav.rayBuf + 8, grav.rayBuf + 32, grav.rayBuf + 56)
                    if Memory.ReadByte(grav.rayBuf) ~= 0 then
                        entry.blockedFrames = entry.blockedFrames + 1
                    else
                        entry.blockedFrames = math.max(0, entry.blockedFrames - 2)
                    end
                    if entry.blockedFrames > 90 then
                        entry.diveBomb = true
                    end
                end

                local aimX, aimY, aimZ
                if entry.diveBomb then
                    if jetPos.z < tgtPos.z + 60.0 or horizDist > 25.0 then
                        aimX = tgtPos.x + tgtVel.x * 0.5
                        aimY = tgtPos.y + tgtVel.y * 0.5
                        aimZ = tgtPos.z + 80.0
                    else
                        aimX = tgtPos.x + tgtVel.x * 0.2
                        aimY = tgtPos.y + tgtVel.y * 0.2
                        aimZ = tgtPos.z - 10.0
                    end
                else
                    local leadTime = dist / speed
                    aimX = tgtPos.x + tgtVel.x * leadTime
                    aimY = tgtPos.y + tgtVel.y * leadTime
                    aimZ = tgtPos.z + tgtVel.z * leadTime

                    local rh = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
                        jetPos.x, jetPos.y, jetPos.z,
                        aimX, aimY, aimZ,
                        1, entry.jet, 7)
                    SHAPETEST.GET_SHAPE_TEST_RESULT(rh,
                        grav.rayBuf, grav.rayBuf + 8, grav.rayBuf + 32, grav.rayBuf + 56)
                    if Memory.ReadByte(grav.rayBuf) ~= 0 then
                        local hitZ = Memory.ReadFloat(grav.rayBuf + 24)
                        aimZ = math.max(aimZ, hitZ + 30.0)
                    end
                end

                local adx = aimX - jetPos.x
                local ady = aimY - jetPos.y
                local adz = aimZ - jetPos.z
                local aDist = math.sqrt(adx * adx + ady * ady + adz * adz)

                if aDist > 1.0 then
                    local nx, ny, nz = adx / aDist, ady / aDist, adz / aDist
                    ENTITY.SET_ENTITY_VELOCITY(entry.jet,
                        nx * speed, ny * speed, nz * speed)
                    local hdg = math.deg(math.atan(-nx, ny)) % 360.0
                    local hd = math.sqrt(nx * nx + ny * ny)
                    local pitch = math.deg(math.atan(nz, hd))
                    ENTITY.SET_ENTITY_ROTATION(entry.jet,
                        pitch, 0.0, hdg, 2, true)
                end
            end

            i = i + 1
        end
    end

    if focusPos then
        STREAMING.SET_FOCUS_POS_AND_VEL(
            focusPos.x, focusPos.y, focusPos.z, 0.0, 0.0, 0.0)
        watchYoJet.focusSet = true
    elseif watchYoJet.focusSet and #playerState.watchYoJetPending == 0 then
        STREAMING.CLEAR_FOCUS()
        watchYoJet.focusSet = false
    end
    end))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(Utils.Joaat("LUA_WYJTGuide")):Toggle()


local function getPlayerIPInfo(playerId)
    local ipInfo = Players.GetIPInfo(playerId)
    if not ipInfo then
        return nil
    end
    if (ipInfo["countryCode"] or "") == "NA" then return nil end
    return ipInfo
end

local function detectFrench(playerId)
    local ipInfo = getPlayerIPInfo(playerId)
    if not ipInfo then return nil end

    local regionsFeat = FeatureMgr.GetFeature(H.FRENCH_REGIONS)
    if not regionsFeat then return false end

    if regionsFeat:IsListIndexToggled(0) and ipInfo["countryCode"] == "CA" then
        local region = (ipInfo["region"] or ""):lower()
        local regionCode = ipInfo["regionCode"] or ""
        if region == "quebec" or regionCode == "QC" then
            return true, "Quebec"
        end
    end

    local countryCode = ipInfo["countryCode"] or ""
    local idx = FRENCH_CODE_TO_INDEX[countryCode]
    if idx and regionsFeat:IsListIndexToggled(idx) then
        return true, FRENCH_BLOCKLIST[idx + 1].name
    end

    return false
end

local function kickFrenchPlayer(playerId, reason)
    local name = Players.GetName(playerId) or "?"

    Logger.LogInfo(("[VibeScript] French Kicker: kicking %s - %s (id %d)"):format(name, reason, playerId))
    doKick(playerId)
    GUI.AddToast("VibeScript",
        ("French Kicker: kicking %s"):format(name), 5000)

    frenchKicker.kicked[playerId] = true
    frenchKicker.pending[playerId] = nil
end

local function checkAndKickFrench(playerId)
    if playerId == GTA.GetLocalPlayerId() then return end
    if frenchKicker.kicked[playerId] then return end
    local exempt = isPlayerFriend(playerId)
    exempt = isPlayerTeammate(playerId) or exempt
    if exempt then return end

    local result, reason = detectFrench(playerId)
    if result == true then
        kickFrenchPlayer(playerId, reason)
    elseif result == nil then
        if not frenchKicker.pending[playerId] then
            frenchKicker.pending[playerId] = {
                attempts = 0,
                nextCheck = os.clock() + KICKER.RETRY_DELAY,
            }
        end
    end
end

local function onFrenchPlayerJoin(playerId)
    local feat = FeatureMgr.GetFeature(H.FRENCH_KICKER)
    if not feat or not feat:IsToggled() then return end
    frenchKicker.kicked[playerId] = nil
    frenchKicker.pending[playerId] = nil
    checkAndKickFrench(playerId)
end

local function frenchKickerOnTick(f)
    if not f:IsToggled() then
        if frenchKicker.scanned or frenchKicker.eventId
           or next(frenchKicker.pending) or next(frenchKicker.kicked) then
            frenchKicker.kicked = {}
            frenchKicker.pending = {}
            frenchKicker.scanned = false
            if frenchKicker.eventId then
                EventMgr.RemoveHandler(frenchKicker.eventId)
                frenchKicker.eventId = nil
            end
        end
        return
    end

    if not frenchKicker.eventId then
        frenchKicker.eventId = EventMgr.RegisterHandler(
            eLuaEvent.ON_PLAYER_JOIN, onFrenchPlayerJoin)
    end

    if not frenchKicker.scanned then
        frenchKicker.scanned = true
        local localId = GTA.GetLocalPlayerId()
        for pid = 0, 31 do
            if pid ~= localId and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                checkAndKickFrench(pid)
            end
        end
    end

    local now = os.clock()
    for pid, info in pairs(frenchKicker.pending) do
        if now >= info.nextCheck then
            if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                frenchKicker.pending[pid] = nil
            else
                local result, reason = detectFrench(pid)
                if result == true then
                    kickFrenchPlayer(pid, reason)
                elseif result == nil then
                    info.attempts = info.attempts + 1
                    if info.attempts >= KICKER.MAX_RETRIES then
                        logf("French Kicker: gave up on player %d after %d retries", pid, KICKER.MAX_RETRIES)
                        frenchKicker.pending[pid] = nil
                    else
                        info.nextCheck = now + KICKER.RETRY_DELAY
                    end
                else
                    frenchKicker.pending[pid] = nil
                end
            end
        end
    end
end

centralOnTick(FeatureMgr.AddFeature(H.FRENCH_KICKER, "French Kicker", eFeatureType.Toggle,
    "Kicks players from French-speaking countries/regions.",
    frenchKickerOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.FRENCH_REGIONS, "Regions", eFeatureType.ComboToggles)
    :SetList(FRENCH_LIST_NAMES)
do
    local feat = FeatureMgr.GetFeature(H.FRENCH_REGIONS)
    for i = 0, #FRENCH_BLOCKLIST - 1 do
        feat:ToggleListIndex(i, true)
    end
end

do
    local CHINESE_BLOCKLIST = {
        {name = "China",  code = "CN"},
        {name = "Macau",  code = "MO"},
        {name = "Taiwan", code = "TW"},
    }
    local CHINESE_LIST_NAMES = {}
    local CHINESE_CODE_TO_INDEX = {}
    for i, entry in ipairs(CHINESE_BLOCKLIST) do
        CHINESE_LIST_NAMES[i] = entry.name
        if entry.code then
            CHINESE_CODE_TO_INDEX[entry.code] = i - 1
        end
    end

    local function detectChinese(playerId)
        local ipInfo = getPlayerIPInfo(playerId)
        if not ipInfo then return nil end

        local regionsFeat = FeatureMgr.GetFeature(H.CHINESE_REGIONS)
        if not regionsFeat then return false end

        local countryCode = ipInfo["countryCode"] or ""
        local idx = CHINESE_CODE_TO_INDEX[countryCode]
        if idx and regionsFeat:IsListIndexToggled(idx) then
            return true, CHINESE_BLOCKLIST[idx + 1].name
        end

        return false
    end

    local function kickChinesePlayer(playerId, reason)
        local name = Players.GetName(playerId) or "?"

        Logger.LogInfo(("[VibeScript] Chinese Kicker: kicking %s - %s (id %d)"):format(name, reason, playerId))
        doKick(playerId)
        GUI.AddToast("VibeScript",
            ("Chinese Kicker: kicking %s"):format(name), 5000)

        chineseKicker.kicked[playerId] = true
        chineseKicker.pending[playerId] = nil
    end

    local function checkAndKickChinese(playerId)
        if playerId == GTA.GetLocalPlayerId() then return end
        if chineseKicker.kicked[playerId] then return end
        local exempt = isPlayerFriend(playerId)
        exempt = isPlayerTeammate(playerId) or exempt
        if exempt then return end

        local result, reason = detectChinese(playerId)
        if result == true then
            kickChinesePlayer(playerId, reason)
        elseif result == nil then
            if not chineseKicker.pending[playerId] then
                chineseKicker.pending[playerId] = {
                    attempts = 0,
                    nextCheck = os.clock() + KICKER.RETRY_DELAY,
                }
            end
        end
    end

    local function onChinesePlayerJoin(playerId)
        local feat = FeatureMgr.GetFeature(H.CHINESE_KICKER)
        if not feat or not feat:IsToggled() then return end
        chineseKicker.kicked[playerId] = nil
        chineseKicker.pending[playerId] = nil
        checkAndKickChinese(playerId)
    end

    local function chineseKickerOnTick(f)
        if not f:IsToggled() then
            if chineseKicker.scanned or chineseKicker.eventId
               or next(chineseKicker.pending) or next(chineseKicker.kicked) then
                chineseKicker.kicked = {}
                chineseKicker.pending = {}
                chineseKicker.scanned = false
                if chineseKicker.eventId then
                    EventMgr.RemoveHandler(chineseKicker.eventId)
                    chineseKicker.eventId = nil
                end
            end
            return
        end

        if not chineseKicker.eventId then
            chineseKicker.eventId = EventMgr.RegisterHandler(
                eLuaEvent.ON_PLAYER_JOIN, onChinesePlayerJoin)
        end

        if not chineseKicker.scanned then
            chineseKicker.scanned = true
            local localId = GTA.GetLocalPlayerId()
            for pid = 0, 31 do
                if pid ~= localId and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                    checkAndKickChinese(pid)
                end
            end
        end

        local now = os.clock()
        for pid, info in pairs(chineseKicker.pending) do
            if now >= info.nextCheck then
                if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                    chineseKicker.pending[pid] = nil
                else
                    local result, reason = detectChinese(pid)
                    if result == true then
                        kickChinesePlayer(pid, reason)
                    elseif result == nil then
                        info.attempts = info.attempts + 1
                        if info.attempts >= KICKER.MAX_RETRIES then
                            logf("Chinese Kicker: gave up on player %d after %d retries", pid, KICKER.MAX_RETRIES)
                            chineseKicker.pending[pid] = nil
                        else
                            info.nextCheck = now + KICKER.RETRY_DELAY
                        end
                    else
                        chineseKicker.pending[pid] = nil
                    end
                end
            end
        end
    end

    centralOnTick(FeatureMgr.AddFeature(H.CHINESE_KICKER, "Chinese Kicker", eFeatureType.Toggle,
        "Kicks players from China, Macau, and Taiwan.",
        chineseKickerOnTick))
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)

    FeatureMgr.AddFeature(H.CHINESE_REGIONS, "Regions", eFeatureType.ComboToggles)
        :SetList(CHINESE_LIST_NAMES)
    local feat = FeatureMgr.GetFeature(H.CHINESE_REGIONS)
    for i = 0, #CHINESE_BLOCKLIST - 1 do
        feat:ToggleListIndex(i, true)
    end
end

do
    local function getLocalCountry()
        if myCountryOnly.localCC then return myCountryOnly.localCC end
        local ipInfo = getPlayerIPInfo(GTA.GetLocalPlayerId())
        if not ipInfo then return nil end
        local cc = ipInfo["countryCode"] or ""
        if cc == "" or cc == "NA" then return nil end
        myCountryOnly.localCC = cc
        return cc
    end

    local function detectForeign(playerId)
        local localCC = getLocalCountry()
        if not localCC then return nil end

        local ipInfo = getPlayerIPInfo(playerId)
        if not ipInfo then return nil end

        local cc = ipInfo["countryCode"] or ""
        if cc == "" or cc == "NA" then return nil end

        if cc ~= localCC then
            return true, cc
        end
        return false
    end

    local function kickForeignPlayer(playerId, cc)
        local name = Players.GetName(playerId) or "?"

        Logger.LogInfo(("[VibeScript] Maximize Xenophobia: kicking %s - %s (id %d)"):format(name, cc, playerId))
        doKick(playerId)
        GUI.AddToast("VibeScript",
            ("Maximize Xenophobia: kicking %s (%s)"):format(name, cc), 5000)

        myCountryOnly.kicked[playerId] = true
        myCountryOnly.pending[playerId] = nil
    end

    local function checkAndKickForeign(playerId)
        if playerId == GTA.GetLocalPlayerId() then return end
        if myCountryOnly.kicked[playerId] then return end
        local exempt = isPlayerFriend(playerId)
        exempt = isPlayerTeammate(playerId) or exempt
        if exempt then return end

        local result, cc = detectForeign(playerId)
        if result == true then
            kickForeignPlayer(playerId, cc)
        elseif result == nil then
            if not myCountryOnly.pending[playerId] then
                myCountryOnly.pending[playerId] = {
                    attempts = 0,
                    nextCheck = os.clock() + KICKER.RETRY_DELAY,
                }
            end
        end
    end

    local function onForeignPlayerJoin(playerId)
        local feat = FeatureMgr.GetFeature(H.MY_COUNTRY_ONLY)
        if not feat or not feat:IsToggled() then return end
        myCountryOnly.kicked[playerId] = nil
        myCountryOnly.pending[playerId] = nil
        checkAndKickForeign(playerId)
    end

    local function myCountryOnlyOnTick(f)
        if not f:IsToggled() then
            if myCountryOnly.scanned or myCountryOnly.eventId or myCountryOnly.localCC
               or next(myCountryOnly.pending) or next(myCountryOnly.kicked) then
                myCountryOnly.kicked = {}
                myCountryOnly.pending = {}
                myCountryOnly.scanned = false
                myCountryOnly.localCC = nil
                if myCountryOnly.eventId then
                    EventMgr.RemoveHandler(myCountryOnly.eventId)
                    myCountryOnly.eventId = nil
                end
            end
            return
        end

        if not myCountryOnly.eventId then
            myCountryOnly.eventId = EventMgr.RegisterHandler(
                eLuaEvent.ON_PLAYER_JOIN, onForeignPlayerJoin)
        end

        if not myCountryOnly.scanned then
            if not getLocalCountry() then return end
            myCountryOnly.scanned = true
            local localId = GTA.GetLocalPlayerId()
            for pid = 0, 31 do
                if pid ~= localId and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                    checkAndKickForeign(pid)
                end
            end
        end

        local now = os.clock()
        for pid, info in pairs(myCountryOnly.pending) do
            if now >= info.nextCheck then
                if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                    myCountryOnly.pending[pid] = nil
                else
                    local result, cc = detectForeign(pid)
                    if result == true then
                        kickForeignPlayer(pid, cc)
                    elseif result == nil then
                        info.attempts = info.attempts + 1
                        if info.attempts >= KICKER.MAX_RETRIES then
                            logf("Maximize Xenophobia: gave up on player %d after %d retries", pid, KICKER.MAX_RETRIES)
                            myCountryOnly.pending[pid] = nil
                        else
                            info.nextCheck = now + KICKER.RETRY_DELAY
                        end
                    else
                        myCountryOnly.pending[pid] = nil
                    end
                end
            end
        end
    end

    centralOnTick(FeatureMgr.AddFeature(H.MY_COUNTRY_ONLY, "Maximize Xenophobia", eFeatureType.Toggle,
        "Kicks every player whose country does not match yours.",
        myCountryOnlyOnTick))
        :SetNoCallbackOnPress(true)
        :SetSaveable(false)
end


local function detectVPN(playerId)
    local ipInfo = Players.GetIPInfo(playerId)
    if not ipInfo then
        return nil
    end
    local proxy = ipInfo["proxy"] or ""
    if proxy == "" or proxy == "NA" then return nil end
    if proxy == "1" then return true, "VPN/Proxy" end
    return false
end

local function kickVPNPlayer(playerId, reason)
    local name = Players.GetName(playerId) or "?"

    Logger.LogInfo(("[VibeScript] VPN Kicker: kicking %s (id %d)"):format(name, playerId))
    doKick(playerId)
    GUI.AddToast("VibeScript",
        ("VPN Kicker: kicking %s"):format(name), 5000)

    vpnKicker.kicked[playerId] = true
    vpnKicker.pending[playerId] = nil
end

local function checkAndKickVPN(playerId)
    if playerId == GTA.GetLocalPlayerId() then return end
    if vpnKicker.kicked[playerId] then return end
    local exempt = isPlayerFriend(playerId)
    exempt = isPlayerTeammate(playerId) or exempt
    if exempt then return end

    local result, reason = detectVPN(playerId)
    if result == true then
        kickVPNPlayer(playerId, reason)
    elseif result == nil then
        if not vpnKicker.pending[playerId] then
            vpnKicker.pending[playerId] = {
                attempts = 0,
                nextCheck = os.clock() + KICKER.RETRY_DELAY,
            }
        end
    end
end

local function onVPNPlayerJoin(playerId)
    local feat = FeatureMgr.GetFeature(H.VPN_KICKER)
    if not feat or not feat:IsToggled() then return end
    vpnKicker.kicked[playerId] = nil
    vpnKicker.pending[playerId] = nil
    checkAndKickVPN(playerId)
end

local function vpnKickerOnTick(f)
    if not f:IsToggled() then
        if vpnKicker.scanned or vpnKicker.eventId
           or next(vpnKicker.pending) or next(vpnKicker.kicked) then
            vpnKicker.kicked = {}
            vpnKicker.pending = {}
            vpnKicker.scanned = false
            if vpnKicker.eventId then
                EventMgr.RemoveHandler(vpnKicker.eventId)
                vpnKicker.eventId = nil
            end
        end
        return
    end

    if not vpnKicker.eventId then
        vpnKicker.eventId = EventMgr.RegisterHandler(
            eLuaEvent.ON_PLAYER_JOIN, onVPNPlayerJoin)
    end

    if not vpnKicker.scanned then
        vpnKicker.scanned = true
        local localId = GTA.GetLocalPlayerId()
        for pid = 0, 31 do
            if pid ~= localId and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                checkAndKickVPN(pid)
            end
        end
    end

    local now = os.clock()
    for pid, info in pairs(vpnKicker.pending) do
        if now >= info.nextCheck then
            if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                vpnKicker.pending[pid] = nil
            else
                local result, reason = detectVPN(pid)
                if result == true then
                    kickVPNPlayer(pid, reason)
                elseif result == nil then
                    info.attempts = info.attempts + 1
                    if info.attempts >= KICKER.MAX_RETRIES then
                        logf("VPN Kicker: gave up on player %d after %d retries", pid, KICKER.MAX_RETRIES)
                        vpnKicker.pending[pid] = nil
                    else
                        info.nextCheck = now + KICKER.RETRY_DELAY
                    end
                else
                    vpnKicker.pending[pid] = nil
                end
            end
        end
    end
end

centralOnTick(FeatureMgr.AddFeature(H.VPN_KICKER, "VPN Kicker", eFeatureType.Toggle,
    "Kicks players using a VPN or proxy.",
    vpnKickerOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)


local function detectRelay(playerId)
    local addr = Players.GetNetAddress(playerId)
    if not addr then
        return nil
    end
    local t = addr.Type
    if t == 1 then return false end
    if t == 2 or t == 3 then return true end
    return false
end

local function kickRelayPlayer(playerId)
    local name = Players.GetName(playerId) or "?"
    Logger.LogInfo(("[VibeScript] Relay Kicker: kicking %s (pid %d)"):format(name, playerId))
    doKick(playerId)
    GUI.AddToast("VibeScript",
        ("Relay Kicker: kicking %s"):format(name), 5000)

    relayKicker.kicked[playerId] = true
    relayKicker.pending[playerId] = nil
end

local function checkAndKickRelay(playerId)
    if playerId == GTA.GetLocalPlayerId() then return end
    if relayKicker.kicked[playerId] then return end
    local exempt = isPlayerFriend(playerId)
    exempt = isPlayerTeammate(playerId) or exempt
    if exempt then return end

    local result = detectRelay(playerId)
    if result == true then
        kickRelayPlayer(playerId)
    elseif result == nil then
        if not relayKicker.pending[playerId] then
            relayKicker.pending[playerId] = {
                attempts = 0,
                nextCheck = os.clock() + KICKER.RETRY_DELAY,
            }
        end
    end
end

local function onRelayPlayerJoin(playerId)
    local feat = FeatureMgr.GetFeature(H.RELAY_KICKER)
    if not feat or not feat:IsToggled() then return end
    relayKicker.kicked[playerId] = nil
    relayKicker.pending[playerId] = nil
    checkAndKickRelay(playerId)
end

local function relayKickerOnTick(f)
    if not f:IsToggled() then
        if relayKicker.scanned or relayKicker.eventId
           or next(relayKicker.pending) or next(relayKicker.kicked) then
            relayKicker.kicked = {}
            relayKicker.pending = {}
            relayKicker.scanned = false
            if relayKicker.eventId then
                EventMgr.RemoveHandler(relayKicker.eventId)
                relayKicker.eventId = nil
            end
        end
        return
    end

    if not relayKicker.eventId then
        relayKicker.eventId = EventMgr.RegisterHandler(
            eLuaEvent.ON_PLAYER_JOIN, onRelayPlayerJoin)
    end

    if not relayKicker.scanned then
        relayKicker.scanned = true
        local localId = GTA.GetLocalPlayerId()
        for pid = 0, 31 do
            if pid ~= localId and NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                checkAndKickRelay(pid)
            end
        end
    end

    local now = os.clock()
    for pid, info in pairs(relayKicker.pending) do
        if now >= info.nextCheck then
            if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
                relayKicker.pending[pid] = nil
            else
                local result = detectRelay(pid)
                if result == true then
                    kickRelayPlayer(pid)
                elseif result == nil then
                    info.attempts = info.attempts + 1
                    if info.attempts >= KICKER.MAX_RETRIES then
                        logf("Relay Kicker: gave up on player %d after %d retries", pid, KICKER.MAX_RETRIES)
                        relayKicker.pending[pid] = nil
                    else
                        info.nextCheck = now + KICKER.RETRY_DELAY
                    end
                else
                    relayKicker.pending[pid] = nil
                end
            end
        end
    end
end

centralOnTick(FeatureMgr.AddFeature(H.RELAY_KICKER, "Relay Kicker", eFeatureType.Toggle,
    "Kicks players connected via relay/peer relay",
    relayKickerOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)



do
    local function getDur()
        local f = FeatureMgr.GetFeature(H.PAUSE_TGT_DUR)
        if f then return f:GetIntValue() end
        return 3000
    end

    local function onTick(f)
    if not f:IsToggled() then
        local pid = f:GetPlayerIndex()
        if playerState.pauseTarget[pid] then
            do
                NETWORK.NETWORK_CONCEAL_PLAYER(pid, false, false)
            end
            playerState.pauseTarget[pid] = nil
        end
        return
    end
    if not isPlayerReady() then return end

    local pid = f:GetPlayerIndex()
    if not NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then return end

    if not playerState.pauseTarget[pid] then
        playerState.pauseTarget[pid] = { phase = "conceal", timer = 0, revealFrames = 0 }
    end
    local st = playerState.pauseTarget[pid]
    local now = Time.GetEpocheMs()
    local dur = getDur()

    if st.phase == "conceal" then
        if now >= st.timer then
            do
                NETWORK.NETWORK_CONCEAL_PLAYER(pid, true, false)
            end
            st.timer = now + dur
            st.phase = "wait_conceal"
            log(("[PauseTarget] pid=%d concealed for %dms"):format(pid, dur))
        end
    elseif st.phase == "wait_conceal" then
        if now >= st.timer then
            do
                NETWORK.NETWORK_CONCEAL_PLAYER(pid, false, false)
            end
            st.revealFrames = 2
            st.phase = "reveal"
            log(("[PauseTarget] pid=%d brief reveal"):format(pid))
        end
    elseif st.phase == "reveal" then
        st.revealFrames = st.revealFrames - 1
        if st.revealFrames <= 0 then
            st.phase = "conceal"
            st.timer = 0
        end
    end
end

    local features = FeatureMgr.AddPlayerFeature(
        H.PAUSE_TARGET, "Pause Spoof Target", eFeatureType.Toggle,
        "Keeps target concealed to trigger pause icon on your screen (long conceal / brief reveal)",
        onTick)
    for _, hash in ipairs(features) do
        FeatureMgr.GetFeature(hash)
            :SetNoCallbackOnPress(true)
            :SetSaveable(false)
    end
    centralPlayerOnTick(H.PAUSE_TARGET, onTick)

    FeatureMgr.AddFeature(H.PAUSE_TGT_DUR, "Pause Conceal Duration (ms)", eFeatureType.SliderInt)
        :SetLimitValues(500, 30000)
        :SetDefaultValue(3000)
        :SetSaveable(false)
        :Reset()

end

local census = {
    data = {},
    countries = {},
    lastRefresh = 0,
    REFRESH_INTERVAL = 5.0,
}

local CONN_TYPE_LABELS = {
    [1] = "Direct",
    [2] = "Relay",
    [3] = "Peer Relay",
}

local function getConnLabel(pid)
    local addr = Players.GetNetAddress(pid)
    if not addr then return "?" end
    local t = addr.Type
    if t == 3 then
        local proxyName = nil
        local proxyAddr = addr.ProxyAddr
        if proxyAddr then
            for otherId = 0, 31 do
                if otherId ~= pid and NETWORK.NETWORK_IS_PLAYER_CONNECTED(otherId) then
                    local otherAddr = Players.GetNetAddress(otherId)
                    if otherAddr and otherAddr.Type == 1 then
                    end
                end
            end
        end
        return "Peer Relay"
    end
    return CONN_TYPE_LABELS[t] or ("Type " .. tostring(t))
end

local function refreshCensus()
    local now = os.clock()
    if now - census.lastRefresh < census.REFRESH_INTERVAL then return end
    census.lastRefresh = now

    local players = {}
    local countryMap = {}
    local localId = GTA.GetLocalPlayerId()

    for pid = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(pid) then
            local name = Players.GetName(pid) or "?"
            local country, region, city = "Unknown", "", ""
            local ipInfo = Players.GetIPInfo(pid)
            if ipInfo then
                local cc = ipInfo["country"] or ""
                if cc ~= "" and cc ~= "NA" then country = cc end
                local r = ipInfo["region"] or ""
                if r ~= "" and r ~= "NA" then region = r end
                local ci = ipInfo["city"] or ""
                if ci ~= "" and ci ~= "NA" then city = ci end
            end
            local connLabel = getConnLabel(pid)
            local vpn = false
            if ipInfo then
                vpn = (ipInfo["proxy"] == "1")
            end
            if pid == localId then name = name .. " (you)" end
            table.insert(players, {
                name = name, country = country,
                region = region, city = city,
                conn = connLabel, vpn = vpn,
            })
            countryMap[country] = (countryMap[country] or 0) + 1
        end
    end

    local sorted = {}
    for cname, count in pairs(countryMap) do
        table.insert(sorted, {name = cname, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    census.data = players
    census.countries = sorted
end

local function sliceColor(index, total)
    local h = ((index - 1) / math.max(total, 1)) % 1.0
    return ImGui.ColorConvertHSVtoRGB(h, 0.65, 0.90)
end

local function sliceColorInt(index, total)
    local r, g, b = sliceColor(index, total)
    return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

local function drawPieChart(cx, cy, radius, slices, totalPlayers)
    if #slices == 0 then return end
    if totalPlayers == 0 then return end

    local startAngle = -math.pi / 2
    local segments = 64

    for i, s in ipairs(slices) do
        local sweep = (s.count / totalPlayers) * 2 * math.pi
        local numSegs = math.max(2, math.floor(segments * (sweep / (2 * math.pi)) + 0.5))
        local step = sweep / numSegs
        local ri, gi, bi = sliceColorInt(i, #slices)

        for seg = 0, numSegs - 1 do
            local a1 = startAngle + seg * step
            local a2 = startAngle + (seg + 1) * step + 0.02
            ImGui.AddTriangleFilled(
                cx, cy,
                cx + radius * math.cos(a1), cy + radius * math.sin(a1),
                cx + radius * math.cos(a2), cy + radius * math.sin(a2),
                ri, gi, bi, 255)
        end
        startAngle = startAngle + sweep
    end

    ImGui.AddCircle(cx, cy, radius, 180, 180, 180, 200, 64, 1.0)
end

local function renderCensusPie()
    refreshCensus()

    if #census.data == 0 then
        ImGui.TextDisabled("No players in session")
        return
    end

    local total = #census.data
    local PIE_RADIUS = 55
    local ELBOW_LEN = 12
    local HORIZ_LEN = 18
    local LINE_H = 14

    local avail_x, _ = ImGui.GetContentRegionAvail()
    local sx, sy = ImGui.GetCursorScreenPos()
    local cx = sx + avail_x / 2
    local TOP_PAD = ELBOW_LEN + LINE_H
    local cy = sy + PIE_RADIUS + TOP_PAD

    drawPieChart(cx, cy, PIE_RADIUS, census.countries, total)

    local leftLabels = {}
    local rightLabels = {}
    local startAngle = -math.pi / 2
    for i, entry in ipairs(census.countries) do
        local sweep = (entry.count / total) * 2 * math.pi
        local midAngle = startAngle + sweep / 2
        local ri, gi, bi = sliceColorInt(i, #census.countries)
        local pct = math.floor((entry.count / total) * 100 + 0.5)
        local label = ("%s %d (%d%%)"):format(entry.name, entry.count, pct)

        local info = {
            midAngle = midAngle,
            edgeX = cx + PIE_RADIUS * math.cos(midAngle),
            edgeY = cy + PIE_RADIUS * math.sin(midAngle),
            naturalY = cy + (PIE_RADIUS + ELBOW_LEN) * math.sin(midAngle),
            ri = ri, gi = gi, bi = bi,
            label = label,
        }
        if math.cos(midAngle) >= 0 then
            table.insert(rightLabels, info)
        else
            table.insert(leftLabels, info)
        end
        startAngle = startAngle + sweep
    end

    local function spreadLabels(labels)
        table.sort(labels, function(a, b) return a.naturalY < b.naturalY end)
        for j = 1, #labels do
            labels[j].drawY = labels[j].naturalY
        end
        for j = 2, #labels do
            if labels[j].drawY - labels[j - 1].drawY < LINE_H then
                labels[j].drawY = labels[j - 1].drawY + LINE_H
            end
        end
    end
    spreadLabels(leftLabels)
    spreadLabels(rightLabels)

    for _, info in ipairs(rightLabels) do
        local elbowX = cx + (PIE_RADIUS + ELBOW_LEN) * math.cos(info.midAngle)
        local horizEndX = elbowX + HORIZ_LEN
        ImGui.AddLine(info.edgeX, info.edgeY, elbowX, info.drawY,
            info.ri, info.gi, info.bi, 255, 1.0)
        ImGui.AddLine(elbowX, info.drawY, horizEndX, info.drawY,
            info.ri, info.gi, info.bi, 255, 1.0)
        ImGui.AddText(horizEndX + 3, info.drawY - LINE_H / 2,
            info.label, info.ri, info.gi, info.bi, 255)
    end

    for _, info in ipairs(leftLabels) do
        local elbowX = cx + (PIE_RADIUS + ELBOW_LEN) * math.cos(info.midAngle)
        local horizEndX = elbowX - HORIZ_LEN
        ImGui.AddLine(info.edgeX, info.edgeY, elbowX, info.drawY,
            info.ri, info.gi, info.bi, 255, 1.0)
        ImGui.AddLine(elbowX, info.drawY, horizEndX, info.drawY,
            info.ri, info.gi, info.bi, 255, 1.0)
        local tw, _ = ImGui.CalcTextSize(info.label)
        ImGui.AddText(horizEndX - tw - 3, info.drawY - LINE_H / 2,
            info.label, info.ri, info.gi, info.bi, 255)
    end

    ImGui.Dummy(avail_x, (PIE_RADIUS + TOP_PAD) * 2)
end
local function renderCensusPlayers()
    if #census.data == 0 then return end
    local total = #census.data
    ImGui.Text(("Players (%d):"):format(total))
    for _, p in ipairs(census.data) do
        local loc = p.country
        if p.region ~= "" then loc = loc .. ", " .. p.region end
        if p.city ~= "" then loc = loc .. ", " .. p.city end
        local tags = p.conn
        if p.vpn then tags = tags .. ", VPN" end
        ImGui.BulletText(("%s - %s (%s)"):format(p.name, loc, tags))
    end
end


local function rewindAddSnapshot(snap)
    rewindState.head = (rewindState.head % rewindState.maxSnapshots) + 1
    rewindState.snapshots[rewindState.head] = snap
    if rewindState.count < rewindState.maxSnapshots then
        rewindState.count = rewindState.count + 1
    end
end

local function rewindGetSnapshot(stepsBack)
    if stepsBack < 0 or stepsBack >= rewindState.count then return nil end
    local idx = rewindState.head - stepsBack
    if idx < 1 then idx = idx + rewindState.maxSnapshots end
    return rewindState.snapshots[idx]
end

local function rewindCapture()
    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ENTITY.DOES_ENTITY_EXIST(ped) then return nil end

    local inVeh = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
    local entity = ped
    local vehHandle, vehModel, seat = 0, 0, -1

    if inVeh then
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
            entity = veh
            vehHandle = veh
            vehModel = ENTITY.GET_ENTITY_MODEL(veh)
            for s = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(veh) - 1 do
                if VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, s, false) == ped then
                    seat = s
                    break
                end
            end
        end
    end

    local c = ENTITY.GET_ENTITY_COORDS(entity, true)
    local r = ENTITY.GET_ENTITY_ROTATION(entity, 2)
    local v = ENTITY.GET_ENTITY_VELOCITY(entity)
    local a = ENTITY.GET_ENTITY_ROTATION_VELOCITY(entity)

    return {
        pos    = { x = c.x, y = c.y, z = c.z },
        rot    = { x = r.x, y = r.y, z = r.z },
        vel    = { x = v.x, y = v.y, z = v.z },
        angVel = { x = a.x, y = a.y, z = a.z },
        camH   = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING(),
        camP   = CAM.GET_GAMEPLAY_CAM_RELATIVE_PITCH(),
        inVeh  = inVeh,
        vehHandle = vehHandle,
        vehModel  = vehModel,
        seat      = seat,
    }
end

local function rewindLoadSnapshot(snap)
    if not snap then return end
    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ENTITY.DOES_ENTITY_EXIST(ped) then return end

    local currentlyInVeh = PED.IS_PED_IN_ANY_VEHICLE(ped, false)

    if snap.inVeh then
        if rewindState._walkAnimPlaying then
            do
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                if STREAMING.HAS_ANIM_DICT_LOADED("mini@strip_club@walk") then
                    STREAMING.REMOVE_ANIM_DICT("mini@strip_club@walk")
                end
            end
            rewindState._walkAnimPlaying = false
        end

        local veh = snap.vehHandle
        local valid = veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh)
            and ENTITY.GET_ENTITY_MODEL(veh) == snap.vehModel
        if not valid then
            veh = GTA.CreateVehicle(snap.vehModel,
                snap.pos.x, snap.pos.y, snap.pos.z, 0.0, true, false)
            if veh == 0 then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped,
                    snap.pos.x, snap.pos.y, snap.pos.z, false, false, false)
                ENTITY.SET_ENTITY_ROTATION(ped, snap.rot.x, snap.rot.y, snap.rot.z, 2, true)
                return
            end
        end
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh,
            snap.pos.x, snap.pos.y, snap.pos.z, false, false, false)
        ENTITY.SET_ENTITY_ROTATION(veh, snap.rot.x, snap.rot.y, snap.rot.z, 2, true)
        ENTITY.SET_ENTITY_VELOCITY(veh, 0.0, 0.0, 0.0)
        ENTITY.FREEZE_ENTITY_POSITION(veh, true)
        rewindState.frozenEntity = veh
        if ENTITY.DOES_ENTITY_EXIST(veh) and not currentlyInVeh then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            ENTITY.FREEZE_ENTITY_POSITION(veh, false)
            PED.SET_PED_INTO_VEHICLE(ped, veh, snap.seat)
            ENTITY.FREEZE_ENTITY_POSITION(veh, true)
        end
    else
        if currentlyInVeh then
            local curVeh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped,
                snap.pos.x, snap.pos.y, snap.pos.z, false, false, false)
        end
        local c = ENTITY.GET_ENTITY_COORDS(ped, true)
        local dx = snap.pos.x - c.x
        local dy = snap.pos.y - c.y
        local dz = snap.pos.z - c.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

        local spd = math.max(rewindState.REWIND_SPEED, 1.0)
        if dist > 5.0 * spd then
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped,
                snap.pos.x, snap.pos.y, snap.pos.z, false, false, false)
            rewindState._walkAnimPlaying = false
        elseif dist > 0.01 then
            local speed = math.min(dist * 60.0, 4.0 * spd)
            local nx, ny, nz = dx / dist, dy / dist, dz / dist
            ENTITY.SET_ENTITY_VELOCITY(ped, nx * speed, ny * speed, nz * speed)
        else
            ENTITY.SET_ENTITY_VELOCITY(ped, 0.0, 0.0, 0.0)
        end
        ENTITY.SET_ENTITY_HEADING(ped, snap.rot.z)

        if not rewindState._walkAnimPlaying then
            local dict = "mini@strip_club@walk"
            if not STREAMING.HAS_ANIM_DICT_LOADED(dict) then
                STREAMING.REQUEST_ANIM_DICT(dict)
            else
                TASK.TASK_PLAY_ANIM(ped, dict, "walk",
                    2.0, -2.0, -1, 1, 0.0, false, false, false)
                rewindState._walkAnimPlaying = true
            end
        end
        rewindState.frozenEntity = ped
    end

    CAM.SET_GAMEPLAY_CAM_RELATIVE_HEADING(snap.camH)
    CAM.SET_GAMEPLAY_CAM_RELATIVE_PITCH(snap.camP, 1.0)
end

local function rewindDrawHUD()
    local pct = rewindState.playhead / math.max(1, rewindState.count)

    local barW, barH = 0.25, 0.005
    local barX, barY = 0.5, 0.05

    GRAPHICS.DRAW_RECT(barX, barY, barW, barH, 0, 0, 0, 150, false)

    local fillW = barW * pct
    local fillX = barX - (barW - fillW) * 0.5
    GRAPHICS.DRAW_RECT(fillX, barY, fillW, barH, 255, 200, 50, 220, false)

    local cursorX = barX - barW * 0.5 + barW * pct
    GRAPHICS.DRAW_RECT(cursorX, barY, 0.004, 0.012, 255, 255, 255, 255, false)
end

local function rewindCancel()
    if rewindState.frozenEntity ~= 0 then
        do
            if ENTITY.DOES_ENTITY_EXIST(rewindState.frozenEntity) then
                ENTITY.FREEZE_ENTITY_POSITION(rewindState.frozenEntity, false)
            end
        end
        rewindState.frozenEntity = 0
    end
    if not rewindState._unloading then
        do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
            if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                ENTITY.SET_ENTITY_VELOCITY(ped, 0.0, 0.0, 0.0)
            end
        end
    end
    rewindState._walkAnimPlaying = false
    do
        if STREAMING.HAS_ANIM_DICT_LOADED("mini@strip_club@walk") then
            STREAMING.REMOVE_ANIM_DICT("mini@strip_club@walk")
        end
    end
    if rewindState.soundId ~= -1 then
        do
            AUDIO.STOP_SOUND(rewindState.soundId)
            AUDIO.RELEASE_SOUND_ID(rewindState.soundId)
        end
        rewindState.soundId = -1
    end
    do
        GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
    end
    rewindState.state = 0
    rewindState.playhead = 0
end

local function rewindClearBuffer()
    rewindState.snapshots = {}
    rewindState.head = 0
    rewindState.count = 0
    rewindState.playhead = 0
end

local function rewindIsRemoteHeld()
    local feat = FeatureMgr.GetFeature(H.REWIND_REMOTE_HOLD)
    if not feat then return false end
    return feat:IsToggled() or false
end

local function rewindForceRemoteHoldOff()
    local feat = FeatureMgr.GetFeature(H.REWIND_REMOTE_HOLD)
    if not feat then return end
    if feat:IsToggled() then
        feat:Toggle(false)
    end
end

local function rewindOnTick(f)
    if not f:IsToggled() then
        if rewindState.state ~= 0 then
            rewindCancel()
        end
        if rewindState.count > 0 then
            rewindClearBuffer()
        end
        return
    end
    if not isPlayerReady() then
        if rewindState.state ~= 0 then rewindCancel() end
        return
    end
    if NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() then
        if rewindState.state ~= 0 then rewindCancel() end
        return
    end

    local playerId = GTA.GetLocalPlayerId()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)

    if PED.IS_PED_INJURED(ped) then
        if rewindState.state ~= 0 then rewindCancel() end
        return
    end

    do
        local kf = FeatureMgr.GetFeature(H.REWIND_KEY)
        if kf then
            local fv = kf:GetIntValue()
            if fv >= 1 and fv <= 255 then rewindState.rewindVK = fv end
        end
    end

    local keyDown
    if PAD.IS_USING_KEYBOARD_AND_MOUSE(2) then
        keyDown = Utils.IsKeyDown(rewindState.rewindVK) and not GUI.IsOpen() and not isGameChatOpen()
    else
        keyDown = rewindState.controlId > 0
            and PAD.IS_DISABLED_CONTROL_PRESSED(0, rewindState.controlId)
    end
    keyDown = keyDown or rewindIsRemoteHeld()

    if rewindState.state == 0 then
        local snap = rewindCapture()
        if snap then rewindAddSnapshot(snap) end

        if keyDown and rewindState.count > 1 then
            rewindState.state = 1
            rewindState.playhead = 0
            rewindState._accumulator = 0

            do
                rewindState.soundId = AUDIO.GET_SOUND_ID()
                AUDIO.PLAY_SOUND(rewindState.soundId,
                    "CHARACTER_CHANGE_DPAD_DOWN_MASTER",
                    "PLAYER_SWITCH_CUSTOM_SOUNDSET", true, 0, true)
                GRAPHICS.SET_TIMECYCLE_MODIFIER("NG_deathfail")
                GRAPHICS.SET_TIMECYCLE_MODIFIER_STRENGTH(0.6)
            end
        end
        return
    end

    if rewindState.state == 1 then
        if not keyDown then
            rewindState.state = 2
            rewindState.settleStart = MISC.GET_GAME_TIMER()
            if rewindState.soundId ~= -1 then
                do
                    AUDIO.STOP_SOUND(rewindState.soundId)
                    AUDIO.RELEASE_SOUND_ID(rewindState.soundId)
                end
                rewindState.soundId = -1
            end
            return
        end

        rewindState._accumulator = (rewindState._accumulator or 0)
            + rewindState.REWIND_SPEED
        local steps = math.floor(rewindState._accumulator)
        rewindState._accumulator = rewindState._accumulator - steps
        rewindState.playhead = math.min(
            rewindState.playhead + steps,
            rewindState.count - 1)

        local snap = rewindGetSnapshot(rewindState.playhead)
        rewindLoadSnapshot(snap)
        rewindDrawHUD()
        return
    end

    if rewindState.state == 2 then
        rewindDrawHUD()

        if keyDown then
            rewindState.state = 1
            do
                rewindState.soundId = AUDIO.GET_SOUND_ID()
                AUDIO.PLAY_SOUND(rewindState.soundId,
                    "CHARACTER_CHANGE_DPAD_DOWN_MASTER",
                    "PLAYER_SWITCH_CUSTOM_SOUNDSET", true, 0, true)
            end
            return
        end

        local elapsed = MISC.GET_GAME_TIMER() - rewindState.settleStart
        if elapsed < rewindState.SETTLE_MS then return end

        local snap = rewindGetSnapshot(rewindState.playhead)
        if snap and rewindState.frozenEntity ~= 0
            and ENTITY.DOES_ENTITY_EXIST(rewindState.frozenEntity) then
            if ENTITY.IS_ENTITY_A_PED(rewindState.frozenEntity)
                and not PED.IS_PED_IN_ANY_VEHICLE(rewindState.frozenEntity, false) then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(rewindState.frozenEntity)
                ENTITY.SET_ENTITY_VELOCITY(rewindState.frozenEntity,
                    snap.vel.x, snap.vel.y, snap.vel.z)
            else
                ENTITY.FREEZE_ENTITY_POSITION(rewindState.frozenEntity, false)
                local fwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(rewindState.frozenEntity)
                local fwdSpeed = snap.vel.x * fwd.x + snap.vel.y * fwd.y + snap.vel.z * fwd.z
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(rewindState.frozenEntity, fwdSpeed)
                ENTITY.SET_ENTITY_VELOCITY(rewindState.frozenEntity,
                    snap.vel.x, snap.vel.y, snap.vel.z)
            end
        end
        rewindState.frozenEntity = 0
        rewindState._walkAnimPlaying = false
        do
            if STREAMING.HAS_ANIM_DICT_LOADED("mini@strip_club@walk") then
                STREAMING.REMOVE_ANIM_DICT("mini@strip_club@walk")
            end
        end

        do
            GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
        end

        rewindState.count = rewindState.count - rewindState.playhead
        if rewindState.count < 0 then rewindState.count = 0 end
        rewindState.head = rewindState.head - rewindState.playhead
        if rewindState.head < 1 then
            rewindState.head = rewindState.head + rewindState.maxSnapshots
        end

        rewindState.playhead = 0
        rewindState.state = 0
    end
end

centralOnTick(FeatureMgr.AddFeature(H.REWIND, "Rewind", eFeatureType.Toggle,
    "Hold Backspace to rewind time (Forza-style)",
    rewindOnTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)

FeatureMgr.AddFeature(H.REWIND_PROTOCOL, "##RewindProtocolVersion", eFeatureType.SliderInt,
    "",
    function() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(1, 1)
    :SetDefaultValue(1)
    :SetSaveable(false)
    :SetSearchable(false)
    :SetVisible(false)
    :Reset()

FeatureMgr.AddFeature(H.REWIND_REMOTE_HOLD, "##RewindRemoteHold", eFeatureType.Toggle,
    "",
    function() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetSaveable(false)
    :SetSearchable(false)
    :SetVisible(false)
    :Reset()

FeatureMgr.AddFeature(H.REWIND_KEY, "##RewindKey", eFeatureType.SliderInt,
    "",
    function(f) rewindState.rewindVK = f:GetIntValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(1, 255)
    :SetDefaultValue(0x08)
    :SetSaveable(false)
    :SetSearchable(false)
    :SetVisible(false)
    :Reset()

FeatureMgr.AddFeature(H.REWIND_LENGTH, "Rewind Length (sec)", eFeatureType.SliderInt,
    "How many seconds of history to keep",
    function(f)
        rewindState.lengthSec = f:GetIntValue()
        rewindState.maxSnapshots = rewindState.lengthSec * 60
        rewindClearBuffer()
    end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(5, 120)
    :SetDefaultValue(10)
    :Reset()

FeatureMgr.AddFeature(H.REWIND_SPEED, "Rewind Speed", eFeatureType.SliderFloat,
    "Playback speed multiplier (1.0 = real-time, 2.0 = 2x fast, 0.5 = half speed)",
    function(f) rewindState.REWIND_SPEED = f:GetFloatValue() end)
    :RegisterCallbackTrigger(eCallbackTrigger.OnChange)
    :SetLimitValues(0.25, 5.0)
    :SetDefaultValue(1.0)
    :Reset()

H.RESET = Utils.Joaat("LUA_ResetAll")

local function resetAll()
    rewindForceRemoteHoldOff()

    infLockonRange.restore()

    restoreAndClearAllWeaponCache()

    restoreLazerNerf()

    if weaponState.restoreVehInfAmmo then weaponState.restoreVehInfAmmo() end

    PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER(GTA.GetLocalPlayerId(), 1.0, true)
    weaponState.superMeleeActive = false

    releaseGravTarget()
    grav.yeeted = 0

    rickHorn.stop()
    if rickHorn.warmVeh ~= 0 then rickHorn.finishWarmup() end

    local toggleFeatures = {
        H.RAPID_FIRE, H.VEH_INF_AMMO, H.ONFOOT_RAPID, H.ONFOOT_HOMING_SPAM, H.ROCKET_SPEED, H.INSTANT_ROCKET,
        H.INFINITE_RANGE, H.INSTANT_LOCKON, H.AUTO_LOCKON_FIRE, H.LOCK_ONTO_PLAYERS, H.LOCK_ONTO_NPCS, H.INF_LOCKON_RANGE, H.DISABLE_LOS, H.GRAVITY_GUN,
        H.SUPERDRIVE, H.SUPERDRIVE_CAM, H.ENGINE_POWER, H.FLY_WINDSCREEN, H.BETTER_ESC_ENGINE, H.WHEELIE,
        H.BETTER_ALT_F4, H.LOCK_CINE_CAM, H.WP_INTERIOR, H.WP_INSIDE_INT, H.AUTO_TP_OBJECTIVE,
        H.RICK_ROLL_HORN,
        H.WEAPON_WHEEL, H.TITAN_DRIVER_WEAPONS, H.TITAN_PROBE, H.TITAN_CANNON_CYCLE, H.PAUSED_SPOOF, H.PASSIVE_SPOOF,
        H.VEH_GUN, H.VEH_GUN_RANDOM, H.VEH_GUN_RAND_AIR, H.VEH_GUN_RAND_SEA,
        H.DRIFT_ASSIST, H.DRIFT_SCORE, H.DRIFT_SMOKE, H.DRIFT_EXIT_BOOST,
        H.JTURN, H.LTURN, H.TURN_LEFT, H.TURN_RIGHT,
        H.FRENCH_KICKER, H.CHINESE_KICKER, H.MY_COUNTRY_ONLY,
        H.VPN_KICKER, H.RELAY_KICKER, H.RAGDOLL_FIX,
        H.REWIND,
        H.RAGDOLL_NO_RAG,
        H.OPP_NERF,
        H.LAZER_NERF,
        H.CANNON_RANGE,
        H.ALL_ROCKETS,
    }
    for _, hash in ipairs(toggleFeatures) do
        local feat = FeatureMgr.GetFeature(hash)
        if feat and feat:IsToggled() then
            feat:Toggle()
        end
    end

    playerState.passivePending = {}
    playerState.stripVehGodJob = nil
    playerState.enterInteriorPending = {}
    playerState.kickInteriorPending = {}
    playerState.chimpSwarmPending = {}
    chimpFn.deleteAll()

    local sliderFeatures = {
        H.ROCKET_SPEED, H.INFINITE_RANGE,
        H.SUPERDRIVE_MULT, H.ENGINE_POWER_MULT, H.GRAV_FORCE,
        H.VEH_GUN_SPEED, H.VEH_GUN_DIST, H.SUPER_MELEE,
        H.DRIFT_TRACTION, H.DRIFT_FORCE, H.DRIFT_POWER,
        H.TURN_SPIN_FORCE, H.TURN_BOOST_FORCE, H.TURN_POP,
        H.REWIND_LENGTH, H.REWIND_SPEED,
        H.PAUSE_TGT_DUR,
        H.WHEELIE_STRENGTH,
    }
    for _, hash in ipairs(sliderFeatures) do
        local feat = FeatureMgr.GetFeature(hash)
        if feat then feat:Reset() end
    end

    lazerExpTag.idx = 2

    weaponState.rocketSpeedMult = 1.0
    weaponState.rangeMult = 1.0
    speedMultiplier = 1.0
    rewindState.controlId = rewindState.DEFAULT_CONTROL
    superDriveKey.vk = superDriveKey.DEFAULT_VK
    superDriveKey.controlId = superDriveKey.DEFAULT_CONTROL
    wheelie.vk = wheelie.DEFAULT_VK
    wheelie.controlId = wheelie.DEFAULT_CONTROL
    wheelie.strength = 1.0
    titanCannonCycle.vk = titanCannonCycle.DEFAULT_VK
    titanCannonCycle.controlId = titanCannonCycle.DEFAULT_CONTROL
    grav.forceMult = 1
    driftState.tractionMult = 0.5
    driftState.forceMult = 1.0

    vehicleGunCleanupAll()

    patchFn.windscreenRestorePatch()

    patchFn.weaponWheelRestorePatch()

    if patchFn.wpInsideInterior then
        patchFn.wpInsideInterior.restore()
        patchFn.wpInsideInterior.releaseCheraxAutoTp()
    end

    if lockOntoPlayers and lockOntoPlayers.reticleDrawPatch then
        lockOntoPlayers.reticleDrawPatch.restore()
    end
    if lockOntoPlayers and lockOntoPlayers.occludedLockSoundPatch then
        lockOntoPlayers.occludedLockSoundPatch.restore()
    end

    if lockOntoPlayers and lockOntoPlayers.nativePlayerLockPatch then
        lockOntoPlayers.nativePlayerLockPatch.restore()
    end
    if lockOntoPlayers and lockOntoPlayers.pedThreatGatePatch then
        lockOntoPlayers.pedThreatGatePatch.restore()
        lockOntoPlayers.pedThreatGatePatch.restoreCave()
    end
    if lockOntoPlayers and lockOntoPlayers.vehicleHomingFlagPatch then
        lockOntoPlayers.vehicleHomingFlagPatch.restore()
    end
    if lockOntoPlayers and lockOntoPlayers.vehicleOccupantGatePatch then
        lockOntoPlayers.vehicleOccupantGatePatch.restore()
    end

    watchYoJetCleanupAll()

    playerState.blackIceLastSent = {}

    if patchFn.drivebyAnyVehRestore then patchFn.drivebyAnyVehRestore() end

    if patchFn.titanDriverWeaponsRestore then patchFn.titanDriverWeaponsRestore() end

    patchFn.pausedSpoofActive = false

    ENTITY.RESET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID())

    if ragdollFix then
        for pid, _ in pairs(ragdollFix.noRagPeds) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            if ped ~= 0 then
                PED.SET_PED_CAN_RAGDOLL(ped, true)
            end
        end
        ragdollFix.state = {}
        ragdollFix.noRagPeds = {}
        ragdollFix.knownModders = {}
    end

    for pid, st in pairs(playerState.pauseTarget) do
        do
            NETWORK.NETWORK_CONCEAL_PLAYER(pid, false, false)
        end
    end
    playerState.pauseTarget = {}

    playerState.steerInvert = {}

    playerState.speed.restoreAll()

    driftResetPower()
    driftState.score = 0.0
    driftState.active = false
    driftState.bestScore = 0.0
    driftState.scoreShow = 0.0
    driftState.scoreExpiry = 0
    driftState.smokeTick = 0
    quickTurn.tick = 0
    quickTurn.totalRotation = 0
    quickTurn.settleStart = 0
    quickTurn.startHeading = 0
    quickTurn.entrySpeed = 0
    quickTurn.boostStart = 0
    quickTurn.activeFeature = nil

    frenchKicker.kicked = {}
    frenchKicker.pending = {}
    frenchKicker.scanned = false
    if frenchKicker.eventId then
        EventMgr.RemoveHandler(frenchKicker.eventId)
        frenchKicker.eventId = nil
    end

    chineseKicker.kicked = {}
    chineseKicker.pending = {}
    chineseKicker.scanned = false
    if chineseKicker.eventId then
        EventMgr.RemoveHandler(chineseKicker.eventId)
        chineseKicker.eventId = nil
    end

    myCountryOnly.kicked = {}
    myCountryOnly.pending = {}
    myCountryOnly.scanned = false
    myCountryOnly.localCC = nil
    if myCountryOnly.eventId then
        EventMgr.RemoveHandler(myCountryOnly.eventId)
        myCountryOnly.eventId = nil
    end

    vpnKicker.kicked = {}
    vpnKicker.pending = {}
    vpnKicker.scanned = false
    if vpnKicker.eventId then
        EventMgr.RemoveHandler(vpnKicker.eventId)
        vpnKicker.eventId = nil
    end

    relayKicker.kicked = {}
    relayKicker.pending = {}
    relayKicker.scanned = false
    if relayKicker.eventId then
        EventMgr.RemoveHandler(relayKicker.eventId)
        relayKicker.eventId = nil
    end

    rewindCancel()
    rewindClearBuffer()
    rewindState.lengthSec = 10

end

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
    scriptUnloading = true
    rewindState._unloading = true
    pendingKicks = {}
    pcall(lockCineCam.forceCleanup)
    if DEV.unloadCleanup then pcall(DEV.unloadCleanup) end
    pcall(resetAll)
end)


local console = {
    cache = "",
    lastRefresh = 0,
    REFRESH_INTERVAL = 2.0,
    enabled = false,
    maxLines = 500,
    MAX_LINES_CAP = 5000,
}

local settings = {
    dir    = FileMgr.GetMenuRootPath() .. "\\lua\\VibeScript",
    status = "",
    pendingAction = nil,
    autoload = false,
    introEnabled = true,
}
settings.file = settings.dir .. "\\settings.cfg"
settings.autoloadFile = settings.dir .. "\\autoload.cfg"
settings.introFile = settings.dir .. "\\intro.cfg"
FileMgr.CreateDir(settings.dir)

if FileMgr.DoesFileExist(settings.autoloadFile) then
    local c = FileMgr.ReadFileContent(settings.autoloadFile)
    settings.autoload = c and c:match("1") ~= nil
end

if FileMgr.DoesFileExist(settings.introFile) then
    local c = FileMgr.ReadFileContent(settings.introFile)
    settings.introEnabled = c and c:match("1") ~= nil
end

FeatureMgr.AddFeature(H.RESET, "Reset All", eFeatureType.Button,
    "Restores all modified weapon values.",
    function(f)
        settings.pendingAction = function() resetAll() end
        GUI.AddToast("VibeScript", "All modifications reset.", 3000)
    end)

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if scriptUnloading then return end
    local scanReady = scanDoctor.gate()
    if scanReady and settings.pendingAction then
        local action = settings.pendingAction
        settings.pendingAction = nil
        pcall(action)
    end
    if settings._kbReloadAt and Time.GetEpocheMs() >= settings._kbReloadAt then
        settings._kbReloadAt = nil
        if settings.loadKeybinds then settings.loadKeybinds() end
    end
    if settings.maybeSnapshotKeybinds then settings.maybeSnapshotKeybinds() end
end)

local SAVEABLE_TOGGLES = {
    { "LUA_VehRapidFire",    H.RAPID_FIRE    },
    { "LUA_VehInfiniteAmmo", H.VEH_INF_AMMO  },
    { "LUA_OnFootRapidFire", H.ONFOOT_RAPID  },
    { "LUA_OnFootHomingSpam", H.ONFOOT_HOMING_SPAM },
    { "LUA_RocketSpeed",     H.ROCKET_SPEED  },
    { "LUA_NoclipRockets",   H.NOCLIP_ROCKETS },
    { "LUA_InfiniteRange",   H.INFINITE_RANGE },
    { "LUA_InstantRocket",   H.INSTANT_ROCKET },
    { "LUA_InstantLockon",   H.INSTANT_LOCKON },
    { "LUA_AutoLockonFire",  H.AUTO_LOCKON_FIRE },
    { "LUA_LockOntoPlayers", H.LOCK_ONTO_PLAYERS },
    { "LUA_LockOntoNPCs",    H.LOCK_ONTO_NPCS },
    { "LUA_InfiniteLockonRange", H.INF_LOCKON_RANGE },
    { "LUA_DisableLOS",     H.DISABLE_LOS  },
    { "LUA_GravityGun",      H.GRAVITY_GUN   },
    { "LUA_GravContrived",   H.GRAV_CONTRIVED },
    { "LUA_GravCollision",   H.GRAV_COLLISION },
    { "LUA_GravInVehicle",   H.GRAV_IN_VEH   },
    { "LUA_SuperDriveToggle",H.SUPERDRIVE     },
    { "LUA_SuperDriveUseCam",H.SUPERDRIVE_CAM },
    { "LUA_WheelieToggle",   H.WHEELIE        },
    { "LUA_EnginePower",     H.ENGINE_POWER   },
    { "LUA_VehicleGun",      H.VEH_GUN       },
    { "LUA_VehGunRandom",    H.VEH_GUN_RANDOM },
    { "LUA_VehGunRandAir",   H.VEH_GUN_RAND_AIR },
    { "LUA_VehGunRandSea",   H.VEH_GUN_RAND_SEA },
    { "LUA_VehGunInVehicle", H.VEH_GUN_IN_VEH  },
    { "LUA_DriftAssist",     H.DRIFT_ASSIST  },
    { "LUA_DriftScoreDisplay", H.DRIFT_SCORE },
    { "LUA_DriftSmoke",      H.DRIFT_SMOKE   },
    { "LUA_DriftExitBoost",  H.DRIFT_EXIT_BOOST },
    { "LUA_FlyWindscreen",   H.FLY_WINDSCREEN },
    { "LUA_BetterEscEngine", H.BETTER_ESC_ENGINE },
    { "LUA_BetterAltF4",    H.BETTER_ALT_F4 },
    { "LUA_LockCineCam",    H.LOCK_CINE_CAM },
    { "LUA_YogaRun",        H.YOGA_RUN      },
    { "LUA_WaypointsInInterior", H.WP_INTERIOR },
    { "LUA_WaypointsInsideInterior", H.WP_INSIDE_INT },
    { "LUA_AutoTeleportObjective", H.AUTO_TP_OBJECTIVE },
    { "LUA_PausedSpoof",     H.PAUSED_SPOOF  },
    { "LUA_FrenchKicker",   H.FRENCH_KICKER },
    { "LUA_ChineseKicker",  H.CHINESE_KICKER },
    { "LUA_MyCountryOnly",  H.MY_COUNTRY_ONLY },
    { "LUA_VPNKicker",      H.VPN_KICKER   },
    { "LUA_RelayKicker",     H.RELAY_KICKER  },
    { "LUA_WeaponWheel",    H.WEAPON_WHEEL  },
    { "LUA_TitanDriverWeapons", H.TITAN_DRIVER_WEAPONS },
    { "LUA_TitanProbe",     H.TITAN_PROBE   },
    { "LUA_TitanCannonCycle", H.TITAN_CANNON_CYCLE },
    { "LUA_RagdollFix",     H.RAGDOLL_FIX   },
    { "LUA_Rewind",          H.REWIND        },
    { "LUA_OppressorNerf",   H.OPP_NERF      },
    { "LUA_LazerNerf",       H.LAZER_NERF    },
    { "LUA_CannonRange",     H.CANNON_RANGE  },
    { "LUA_AllRockets",      H.ALL_ROCKETS   },
}

local SAVEABLE_SLIDERS = {
    { "LUA_RocketSpeed",         H.ROCKET_SPEED,     "float" },
    { "LUA_InfiniteRange",       H.INFINITE_RANGE,   "float" },
    { "LUA_SuperDriveMultiplier",H.SUPERDRIVE_MULT,  "float" },
    { "LUA_WheelieStrength",     H.WHEELIE_STRENGTH, "float" },
    { "LUA_EnginePowerMult",     H.ENGINE_POWER_MULT,"float" },
    { "LUA_GravForce",           H.GRAV_FORCE,       "int"   },
    { "LUA_VehGunSpeed",         H.VEH_GUN_SPEED,    "float" },
    { "LUA_VehGunDist",          H.VEH_GUN_DIST,     "float" },
    { "LUA_SuperMelee",          H.SUPER_MELEE,      "int"   },
    { "LUA_DriftTraction",       H.DRIFT_TRACTION,   "float" },
    { "LUA_DriftForce",          H.DRIFT_FORCE,      "float" },
    { "LUA_DriftPower",          H.DRIFT_POWER,      "float" },
    { "LUA_TurnSpinForce",       H.TURN_SPIN_FORCE,  "float" },
    { "LUA_TurnBoostForce",      H.TURN_BOOST_FORCE, "float" },
    { "LUA_TurnPop",             H.TURN_POP,         "float" },
    { "LUA_RewindLength",        H.REWIND_LENGTH,    "int"   },
    { "LUA_RewindSpeed",         H.REWIND_SPEED,     "float" },
}

local function saveSettings()
    local ok, err = pcall(function()
        local lines = { "# VibeScript Settings" }

        for _, entry in ipairs(SAVEABLE_TOGGLES) do
            local name, hash = entry[1], entry[2]
            local feat = FeatureMgr.GetFeature(hash)
            if feat then
                lines[#lines + 1] = ("T:%s=%d"):format(name, feat:IsToggled() and 1 or 0)
            end
        end

        for _, entry in ipairs(SAVEABLE_SLIDERS) do
            local name, hash, vtype = entry[1], entry[2], entry[3]
            local feat = FeatureMgr.GetFeature(hash)
            if feat then
                if vtype == "int" then
                    lines[#lines + 1] = ("I:%s=%d"):format(name, feat:GetIntValue())
                else
                    lines[#lines + 1] = ("F:%s=%.6f"):format(name, feat:GetFloatValue())
                end
            end
        end

        lines[#lines + 1] = ("V:classIdx=%d"):format(vehGun.classIdx)
        lines[#lines + 1] = ("V:lazerExpTagIdx=%d"):format(lazerExpTag.idx)
        lines[#lines + 1] = ("V:vehIdx=%d"):format(vehGun.vehIdx)
        lines[#lines + 1] = ("V:rewindVK=%d"):format(rewindState.rewindVK)
        lines[#lines + 1] = ("V:rewindCtrl=%d"):format(rewindState.controlId)
        lines[#lines + 1] = ("V:superDriveVK=%d"):format(superDriveKey.vk)
        lines[#lines + 1] = ("V:superDriveCtrl=%d"):format(superDriveKey.controlId)
        lines[#lines + 1] = ("V:wheelieVK=%d"):format(wheelie.vk)
        lines[#lines + 1] = ("V:wheelieCtrl=%d"):format(wheelie.controlId)
        lines[#lines + 1] = ("V:titanCannonVK=%d"):format(titanCannonCycle.vk)
        lines[#lines + 1] = ("V:titanCannonCtrl=%d"):format(titanCannonCycle.controlId)
        lines[#lines + 1] = ("V:titanCannonHops=%d"):format(titanCannonCycle.shuffleHops or 2)
        lines[#lines + 1] = ("V:titanCannonDelay=%d"):format(titanCannonCycle.shuffleDelayMs or 1500)
        lines[#lines + 1] = ("V:titanCannonTarget=%d"):format(titanCannonCycle.targetGunnerSeat or titanCannonCycle.DEFAULT_TARGET)
        lines[#lines + 1] = ("V:titanCannonExit=%d"):format(titanCannonCycle.exitTargetSeat or titanCannonCycle.DEFAULT_EXIT)
        lines[#lines + 1] = ("V:consoleLines=%d"):format(console.maxLines)

        local content = table.concat(lines, "\n")
        FileMgr.WriteFileContent(settings.file, content, false)
    end)

    if ok then
        settings.status = "Settings saved."
        GUI.AddToast("VibeScript", "Settings saved.", 3000)
    else
        settings.status = "Save failed: " .. tostring(err)
        logErr("Save settings failed: " .. tostring(err))
    end
end

local function loadSettings()
    if not FileMgr.DoesFileExist(settings.file) then
        settings.status = "No saved settings found."
        GUI.AddToast("VibeScript", "No saved settings found.", 3000)
        return
    end

    local ok, err = pcall(function()
        local content = FileMgr.ReadFileContent(settings.file)
        if not content or #content == 0 then
            error("Settings file is empty")
        end

        local toggleMap = {}
        local floatMap  = {}
        local intMap    = {}
        local valueMap  = {}

        for line in content:gmatch("[^\r\n]+") do
            if line:sub(1, 1) ~= "#" then
                local prefix, rest = line:match("^(%a):(.+)$")
                if prefix and rest then
                    local key, val = rest:match("^(.-)=(.+)$")
                    if key and val then
                        if prefix == "T" then
                            toggleMap[key] = val == "1"
                        elseif prefix == "F" then
                            floatMap[key] = tonumber(val)
                        elseif prefix == "I" then
                            intMap[key] = tonumber(val)
                        elseif prefix == "V" then
                            valueMap[key] = val
                        end
                    end
                end
            end
        end

        if valueMap["classIdx"] then vehGun.classIdx = tonumber(valueMap["classIdx"]) or 1 end
        if valueMap["vehIdx"]   then vehGun.vehIdx   = tonumber(valueMap["vehIdx"])   or 1 end
        if valueMap["lazerExpTagIdx"] then
            local i = tonumber(valueMap["lazerExpTagIdx"])
            if i and i >= 1 and i <= #lazerExpTag.labels then
                lazerExpTag.idx = i
            end
        end
        if valueMap["rewindVK"] then
            local vk = tonumber(valueMap["rewindVK"])
            if vk and vk >= 1 and vk <= 255 then
                rewindState.rewindVK = vk
                local kf = FeatureMgr.GetFeature(H.REWIND_KEY)
                if kf then kf:SetIntValue(vk) end
            end
        end
        if valueMap["rewindCtrl"] then
            local id = tonumber(valueMap["rewindCtrl"])
            if id and id >= 0 and id <= 350 then
                rewindState.controlId = id
            end
        end
        if valueMap["superDriveVK"] then
            local vk = tonumber(valueMap["superDriveVK"])
            if vk and vk >= 1 and vk <= 255 then
                superDriveKey.vk = vk
            end
        end
        if valueMap["superDriveCtrl"] then
            local id = tonumber(valueMap["superDriveCtrl"])
            if id and id >= 0 and id <= 350 then
                superDriveKey.controlId = id
            end
        end
        if valueMap["wheelieVK"] then
            local vk = tonumber(valueMap["wheelieVK"])
            if vk and vk >= 1 and vk <= 255 then
                wheelie.vk = vk
            end
        end
        if valueMap["wheelieCtrl"] then
            local id = tonumber(valueMap["wheelieCtrl"])
            if id and id >= 0 and id <= 350 then
                wheelie.controlId = id
            end
        end
        if valueMap["titanCannonVK"] then
            local vk = tonumber(valueMap["titanCannonVK"])
            if vk and vk >= 1 and vk <= 255 then
                titanCannonCycle.vk = vk
            end
        end
        if valueMap["titanCannonCtrl"] then
            local id = tonumber(valueMap["titanCannonCtrl"])
            if id and id >= 0 and id <= 350 then
                titanCannonCycle.controlId = id
            end
        end
        if valueMap["titanCannonHops"] then
            local h = tonumber(valueMap["titanCannonHops"])
            if h and h >= 1 and h <= 3 then titanCannonCycle.shuffleHops = h end
        end
        if valueMap["titanCannonDelay"] then
            local d = tonumber(valueMap["titanCannonDelay"])
            if d and d >= 250 and d <= 3000 then titanCannonCycle.shuffleDelayMs = d end
        end
        if valueMap["titanCannonTarget"] then
            local t = tonumber(valueMap["titanCannonTarget"])
            if t and (t == 2 or t == 3 or t == 4) then titanCannonCycle.targetGunnerSeat = t end
        end
        if valueMap["titanCannonExit"] then
            local e = tonumber(valueMap["titanCannonExit"])
            if e and (e == 0 or e == 1) then titanCannonCycle.exitTargetSeat = e end
        end
        if valueMap["consoleLines"] then
            local n = tonumber(valueMap["consoleLines"])
            if n then console.maxLines = math.max(50, math.min(n, console.MAX_LINES_CAP)) end
        end

        settings.pendingAction = function()
            for _, entry in ipairs(SAVEABLE_TOGGLES) do
                local name, hash = entry[1], entry[2]
                local feat = FeatureMgr.GetFeature(hash)
                if feat and toggleMap[name] ~= nil then
                    local shouldBeOn = toggleMap[name]
                    if feat:IsToggled() ~= shouldBeOn then
                        feat:Toggle()
                    end
                end
            end

            for _, entry in ipairs(SAVEABLE_SLIDERS) do
                local name, hash, vtype = entry[1], entry[2], entry[3]
                local feat = FeatureMgr.GetFeature(hash)
                if feat then
                    if vtype == "int" and intMap[name] then
                        feat:SetIntValue(intMap[name])
                    elseif vtype == "float" and floatMap[name] then
                        feat:SetFloatValue(floatMap[name])
                    end
                end
            end
        end
    end)

    if ok then
        settings.status = "Settings loaded."
        GUI.AddToast("VibeScript", "Settings loaded.", 3000)
    else
        settings.status = "Load failed: " .. tostring(err)
        logErr("Load settings failed: " .. tostring(err))
    end
end

local function restoreDefaults()
    settings.pendingAction = function()
        resetAll()
        vehGun.classIdx = 1
        vehGun.vehIdx = 1
        console.enabled = false
    end
    settings.status = "Defaults restored. Saved config kept."
    GUI.AddToast("VibeScript", "All settings restored to defaults.", 3000)
end

local function deleteSavedSettings()
    settings.pendingAction = function()
        resetAll()
        vehGun.classIdx = 1
        vehGun.vehIdx = 1
        console.enabled = false
    end
    pcall(FileMgr.DeleteFile, settings.file)
    settings.status = "Settings deleted and reset to defaults."
    GUI.AddToast("VibeScript", "Saved settings deleted.", 3000)
end

settings.keybindsFile = settings.dir .. "\\keybinds.cfg"
settings._kbLast = nil
settings._kbNext = 0
settings._kbLogCount = -1

settings.kbReadKeys = function(v)
    local out = {}
    if v == nil then return out end
    local ok, n = pcall(function() return #v end)
    if not ok or type(n) ~= "number" or n <= 0 then return out end
    for i = 1, n do
        local ok2, k = pcall(function() return v[i] end)
        if ok2 and type(k) == "number" and k > 0 then out[#out + 1] = k end
    end
    return out
end


settings.buildKeybinds = function()
    local lines = { "# VibeScript Keybinds" }
    local seen, count = {}, 0
    for _, hash in pairs(H) do
        if type(hash) == "number" and not seen[hash] then
            seen[hash] = true
            local keys = settings.kbReadKeys(HotKeyMgr.GetHotKeys(hash))
            if #keys > 0 then
                local parts = {}
                for i = 1, #keys do parts[#parts + 1] = ("%d"):format(keys[i]) end
                lines[#lines + 1] = ("K:%d=%s"):format(hash, table.concat(parts, ","))
                count = count + 1
            end
        end
    end
    return table.concat(lines, "\n"), count
end

settings.saveKeybinds = function(reason)
    local ok, err = pcall(function()
        local content, count = settings.buildKeybinds()
        if count ~= settings._kbLogCount then
            settings._kbLogCount = count
            if VIBESCRIPT_VERBOSE then logf("[Keybinds] %s: %d of our features bound", tostring(reason), count) end
        end
        if count == 0 and settings._kbLast and settings._kbLast ~= "" then return end
        if content == settings._kbLast then return end
        FileMgr.WriteFileContent(settings.keybindsFile, content, false)
        settings._kbLast = content
    end)
    if not ok then logErr("Save keybinds failed: " .. tostring(err)) end
end

settings.maybeSnapshotKeybinds = function()
    local now = Time.GetEpocheMs()
    if now < (settings._kbNext or 0) then return end
    settings._kbNext = now + 3000
    settings.saveKeybinds("snapshot")
end

settings.loadKeybinds = function()
    if not FileMgr.DoesFileExist(settings.keybindsFile) then
        if VIBESCRIPT_VERBOSE then logf("[Keybinds] load: no saved file") end
        return
    end
    local ok, err = pcall(function()
        local content = FileMgr.ReadFileContent(settings.keybindsFile)
        if not content or #content == 0 then return end
        settings._kbLast = content
        local applied = 0
        for line in content:gmatch("[^\r\n]+") do
            local hashStr, keysStr = line:match("^K:(%-?%d+)=(.+)$")
            if hashStr and keysStr then
                local hash = tonumber(hashStr)
                if hash then
                    local cur = settings.kbReadKeys(HotKeyMgr.GetHotKeys(hash))
                    for i = 1, #cur do HotKeyMgr.RemoveHotkey(hash, cur[i]) end
                    for keyStr in keysStr:gmatch("[^,]+") do
                        local key = tonumber(keyStr)
                        if key and key > 0 then
                            HotKeyMgr.AddHotkey(hash, key)
                            applied = applied + 1
                        end
                    end
                end
            end
        end
        if VIBESCRIPT_VERBOSE then logf("[Keybinds] load: applied %d hotkey(s)", applied) end
    end)
    if not ok then logErr("Load keybinds failed: " .. tostring(err)) end
end

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
    if settings.saveKeybinds then settings.saveKeybinds("unload") end
end)




local function readCheraxLog()
    local now = os.clock()
    if now - console.lastRefresh < console.REFRESH_INTERVAL then return end
    console.lastRefresh = now

    local root = FileMgr.GetMenuRootPath()
    local paths = {
        root .. "\\cherax.log",
        root .. "\\Logs\\cherax.log",
        root .. "\\log.txt",
        root .. "\\Logs\\log.txt",
    }
    local tailBytes = console.maxLines * 120
    for _, path in ipairs(paths) do
        local ok, f = pcall(io.open, path, "rb")
        if ok and f then
            local size = f:seek("end") or 0
            if size > 0 then
                local seeked = size > tailBytes
                if seeked then
                    f:seek("set", size - tailBytes)
                else
                    f:seek("set", 0)
                end
                local chunk = f:read("*a")
                f:close()
                if chunk and #chunk > 0 then
                    if seeked then
                        local nl = chunk:find("\n")
                        if nl then chunk = chunk:sub(nl + 1) end
                    end
                    local nls = {}
                    local pos = 0
                    while true do
                        pos = chunk:find("\n", pos + 1, true)
                        if not pos then break end
                        nls[#nls + 1] = pos
                    end
                    if #nls > console.maxLines then
                        chunk = chunk:sub(nls[#nls - console.maxLines] + 1)
                    end
                    console.cache = chunk
                    return
                end
            else
                f:close()
            end
        end
    end
    if logging.logDirty or console.cache == "" then
        console.cache = table.concat(logging.buffer, "\n")
        logging.logDirty = false
    end
end



;(function()

noclipRockets = {
    SCAN_TAIL_MS  = 1200,
    GRACE_MS      = 600,
    MAX_SLOTS     = 50,
    COUNT_OFF     = 0x190,
    POOL_PAT_ENH  = "56 57 55 53 48 83 EC 28 83 3D ? ? ? ? 00 7E ? 89 D5 89 CE 48 8D 3D",
    POOL_RIP_ENH  = 0x18,
    POOL_PAT_LEG  = "48 63 0D ? ? ? ? 48 8D 15 ? ? ? ? 48 8D 45",
    POOL_RIP_LEG  = 10,
    PP_PAT_ENH    = "76 08 C7 00 C2 35 F6 07 EB 06 C7 00 C4 35 F6 07",
    PP_EDITS_ENH  = { {4,0xC2,0xC0}, {5,0x35,0x15}, {12,0xC4,0xC0}, {13,0x35,0x15} },
    PP_PAT_LEG    = "73 09 C7 42 10 C2 35 F6 07 EB 07 C7 42 10 C4 35 F6 07",
    PP_EDITS_LEG  = { {5,0xC2,0xC0}, {6,0x35,0x15}, {14,0xC4,0xC0}, {15,0x35,0x15} },

    poolElems   = nil,
    patchEdits  = nil,
    resolveTries = 0,
    RESOLVE_TRIES = 90,
    patched     = false,
    seen        = {},
    mine        = {},
    lastFire    = 0,
    lastAliveMs = 0,
    wasOn       = false,
}

noclipRockets.toast = function(msg)
    GUI.AddToast("Noclip Rockets", msg, 4000)
end

noclipRockets.resolvePool = function()
    local nR = noclipRockets
    if nR.poolElems ~= nil then return nR.poolElems ~= 0 end
    local pat, ripOff
    if IS_ENHANCED then pat, ripOff = nR.POOL_PAT_ENH, nR.POOL_RIP_ENH
    else pat, ripOff = nR.POOL_PAT_LEG, nR.POOL_RIP_LEG end
    local hit = Memory.Scan(pat)
    local elems = nil
    if hit and hit ~= 0 then
        local e = Memory.Rip(hit + ripOff)
        if e and e ~= 0 then elems = e end
    end
    nR.poolElems = elems or 0
    return elems ~= nil
end

noclipRockets.findSite = function()
    local nR = noclipRockets
    local pat, edits
    if IS_ENHANCED then pat, edits = nR.PP_PAT_ENH, nR.PP_EDITS_ENH
    else pat, edits = nR.PP_PAT_LEG, nR.PP_EDITS_LEG end
    local hit = Memory.Scan(pat)
    if hit and hit ~= 0 then return hit end
    local toks = {}
    for t in pat:gmatch("%S+") do toks[#toks + 1] = t end
    for i = 1, #edits do toks[edits[i][1] + 1] = "?" end
    hit = Memory.Scan(table.concat(toks, " "))
    if not hit or hit == 0 then return nil end
    for i = 1, #edits do
        local e = edits[i]
        local b = Memory.ReadUByte(hit + e[1])
        b = (type(b) == "number") and (b & 0xFF) or -1
        if b ~= e[2] and b ~= e[3] then return nil end
    end
    for i = 1, #edits do
        Memory.WriteByte(hit + edits[i][1], edits[i][2])
    end
    return hit
end

noclipRockets.resolvePatch = function()
    local nR = noclipRockets
    if nR.patchEdits ~= nil then return nR.patchEdits ~= 0 end
    local hit = nR.findSite()
    if hit then
        local edits = IS_ENHANCED and nR.PP_EDITS_ENH or nR.PP_EDITS_LEG
        local resolved = {}
        for i = 1, #edits do
            local e = edits[i]
            resolved[i] = { addr = hit + e[1], orig = e[2], patched = e[3] }
        end
        nR.patchEdits = resolved
        return true
    end
    nR.resolveTries = nR.resolveTries + 1
    if nR.resolveTries < nR.RESOLVE_TRIES then return false end
    nR.patchEdits = 0
    nR.toast("Not supported on this game build (update needed).")
    return false
end

noclipRockets.applyPatch = function()
    local nR = noclipRockets
    if nR.patched or not nR.patchEdits or nR.patchEdits == 0 then return end
    for i = 1, #nR.patchEdits do
        local e = nR.patchEdits[i]
        Memory.WriteByte(e.addr, e.patched)
    end
    nR.patched = true
end

noclipRockets.revertPatch = function()
    local nR = noclipRockets
    if not nR.patched or not nR.patchEdits or nR.patchEdits == 0 then return end
    for i = 1, #nR.patchEdits do
        local e = nR.patchEdits[i]
        Memory.WriteByte(e.addr, e.orig)
    end
    nR.patched = false
end

noclipRockets.updateMine = function(inWindow, now)
    local nR = noclipRockets
    local base = nR.poolElems
    if not base or base == 0 then return next(nR.mine) ~= nil end
    local count = Memory.ReadInt(base + nR.COUNT_OFF)
    if type(count) ~= "number" then return next(nR.mine) ~= nil end
    if count > nR.MAX_SLOTS then count = nR.MAX_SLOTS end
    local live = {}
    for i = 0, count - 1 do
        local addr = Memory.ReadLong(base + i * 8)
        if addr and addr ~= 0 then
            live[addr] = true
            if inWindow and not nR.seen[addr] then nR.mine[addr] = true end
            nR.seen[addr] = true
        end
    end
    for addr in pairs(nR.seen) do
        if not live[addr] then nR.seen[addr] = nil; nR.mine[addr] = nil end
    end
    local haveMine = next(nR.mine) ~= nil
    if haveMine then nR.lastAliveMs = now end
    return haveMine
end

noclipRockets.onTick = function(f)
    local nR = noclipRockets
    if not f:IsToggled() then
        if nR.wasOn then
            nR.wasOn = false
            nR.revertPatch()
            nR.seen = {}
            nR.mine = {}
        end
        return
    end
    nR.wasOn = true
    if not nR.resolvePatch() then return end
    nR.resolvePool()

    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    if ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    local now = MISC.GET_GAME_TIMER()
    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)

    local firing = false
    if veh ~= 0 and VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(veh) then
        local weaponInfoAddr, trusted = getVehicleWeaponInfoAddr()
        if weaponInfoAddr and not forceSyncVehicleWeaponInfoIfStale(ped, weaponInfoAddr)
           and trusted then
            local weaponHash = Memory.ReadUInt(weaponInfoAddr + OFF.WEAPON_NAME_HASH)
            if weaponHash ~= 0 and ROCKET_TYPE_WEAPONS[weaponHash] == true then
                firing = PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.VEH_ATTACK)
                      or PAD.IS_DISABLED_CONTROL_PRESSED(0, INPUT.VEH_FLY_ATTACK)
            end
        end
    end
    if firing then nR.lastFire = now end
    local inWindow = nR.lastFire ~= 0 and (now - nR.lastFire) <= nR.SCAN_TAIL_MS

    local haveMine = nR.updateMine(inWindow, now)
    local wanted = inWindow or haveMine
        or (nR.lastAliveMs ~= 0 and (now - nR.lastAliveMs) <= nR.GRACE_MS)
    if wanted and not nR.patched then
        nR.applyPatch()
    elseif not wanted and nR.patched then
        nR.revertPatch()
    end
end

centralOnTick(FeatureMgr.AddFeature(H.NOCLIP_ROCKETS, "Noclip Rockets", eFeatureType.Toggle,
    "Your vehicle rockets and missiles fly through walls, buildings, cover and props but still hit players and vehicles. Pair with Disable Line Of Sight to hit enemies behind cover.",
    noclipRockets.onTick, true)
    :SetSaveable(false))

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function() pcall(noclipRockets.revertPatch) end)

end)()

scanDoctor.register("NCR", { probe = function()
    return noclipRockets.findSite() ~= nil end })
scanDoctor.register("NCR-POOL", { sig = function()
    return IS_ENHANCED and noclipRockets.POOL_PAT_ENH or noclipRockets.POOL_PAT_LEG end })

scanDoctor.register("DLS-RET",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "reticleDrawPatch", "AOB", "E_AOB") })
scanDoctor.register("DLS-SND",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "occludedLockSoundPatch", "AOB", "E_AOB") })
scanDoctor.register("LOP-NPL",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "nativePlayerLockPatch", "AOB", "E_AOB") })
scanDoctor.register("LO-PTG",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "pedThreatGatePatch", "AOB", "E_AOB") })
scanDoctor.register("LON-VHF",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "vehicleHomingFlagPatch", "AOB", "E_AOB") })
scanDoctor.register("LON-VOG",
    { sig = scanDoctor.fieldSig(lockOntoPlayers, "vehicleOccupantGatePatch", "AOB", "E_AOB") })

scanDoctor.register("FTW", { sig = scanDoctor.litSig(
    "E8 ? ? ? ? 84 C0 0F 84 ? ? ? ? 65 48 8B 0C 25 ? ? ? ? 8B 05 ? ? ? ? BA ? ? ? ? 48 8B 04 C1 48 83 3C 02 ? 75 0C",
    "E8 ? ? ? ? 89 C5 84 C0 0F 84 ? ? ? ? 8B 05 ? ? ? ? 65 48 8B 0C 25") })

scanDoctor.register("WW", { sig = scanDoctor.litSig(
    "74 09 41 B5 01 44 88 6D E0",
    "C0 E8 06 49 8B 8D 30 15 00 00 48 85 C9 41 0F 95 C4") })

scanDoctor.register("AS-BOOM",
    { sig = scanDoctor.fieldSig(aircraftSabotage, "boomFn", "leg", "enh") })
scanDoctor.register("AS-SECT",
    { sig = scanDoctor.fieldSig(aircraftSabotage, "sectionFn", "leg", "enh") })
scanDoctor.register("AS-ROTOR",
    { sig = scanDoctor.fieldSig(aircraftSabotage, "rotorFn", "leg", "enh") })

scanDoctor.register("VD-BLOW",
    { sig = scanDoctor.fieldSig(vehicleDismantle, "blowUpFn", "leg", "enh") })
scanDoctor.register("VD-WHEEL",
    { sig = scanDoctor.fieldSig(vehicleDismantle, "wheelFn", "leg", "enh") })

scanDoctor.register("ESC", { sig = scanDoctor.litSig(
    "89 91 1C 83 02 00 E9",
    "48 81 EC 30 09 00 00 48 89 CE 03 15") })

scanDoctor.register("WPI", { probe = function()
    local t = patchFn and patchFn.wpInsideInterior
    if not t then return nil end
    local sites = IS_ENHANCED and t.ENHANCED_SITES or t.LEGACY_SITES
    if not sites or #sites == 0 then return nil end
    for _, s in ipairs(sites) do
        if not scanDoctor.scanOk(s.AOB) then return false end
    end
    return true
end })

scanDoctor.register("BC", { probe = function()
    if not IS_ENHANCED then
        return scanDoctor.scanOk("E8 ? ? ? ? 49 8B CD 0F 28 F8")
    end
    for xmm = 0, 7 do
        for base = 0, 7 do
            if base ~= 4 then
                local modrm = 0x80 + (xmm << 3) + base
                if scanDoctor.scanOk(("F3 0F 5F %02X 3C 01 00 00 F3 0F 11 %02X 3C 01 00 00"):format(modrm, modrm)) then
                    return true
                end
            end
        end
    end
    return false
end })


doomLauncher = {}
doomLauncher.COMMIT        = "416e34cfd347ab07c030580df83aff24ac8eade2"
doomLauncher.RAW_URL       = "https://raw.githubusercontent.com/RealToasterBoi/Cherax-Doom/"
                             .. doomLauncher.COMMIT .. "/CheraxDoom.lua"
doomLauncher.dir           = FileMgr.GetMenuRootPath() .. "\\lua\\VibeScript"
doomLauncher.path          = doomLauncher.dir .. "\\CheraxDoom.lua"
doomLauncher.verFile       = doomLauncher.dir .. "\\CheraxDoom.ver"
doomLauncher.phase         = "idle"
doomLauncher.handle        = nil
doomLauncher.start         = 0
doomLauncher.status        = ""
doomLauncher.SHUTDOWN_HASH = Utils.Joaat("CheraxDoom_Shutdown")
H.DOOM_LAUNCHER_RUNNER     = Utils.Joaat("LUA_DoomLauncherRunner")

function doomLauncher.isRunning()
    return FeatureMgr.GetFeature(doomLauncher.SHUTDOWN_HASH) ~= nil
end

function doomLauncher.cached()
    local okF, exF = pcall(FileMgr.DoesFileExist, doomLauncher.path)
    if not (okF and exF) then return false end
    local okV, ver = pcall(FileMgr.ReadFileContent, doomLauncher.verFile)
    return okV and type(ver) == "string" and ver:gsub("%s+", "") == doomLauncher.COMMIT
end

function doomLauncher.writeLaunchCopy(src)
    pcall(FileMgr.CreateDir, doomLauncher.dir)
    local wrote = false
    pcall(function()
        local f = io.open(doomLauncher.path, "wb")
        if f then f:write("BladscriptLoaded=true\n" .. src); f:close(); wrote = true end
    end)
    if wrote then pcall(FileMgr.WriteFileContent, doomLauncher.verFile, doomLauncher.COMMIT, false) end
    return wrote
end

function doomLauncher.launchFromDisk()
    local ok, ran = pcall(Utils.ExecuteScript, doomLauncher.path)
    if ok and ran ~= false then
        doomLauncher.phase = "idle"; doomLauncher.status = ""
    else
        doomLauncher.phase = "error"; doomLauncher.status = "Launch failed (ExecuteScript)."
    end
end

function doomLauncher.toggle()
    if doomLauncher.isRunning() then
        local f = FeatureMgr.GetFeature(doomLauncher.SHUTDOWN_HASH)
        if f then f:OnClick() end
        doomLauncher.status = "Stopping..."
        return
    end
    if doomLauncher.phase == "downloading" or doomLauncher.phase == "launching" then return end
    if doomLauncher.cached() then
        doomLauncher.phase = "launching"; doomLauncher.status = "Launching..."
        return
    end
    local runBody = function()
        local h = Curl.Easy()
        h:Setopt(eCurlOption.CURLOPT_URL, doomLauncher.RAW_URL)
        h:Setopt(eCurlOption.CURLOPT_USERAGENT, "VibeScript-DoomLauncher")
        h:Perform()
        doomLauncher.handle = h
    end
    runBody()
    if doomLauncher.handle then
        doomLauncher.phase = "downloading"; doomLauncher.start = os.clock()
        doomLauncher.status = "Downloading..."
    else
        doomLauncher.handle = nil
        doomLauncher.phase = "error"; doomLauncher.status = "Could not start download."
    end
end

function doomLauncher.onTick()
    local doomRunning = doomLauncher.isRunning()
    if doomLauncher.status == "Stopping..." and not doomRunning then
        doomLauncher.status = ""
    end
    if doomLauncher.wasRunning and not doomRunning then
        doomLauncher.mciKill = 60
        Logger.LogInfo("[VibeScript] DOOM unloaded; stopping its MCI music from the central tick.")
    end
    doomLauncher.wasRunning = doomRunning
    if (doomLauncher.mciKill or 0) > 0 then
        doomLauncher.mciKill = doomLauncher.mciKill - 1
        Utils.MciSendString("stop doommus")
        Utils.MciSendString("close doommus")
    end
    local p = doomLauncher.phase
    if p == "downloading" then
        if not doomLauncher.handle then doomLauncher.phase = "error"; return end
        local fin = false
        pcall(function() fin = doomLauncher.handle:GetFinished() end)
        if not fin then
            if os.clock() - doomLauncher.start > 20 then
                doomLauncher.handle = nil
                doomLauncher.phase = "error"; doomLauncher.status = "Download timed out."
            end
            return
        end
        local code, body
        pcall(function() code, body = doomLauncher.handle:GetResponse() end)
        doomLauncher.handle = nil
        if code == eCurlCode.CURLE_OK and type(body) == "string" and #body > 1000
           and body:find("CheraxDoom", 1, true) then
            if doomLauncher.writeLaunchCopy(body) then
                doomLauncher.phase = "launching"; doomLauncher.status = "Launching..."
            else
                doomLauncher.phase = "error"; doomLauncher.status = "Could not write script."
            end
        else
            doomLauncher.phase = "error"; doomLauncher.status = "Download failed."
        end
    elseif p == "launching" then
        doomLauncher.launchFromDisk()
    end
end

centralOnTick(FeatureMgr.AddFeature(H.DOOM_LAUNCHER_RUNNER, "##DoomLauncherRunner",
    eFeatureType.Toggle, "", doomLauncher.onTick))
    :SetNoCallbackOnPress(true)
    :SetSaveable(false)
FeatureMgr.GetFeature(H.DOOM_LAUNCHER_RUNNER):Toggle()

lockCineCam = {
    O_CONTEXTS  = 0x2F0,
    O_CTX_COUNT = 0x2F8,
    O_CURRENT   = 0x384,
    O_PREV_TIME = 0x38,
    O_SHOT_IDX  = 0x40,
    O_SHOTS     = 0x18,
    O_SHOT_CNT  = 0x20,
    O_SHOT_META = 0x18,
    O_SHOT_PRIO = 0x4C,
    O_SHOT_CAM  = 0x20,
    O_META_NAME = 0x08,
    HIST_SLOTS  = 20,
    PRIO_BOOST  = 0x40000000,
    PATCH_SCAN_TRIES = 60,
    DIR_AOB  = IS_ENHANCED
        and "48 8B 05 ? ? ? ? 80 A0 9D 03 00 00 FE 66 83 7E 20 00"
        or  "48 8B 05 ? ? ? ? 80 A0 9D 03 00 00 FE 66 44 39 6D ? 0F 84 ? ? ? ?",
    TIME_AOB = IS_ENHANCED and "8B 0D ? ? ? ? 2B 4E 38"
                            or  "8B 05 ? ? ? ? 89 43 38 48 8B 5C 24 30",
    HIST_AOB = IS_ENHANCED
        and "48 63 0D ? ? ? ? 48 8D 15 ? ? ? ? 89 04 8A 8B 05 ? ? ? ? 83 E8 01 B9 13 00 00 00"
        or  "48 8D 15 ? ? ? ? 48 8B 0C F8 48 8B 41 18 48 63 0D",
    HIST_RIP = IS_ENHANCED and 10 or 3,
    resolved   = nil,
    attempts   = 0,
    moduleBase = 0,
    diag       = { toastAt = 0 },
    ISV_SLOT   = 20,
    ISV_PATCH  = { 0xB0, 0x01, 0xC3 },
    SHOT_ISV_VOFF = 0x40,
    isvPatched = {},
    BU_ORIG    = IS_ENHANCED
        and { 0x0F,0x84,0xF1,0x00,0x00,0x00 }
        or  { 0x0F,0x84,0x1A,0x01,0x00,0x00 },
    GCS_AOB    = IS_ENHANCED
        and "B8 01 00 00 00 83 7E 40 FF 74 ? ? ? ? ? ? 79 32 00"
        or  "83 79 40 FF 48 8B F9 74 79",
    GCS_OFF    = IS_ENHANCED and 11 or 9,
    GCS_ORIG   = IS_ENHANCED
        and { 0x48,0x8B,0x4E,0x50,0x80 }
        or  { 0x48,0x8B,0x41,0x50,0x33 },
    GCS_PATCH  = IS_ENHANCED
        and { 0xE9,0x7F,0x00,0x00,0x00 }
        or  { 0xE9,0x6D,0x00,0x00,0x00 },
    gcsAddr    = nil,
    gcsApplied = false,
    gcsHealed  = false,
    HIPRIO_AOB = IS_ENHANCED
        and "41 57 41 56 41 55 41 54 56 57 55 53 48 83 EC 38 48 8B 05 ? ? ? ? F6 80 9D 03 00 00 01"
        or  nil,
    HIPRIO_OFF   = 30,
    HIPRIO_ORIG  = { 0x0F,0x85,0xD9,0x03,0x00,0x00 },
    HIPRIO_PATCH = { 0xE9,0xDA,0x03,0x00,0x00,0x90 },
    hiprioAddr    = nil,
    hiprioApplied = false,
    hiprioHealed  = false,
    hiprioFailed  = false,
    hiprioMiss    = 0,
    OCC_AOB = IS_ENHANCED
        and "4D 89 C6 48 89 D3 48 89 CF E8 E0 FA FF FF 40 B6 01"
        or  "49 8B F0 48 8B DA 48 8B F9 44 0F 29 48 B8 44 0F 29 58 A8 E8 ? ? ? ? 85 C0",
    OCC_OFF   = IS_ENHANCED and -0x52 or -0x28,
    OCC_ORIG  = IS_ENHANCED
        and { 0x41,0x56,0x56 }
        or  { 0x48,0x8B,0xC4 },
    OCC_PATCH = { 0xB0,0x01,0xC3 },
    occAddr    = nil,
    occApplied = false,
    occHealed  = false,
    occFailed  = false,
    occMiss    = 0,
    BU_AOB     = IS_ENHANCED
        and "F3 0F 10 B7 ? ? ? ? 48 8B 07 48 89 F9 FF 90 B0 00 00 00 84 C0"
        or  "48 8B 03 F3 0F 10 B3 ? ? ? ? 48 8B CB FF 90 B0 00 00 00 84 C0",
    BU_JZ_OFF  = 22,
    buAddr     = nil,
    buSaved    = nil,
    buApplied  = false,
    buHealed   = false,
    buMiss     = 0,
    losPatched = false,
    LATCH_SIGS = {
        { name = "low-orbit ShouldUpdate", aob = "83 79 18 00 48 8B D9 ? 0D F6 81 98 02 00 00 01 75 04 32 C0", off = 7,  kind = "flip", orig = {0x76} },
        { name = "orbit ShouldUpdate",     aob = "83 79 18 00 48 8B D9 ? 0D F6 81 6C 02 00 00 01 75 04 32 C0", off = 7,  kind = "flip", orig = {0x76} },
        { name = "mountPart top latch",    aob = "38 4F 28 0F 85 ? ? ? ? 44 84 B3 80 02 00 00", off = 16, kind = "nop6", orig = {0x0F,0x84,0x28,0x04,0x00,0x00} },
        { name = "mountPart mid latch",    aob = "F3 0F 11 44 24 4C 44 84 B3 80 02 00 00", off = 13, kind = "flip", orig = {0x75} },
        { name = "low-orbit orient bail",  aob = "80 7A 28 03 75 10 48 8B CB E8 ? ? ? ? 84 C0", off = 16, kind = "nop6", orig = {0x0F,0x84,0x9A,0x04,0x00,0x00} },
        { name = "low-orbit collide bail", aob = "4C 8D 87 C0 03 00 00 48 8D 55 ? 48 8B CB E8 ? ? ? ? 84 C0", off = 21, kind = "nop6", orig = {0x0F,0x84,0xF1,0x00,0x00,0x00} },
        { name = "heli distance re-plan",  aob = "84 C0 ? 07 80 A3 58 03 00 00 FE", off = 2,  kind = "flip", orig = {0x75} },
        { name = "heli follow sweep bail",  aob = "48 8D 53 60 4C 8D 44 24 20 48 8B CB E8 ?? ?? ?? ?? 84 C0", off = 19, kind = "nop6", orig = {0x0F,0x85,0x2E,0xFA,0xFF,0xFF} },
        { name = "cam-man freeze bail",    aob = "F3 44 0F 10 25 ? ? ? ? F3 0F 10 35 ? ? ? ? F6 83 C8 02 00 00 10", off = 24, kind = "nop6", orig = {0x0F,0x84,0xBF,0xF4,0xFF,0xFF} },
    },
    ENH_LATCH_SIGS = {
        { name = "heli distance re-plan",  aob = "84 C0 ?? 07 80 A6 58 03 00 00 FE",       off = 2,  kind = "flip", orig = {0x75} },
        { name = "cam-man freeze bail",    aob = "F6 81 C8 02 00 00 10",                   off = 7,  kind = "nop6", orig = {0x0F,0x84,0xA0,0x01,0x00,0x00} },
        { name = "cam-man too-far bail",   aob = "F3 0F 59 40 24 44 0F 2E C0",             off = 9,  kind = "nop2", orig = {0x77,0x19} },
        { name = "cam-man too-close bail",  aob = "F3 0F 10 48 20 41 0F 2E C8",             off = 9,  kind = "nop2", orig = {0x77,0x24} },
        { name = "cam-man occlusion bail",  aob = "E8 CA FC FF FF 84 C0",                   off = 7,  kind = "flip", orig = {0x74} },
        { name = "low-orbit ShouldUpdate", aob = "83 79 18 00 ?? 0D F6 86 98 02 00 00 01", off = 4,  kind = "flip", orig = {0x74} },
        { name = "orbit ShouldUpdate",     aob = "56 48 83 EC 20 48 89 CE E8 43 FE FF FF 84 C0", off = 15, kind = "nop2", orig = {0x74,0x33} },
        { name = "mountPart top latch",    aob = "80 7F 28 03 0F 85 ?? ?? ?? ?? F6 86 80 02 00 00 01", off = 17, kind = "nop6", orig = {0x0F,0x84,0xFB,0x02,0x00,0x00} },
        { name = "mountPart mid latch",    aob = "89 DD F6 86 80 02 00 00 01",             off = 9,  kind = "nop6", orig = {0x0F,0x84,0x5B,0x02,0x00,0x00} },
        { name = "low-orbit orient bail",  aob = "0F 84 A6 00 00 00 48 8B 8E 10 02 00 00 80 79 28 03", off = 17, kind = "jmp6", orig = {0x0F,0x85,0xD5,0x00,0x00,0x00}, patched = {0xE9,0xD6,0x00,0x00,0x00,0x90} },
        { name = "low-orbit occlusion bail", aob = "E8 E5 80 FF FF 84 C0", off = 7, kind = "nop2", orig = {0x74,0x51} },
        { name = "low-orbit collide-freeze", aob = "48 8B 86 30 02 00 00 BD 01 00 00 00 0F 2E 40 64",             off = 16, kind = "nop6", orig = {0x0F,0x87,0xA0,0x01,0x00,0x00} },
        { name = "low-orbit close-freeze",   aob = "F3 0F 10 8E 60 02 00 00 48 8B 86 30 02 00 00 F3 0F 59 48 60 0F 2E C8", off = 23, kind = "nop6", orig = {0x0F,0x87,0x0D,0x01,0x00,0x00} },
        { name = "heli follow sweep bail",   aob = "48 8D 54 24 40 48 89 C1 45 31 C0 E8 ?? ?? ?? ?? 84 C0", off = 18, kind = "nop6", orig = {0x0F,0x85,0xA9,0x01,0x00,0x00} },
    },
    latchOffDone = false,
    dirGlobal  = 0,
    timeGlobal = 0,
    histBuf    = 0,
    lock       = nil,
    switch     = { active = false, oldIdx = nil, ticks = 0,
                   pending = false, wantEnter = false, enterTicks = 0, enterWait = 0 },
    SWITCH_CAP = 30,
    swapPending = false,
    swapTicks   = 0,
    SWAP_FIRE   = 6,
    SWAP_HOLD   = 30,
    VEH_CIN_CAM = 80,
    ENTER_GAP   = 30,
    ENTER_TAPS  = 3,
    BIRTH_TICKS = 15,
    birthUntil  = 0,
    frameN      = 0,
    lastVeh     = 0,
    lastVehPtr  = 0,
}

do
    local L = lockCineCam
    scanDoctor.register("LCCDIR", { sig = L.DIR_AOB })
    scanDoctor.register("LCCTMR", { sig = L.TIME_AOB })
    scanDoctor.register("LCCHST", { sig = L.HIST_AOB })
    scanDoctor.register("LCCBU",  { sig = L.BU_AOB })
    scanDoctor.register("LCCGCS", { sig = L.GCS_AOB })
    scanDoctor.register("LCCHP",  { sig = L.HIPRIO_AOB })
    scanDoctor.register("LCCOCC", { sig = L.OCC_AOB })
    local latchCodes = {
        ["low-orbit ShouldUpdate"]   = "LCCLOSU",
        ["orbit ShouldUpdate"]       = "LCCOSU",
        ["mountPart top latch"]      = "LCCMPT",
        ["mountPart mid latch"]      = "LCCMPM",
        ["low-orbit orient bail"]    = "LCCLOOB",
        ["low-orbit collide bail"]   = "LCCLOCB",
        ["low-orbit occlusion bail"] = "LCCLOC",
        ["low-orbit collide-freeze"] = "LCCLOCF",
        ["low-orbit close-freeze"]   = "LCCLOZF",
        ["heli distance re-plan"]    = "LCCHDR",
        ["heli follow sweep bail"]   = "LCCHFS",
        ["cam-man freeze bail"]      = "LCCCMF",
        ["cam-man too-far bail"]     = "LCCCMTF",
        ["cam-man too-close bail"]   = "LCCCMTC",
        ["cam-man occlusion bail"]   = "LCCCMOB",
    }
    for _, sig in ipairs(IS_ENHANCED and L.ENH_LATCH_SIGS or L.LATCH_SIGS) do
        local code = latchCodes[sig.name]
        if code then scanDoctor.register(code, { sig = sig.aob }) end
    end
end

function lockCineCam.plausiblePtr(p)
    return p and p > 0x10000 and p < 0x7FFFFFFFFFFF
end

function lockCineCam.resolve()
    local s = lockCineCam
    if s.resolved == true then return true end
    if s.resolved == false then return false end
    s.attempts = s.attempts + 1
    local dh = Memory.Scan(s.DIR_AOB)
    local th = Memory.Scan(s.TIME_AOB)
    local hh = Memory.Scan(s.HIST_AOB)
    if dh and dh ~= 0 and th and th ~= 0 and hh and hh ~= 0 then
        local dg = Memory.Rip(dh + 3)
        local tg = Memory.Rip(th + 2)
        local hg = Memory.Rip(hh + s.HIST_RIP)
        if dg and dg ~= 0 and tg and tg ~= 0 and hg and hg ~= 0 then
            s.dirGlobal, s.timeGlobal, s.histBuf, s.resolved = dg, tg, hg, true
            return true
        end
    end
    if s.attempts >= 90 then
        s.resolved = false
        logErr("[LockCineCam] AOB scan failed (" ..
            (IS_ENHANCED and "Enhanced" or "Legacy") .. ")")
    end
    return false
end

function lockCineCam.activeCtx()
    local s = lockCineCam
    local dir = Memory.ReadLong(s.dirGlobal)
    if not s.plausiblePtr(dir) then return nil end
    local idx = Memory.ReadInt(dir + s.O_CURRENT)
    if idx < 0 then return nil end
    local count = Memory.ReadInt(dir + s.O_CTX_COUNT) & 0xFFFF
    if idx >= count then return nil end
    local arr = Memory.ReadLong(dir + s.O_CONTEXTS)
    if not s.plausiblePtr(arr) then return nil end
    local ctx = Memory.ReadLong(arr + idx * 8)
    if not s.plausiblePtr(ctx) then return nil end
    return ctx
end

function lockCineCam.gated()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    return PED.IS_PED_IN_ANY_VEHICLE(ped, false)
end

function lockCineCam.shotAt(ctx, idx)
    local s = lockCineCam
    if idx < 0 then return nil end
    local cnt = Memory.ReadInt(ctx + s.O_SHOT_CNT) & 0xFFFF
    if idx >= cnt then return nil end
    local arr = Memory.ReadLong(ctx + s.O_SHOTS)
    if not s.plausiblePtr(arr) then return nil end
    local shot = Memory.ReadLong(arr + idx * 8)
    if not s.plausiblePtr(shot) then return nil end
    return shot
end

function lockCineCam.engage(ctx, idx)
    local s = lockCineCam
    local shot = s.shotAt(ctx, idx)
    if not shot then return false end
    local orig = Memory.ReadInt(shot + s.O_SHOT_PRIO)
    if orig < 0 or orig >= s.PRIO_BOOST then return false end
    Memory.WriteInt(shot + s.O_SHOT_PRIO, s.PRIO_BOOST)
    s.lock = { ctx = ctx, shot = shot, idx = idx, origPrio = orig }
    return true
end

function lockCineCam.disengage()
    local s = lockCineCam
    if s.lock then
        if s.plausiblePtr(s.lock.shot)
            and Memory.ReadInt(s.lock.shot + s.O_SHOT_PRIO) == s.PRIO_BOOST then
            Memory.WriteInt(s.lock.shot + s.O_SHOT_PRIO, s.lock.origPrio)
        end
        s.lock = nil
    end
end

function lockCineCam.fillHistory(hash)
    local s = lockCineCam
    for i = 0, s.HIST_SLOTS - 1 do
        Memory.WriteInt(s.histBuf + i * 4, hash)
    end
end

function lockCineCam.gameBase()
    local s = lockCineCam
    if s.moduleBase ~= 0 then return s.moduleBase end
    local b = Memory.GetBaseAddress("GTA5.exe")
    if b and b > 0x10000 then s.moduleBase = b return b end
    local b2 = Memory.GetBaseAddress()
    if b2 and b2 > 0x10000 then s.moduleBase = b2 return b2 end
    return 0
end

function lockCineCam.patchIsValidFor(ctx, idx)
    local s = lockCineCam
    local shot = s.shotAt(ctx, idx)
    if not shot then return end
    local cam = Memory.ReadLong(shot + s.O_SHOT_CAM)
    if not s.plausiblePtr(cam) then return end
    local vt = Memory.ReadLong(cam)
    if not s.plausiblePtr(vt) then return end
    local fn = Memory.ReadLong(vt + s.ISV_SLOT * 8)
    if not s.plausiblePtr(fn) or s.isvPatched[fn] then return end
    local b0 = Memory.ReadByte(fn) & 0xFF
    if b0 == 0x00 or b0 == 0xCC or b0 == 0xB0 then
        s.isvPatched[fn] = true
        return
    end
    s.isvPatched[fn] = { Memory.ReadByte(fn), Memory.ReadByte(fn + 1), Memory.ReadByte(fn + 2) }
    for i = 1, #s.ISV_PATCH do Memory.WriteByte(fn + i - 1, s.ISV_PATCH[i]) end
    local base = s.gameBase()
    logf("[LockCine] IsValid patched: vtRva=0x%X fnRva=0x%X",
        (vt > base) and (vt - base) or 0, (fn > base) and (fn - base) or 0)
end

function lockCineCam.patchShotValidFor(ctx, idx)
    local s = lockCineCam
    local shot = s.shotAt(ctx, idx)
    if not shot then return end
    local vt = Memory.ReadLong(shot)
    if not s.plausiblePtr(vt) then return end
    local fn = Memory.ReadLong(vt + s.SHOT_ISV_VOFF)
    if not s.plausiblePtr(fn) or s.isvPatched[fn] then return end
    local b0 = Memory.ReadByte(fn) & 0xFF
    if b0 == 0x00 or b0 == 0xCC or b0 == 0xB0 then
        s.isvPatched[fn] = true
        return
    end
    s.isvPatched[fn] = { Memory.ReadByte(fn), Memory.ReadByte(fn + 1), Memory.ReadByte(fn + 2) }
    for i = 1, #s.ISV_PATCH do Memory.WriteByte(fn + i - 1, s.ISV_PATCH[i]) end
    local base = s.gameBase()
    logf("[LockCine] shot IsValid patched: vtRva=0x%X fnRva=0x%X",
        (vt > base) and (vt - base) or 0, (fn > base) and (fn - base) or 0)
end

function lockCineCam.restoreIsValid()
    local s = lockCineCam
    for fn, saved in pairs(s.isvPatched) do
        if type(saved) == "table" then
            for i = 1, #saved do Memory.WriteByte(fn + i - 1, saved[i]) end
        end
    end
    s.isvPatched = {}
end

function lockCineCam.patchBaseUpdate(enable)
    local s = lockCineCam
    if enable then
        s.buHealed = false
        if s.buApplied or s.buFailed then return end
        if not s.buAddr then
            local a = Memory.Scan(s.BU_AOB)
            if a and a ~= 0 then
                s.buAddr, s.buMiss = a + s.BU_JZ_OFF, 0
            else
                s.buMiss = s.buMiss + 1
                if s.buMiss >= s.PATCH_SCAN_TRIES then
                    s.buFailed = true
                    log("[LockCine] BaseUpdate sig not on this build -- giving up (no per-frame rescan)")
                end
                return
            end
        end
        local b0 = Memory.ReadByte(s.buAddr) & 0xFF
        local b1 = Memory.ReadByte(s.buAddr + 1) & 0xFF
        if b0 == 0x0F and b1 == 0x84 then
            s.buSaved = {}
            for i = 0, 5 do
                s.buSaved[i + 1] = Memory.ReadByte(s.buAddr + i)
                Memory.WriteByte(s.buAddr + i, 0x90)
            end
            s.buApplied = true
            if not s.buLogged then
                s.buLogged = true
                log("[LockCine] BaseUpdate LOS-bail NOP'd -- shots no longer tear down")
            end
        elseif b0 == 0x90 and b1 == 0x90 then
            s.buApplied = true
            if not s.buLogged then
                s.buLogged = true
                log("[LockCine] BaseUpdate already NOP'd (adopted)")
            end
        else
            s.buAddr = nil
        end
    else
        if s.buHealed then return end
        s.buHealed = true
        if not s.buAddr and not s.buFailed then
            local a = Memory.Scan(s.BU_AOB)
            if a and a ~= 0 then s.buAddr = a + s.BU_JZ_OFF end
        end
        if s.buAddr and (Memory.ReadByte(s.buAddr) & 0xFF) == 0x90
            and (Memory.ReadByte(s.buAddr + 1) & 0xFF) == 0x90 then
            local src = (type(s.buSaved) == "table") and s.buSaved or s.BU_ORIG
            for i = 1, 6 do Memory.WriteByte(s.buAddr + i - 1, src[i]) end
        end
        s.buSaved, s.buApplied = nil, false
    end
end

function lockCineCam.byteState(addr, orig, patched)
    local isOrig, isPatched = true, true
    for i = 1, #orig do
        local b = Memory.ReadByte(addr + i - 1) & 0xFF
        if b ~= orig[i] then isOrig = false end
        if b ~= patched[i] then isPatched = false end
    end
    return isOrig and "pristine" or (isPatched and "patched" or "other")
end

function lockCineCam.patchNoSwitch(enable)
    local s = lockCineCam
    if enable then
        s.gcsHealed = false
        if s.gcsApplied or s.gcsFailed then return end
        if not s.gcsAddr then
            local a = Memory.Scan(s.GCS_AOB)
            if a and a ~= 0 then
                s.gcsAddr = a + s.GCS_OFF
            else
                s.gcsMiss = (s.gcsMiss or 0) + 1
                if s.gcsMiss >= s.PATCH_SCAN_TRIES then
                    s.gcsFailed = true
                    log("[LockCine] GetChangeShotStatus sig not on this build -- anti-switch unavailable here (no per-frame rescan)")
                end
                return
            end
        end
        local st = s.byteState(s.gcsAddr, s.GCS_ORIG, s.GCS_PATCH)
        if st == "pristine" then
            for i = 1, #s.GCS_PATCH do Memory.WriteByte(s.gcsAddr + i - 1, s.GCS_PATCH[i]) end
            s.gcsApplied = true
            if not s.gcsLogged then
                s.gcsLogged = true
                log("[LockCine] GetChangeShotStatus locked -> no automatic shot switching")
            end
        elseif st == "patched" then
            s.gcsApplied = true
        else
            s.gcsAddr = nil
        end
    else
        if s.gcsHealed then return end
        s.gcsHealed = true
        if not s.gcsAddr and not s.gcsFailed then
            local a = Memory.Scan(s.GCS_AOB)
            if a and a ~= 0 then s.gcsAddr = a + s.GCS_OFF end
        end
        if s.gcsAddr and (s.gcsApplied or s.byteState(s.gcsAddr, s.GCS_ORIG, s.GCS_PATCH) == "patched") then
            for i = 1, #s.GCS_ORIG do Memory.WriteByte(s.gcsAddr + i - 1, s.GCS_ORIG[i]) end
        end
        s.gcsApplied = false
    end
end

function lockCineCam.patchNoHiPrio(enable)
    local s = lockCineCam
    if not s.HIPRIO_AOB then return end
    if enable then
        s.hiprioHealed = false
        if s.hiprioApplied or s.hiprioFailed then return end
        if not s.hiprioAddr then
            local a = Memory.Scan(s.HIPRIO_AOB)
            if a and a ~= 0 then
                s.hiprioAddr = a + s.HIPRIO_OFF
            else
                s.hiprioMiss = (s.hiprioMiss or 0) + 1
                if s.hiprioMiss >= s.PATCH_SCAN_TRIES then
                    s.hiprioFailed = true
                    log("[LockCine] ComputeShouldChangeForHigherPriorityShot sig not on this build -- priority-switch not blocked")
                end
                return
            end
        end
        local st = s.byteState(s.hiprioAddr, s.HIPRIO_ORIG, s.HIPRIO_PATCH)
        if st == "pristine" then
            for i = 1, #s.HIPRIO_PATCH do Memory.WriteByte(s.hiprioAddr + i - 1, s.HIPRIO_PATCH[i]) end
            s.hiprioApplied = true
            log("[LockCine] ComputeShouldChangeForHigherPriorityShot locked -> no priority auto-switch")
        elseif st == "patched" then
            s.hiprioApplied = true
        else
            s.hiprioAddr = nil
        end
    else
        if s.hiprioHealed then return end
        s.hiprioHealed = true
        if not s.hiprioAddr and not s.hiprioFailed then
            local a = Memory.Scan(s.HIPRIO_AOB)
            if a and a ~= 0 then s.hiprioAddr = a + s.HIPRIO_OFF end
        end
        if s.hiprioAddr and (s.hiprioApplied or s.byteState(s.hiprioAddr, s.HIPRIO_ORIG, s.HIPRIO_PATCH) == "patched") then
            for i = 1, #s.HIPRIO_ORIG do Memory.WriteByte(s.hiprioAddr + i - 1, s.HIPRIO_ORIG[i]) end
        end
        s.hiprioApplied = false
    end
end

function lockCineCam.patchOcclusion(enable)
    local s = lockCineCam
    if not s.OCC_AOB then return end
    if enable then
        s.occHealed = false
        if s.occApplied or s.occFailed then return end
        if not s.occAddr then
            local a = Memory.Scan(s.OCC_AOB)
            if a and a ~= 0 then
                s.occAddr = a + s.OCC_OFF
            else
                s.occMiss = (s.occMiss or 0) + 1
                if s.occMiss >= s.PATCH_SCAN_TRIES then
                    s.occFailed = true
                    log("[LockCine] occlusion helper sig not on this build -- occlusion freeze not blocked")
                end
                return
            end
        end
        local st = s.byteState(s.occAddr, s.OCC_ORIG, s.OCC_PATCH)
        if st == "pristine" then
            for i = 1, #s.OCC_PATCH do Memory.WriteByte(s.occAddr + i - 1, s.OCC_PATCH[i]) end
            s.occApplied = true
            log("[LockCine] occlusion helper -> always visible (no camera occlusion freeze)")
        elseif st == "patched" then
            s.occApplied = true
        else
            s.occAddr = nil
        end
    else
        if s.occHealed then return end
        s.occHealed = true
        if not s.occAddr and not s.occFailed then
            local a = Memory.Scan(s.OCC_AOB)
            if a and a ~= 0 then s.occAddr = a + s.OCC_OFF end
        end
        if s.occAddr and (s.occApplied or s.byteState(s.occAddr, s.OCC_ORIG, s.OCC_PATCH) == "patched") then
            for i = 1, #s.OCC_ORIG do Memory.WriteByte(s.occAddr + i - 1, s.OCC_ORIG[i]) end
        end
        s.occApplied = false
    end
end

function lockCineCam.patchLatches(enable)
    local s = lockCineCam
    local sigs = IS_ENHANCED and s.ENH_LATCH_SIGS or s.LATCH_SIGS
    local function siteState(sig)
        local site = sig.addr + sig.off
        local pv = (sig.kind == "nop6" or sig.kind == "nop2") and 0x90 or 0xEB
        local isPristine, isPatched = true, true
        for i = 1, #sig.orig do
            local b  = Memory.ReadByte(site + i - 1) & 0xFF
            local pb = sig.patched and sig.patched[i] or pv
            if b ~= sig.orig[i] then isPristine = false end
            if b ~= pb then isPatched = false end
        end
        return isPristine and "pristine" or (isPatched and "patched" or "other")
    end
    if enable then
        s.latchOffDone = false
        for _, sig in ipairs(sigs) do
            if not sig.applied and not sig.failed then
                if not sig.addr then
                    local a = Memory.Scan(sig.aob)
                    if a and a ~= 0 then
                        sig.addr = a
                    else
                        sig.miss = (sig.miss or 0) + 1
                        if sig.miss >= s.PATCH_SCAN_TRIES then sig.failed = true end
                    end
                end
                if not sig.addr then
                    if not sig.warned then sig.warned = true
                        logf("[LockCine] latch %s: NOT FOUND%s",
                            sig.name, sig.failed and " (giving up)" or "")
                    end
                else
                    local base = s.gameBase()
                    local rva  = (base ~= 0 and sig.addr > base) and (sig.addr - base) or 0
                    local st   = siteState(sig)
                    if st == "pristine" then
                        local site = sig.addr + sig.off
                        if sig.kind == "nop6" then
                            for i = 0, 5 do Memory.WriteByte(site + i, 0x90) end
                        elseif sig.kind == "nop2" then
                            for i = 0, 1 do Memory.WriteByte(site + i, 0x90) end
                        elseif sig.kind == "jmp6" then
                            for i = 1, #sig.patched do Memory.WriteByte(site + i - 1, sig.patched[i]) end
                        else
                            Memory.WriteByte(site, 0xEB)
                        end
                        sig.applied = true
                        if not sig.logged then
                            sig.logged = true
                            logf("[LockCine] latch %s: un-stuck (rva=0x%X %s)", sig.name, rva, sig.kind) end
                    elseif st == "patched" then
                        sig.applied = true
                        if not sig.logged then
                            sig.logged = true
                            logf("[LockCine] latch %s: already applied (adopted, rva=0x%X)", sig.name, rva) end
                    elseif not sig.warned then
                        sig.warned = true
                        logf("[LockCine] latch %s: unexpected bytes rva=0x%X+%d -- skipped", sig.name, rva, sig.off)
                    end
                end
            end
        end
    else
        if s.latchOffDone then return end
        s.latchOffDone = true
        for _, sig in ipairs(sigs) do
            if not sig.addr and not sig.failed then
                local a = Memory.Scan(sig.aob)
                if a and a ~= 0 then sig.addr = a end
            end
            if sig.addr and (sig.applied or siteState(sig) == "patched") then
                local site = sig.addr + sig.off
                for i = 1, #sig.orig do Memory.WriteByte(site + i - 1, sig.orig[i]) end
            end
            sig.applied = false
            sig.warned  = false
        end
    end
end

function lockCineCam.diagToast(msg)
    local s = lockCineCam
    local t = os.clock()
    if t < (s.diag.toastAt or 0) then return end
    s.diag.toastAt = t + 3.0
    GUI.AddToast("LockCine debug", msg, 3000)
end

function lockCineCam.ensureBoost(ctx, idx)
    local s = lockCineCam
    local L = s.lock
    if L and L.ctx == ctx and L.idx == idx then return end
    s.disengage()
    s.engage(ctx, idx)
end

function lockCineCam.onTick(f)
    local s = lockCineCam
    if scriptUnloading then s.forceCleanup() return end
    if not f:IsToggled() or not s.gated() then
        s.switch.active, s.switch.pending, s.switch.wantEnter = false, false, false
        s.swapPending = false
        s.disengage()
        s.restoreIsValid()
        s.patchBaseUpdate(false)
        s.patchLatches(false)
        s.patchNoSwitch(false)
        s.patchNoHiPrio(false)
        s.patchOcclusion(false)
        return
    end
    if not s.resolve() then
        if s.resolved == false then
            s.diagToast("AOB scan FAILED - game build changed? offsets stale")
        end
        return
    end
    s.frameN = s.frameN + 1
    local ctx = s.activeCtx()
    local sw  = s.switch
    local idx = ctx and Memory.ReadInt(ctx + s.O_SHOT_IDX) or nil
    if sw.pending then
        sw.pending = false
        if ctx then
            sw.active, sw.oldIdx, sw.ticks = true, nil, 0
        else
            sw.wantEnter, sw.enterTicks, sw.enterWait = true, 0, 0
        end
    end
    if ctx and (s.lastIdx == nil or idx ~= s.lastIdx) then
        s.birthUntil = s.frameN + s.BIRTH_TICKS
    end
    if ctx then
        local pveh = PED.GET_VEHICLE_PED_IS_IN(
            PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId()), false)
        local pphys = pveh ~= 0 and GTA.HandleToPointer(pveh) or nil
        local pptr  = pphys and pphys:GetAddress() or 0
        if pveh ~= s.lastVeh or pptr ~= s.lastVehPtr then
            if s.lastVeh ~= 0 and pptr ~= 0 then s.swapPending, s.swapTicks = true, 0 end
            s.lastVeh, s.lastVehPtr = pveh, pptr
        end
    end
    local inBirth = sw.active or (ctx ~= nil and s.frameN < s.birthUntil) or false
    s.patchBaseUpdate(not inBirth)
    s.patchLatches(not inBirth)
    if not ctx then
        s.switch.active = false
        s.lastIdx = nil
        s.swapPending = false
        s.disengage()
        if sw.wantEnter then s.enterView() end
        return
    end

    if sw.wantEnter then sw.wantEnter, sw.enterTicks = false, 0 end

    local now = Memory.ReadInt(s.timeGlobal)

    if s.lastIdx ~= nil and idx ~= s.lastIdx and not sw.active and not inBirth and logging.enabled then
        local base  = s.gameBase()
        local shot  = s.shotAt(ctx, idx)
        local cam   = shot and Memory.ReadLong(shot + s.O_SHOT_CAM)
        local vt    = (cam and s.plausiblePtr(cam)) and Memory.ReadLong(cam) or 0
        local isvfn = s.plausiblePtr(vt) and Memory.ReadLong(vt + s.ISV_SLOT * 8) or 0
        local isvB0 = s.plausiblePtr(isvfn) and (Memory.ReadByte(isvfn) & 0xFF) or 0
        local buB0  = s.buAddr and (Memory.ReadByte(s.buAddr) & 0xFF) or 0
        logf("[LockCine] *** SWITCHED idx %d->%d camVt=0x%X IsValid[0]=0x%02X(%s) BaseUpdate[0]=0x%02X(%s)",
            s.lastIdx, idx, (base ~= 0 and vt > base) and (vt - base) or 0,
            isvB0, (isvB0 == 0xB0) and "patched" or "RAW",
            buB0, (buB0 == 0x90) and "NOP" or "RAW")
    end
    s.lastIdx = idx

    if sw.active then
        if sw.oldIdx == nil then
            sw.oldIdx, sw.ticks = idx, 0
            s.disengage()
            local shot = s.shotAt(ctx, idx)
            local meta = shot and Memory.ReadLong(shot + s.O_SHOT_META)
            local hash = (meta and s.plausiblePtr(meta))
                and Memory.ReadInt(meta + s.O_META_NAME) or 0
            s.fillHistory(hash)
            s.patchNoSwitch(false)
            Memory.WriteInt(ctx + s.O_PREV_TIME, 0)
        end
        sw.ticks = sw.ticks + 1
        if idx ~= sw.oldIdx or sw.ticks >= s.SWITCH_CAP then
            sw.active, sw.oldIdx = false, nil
        end
        return
    end

    if s.swapPending then
        s.swapTicks = s.swapTicks + 1
        if s.swapTicks == s.SWAP_FIRE then
            s.restoreIsValid()
            s.patchNoSwitch(false)
            s.disengage()
            s.fillHistory(0)
            Memory.WriteInt(ctx + s.O_PREV_TIME, 0)
            s.birthUntil = s.frameN + s.BIRTH_TICKS
        end
        if s.swapTicks >= s.SWAP_HOLD then
            s.swapPending = false
        else
            return
        end
    end

    s.ensureBoost(ctx, idx)
    s.fillHistory(0)
    Memory.WriteInt(ctx + s.O_PREV_TIME, now)
    s.patchNoSwitch(true)
    s.patchNoHiPrio(true)
    s.patchOcclusion(true)
    s.patchIsValidFor(ctx, idx)
    s.patchShotValidFor(ctx, idx)
end

function lockCineCam.forceCleanup()
    local s = lockCineCam
    s.buHealed, s.gcsHealed, s.hiprioHealed, s.occHealed = false, false, false, false
    s.latchOffDone = false
    s.switch.active, s.switch.pending, s.switch.wantEnter = false, false, false
    s.swapPending = false
    s.disengage()
    s.restoreIsValid()
    s.patchBaseUpdate(false)
    s.patchLatches(false)
    s.patchNoSwitch(false)
    s.patchNoHiPrio(false)
    s.patchOcclusion(false)
end
function lockCineCam.doSwitch()
    local f = FeatureMgr.GetFeature(H.LOCK_CINE_CAM)
    if not (f and f:IsToggled()) then
        GUI.AddToast("VibeScript", "Enable Lock Cinematic Camera first.", 2500)
        return
    end
    lockCineCam.switch.pending = true
end

function lockCineCam.enterView()
    local s = lockCineCam
    local sw = s.switch
    if sw.enterWait > 0 then sw.enterWait = sw.enterWait - 1 return end
    if sw.enterTicks >= s.ENTER_TAPS then sw.wantEnter = false return end
    sw.enterTicks = sw.enterTicks + 1
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(0, s.VEH_CIN_CAM, 1.0)
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, s.VEH_CIN_CAM, 1.0)
    sw.enterWait = s.ENTER_GAP
end

centralOnTick(FeatureMgr.AddFeature(H.LOCK_CINE_CAM, "Lock Cinematic Camera", eFeatureType.Toggle,
    "Holds the current cinematic camera angle instead of letting the game cycle through them.",
    lockCineCam.onTick)
    :SetNoCallbackOnPress(true)
    :SetSaveable(false))

FeatureMgr.AddFeature(H.LOCK_CINE_CAM_SWITCH, "Switch Cinematic Angle", eFeatureType.Button,
    "Manually change to the next cinematic camera angle while Lock Cinematic Camera is on.",
    function() lockCineCam.doSwitch() end)
    :SetSaveable(false)

ClickGUI.AddTab("VibeScript", function()
    if ImGui.BeginTabBar("##VS_MainTabBar", ImGuiTabBarFlags.Reorderable) then

        ImGui.PushID("TAB_Self")
        if ImGui.BeginTabItem("Self") then
            if ImGui.BeginTable("##VS_SelfTabColumns", 2, ImGuiTableFlags.SizingStretchSame) then
                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.PushID("SelfGeneral")
                if ClickGUI.BeginCustomChildWindow("General") then
                    ClickGUI.RenderFeature(H.BETTER_ESC_ENGINE)
                    ClickGUI.RenderFeature(H.YOGA_RUN)
                    if DEV.renderSelfGeneralExtras then DEV.renderSelfGeneralExtras() end
                    ClickGUI.RenderFeature(H.PAUSED_SPOOF)
                    ClickGUI.RenderFeature(H.PASSIVE_SPOOF)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("Waypoints")
                if ClickGUI.BeginCustomChildWindow("Waypoints") then
                    ClickGUI.RenderFeature(H.WP_INTERIOR)
                    ClickGUI.RenderFeature(H.WP_INSIDE_INT)
                    ClickGUI.RenderFeature(H.AUTO_TP_OBJECTIVE)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.TableSetColumnIndex(1)
                ImGui.PushID("Rewind")
                if ClickGUI.BeginCustomChildWindow("Rewind") then
                    ClickGUI.RenderFeature(H.REWIND)
                    ClickGUI.RenderFeature(H.REWIND_LENGTH)
                    ClickGUI.RenderFeature(H.REWIND_SPEED)
                    ImGui.Separator()
                    do
                        local rs = rewindState
                        if VIBESCRIPT_REWIND_BINDING_RENDER then
                            pcall(VIBESCRIPT_REWIND_BINDING_RENDER)
                        else
                            local keyFeat = FeatureMgr.GetFeature(H.REWIND_KEY)
                            if rs.captureState == "snapshot" then
                                rs.captureHeld = {}
                                for vk = 1, 255 do
                                    if Utils.IsKeyDown(vk) then rs.captureHeld[vk] = true end
                                end
                                rs.captureState = true
                            elseif rs.captureState then
                                ImGui.Text(">> Press a key... <<")
                                for vk = 1, 255 do
                                    if vk > 6 and not rs.captureHeld[vk] and Utils.IsKeyDown(vk) then
                                        rs.rewindVK = vk
                                        if keyFeat then keyFeat:SetIntValue(vk) end
                                        rs.captureState = nil
                                        rs.captureHeld = nil
                                        break
                                    end
                                end
                            else
                                if ImGui.Button("Change", 80, 0) then
                                    rs.captureState = "snapshot"
                                end
                                ImGui.SameLine()
                                ImGui.Text("Rewind Key: " .. (rs.VK_NAMES[rs.rewindVK] or ("Key 0x%02X"):format(rs.rewindVK)))
                                ImGui.SameLine()
                                if ImGui.SmallButton("Reset") then
                                    rs.rewindVK = rs.VK_BACKSPACE
                                    if keyFeat then keyFeat:SetIntValue(rs.VK_BACKSPACE) end
                                end
                            end
                        end

                        ImGui.PushItemWidth(120)
                        if ImGui.BeginCombo("Rewind Button", controllerButtonName(rs.controlId)) then
                            for _, btn in ipairs(CONTROLLER_BUTTONS) do
                                if ImGui.Selectable(btn.name, btn.id == rs.controlId) then
                                    rs.controlId = btn.id
                                end
                            end
                            ImGui.EndCombo()
                        end
                        ImGui.PopItemWidth()
                        ImGui.SameLine()
                        if ImGui.SmallButton("Reset##rwctrl") then
                            rs.controlId = rs.DEFAULT_CONTROL
                        end
                    end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("LockCineCam")
                if ClickGUI.BeginCustomChildWindow("Lock Cinematic Camera") then
                    ClickGUI.RenderFeature(H.LOCK_CINE_CAM)
                    ClickGUI.RenderFeature(H.LOCK_CINE_CAM_SWITCH)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.EndTable()
            end
            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.PushID("TAB_Vehicle")
        if ImGui.BeginTabItem("Vehicle") then
            local fl = ImGuiTableFlags.SizingStretchSame

            if ImGui.BeginTable("##VS_VehicleTabColumns", 2, fl) then
                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)

                ImGui.PushID("General")
                if ClickGUI.BeginCustomChildWindow("General") then
                    ClickGUI.RenderFeature(H.FLY_WINDSCREEN)
                    ClickGUI.RenderFeature(H.WEAPON_WHEEL)
                    ClickGUI.RenderFeature(H.RICK_ROLL_HORN)
                    if DEV.renderVehicleGeneralExtras then DEV.renderVehicleGeneralExtras() end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                if ClickGUI.BeginCustomChildWindow("Vehicle Projectile Mods") then
                    ClickGUI.RenderFeature(H.RAPID_FIRE)
                    ClickGUI.RenderFeature(H.NOCLIP_ROCKETS)
                    ClickGUI.RenderFeature(H.VEH_INF_AMMO)
                    ClickGUI.RenderFeature(H.AUTO_LOCKON_FIRE)
                    ClickGUI.RenderFeature(H.INSTANT_ROCKET)
                    ClickGUI.RenderFeature(H.INSTANT_LOCKON)
                    ClickGUI.RenderFeature(H.LOCK_ONTO_PLAYERS)
                    ClickGUI.RenderFeature(H.LOCK_ONTO_NPCS)
                    ClickGUI.RenderFeature(H.DISABLE_LOS)
                    ClickGUI.RenderFeature(H.INF_LOCKON_RANGE)
                    ClickGUI.RenderFeature(H.ROCKET_SPEED)
                    ClickGUI.RenderFeature(H.INFINITE_RANGE)
                    ClickGUI.EndCustomChildWindow()
                end

                ImGui.PushID("TurnAssist")
                if ClickGUI.BeginCustomChildWindow("Turn Assist") then
                    ClickGUI.RenderFeature(H.JTURN)
                    ClickGUI.RenderFeature(H.LTURN)
                    ClickGUI.RenderFeature(H.TURN_LEFT)
                    ClickGUI.RenderFeature(H.TURN_RIGHT)
                    ImGui.Separator()
                    ClickGUI.RenderFeature(H.TURN_SPIN_FORCE)
                    ClickGUI.RenderFeature(H.TURN_BOOST_FORCE)
                    ClickGUI.RenderFeature(H.TURN_POP)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("DriftAssist")
                if ClickGUI.BeginCustomChildWindow("Drift Assist") then
                    ClickGUI.RenderFeature(H.DRIFT_ASSIST)
                    ClickGUI.RenderFeature(H.DRIFT_TRACTION)
                    ClickGUI.RenderFeature(H.DRIFT_FORCE)
                    ClickGUI.RenderFeature(H.DRIFT_POWER)
                    ClickGUI.RenderFeature(H.DRIFT_SCORE)
                    ClickGUI.RenderFeature(H.DRIFT_SMOKE)
                    ClickGUI.RenderFeature(H.DRIFT_EXIT_BOOST)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.TableSetColumnIndex(1)

                ImGui.PushID("SuperDrive")
                if ClickGUI.BeginCustomChildWindow("SuperDrive") then
                    ClickGUI.RenderFeature(H.SUPERDRIVE)
                    ClickGUI.RenderFeature(H.SUPERDRIVE_MULT)
                    ClickGUI.RenderFeature(H.SUPERDRIVE_CAM)
                    ImGui.Separator()
                    do
                        local sdk = superDriveKey
                        local VK_NAMES = rewindState.VK_NAMES
                        if sdk.captureState == "snapshot" then
                            sdk.captureHeld = {}
                            for vk = 1, 255 do
                                if isAnyKeyDown(vk) then sdk.captureHeld[vk] = true end
                            end
                            sdk.captureState = true
                        elseif sdk.captureState then
                            ImGui.Text(">> Press a key... <<")
                            for vk = 1, 255 do
                                local down = isAnyKeyDown(vk)
                                if sdk.captureHeld[vk] and not down then
                                    sdk.captureHeld[vk] = nil
                                end
                                if not sdk.captureHeld[vk] and down then
                                    sdk.vk = vk
                                    sdk.captureState = nil
                                    sdk.captureHeld = nil
                                    break
                                end
                            end
                        else
                            if ImGui.Button("Change", 80, 0) then
                                sdk.captureState = "snapshot"
                            end
                            ImGui.SameLine()
                            ImGui.Text("Boost Key: " .. (VK_NAMES[sdk.vk] or ("Key 0x%02X"):format(sdk.vk)))
                            ImGui.SameLine()
                            if ImGui.SmallButton("Reset") then
                                sdk.vk = sdk.DEFAULT_VK
                            end

                            ImGui.PushItemWidth(120)
                            if ImGui.BeginCombo("Boost Button", controllerButtonName(sdk.controlId)) then
                                for _, btn in ipairs(CONTROLLER_BUTTONS) do
                                    if ImGui.Selectable(btn.name, btn.id == sdk.controlId) then
                                        sdk.controlId = btn.id
                                    end
                                end
                                ImGui.EndCombo()
                            end
                            ImGui.PopItemWidth()
                            ImGui.SameLine()
                            if ImGui.SmallButton("Reset##ctrl") then
                                sdk.controlId = sdk.DEFAULT_CONTROL
                            end
                        end
                    end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("Wheelie")
                if ClickGUI.BeginCustomChildWindow("Wheelie") then
                    ClickGUI.RenderFeature(H.WHEELIE)
                    ClickGUI.RenderFeature(H.WHEELIE_STRENGTH)
                    ImGui.Separator()
                    do
                        local wk = wheelie
                        local VK_NAMES = rewindState.VK_NAMES
                        if wk.captureState == "snapshot" then
                            wk.captureHeld = {}
                            for vk = 1, 255 do
                                if isAnyKeyDown(vk) then wk.captureHeld[vk] = true end
                            end
                            wk.captureState = true
                        elseif wk.captureState then
                            ImGui.Text(">> Press a key... <<")
                            for vk = 1, 255 do
                                local down = isAnyKeyDown(vk)
                                if wk.captureHeld[vk] and not down then
                                    wk.captureHeld[vk] = nil
                                end
                                if not wk.captureHeld[vk] and down then
                                    wk.vk = vk
                                    wk.captureState = nil
                                    wk.captureHeld = nil
                                    break
                                end
                            end
                        else
                            if ImGui.Button("Change##wkb", 80, 0) then
                                wk.captureState = "snapshot"
                            end
                            ImGui.SameLine()
                            ImGui.Text("Key: " .. (VK_NAMES[wk.vk] or ("Key 0x%02X"):format(wk.vk)))
                            ImGui.SameLine()
                            if ImGui.SmallButton("Reset##wkb") then
                                wk.vk = wk.DEFAULT_VK
                            end

                            local btnName = ("Ctrl %d"):format(wk.controlId)
                            for _, b in ipairs(wk.BUTTONS) do
                                if b.id == wk.controlId then btnName = b.name; break end
                            end
                            ImGui.PushItemWidth(100)
                            if ImGui.BeginCombo("Button", btnName) then
                                for _, btn in ipairs(wk.BUTTONS) do
                                    if ImGui.Selectable(btn.name, btn.id == wk.controlId) then
                                        wk.controlId = btn.id
                                    end
                                end
                                ImGui.EndCombo()
                            end
                            ImGui.PopItemWidth()
                            ImGui.SameLine()
                            if ImGui.SmallButton("Reset##wctrl") then
                                wk.controlId = wk.DEFAULT_CONTROL
                            end


                        end
                    end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("EnginePower")
                if ClickGUI.BeginCustomChildWindow("Engine Power") then
                    ClickGUI.RenderFeature(H.ENGINE_POWER)
                    ClickGUI.RenderFeature(H.ENGINE_POWER_MULT)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("NerfRemovals")
                if ClickGUI.BeginCustomChildWindow("Nerf Removals") then
                    ClickGUI.RenderFeature(H.OPP_NERF)
                    ClickGUI.RenderFeature(H.ALL_ROCKETS)
                    ClickGUI.RenderFeature(H.LAZER_NERF)

                    local expPreview = lazerExpTag.labels[lazerExpTag.idx]
                        or lazerExpTag.labels[1]
                    if ImGui.BeginCombo("Cannon Explosion", expPreview) then
                        for i, name in ipairs(lazerExpTag.labels) do
                            local selected = (i == lazerExpTag.idx)
                            if ImGui.Selectable(name, selected) then
                                lazerExpTag.idx = i
                            end
                        end
                        ImGui.EndCombo()
                    end

                    ClickGUI.RenderFeature(H.CANNON_RANGE)
                    if DEV.renderTitanCannonStuff then DEV.renderTitanCannonStuff() end
                    if DEV.renderTitanProbeBlock then DEV.renderTitanProbeBlock() end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.EndTable()
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.PushID("TAB_Weapon")
        if ImGui.BeginTabItem("Weapon") then
            local fl = ImGuiTableFlags.SizingStretchSame

            if ImGui.BeginTable("##VS_WeaponTabColumns", 2, fl) then
                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)

                ImGui.PushID("VehicleGun")
                if ClickGUI.BeginCustomChildWindow("Vehicle Gun") then
                    ClickGUI.RenderFeature(H.VEH_GUN)
                    ClickGUI.RenderFeature(H.VEH_GUN_IN_VEH)
                    ClickGUI.RenderFeature(H.VEH_GUN_RANDOM)
                    ClickGUI.RenderFeature(H.VEH_GUN_RAND_AIR)
                    ClickGUI.RenderFeature(H.VEH_GUN_RAND_SEA)

                    local classNames = {}
                    for i, cls in ipairs(VEH_CLASSES) do
                        classNames[i] = cls.name
                    end
                    local classPreview = classNames[vehGun.classIdx] or "Super"
                    if ImGui.BeginCombo("Class", classPreview) then
                        for i, name in ipairs(classNames) do
                            local selected = (i == vehGun.classIdx)
                            if ImGui.Selectable(name, selected) then
                                vehGun.classIdx = i
                                vehGun.vehIdx = 1
                            end
                        end
                        ImGui.EndCombo()
                    end

                    local cls = VEH_CLASSES[vehGun.classIdx]
                    if cls then
                        local vehPreview = cls.vehicles[vehGun.vehIdx] or cls.vehicles[1]
                        if ImGui.BeginCombo("Vehicle", vehPreview) then
                            for i, name in ipairs(cls.vehicles) do
                                local selected = (i == vehGun.vehIdx)
                                if ImGui.Selectable(name, selected) then
                                    vehGun.vehIdx = i
                                end
                            end
                            ImGui.EndCombo()
                        end
                    end

                    ClickGUI.RenderFeature(H.VEH_GUN_SPEED)
                    ClickGUI.RenderFeature(H.VEH_GUN_DIST)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.TableSetColumnIndex(1)

                ImGui.PushID("GravityGun")
                if ClickGUI.BeginCustomChildWindow("Improved Gravity Gun") then
                    ClickGUI.RenderFeature(H.GRAVITY_GUN)
                    ClickGUI.RenderFeature(H.GRAV_FORCE)
                    ClickGUI.RenderFeature(H.GRAV_CONTRIVED)
                    ClickGUI.RenderFeature(H.GRAV_COLLISION)
                    ClickGUI.RenderFeature(H.GRAV_IN_VEH)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("SuperMelee")
                if ClickGUI.BeginCustomChildWindow("Super Melee") then
                    ClickGUI.RenderFeature(H.SUPER_MELEE)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                if DEV.renderOnFootWeaponsPanel then DEV.renderOnFootWeaponsPanel() end

                ImGui.EndTable()
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.PushID("TAB_Session")
        if ImGui.BeginTabItem("Session") then
            if ClickGUI.BeginCustomChildWindow("Session Kickers") then
                ClickGUI.RenderFeature(H.FRENCH_KICKER)
                ClickGUI.RenderFeature(H.FRENCH_REGIONS)
                ImGui.Separator()
                ClickGUI.RenderFeature(H.CHINESE_KICKER)
                ClickGUI.RenderFeature(H.CHINESE_REGIONS)
                ImGui.Separator()
                ClickGUI.RenderFeature(H.MY_COUNTRY_ONLY)
                ImGui.Separator()
                ClickGUI.RenderFeature(H.VPN_KICKER)
                ImGui.Separator()
                ClickGUI.RenderFeature(H.RELAY_KICKER)
                if DEV.renderSessionExtras then DEV.renderSessionExtras() end
                ClickGUI.EndCustomChildWindow()
            end
            if ClickGUI.BeginCustomChildWindow("Messaging") then
                local cur = FeatureMgr.GetFeatureString(H.SMS_BCAST_MSG) or ""
                local overLimit = #cur > 60
                if overLimit then ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.35, 0.35, 1.0) end
                ImGui.SetNextItemWidth(-1)
                local hint = "Type a broadcast SMS (max 60)..."
                local newText = ImGui.InputTextWithHint("##sms_bcast",
                    #cur > #hint and "" or hint, cur, ImGuiInputTextFlags.AutoSelectAll)
                if overLimit then ImGui.PopStyleColor() end
                if newText ~= cur then
                    FeatureMgr.GetFeature(H.SMS_BCAST_MSG):SetStringValue(newText)
                    FeatureMgr.GetFeature(H.SMS_BCAST_STATUS):SetStringValue("")
                end
                if #newText > 60 then
                    ImGui.PushTextWrapPos(0)
                    ImGui.TextColored(255, 170, 60, 255,
                        string.format("Over 60 characters (%d) - shorten to send", #newText))
                    ImGui.PopTextWrapPos()
                else
                    ClickGUI.RenderFeature(H.SMS_BCAST)
                    ImGui.SameLine()
                    ClickGUI.RenderFeature(H.SMS_KEEP_TEXT)
                    local note = FeatureMgr.GetFeatureString(H.SMS_BCAST_STATUS) or ""
                    if note ~= "" then
                        ImGui.PushTextWrapPos(0)
                        ImGui.TextColored(255, 90, 90, 255, note)
                        ImGui.PopTextWrapPos()
                    end
                end
                ClickGUI.EndCustomChildWindow()
            end
            if ClickGUI.BeginCustomChildWindow("Bounty") then
                ClickGUI.RenderFeature(H.BOUNTY_AMOUNT)
                ClickGUI.RenderFeature(H.SET_BOUNTY_ALL_NPC)
                ClickGUI.RenderFeature(H.SET_BOUNTY_ALL_OWNED)
                ClickGUI.EndCustomChildWindow()
            end
            ImGui.Separator()
            ImGui.Text("Session Census")
            ImGui.Separator()
            renderCensusPie()
            ImGui.Separator()
            if ImGui.BeginChild("##SessionCensus", -1, 150, true, 0) then
                renderCensusPlayers()
            end
            ImGui.EndChild()
            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.PushID("TAB_Console")
        if ImGui.BeginTabItem("Console") then
            console.enabled, _ = ImGui.Checkbox("Enable Console", console.enabled)
            if VIBESCRIPT_LOADER then
                ImGui.SameLine()
                logging.toasts, _ = ImGui.Checkbox("Debug Toasts", logging.toasts)
            end
            ImGui.SameLine()
            ImGui.SetNextItemWidth(80)
            local newLines, _ = ImGui.InputInt("Lines", console.maxLines, 0, 0)
            if newLines ~= console.maxLines then
                console.maxLines = math.max(50, math.min(newLines, console.MAX_LINES_CAP))
                console.lastRefresh = 0
            end

            if not console.enabled then
                ImGui.TextDisabled("Console disabled - enable to read logs")
            else
                readCheraxLog()
                local avail_x, avail_y = ImGui.GetContentRegionAvail()
                ImGui.InputTextMultiline("##VSConsole", console.cache,
                    avail_x, avail_y, ImGuiInputTextFlags.ReadOnly)
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        if DEV.renderDebugTab then DEV.renderDebugTab() end

        ImGui.PushID("TAB_Settings")
        if ImGui.BeginTabItem("Settings") then
            ImGui.Spacing()
            ImGui.Text("Save your current feature states and slider values,")
            ImGui.Text("or restore everything back to defaults.")
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            local prev = settings.autoload
            settings.autoload, _ = ImGui.Checkbox("Load Settings On Startup", settings.autoload)
            if settings.autoload ~= prev then
                pcall(FileMgr.WriteFileContent, settings.autoloadFile, settings.autoload and "1" or "0", false)
            end

            local prevIntro = settings.introEnabled
            settings.introEnabled, _ = ImGui.Checkbox("Play Intro Animation", settings.introEnabled)
            if settings.introEnabled ~= prevIntro then
                pcall(FileMgr.WriteFileContent, settings.introFile, settings.introEnabled and "1" or "0", false)
            end
            ImGui.SameLine()
            ImGui.TextDisabled("(applies on next inject)")

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            if ImGui.Button("Save Settings", 200, 30) then
                saveSettings()
            end
            ImGui.SameLine()
            ImGui.TextDisabled("(saves toggles, sliders, vehicle gun selection)")

            ImGui.Spacing()

            if ImGui.Button("Load Settings", 200, 30) then
                loadSettings()
            end
            ImGui.SameLine()
            if FileMgr.DoesFileExist(settings.file) then
                ImGui.TextDisabled("(saved settings found)")
            else
                ImGui.TextDisabled("(no saved settings)")
            end

            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            if ImGui.Button("Restore Defaults", 200, 30) then
                restoreDefaults()
            end
            ImGui.SameLine()
            ImGui.TextDisabled("(resets everything to defaults, keeps saved config)")

            ImGui.Spacing()

            if ImGui.Button("Delete Saved Settings", 200, 30) then
                deleteSavedSettings()
            end
            ImGui.SameLine()
            ImGui.TextDisabled("(resets to defaults and deletes config file)")

            if #settings.status > 0 then
                ImGui.Spacing()
                ImGui.Separator()
                ImGui.Spacing()
                ImGui.Text(settings.status)
            end

            do
                ImGui.Spacing()
                ImGui.Separator()
                ImGui.Spacing()
                local running = doomLauncher.isRunning()
                local busy = (doomLauncher.phase == "downloading" or doomLauncher.phase == "launching")
                local label = running and "Stop DOOM" or (busy and "Working..." or "DOOM")
                if ImGui.Button(label, 200, 30) then
                    if not busy then doomLauncher.toggle() end
                end
                ImGui.SameLine()
                if #doomLauncher.status > 0 then
                    ImGui.TextDisabled(doomLauncher.status)
                elseif running then
                    ImGui.TextDisabled("(running, close the menu to play)")
                else
                    ImGui.TextDisabled("(rip and tear)")
                end
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.EndTabBar()
    end

    local versionText = "v" .. VIBE_VERSION
    local textWidth = ImGui.CalcTextSize(versionText)
    local availWidth = ImGui.GetContentRegionAvail()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + availWidth - textWidth)
    ImGui.TextDisabled(versionText)
end)

ClickGUI.AddPlayerTab("VibeScript", function()
    local playerId = Utils.GetSelectedPlayer()
    ImGui.PushID("VS_Player")

    if ImGui.BeginTabBar("##VS_PlayerTabBar", ImGuiTabBarFlags.Reorderable) then
        ImGui.PushID("TAB_PlayerTrolling")
        if ImGui.BeginTabItem("Trolling") then
            local fl = ImGuiTableFlags.SizingStretchSame

            if ImGui.BeginTable("##VS_PlayerTrollingColumns", 2, fl) then
                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)

                ImGui.PushID("PlayerVehicle")
                if ClickGUI.BeginCustomChildWindow("Vehicle") then
                    if DEV.renderPlayerVehicleExtras then DEV.renderPlayerVehicleExtras(playerId) end
                    ClickGUI.RenderFeature(H.STRIP_VEH_GOD, playerId)
                    ClickGUI.RenderFeature(H.DETACH_WING, playerId)
                    ClickGUI.RenderFeature(H.BREAK_TAIL_BOOM, playerId)
                    ClickGUI.RenderFeature(H.DESTROY_AIR_PROPS, playerId)
                    ClickGUI.RenderFeature(H.DISMANTLE_VEHICLE, playerId)
                    ClickGUI.RenderFeature(H.BLACK_ICE, playerId)
                    ClickGUI.RenderFeature(H.PHANTOM_BRAKE, playerId)
                    ClickGUI.RenderFeature(H.PHANTOM_MIN, playerId)
                    ClickGUI.RenderFeature(H.PHANTOM_MAX, playerId)
                    if DEV.renderPlayerPhantomBrakeDur then DEV.renderPlayerPhantomBrakeDur(playerId) end
                    if DEV.renderPlayerVehicleSteerInvert then DEV.renderPlayerVehicleSteerInvert(playerId) end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("PlayerBounty")
                if ClickGUI.BeginCustomChildWindow("Bounty") then
                    ClickGUI.RenderFeature(H.BOUNTY_AMOUNT)
                    ClickGUI.RenderFeature(H.SET_BOUNTY_NPC, playerId)
                    ClickGUI.RenderFeature(H.SET_BOUNTY_OWNED, playerId)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.TableSetColumnIndex(1)

                ImGui.PushID("PlayerJets")
                if ClickGUI.BeginCustomChildWindow("Jets") then
                    ClickGUI.RenderFeature(H.WATCH_YO_JET, playerId)
                    ClickGUI.RenderFeature(H.WATCH_YO_JET_FU, playerId)
                    ClickGUI.RenderFeature(H.WATCH_YO_JET_DEL, playerId)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("PlayerChimpSwarm")
                if ClickGUI.BeginCustomChildWindow("Chimp Swarm") then
                    ClickGUI.RenderFeature(H.CHIMP_SWARM, playerId)
                    ClickGUI.RenderFeature(H.CHIMP_DEL, playerId)
                    ClickGUI.RenderFeature(H.CHIMP_COUNT)
                    ClickGUI.RenderFeature(H.CHIMP_DIST)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("PlayerTrolling")
                if ClickGUI.BeginCustomChildWindow("Trolling") then
                    ClickGUI.RenderFeature(H.REMOVE_PASSIVE, playerId)
                    ClickGUI.RenderFeature(H.JOIN_CEO, playerId)
                    if DEV.renderPlayerTrollingExtras then DEV.renderPlayerTrollingExtras(playerId) end
                    ClickGUI.RenderFeature(H.KICK_INTERIOR, playerId)
                    ClickGUI.RenderFeature(H.ENTER_INTERIOR, playerId)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                if DEV.renderPlayerDebugPanel then DEV.renderPlayerDebugPanel(playerId) end

                ImGui.EndTable()
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.PushID("TAB_PlayerFriendly")
        if ImGui.BeginTabItem("Friendly") then
            local fl = ImGuiTableFlags.SizingStretchSame

            if ImGui.BeginTable("##VS_PlayerFriendlyColumns", 2, fl) then
                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)

                ImGui.PushID("PlayerMovement")
                if ClickGUI.BeginCustomChildWindow("Movement") then
                    ClickGUI.RenderFeature(H.PLAYER_SPEED, playerId)
                    ClickGUI.RenderFeature(H.PLAYER_SPEED_MULT, playerId)
                    ClickGUI.RenderFeature(H.PLAYER_SPEED_SYNC, playerId)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                if VIBESCRIPT_LOADER then
                    ImGui.PushID("PlayerDriftAssist")
                    if ClickGUI.BeginCustomChildWindow("Drift Assist") then
                        ClickGUI.RenderFeature(H.DRIFT_TARGET, playerId)
                        ClickGUI.RenderFeature(H.DRIFT_TARGET_TR, playerId)
                        ClickGUI.RenderFeature(H.DRIFT_TARGET_F, playerId)
                        ClickGUI.EndCustomChildWindow()
                    end
                    ImGui.PopID()
                end

                ImGui.TableSetColumnIndex(1)

                ImGui.PushID("PlayerVehicleGun")
                if ClickGUI.BeginCustomChildWindow("Vehicle Gun") then
                    ClickGUI.RenderFeature(H.VEH_GUN_TARGET, playerId)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.PushID("PlayerMessaging")
                if ClickGUI.BeginCustomChildWindow("Messaging") then
                    local cur = FeatureMgr.GetFeatureString(H.SMS_MSG, playerId) or ""
                    local overLimit = #cur > 60
                    if overLimit then ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.35, 0.35, 1.0) end
                    ImGui.SetNextItemWidth(-1)
                    local hint = "Type an SMS (max 60)..."
                    local newText = ImGui.InputTextWithHint("##sms_msg_" .. playerId,
                        #cur > #hint and "" or hint, cur, ImGuiInputTextFlags.AutoSelectAll)
                    if overLimit then ImGui.PopStyleColor() end
                    if newText ~= cur then
                        FeatureMgr.GetFeature(H.SMS_MSG, playerId):SetStringValue(newText)
                        FeatureMgr.GetFeature(H.SMS_STATUS, playerId):SetStringValue("")
                    end
                    if #newText > 60 then
                        ImGui.PushTextWrapPos(0)
                        ImGui.TextColored(255, 170, 60, 255,
                            string.format("Over 60 characters (%d) - shorten to send", #newText))
                        ImGui.PopTextWrapPos()
                    else
                        ClickGUI.RenderFeature(H.SMS_SEND, playerId)
                        ImGui.SameLine()
                        ClickGUI.RenderFeature(H.SMS_KEEP_TEXT)
                        local note = FeatureMgr.GetFeatureString(H.SMS_STATUS, playerId) or ""
                        if note ~= "" then
                            ImGui.PushTextWrapPos(0)
                            ImGui.TextColored(255, 90, 90, 255, note)
                            ImGui.PopTextWrapPos()
                        end
                    end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.PopID()

                ImGui.EndTable()
            end

            ImGui.EndTabItem()
        end
        ImGui.PopID()

        ImGui.EndTabBar()
    end

    ImGui.PopID()
end)

if settings.autoload and FileMgr.DoesFileExist(settings.file) then
    loadSettings()
end

if settings.loadKeybinds then settings.loadKeybinds() end
settings._kbReloadAt = Time.GetEpocheMs() + 1500

local telemetry = {
    BEAT_URL     = "https://bladscript-telemetry.toasterboi.workers.dev/beat",
    INTERVAL_SEC = 30,
    WARMUP_SEC   = 10,
    ENABLED      = true,
    SALT         = "bladscript-telemetry-v1",
}

local TELEMETRY_FEATURES = {
    H.RAPID_FIRE,       H.ONFOOT_RAPID,     H.ONFOOT_HOMING_SPAM, H.ROCKET_SPEED,     H.INFINITE_RANGE,   H.INSTANT_ROCKET,
    H.INSTANT_LOCKON,   H.AUTO_LOCKON_FIRE, H.GRAVITY_GUN,      H.GRAV_CONTRIVED,
    H.GRAV_COLLISION,   H.GRAV_IN_VEH,      H.SUPERDRIVE,       H.SUPERDRIVE_CAM,
    H.ENGINE_POWER,     H.VEH_GUN,          H.VEH_GUN_RANDOM,   H.VEH_GUN_RAND_AIR,
    H.VEH_GUN_RAND_SEA, H.VEH_GUN_IN_VEH,   H.DRIFT_ASSIST,     H.DRIFT_SCORE,
    H.DRIFT_SMOKE,      H.DRIFT_EXIT_BOOST, H.FLY_WINDSCREEN,   H.BETTER_ESC_ENGINE,
    H.PAUSED_SPOOF,     H.FRENCH_KICKER,    H.CHINESE_KICKER,
    H.MY_COUNTRY_ONLY,  H.VPN_KICKER,       H.RELAY_KICKER,     H.WEAPON_WHEEL,
    H.RAGDOLL_FIX,      H.REWIND,           H.OPP_NERF,         H.LAZER_NERF,
    H.ALL_ROCKETS,      H.CANNON_RANGE,      H.TITAN_DRIVER_WEAPONS,
    H.TITAN_PROBE,      H.TITAN_CANNON_CYCLE,
    H.LOCK_ONTO_PLAYERS, H.LOCK_ONTO_NPCS, H.PASSIVE_SPOOF,
    H.JOIN_CEO,
    H.INF_LOCKON_RANGE,
    H.BETTER_ALT_F4,
    H.DISABLE_LOS,
    H.WP_INTERIOR,
    H.WP_INSIDE_INT,
    H.WHEELIE,
    H.SUPER_MELEE,
    H.VEH_INF_AMMO,
    H.NOCLIP_ROCKETS,
    H.YOGA_RUN,
    H.LOCK_CINE_CAM,
    H.AUTO_TP_OBJECTIVE,
    H.SMS_KEEP_TEXT,
    H.RICK_ROLL_HORN,
}

local function telemetryJsonStr(s)
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    return '"' .. s .. '"'
end

local function telemetryJsonEncode(v)
    local t = type(v)
    if t == "nil"     then return "null" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number"  then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        if math.type and math.type(v) == "integer" then
            return string.format("%d", v)
        end
        if v == math.floor(v) and math.abs(v) < 1e15 then
            return string.format("%d", v)
        end
        return string.format("%.14g", v)
    end
    if t == "string"  then return telemetryJsonStr(v) end
    if t == "table"   then
        local parts = {}
        for k, val in pairs(v) do
            parts[#parts + 1] = telemetryJsonStr(tostring(k)) .. ":" .. telemetryJsonEncode(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

local function telemetryHash(inputStr)
    local h = 2166136261
    local s = telemetry.SALT .. inputStr
    for i = 1, #s do
        h = (h ~ s:byte(i)) * 16777619 & 0xFFFFFFFF
    end
    return string.format("%08x", h)
end

local function telemetryBuildUid()
    local rawUid = 0
    if Cherax and Cherax.GetUID then rawUid = Cherax.GetUID() or 0 end
    if rawUid == 0 then
        local idFile = settings.dir .. "\\telemetry_id.txt"
        if FileMgr.DoesFileExist(idFile) then
            local content = FileMgr.ReadFileContent(idFile)
            rawUid = tonumber(content or "") or 0
        end
        if rawUid == 0 then
            math.randomseed(os.time() + os.clock() * 1000)
            rawUid = math.random(1, 0x7FFFFFFF)
            pcall(function() FileMgr.WriteFileContent(idFile, tostring(rawUid), false) end)
        end
    end
    return telemetryHash(tostring(rawUid))
end

local function telemetryFeatureBitmap()
    local bitmap = 0
    for i, hash in ipairs(TELEMETRY_FEATURES) do
        local on
        if hash == H.SUPER_MELEE then
            on = (FeatureMgr.GetFeatureInt(H.SUPER_MELEE) or 0) > 0
        else
            local feat = FeatureMgr.GetFeature(hash)
            on = feat and feat:IsToggled()
        end
        if on then
            bitmap = bitmap | (1 << (i - 1))
        end
    end
    return bitmap
end

local function telemetryCheraxVersion()
    local v = Cherax and Cherax.GetVersion and tostring(Cherax.GetVersion() or "?") or "?"
    local b = Cherax and Cherax.GetBuild and tostring(Cherax.GetBuild() or "?") or "?"
    return v .. "." .. b
end

local function telemetryGetIgn()
    local ign = ""
    local pid = GTA.GetLocalPlayerId()
    if pid and pid >= 0 then
        local name = PLAYER.GET_PLAYER_NAME(pid)
        if name and name ~= "" and name ~= "**Invalid**" and name ~= "NONE" then
            ign = tostring(name):sub(1, 32)
        end
    end
    return ign
end

telemetry._uid        = telemetryBuildUid()
telemetry._battleye   = (Cherax.GetEdition():find("BE") ~= nil) and 1 or 0
telemetry._firstBeatSent = false

local TELEMETRY_FEATURE_LAYOUT = 4

local function telemetryBuildBody()
    local bm = telemetryFeatureBitmap()
    return telemetryJsonEncode({
        uid            = telemetry._uid,
        version        = VIBE_VERSION,
        variant        = IS_ENHANCED and "enhanced" or "legacy",
        battleye       = telemetry._battleye,
        cherax         = telemetryCheraxVersion(),
        features       = bm & 0x1FFFFFFFFFFFFF,
        features_hi    = bm >> 53,
        feature_layout = TELEMETRY_FEATURE_LAYOUT,
        ign            = telemetryGetIgn(),
        loader         = VIBESCRIPT_LOADER and 1 or 0,
        first_beat     = telemetry._firstBeatSent and 0 or 1,
        counts         = TELEMETRY_ACTIONS,
    })
end

local function telemetryBeatOnce()
    if not telemetry.ENABLED then return end
    local body = telemetryBuildBody()
    telemetry._firstBeatSent = true
    TELEMETRY_ACTIONS = {}

    local h
    local ok = pcall(function()
        h = Curl.Easy()
        h:Setopt(eCurlOption.CURLOPT_URL, telemetry.BEAT_URL)
        h:Setopt(eCurlOption.CURLOPT_CUSTOMREQUEST, "POST")
        h:Setopt(eCurlOption.CURLOPT_USERAGENT, "BladScript-Telemetry/1.0")
        h:Setopt(eCurlOption.CURLOPT_POSTFIELDS, body)
        h:AddHeader("Content-Type: application/json")
        h:Perform()
    end)
    if not ok or not h then return end
    while not h:GetFinished() do
        Script.Yield()
    end
    pcall(function() h:GetResponse() end)
end

Script.RegisterLooped(function()
    Script.Yield((telemetry._firstBeatSent and telemetry.INTERVAL_SEC or telemetry.WARMUP_SEC) * 1000)
    if scriptUnloading then return end
    telemetryBeatOnce()
end)

do
    local intro = {
        ENABLED    = (settings.introEnabled ~= false),
        TIMEOUT_MS = 0,
        BASE       = "https://vibescript-assets.pages.dev",
        COUNT      = 25,
        FPS        = 26,
        HOLD       = 2500,
        FADE       = 1200,
        WIDTH_FRAC = 0.75,
        MAX_H_FRAC = 0.85,
        PER_TICK   = 8,
        MAX_ATTEMPTS = 5,
        RETRY_DELAY  = 600,
        VALIDATE_TIMEOUT = 5000,
        loadAttempts = 0, retryAt = 0, validateStart = nil,
        t0 = nil, deadline = 0,
        netPhase = "checkver",
        texPhase = "idle",
        playPhase = "waiting",
        focused = false,
        frames = {}, loadCursor = 0,
        curlVer = nil, curlZip = nil, zipKicked = false,
        localVer = nil, remoteVer = nil, framesOnDisk = false, playStart = 0,
    }
    intro.dir       = FileMgr.GetMenuRootPath() .. "\\lua\\VibeScript\\intro"
    intro.framesDir = intro.dir .. "\\frames"
    intro.zipPath   = intro.dir .. "\\intro.zip"
    intro.verFile   = intro.dir .. "\\version.txt"

    function intro.framePath(i)
        return intro.framesDir .. "\\frame_" .. string.format("%02d", i) .. ".png"
    end

    function intro.dlog(msg)
        if VIBESCRIPT_VERBOSE then
            Logger.LogInfo("[VibeScript intro] " .. tostring(msg))
        end
    end

    function intro.log(msg)
        if not VIBESCRIPT_VERBOSE then return end
        Logger.LogInfo("[VibeScript intro] " .. tostring(msg))
    end

    function intro.newCurl(url)
        local h = Curl.Easy()
        h:Setopt(eCurlOption.CURLOPT_URL, url)
        h:Setopt(eCurlOption.CURLOPT_USERAGENT, "VibeScript-Intro")
        h:Perform()
        return h
    end

    function intro.startLoad()
        if intro.texPhase ~= "idle" and intro.texPhase ~= "failed" then return end
        intro.frames = {}
        intro.loadCursor = 0
        intro.validateStart = nil
        intro.loadAttempts = intro.loadAttempts + 1
        intro.texPhase = "loading"
        intro.log("load attempt " .. intro.loadAttempts .. "/" .. intro.MAX_ATTEMPTS)
    end

    function intro.driveLoad()
        if intro.texPhase ~= "failed" then return end
        if not intro.framesOnDisk then return end
        if intro.loadAttempts >= intro.MAX_ATTEMPTS then return end
        if Time.GetEpocheMs() < intro.retryAt then return end
        intro.startLoad()
    end

    function intro.ensureInit()
        if intro.t0 then return end
        local now = Time.GetEpocheMs()
        intro.t0 = now
        intro.deadline = now + intro.TIMEOUT_MS
        pcall(function() FileMgr.CreateDir(intro.dir) end)
        for i = intro.COUNT, 99 do
            local p = intro.framePath(i)
            if FileMgr.DoesFileExist(p) then pcall(function() FileMgr.DeleteFile(p) end) end
        end
        if FileMgr.DoesFileExist(intro.verFile) then
            local v = FileMgr.ReadFileContent(intro.verFile)
            if v then intro.localVer = v:gsub("%s+", "") end
        end
        intro.framesOnDisk = FileMgr.DoesFileExist(intro.framePath(0))
            and FileMgr.DoesFileExist(intro.framePath(intro.COUNT - 1))
        if intro.framesOnDisk then intro.startLoad() end
        local ok = pcall(function() intro.curlVer = intro.newCurl(intro.BASE .. "/version.txt") end)
        if not ok then
            intro.curlVer = nil
            intro.netPhase = intro.framesOnDisk and "done" or "failed"
        end
        intro.log("init cache=" .. tostring(intro.framesOnDisk) .. " ver=" .. tostring(intro.localVer))
    end

    function intro.stepNet()
        local np = intro.netPhase
        if np == "done" or np == "failed" then return end

        if np == "checkver" then
            if not intro.curlVer then
                intro.netPhase = intro.framesOnDisk and "done" or "failed"
                return
            end
            local fin = false
            pcall(function() fin = intro.curlVer:GetFinished() end)
            if not fin then return end
            local code, body
            pcall(function() code, body = intro.curlVer:GetResponse() end)
            intro.curlVer = nil
            if code == eCurlCode.CURLE_OK and body and #body > 0 then
                intro.remoteVer = body:gsub("%s+", "")
                if intro.framesOnDisk and intro.remoteVer == intro.localVer then
                    intro.netPhase = "done"
                else
                    intro.netPhase = "download"
                end
            else
                intro.netPhase = intro.framesOnDisk and "done" or "failed"
            end

        elseif np == "download" then
            if not intro.zipKicked then
                intro.zipKicked = true
                local ok = pcall(function() intro.curlZip = intro.newCurl(intro.BASE .. "/intro.zip") end)
                if not ok then intro.curlZip = nil end
            end
            if not intro.curlZip then
                intro.netPhase = intro.framesOnDisk and "done" or "failed"
                return
            end
            local fin = false
            pcall(function() fin = intro.curlZip:GetFinished() end)
            if not fin then return end
            local code, body
            pcall(function() code, body = intro.curlZip:GetResponse() end)
            intro.curlZip = nil
            if code == eCurlCode.CURLE_OK and body and #body > 1000 then
                local wrote = false
                pcall(function()
                    local f = io.open(intro.zipPath, "wb")
                    if f then f:write(body); f:close(); wrote = true end
                end)
                intro.netPhase = wrote and "unzip" or (intro.framesOnDisk and "done" or "failed")
            else
                intro.netPhase = intro.framesOnDisk and "done" or "failed"
            end

        elseif np == "unzip" then
            local runBody = function()
                FileMgr.CreateDir(intro.framesDir)
                FileMgr.Unzip(intro.zipPath, intro.framesDir)
            end
            runBody()
            if FileMgr.DoesFileExist(intro.framePath(0)) then
                if intro.remoteVer then
                    pcall(function() FileMgr.WriteFileContent(intro.verFile, intro.remoteVer, false) end)
                end
                intro.framesOnDisk = true
                intro.loadAttempts = 0
                if intro.texPhase == "idle" or intro.texPhase == "failed" then intro.startLoad() end
                intro.log("cache refreshed ver=" .. tostring(intro.remoteVer))
            end
            pcall(function() FileMgr.DeleteFile(intro.zipPath) end)
            intro.netPhase = "done"
        end
    end

    function intro.stepTex()
        if intro.texPhase == "loading" then
            local target = math.min(intro.loadCursor + intro.PER_TICK, intro.COUNT)
            while intro.loadCursor < target do
                local i = intro.loadCursor
                local id = 0
                pcall(function() id = Texture.LoadTexture(intro.framePath(i)) or 0 end)
                if id == 0 then
                    intro.texPhase = "failed"
                    intro.retryAt = Time.GetEpocheMs() + intro.RETRY_DELAY
                    intro.log("LoadTexture failed at frame " .. i .. " (attempt " .. intro.loadAttempts .. ")")
                    return
                end
                intro.frames[i] = id
                intro.loadCursor = i + 1
            end
            if intro.loadCursor >= intro.COUNT then
                intro.texPhase = "validating"
                intro.validateStart = Time.GetEpocheMs()
            end

        elseif intro.texPhase == "validating" then
            for i = 0, intro.COUNT - 1 do
                local valid = false
                pcall(function() valid = Texture.IsTextureValid(intro.frames[i]) end)
                if not valid then
                    if intro.validateStart
                       and (Time.GetEpocheMs() - intro.validateStart) > intro.VALIDATE_TIMEOUT then
                        intro.texPhase = "failed"
                        intro.retryAt = Time.GetEpocheMs() + intro.RETRY_DELAY
                        intro.log("validate timeout at frame " .. i .. " (attempt " .. intro.loadAttempts .. ")")
                    end
                    return
                end
            end
            intro.texPhase = "ready"
            intro.log("frames ready (attempt " .. intro.loadAttempts .. ")")
        end
    end

    function intro.render()
        local elapsed  = Time.GetEpocheMs() - intro.playStart
        local revealMs = (intro.COUNT / intro.FPS) * 1000.0
        local total    = revealMs + intro.HOLD + intro.FADE
        if elapsed >= total then intro.playPhase = "ended"; return end

        local idx, alpha = intro.COUNT - 1, 255
        if elapsed < revealMs then
            idx = math.floor(elapsed / 1000.0 * intro.FPS)
            if idx > intro.COUNT - 1 then idx = intro.COUNT - 1 end
        elseif elapsed < revealMs + intro.HOLD then
            idx = intro.COUNT - 1
        else
            local fo = elapsed - revealMs - intro.HOLD
            alpha = math.floor((1.0 - fo / intro.FADE) * 255)
            if alpha < 0 then alpha = 0 end
        end

        local texId = intro.frames[idx]
        if not texId then return end

        local handle, sw, sh, w, h
        local runBody = function()
            local d3d = Texture.GetTexture(texId)
            if not d3d then return end
            handle = d3d:GetCurrent()
            local tw, th = d3d:GetWidth(), d3d:GetHeight()
            sw, sh = ImGui.GetDisplaySize()
            local aspect = (tw and tw > 0 and th) and (th / tw) or (450.0 / 800.0)
            w = sw * intro.WIDTH_FRAC
            h = w * aspect
            local maxH = sh * intro.MAX_H_FRAC
            if h > maxH then h = maxH; w = h / aspect end
        end
        runBody()
        if not handle or not sw then return end

        ImGui.SetNextWindowPos(0, 0, ImGuiCond.Always)
        ImGui.SetNextWindowSize(sw, sh, ImGuiCond.Always)
        if not intro.focused then
            ImGui.SetNextWindowFocus()
            intro.focused = true
        end
        local flags = ImGuiWindowFlags.NoTitleBar
            | ImGuiWindowFlags.NoResize
            | ImGuiWindowFlags.NoMove
            | ImGuiWindowFlags.NoCollapse
            | ImGuiWindowFlags.NoScrollbar
            | ImGuiWindowFlags.NoSavedSettings
            | ImGuiWindowFlags.NoBackground
            | ImGuiWindowFlags.NoInputs
        ImGui.Begin("##VibeScriptIntro", true, flags)
        pcall(function() ImGui.AddImageRotated(handle, sw / 2.0, sh / 2.0, w, h, 0.0, alpha) end)
        ImGui.End()
    end

    function intro.stepPlay()
        if intro.playPhase == "waiting" then
            local now = Time.GetEpocheMs()
            local expired = (intro.TIMEOUT_MS > 0) and (now > intro.deadline)
            if intro.texPhase == "ready" and not expired then
                intro.playPhase = "playing"
                intro.playStart = now
                intro.log("playing")
            elseif (expired and intro.texPhase ~= "ready")
                or (intro.texPhase == "failed" and intro.loadAttempts >= intro.MAX_ATTEMPTS)
                or (intro.netPhase == "failed" and not intro.framesOnDisk) then
                intro.playPhase = "skipped"
                intro.log("skipped (assets unavailable or timed out)")
            end
        end
        if intro.playPhase == "playing" then intro.render() end
    end

    if intro.ENABLED then
        EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
            if scriptUnloading then return end
            if (intro.playPhase == "ended" or intro.playPhase == "skipped")
               and (intro.netPhase == "done" or intro.netPhase == "failed") then
                return
            end
            intro.ensureInit()
            intro.stepNet()
            intro.driveLoad()
            intro.stepTex()
            intro.stepPlay()
        end)
    end
end

