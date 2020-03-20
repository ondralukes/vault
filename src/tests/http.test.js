const http = require('supertest')('http://localhost:8080');

const registerParams = {
  name:'򿺢ޠ٬׌~㳄5্ĥ鷍植wgJ҆h򆫵葏੃ђ𜹀ݑƥ⧶󢷫𒞮D򝃐▧􇓢𷢵ϡ',
  rsa:
  {
    public:'-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5BoejbJkHGxxY17kgfyn\n5EyYcdbgxpUs4q3sg5MRGaUsKhlx3FMRl/tbEYu7jXnJ97rOfMxX8QI4LR2HxaxW\ngr3DFhi9TF90fjsixbjbU2AhjruyC2NhjsYG2AQAzQH0ufHQUlYQiDfE1ZSoYPli\nZl5iD0JrZ0AaLEbiYD5v4qOXPd56258MVU6Hyv+CQKR/o7rBHzts9SdppcwbE9u2\nMcSO51/tbacs2pUSjEUj6tgD9yz/1YEXNOTZTSNbEmr0dhF2A7QAyZ9pA/MGZq3q\nOiotRz0fYIKFaRFUkO2mRUdatoqKBNIX34e8SFWpFkcuTuUs712aUCGPzpQgMWp9\nAQIDAQAB\n-----END PUBLIC KEY-----',
    private:'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'
  }
};

describe('Testing webpage', () => {
  it('root page should be available', async (done) =>{
    var res = await http.get('/');
    expect(res.statusCode).toEqual(200);
    done();
  });
  it('can register new user', async (done) =>{
    var res = await http
    .post('/user/create')
    .send(registerParams);
    expect(res.statusCode).toEqual(200);
    done();
  });
});
