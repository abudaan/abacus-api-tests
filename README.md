# API tests for Abacus

Testing Abacus with direct API calls using [httpyac](https://httpyac.github.io/)

Install httpyac:

```
npm install -g httpyac
```



### 1 Changing committee session details after session is completed

```
ABACUS_BACKEND=path/to/abacus ./run.sh
```


steps:
- start abacus with empty database
- initialise and create users
- generate election
- complete committee session
- download zip
- update committee session details (location, date, time)
- download zip

result: Model_Na31.1.pdf is not updated