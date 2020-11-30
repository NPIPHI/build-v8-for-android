# build-v8-for-android
docker file to build v8 as a monolith for android<br>
To run:<br>
```git clone https://github.com/NPIPHI/build-v8-for-android
cd build-v8-for-android
docker build -t build-v8-for-android .
docker cp build-v8-for-android:/buildv8/libs libs
```
Based on the <a href="https://github.com/eclipsesource/J2V8/tree/master/v8">buildscript from j2v8</a>
