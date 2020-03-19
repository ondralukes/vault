module.exports = {
  "env": {
        "es6": true,
        "browser": true,
        "node": true
    },
  "parserOptions":{
    "ecmaVersion": 8
  },
  "extends": "eslint:recommended",
  "rules" : {
    "quotes": ["error", "single"]
  },
  "globals": {
    "cryptoTools": true
  }
}
