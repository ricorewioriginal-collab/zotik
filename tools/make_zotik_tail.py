"""Generates game/zotik/assets/characters/custom/zotik_tail.glb (pip install pygltflib numpy). Procedural, CC0-equivalent: no third-party data."""
import numpy as np, math
from pygltflib import *
L=0.9; NB=6; NR=25; NS=14   # bones, rings along, sides
def spine(t):  # rest curve: back then gently up, local +Z backwards, +Y up
    return np.array([0.0, 0.28*L*t*t, L*t])
def radius(t):
    return 0.045+0.135*math.sin(min(t/0.62,1)*math.pi/2)**1.2 if t<0.62 else 0.18*(1-((t-0.62)/0.38))**0.6+0.012
def col(t):
    k=min(max((t-0.62)/0.2,0),1); k=k*k*(3-2*k)
    o=np.array([0.93,0.42,0.09]); w=np.array([0.97,0.93,0.86]); d=np.array([0.80,0.32,0.06])
    base=d*(1-t)+o*t if t<0.5 else o
    return base*(1-k)+w*k
pos=[];nor=[];colr=[];jnt=[];wgt=[];idx=[]
for i in range(NR):
    t=i/(NR-1); c=spine(t); tan=spine(min(t+.01,1))-spine(max(t-.01,0)); tan/=np.linalg.norm(tan)
    up=np.array([0,1,0]); s=np.cross(up,tan); s/=np.linalg.norm(s); u=np.cross(tan,s)
    f=t*(NB-1); b0=min(int(f),NB-2); w1=f-b0
    for j in range(NS):
        a=2*math.pi*j/NS; n=math.cos(a)*s+math.sin(a)*u
        rr=radius(t)*(1.0+0.05*math.sin(5*a+8*t))  # slight fur irregularity
        pos.append(c+n*rr); nor.append(n); colr.append([*col(t),1]); jnt.append([b0,b0+1,0,0]); wgt.append([1-w1,w1,0,0])
for i in range(NR-1):
    for j in range(NS):
        a=i*NS+j; b=i*NS+(j+1)%NS; c2=(i+1)*NS+j; d=(i+1)*NS+(j+1)%NS
        idx+= [a,c2,b, b,c2,d]
# tip cap
pos.append(spine(1)); nor.append(spine(1)-spine(.99)); colr.append([*col(1),1]); jnt.append([NB-1,0,0,0]); wgt.append([1,0,0,0]); tip=len(pos)-1
for j in range(NS): idx+=[(NR-1)*NS+(j+1)%NS,(NR-1)*NS+j,tip]
P=np.array(pos,np.float32); N=np.array(nor,np.float32); N/=np.linalg.norm(N,axis=1,keepdims=True)
C=np.array(colr,np.float32); J=np.array(jnt,np.uint16); W=np.array(wgt,np.float32); I=np.array(idx,np.uint16)
bp=[spine(i/(NB-1)) for i in range(NB)]
ibm=np.array([np.array([[1,0,0,0],[0,1,0,0],[0,0,1,0],[*(-bp[i]),1]],np.float32) for i in range(NB)],np.float32)  # column-major
blobs=[P,N,C,J,W,I,ibm]; data=b''; views=[]; accs=[]
def add(arr,target,ctype,atype,minmax=False):
    global data
    while len(data)%4: data+=b'\0'
    views.append(BufferView(buffer=0,byteOffset=len(data),byteLength=arr.nbytes,target=target)); data+=arr.tobytes()
    a=Accessor(bufferView=len(views)-1,componentType=ctype,count=len(arr),type=atype)
    if minmax: a.min=arr.min(0).tolist(); a.max=arr.max(0).tolist()
    accs.append(a); return len(accs)-1
aP=add(P,ARRAY_BUFFER,FLOAT,VEC3,True); aN=add(N,ARRAY_BUFFER,FLOAT,VEC3); aC=add(C,ARRAY_BUFFER,FLOAT,VEC4)
aJ=add(J,ARRAY_BUFFER,UNSIGNED_SHORT,VEC4); aW=add(W,ARRAY_BUFFER,FLOAT,VEC4); aI=add(I,ELEMENT_ARRAY_BUFFER,UNSIGNED_SHORT,SCALAR)
aM=add(ibm.reshape(-1,16),None,FLOAT,MAT4)
nodes=[Node(name="Tail_Root",children=[1] if NB>1 else [],translation=bp[0].tolist())]
for i in range(1,NB): nodes.append(Node(name=f"Tail_{i:02d}",children=[i+1] if i<NB-1 else [],translation=(bp[i]-bp[i-1]).tolist()))
nodes[0].name="Tail_00"
nodes.append(Node(name="TailMesh",mesh=0,skin=0))
g=GLTF2(asset=Asset(version="2.0",generator="zotik procedural tail"),scene=0,scenes=[Scene(nodes=[0,NB])],nodes=nodes,
  meshes=[Mesh(name="TailMesh",primitives=[Primitive(attributes=Attributes(POSITION=aP,NORMAL=aN,COLOR_0=aC,JOINTS_0=aJ,WEIGHTS_0=aW),indices=aI,material=0)])],
  skins=[Skin(joints=list(range(NB)),inverseBindMatrices=aM,skeleton=0)],
  materials=[Material(name="TailFur",pbrMetallicRoughness=PbrMetallicRoughness(baseColorFactor=[1,1,1,1],metallicFactor=0,roughnessFactor=1),doubleSided=True)],
  accessors=accs,bufferViews=views,buffers=[Buffer(byteLength=len(data))])
g.set_binary_blob(data); g.save_binary("game/zotik/assets/characters/custom/zotik_tail.glb"); print(len(data),len(P),len(I)//3)
