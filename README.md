# snapcraft-isc-dhcp-server

The purpose is to use [snapcraft](https://developer.ubuntu.com/en/snappy/build-apps/snapcraft-advanced-features/) to build the isc-dhcp-server as snap package.  

## Requirement

First, installing snapcraft:
```bash
sudo add-apt-repository ppa:snappy-dev/tools
sudo apt-get update
sudo apt-get install snapcraft
```
## How to build

Run `snapcraft` to build a snap.

## How to rebuild

```bash
snapcraft clean
snapcraft
```

## snapcraft commands

`snapcraft pull`: get source  
`snapcraft build`: build parts  
`snapcraft stage`: put parts into staging area  
`snapcraft snap`: put parts into snap area  
`snapcraft all`: make a snap package  
