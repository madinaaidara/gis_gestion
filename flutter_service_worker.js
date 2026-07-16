'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "9f481877aa70a9834631bfd9370b3a03",
".git/config": "fffbaff27fade3aa83be7ad37ddb7b2d",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "bea0fe579695cd4091864d5fe8f32132",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "b41b21fe95fd3f64b4459d4efc83ae4e",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "c8874442e1758ece6a4406e5a2af144a",
".git/logs/refs/heads/gh-pages": "a60ccd540f1cdbc4c17bf96a0acc64d3",
".git/logs/refs/remotes/origin/gh-pages": "c01f725c329f592cdd0244968a7a3f00",
".git/logs/refs/remotes/origin/HEAD": "b34e797a9b4fe9829af7e2fee39e9c07",
".git/logs/refs/remotes/origin/main": "b1717c4237a6a2319d5c5006183ba70b",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/05/1a996648229682610717af8147d83c15423454": "986a4bd9e8defb4660233b7a4da8923f",
".git/objects/05/4eea0ce53060b09c30c75b5d709ab2c535058c": "be25835f2ddb0567da9b1a2f72d05486",
".git/objects/05/665b6306ee68858f047dca274bbfebdd548787": "ede4e09c030ae15cc30b1423ace44bd9",
".git/objects/13/15a989d9fa5e0c8b491d260c8438e06173be21": "042789ecffa7162137e876484ac99a2f",
".git/objects/14/84c233bfd5b32081bbca369d55c8414fb9bf77": "95000f1cfd9a6c71e2ab250048eaa869",
".git/objects/14/d545ef16d2bf456b213b17faf6a6cd801e735a": "a123bc591891815dc132b240c1f3704c",
".git/objects/19/38a5d1845b7567e41b6b97e5bc24af0b3ffb58": "990926469e3f687eb35ecd57c748ed21",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/25/d27d4cc62c657f1d09f915368466c69cba500a": "56f5991d8f9fc1beb468c70e73b93dbc",
".git/objects/27/8e7609ce84f8a817d51045018db6749376628d": "c36d33cd85a9dc54c10a28f838fb7ae0",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/34/3297d27134c7fac186de27007ef9f9f50704f1": "f4e19444f63b631e62904812407b4c20",
".git/objects/35/d5d466a9d48ace7fbceed5c1c23190dc0ee8db": "1ad81a83f85a8d702ffff1835e444f08",
".git/objects/3c/86744b92c9b4ef2d13e27db497f1eea73d2974": "60dce59f3ee09cbf83605686dd0312a8",
".git/objects/3d/8a46576e7f16fd763f442952392956688185b7": "68eea5e1808ab6c6b182445a61ded827",
".git/objects/40/76b7c211bb8749773d3e45acd676fcc85a8fad": "8b890a2d78d5497d011e115dcc90faf4",
".git/objects/41/a5199f9aa269d67c557967864dc65c2e55565b": "3214f8d1f10939108a9d5bf9d78f1e50",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/4b500f1eb1d4eecbfddc24fb0b6a95bea8267f": "b6477c3e76eb3193f2a4cf31927a50f9",
".git/objects/47/01048db7809af9c959523bbdb4794b9eacc4e5": "35fb571e32fe8dd498638c684a69362d",
".git/objects/48/a719fa6140c1a8055158c43276913666b6273a": "23fcaface236e7f11f2b88c293c73e44",
".git/objects/4c/8d0ddd3668adfc7609c6b4699609cfbccff7e6": "d11b1c291e7c0b7aaeeec3e398e5c566",
".git/objects/4d/7d4def38a7d130114ab9dbf08ac31d51fc674f": "19b945c1cee84267d72c8fff62dfb764",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/50/a24630993c80d06fd8a015e3147df61c967261": "d3a4898cfd2fdd88ec75102c0133e4b2",
".git/objects/51/b24a51d1ff4ab8f18c5ec39c45760e436a2bc1": "5aa71e9245670aa9911c94bd9d4e3729",
".git/objects/54/5b9f35d714e6714e09335683c8cdc92ec07b07": "bce6d357e72e45d0c884a4874bbac8b1",
".git/objects/58/f5ac848a69e0646948df91edab53ef02d337ff": "7f842d1c903027c9a7e8d82de84f2f7c",
".git/objects/62/642e80d92f2b60e66e98c63609fa3c3a1d4bf7": "c815e16f958d65ff32ad67e5c72707b2",
".git/objects/63/59659e080cc838e9167f9c9d6e0bd6b97213d9": "a0669e60ab3d9fe56dcf1cf087b2cd03",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/76/45e090a39222f596fe9c9447e4cbcd4a3b9431": "6044f015826dbdfdc2fff0e1c6e74765",
".git/objects/77/eb178f8c9ed3174580d63c269478d0ac27f7c3": "4ea45f881236f8168b024a320efd5bf8",
".git/objects/79/b2e54ee39fd05bee483cc462ae68168a583099": "458dc5c6c97c5bca7bccedb7a15f838f",
".git/objects/7a/11795e796ef24506c2305677d4cba55cd9c663": "89a863ac79bd1efe000e0ae14eef863f",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7c/c460c8d69ef3a90692d6fce2ee1b44e90c80f7": "885f2eac54536522498b8066b49d9121",
".git/objects/82/2079f224c57dd840cb3bcfaf83b6a9161479f2": "3d9ce5419fa6f5654f3c4ea00f4330fd",
".git/objects/84/3e835af5b6a2fb41a553d66a55f2c333e5451c": "f7ce97a518c8da55a92562e8a5a2c1b8",
".git/objects/85/f143405edcdce30654cc2a2a276f024d08bfe8": "31c83a72d68884fab18c540284101c57",
".git/objects/8e/f80fc4e1ab301750c55a399872ae83619e0e67": "7d797925274ca43648b102b465f0049f",
".git/objects/8f/c21ee72f1bae72d36b5b8342b177e44faefd2a": "67c52e85328a95a83ed6996b0fba8d6b",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/9a/ebee9afb25f9dda82f4efb635aade6e81b55b9": "2a702579bd566071b669c3f11f6e59e1",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/9e/6223581dc5ae93f54c59d7fab82b8a5a4302c7": "5f607441aec8504b4ea1dd1d098673ac",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b9/6606be1637e480621926313936f86786543229": "7bac43c5e7d05091b7cce603370180d7",
".git/objects/bc/46793b54c2631979a4459510f2a1790c4df986": "7464499f3a625d1326b9460065e40e35",
".git/objects/c2/29a9930ebd7be6abc45953490a12c6ac92b8f0": "f958f1c3c32c31bc4e440ec331687d86",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/c4/3c73f674970a91f28315a68263c713b6639ec6": "cc615ac2f26365bcd0aed40ad706e317",
".git/objects/c5/195736637e9a98782c1512955b646efeba5d26": "e1507ebe3208e3c56f2da9c0fa7d389f",
".git/objects/c7/13ba81f906e0b1a397dd25e20eb81ac3341a7b": "352be5476985f0d73f0bedadf25af07d",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/d1/099ad27161a4cf259f975793ac7a99889e225c": "01ca0e7741a438dab6d92b4dbe8970e3",
".git/objects/d1/763eac5d9a47b2dc7bfcafe1c5fb5d98bc38b8": "6282c5e53904bdc9d6f5a5f85ae1f7a1",
".git/objects/d3/17b267414db2e8c623d6e0db9effb15595882a": "b0093361d5fa99f50401ee9e01aaad83",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d7/36e573b9adb132093ca36ec85723f617d04431": "98e4f66b4a34ccb8fa03b2fb629e87a3",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/db/9a3077508c8d199fc631d533e1b41a657385d3": "3d330dd882c149f392e3ee5d94ead90c",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/ef/fbe4d1c38bbab6f19f4477c9739cc1face696a": "343b1f048ff9c8b54a36b8f9710afcec",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f7/59d5dd4ec0e860afcb6bf3f6f3f01f964ede2e": "ba0ec87975cf5f0a16d56ddb70aed893",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/ff/8d01a4947ac373f90f87041954b7a0bbed517c": "5fbebeced604ea69c377c29e3907a632",
".git/objects/pack/pack-c2417c9311832a438abf76f0e9ca47028cf96c42.idx": "d5e750f4e4d8696be3166aa70c29c66f",
".git/objects/pack/pack-c2417c9311832a438abf76f0e9ca47028cf96c42.pack": "e6a17ed224f5472ee3da9febcbbbfd72",
".git/objects/pack/pack-c2417c9311832a438abf76f0e9ca47028cf96c42.rev": "ef192577a1d80d1688c0885903ae9ae4",
".git/refs/heads/gh-pages": "c052c20b6ec3ba7299c82baa575cd642",
".git/refs/remotes/origin/gh-pages": "c052c20b6ec3ba7299c82baa575cd642",
".git/refs/remotes/origin/HEAD": "98b16e0b650190870f1b40bc8f4aec4e",
".git/refs/remotes/origin/main": "afd1dc86994aa7f02f867b2b5ea4f359",
"assets/AssetManifest.bin": "12e9dfaf34ee5c39dc0f50d9ab9f303d",
"assets/AssetManifest.bin.json": "45df6fc9452e9e4e68043e4eaf55d285",
"assets/AssetManifest.json": "41b4c25e9a07d4d934fb128e702ffb48",
"assets/assets/images/ac1.png": "05727dfc7dc1e63bb0add53efbc20fb6",
"assets/assets/images/acceuil.png": "f50ef2c5a87f690d3fea335b0ff273f8",
"assets/assets/images/cre1.png": "3d204568a0e617edd2a51873f4f1b5ad",
"assets/assets/images/his1.png": "129df820ac62a58b9fb1da2ea67cc522",
"assets/assets/images/logo.jpeg": "7282c8c82548e3e3fa3a1749fabf2e27",
"assets/assets/images/logo_guiss_gestion.png": "6b49f505d5dfa253a304d4669001b35a",
"assets/assets/images/logo_guiss_gestion1.png": "546d6def88b80478e524076b3d068bee",
"assets/assets/images/onboarding_dashboard.png": "b1994b05f277456ce88bdf018a6ea313",
"assets/assets/images/onboarding_produits.png": "0dbcf775ffbb96936a13bf836bbb8f04",
"assets/assets/images/onboarding_stats.png": "993c6622d9ffaa514cb317495511e67b",
"assets/assets/images/onboarding_ventes.png": "a34345b831d0d1258796aa3aeac4f66c",
"assets/assets/images/pro1.png": "b49edb31b9946d97833db69c785271d8",
"assets/assets/images/produits.png": "346fde686fedf0fa6bcd334ba3049072",
"assets/assets/images/sta1.png": "68056e5ac4d814319d590eabb0bbd5c9",
"assets/assets/images/stats.png": "23757c4cc09f1a64ed28fdf69fe72ed0",
"assets/assets/images/ven1.png": "ed1232c5a746d3a3eaeac8ea960eb894",
"assets/assets/images/ventes.png": "9eca52fe66ac959b39f3cb0ffde13442",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "d8f1aa55ca2bd85e8a9ec957491f9fff",
"assets/NOTICES": "8a21eab6a8455209cae308723e00ea24",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "2d2673667586797c5ab55b433b6b194f",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "bf15783415e2b4b935e6d351fb2d9c13",
"icons/Icon-192.png": "cc313ee8c83880764b0d88c41cfe3042",
"icons/Icon-512.png": "201bd8e9adb04621754ee4c814952827",
"icons/Icon-maskable-192.png": "cc313ee8c83880764b0d88c41cfe3042",
"icons/Icon-maskable-512.png": "201bd8e9adb04621754ee4c814952827",
"index.html": "5b06fa79ec0d6c666bbb205a38086e52",
"/": "5b06fa79ec0d6c666bbb205a38086e52",
"main.dart.js": "1153b80e76f8c653fef5a758e18daae5",
"manifest.json": "21a7e5d5c2a60afef7cf476ef2317708",
"version.json": "cd91dd23b59938a2f231bdd931b84487"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
