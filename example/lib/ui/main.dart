import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/repository_diet_plan.dart';
import 'package:flutter_plugin_example/domain/constants/application_constants.dart';
import 'package:flutter_plugin_example/domain/utils/db_utils.dart';
import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() {
  Stetho.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DietPlanRepository repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initData());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: const Text('Running Parse init'),
        ),
      ),
    );
  }

  Future<void> initData() async {
    // Initialize repository
    await initRepository();

    // Initialize parse
    Parse().initialize(keyParseApplicationId, keyParseServerUrl,
        masterKey: keyParseMasterKey, debug: true);

    // Check server is healthy and live - Debug is on in this instance so check logs for result
    final ParseResponse response = await Parse().healthCheck();
    if (response.success) {
      await runTestQueries();
    } else {
      print('Server health check failed');
    }
  }

  Future<void> runTestQueries() async {
    // Basic repository example
    //await repositoryAddItems();
    //await repositoryGetAllItems();

    // Basic usage
    //createItem();
    //getAllItems();
    //getAllItemsByName();
    getSingleItem();
    //getConfigs();
    //query();
    //initUser();
    //function();
    //functionWithParameters();
  }

  Future<void> createItem() async {
    final ParseObject newObject = ParseObject('TestObjectForApi');
    newObject.set<String>('name', 'testItem');
    newObject.set<int>('age', 26);

    final ParseResponse apiResponse = await newObject.create();

    if (apiResponse.success && apiResponse.result != null) {
      print(keyAppName + ': ' + apiResponse.result.toString());
    }
  }

  Future<void> getAllItemsByName() async {
    final ParseResponse apiResponse =
        await ParseObject('TestObjectForApi').getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (final ParseObject testObject in apiResponse.result) {
        print(keyAppName + ': ' + testObject.toString());
      }
    }
  }

  Future<void> getAllItems() async {
    final ParseResponse apiResponse = await DietPlan().getAll();

    if (apiResponse.success && apiResponse.result != null) {
      String json = JsonEncoder().convert(apiResponse.result);
      print(json);
      for (final DietPlan plan in apiResponse.result) {
        print(keyAppName + ': ' + plan.name);
      }
    } else {
      print(keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> getSingleItem() async {
    final ParseResponse apiResponse = await DietPlan().getObject('B0xtU0Ekqi');

    if (apiResponse.success && apiResponse.result != null) {
      final DietPlan dietPlan = apiResponse.result;

      // Shows example of storing values in their proper type and retrieving them
      dietPlan.set<int>('RandomInt', 8);
      final int randomInt = dietPlan.get<int>('RandomInt');

      if (randomInt is int) {
        print('Saving generic value worked!');
      }

      // Shows example of pinning an item
      await dietPlan.pin();

      // shows example of retrieving a pin
      final DietPlan newDietPlanFromPin =
          await DietPlan().fromPin('R5EonpUDWy');
      if (newDietPlanFromPin != null) {
        print('Retreiving from pin worked!');
      }
    } else {
      print(keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> query() async {
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder<ParseObject>(ParseObject('TestObjectForApi'))
          ..whereLessThan(keyVarCreatedAt, DateTime.now());

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.result != null) {
      final List<ParseObject> listFromApi = apiResponse.result;
      final ParseObject parseObject = listFromApi?.first;
      print('Result: ${parseObject.toString()}');
    } else {
      print('Result: ${apiResponse.error.message}');
    }
  }

  Future<void> initUser() async {
    // All return type ParseUser except all
    ParseUser user =
        ParseUser('TestFlutter', 'TestPassword123', 'test.flutter@gmail.com');

    /// Sign-up
    ParseResponse response = await user.signUp();
    if (response.success) {
      user = response.result;
    }

    /// Login
    response = await user.login();
    if (response.success) {
      user = response.result;
    }

    /// Reset password
    response = await user.requestPasswordReset();
    if (response.success) {
      user = response.result;
    }

    /// Verify email
    response = await user.verificationEmailRequest();
    if (response.success) {
      user = response.result;
    }

    // Best practice for starting the app. This will check for a valid user from a previous session from a local storage
    user = await ParseUser.currentUser();

    /// Update current user from server - Best done to verify user is still a valid user
    response = await ParseUser.getCurrentUserFromServer(
        token: user?.get<String>(keyHeaderSessionToken));
    if (response.success) {
      user = response.result;
    }

    /// log user out
    response = await user.logout();
    if (response.success) {
      user = response.result;
    }

    user =
        ParseUser('TestFlutter', 'TestPassword123', 'phill.wiggins@gmail.com');
    response = await user.login();
    if (response.success) {
      user = response.result;
    }

    response = await user.save();
    if (response.success) {
      user = response.result;
    }

    /// Remove a user and delete
    final ParseResponse destroyResponse = await user.destroy();
    if (destroyResponse.success) {
      print('object has been destroyed!');
    }

    // Returns type ParseResponse as its a query, not a single result
    response = await ParseUser.all();
    if (response.success) {
      // We have a list of all users (LIMIT SET VIA SDK)
    }

    final QueryBuilder<ParseUser> queryBuilder =
        QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereStartsWith(ParseUser.keyUsername, 'phillw');

    final ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      final List<ParseUser> users = response.result;
      for (final ParseUser user in users) {
        print(keyAppName + ': ' + user.toString());
      }
    }
  }

  Future<void> function() async {
    final ParseCloudFunction function = ParseCloudFunction('hello');
    final ParseResponse result =
        await function.executeObjectFunction<ParseObject>();
    if (result.success) {
      if (result.result is ParseObject) {
        final ParseObject parseObject = result.result;
        print(parseObject.className);
      }
    }
  }

  Future<void> functionWithParameters() async {
    final ParseCloudFunction function = ParseCloudFunction('hello');
    final Map<String, String> params = <String, String>{'plan': 'paid'};
    function.execute(parameters: params);
  }

  Future<void> getConfigs() async {
    final ParseConfig config = ParseConfig();
    final ParseResponse addResponse =
        await config.addConfig('TestConfig', 'testing');

    if (addResponse.success) {
      print('Added a config');
    }

    final ParseResponse getResponse = await config.getConfigs();

    if (getResponse.success) {
      print('We have our configs.');
    }
  }

  Future<void> repositoryAddItems() async {
    final List<DietPlan> dietPlans = List();

    final List<dynamic> json = const JsonDecoder().convert(dietPlansToAdd);
    for (final Map<String, dynamic> element in json) {
      final DietPlan dietPlan = DietPlan().fromJson(element);
      dietPlans.add(dietPlan);
    }

    await initRepository();
    final ApiResponse response = await repository.addAll(dietPlans);
    if (response.success) {
      print(response.result);
    }
  }

  Future<void> repositoryGetAllItems() async {
    final ApiResponse response = await repository.getAll();
    if (response.success) {
      print(response.result);
    }
  }

  Future<void> initRepository() async {
    repository ??= DietPlanRepository.init(await getDB());
  }
}

const String dietPlansToAdd =
    '[{"className":"Diet_Plans","Name":"Textbook","Description":"For an active lifestyle and a straight forward macro plan, we suggest this plan.","Fat":25,"Carbs":50,"Protein":25,"Status":0},'
    '{"className":"Diet_Plans","Name":"Body Builder","Description":"Default Body Builders Diet","Fat":20,"Carbs":40,"Protein":40,"Status":0},'
    '{"className":"Diet_Plans","Name":"Zone Diet","Description":"Popular with CrossFit users. Zone Diet targets similar macros.","Fat":30,"Carbs":40,"Protein":30,"Status":0},'
    '{"className":"Diet_Plans","Name":"Low Fat","Description":"Low fat diet.","Fat":15,"Carbs":60,"Protein":25,"Status":0},'
    '{"className":"Diet_Plans","Name":"Low Carb","Description":"Low Carb diet, main focus on quality fats and protein.","Fat":35,"Carbs":25,"Protein":40,"Status":0},'
    '{"className":"Diet_Plans","Name":"Paleo","Description":"Paleo diet.","Fat":60,"Carbs":25,"Protein":10,"Status":0},'
    '{"className":"Diet_Plans","Name":"Ketogenic","Description":"High quality fats, low carbs.","Fat":65,"Carbs":5,"Protein":30,"Status":0}]';