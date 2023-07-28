
#property copyright "Copyright © 2023-_07, fxowl"
#property link "javajava0708@gmail.com"
#property version "1.00"
#property strict

#include <Tools/Json.mqh>
#include <Tools/hash.mqh>

void OnStart()
{
    static string json_data =
        "{ \"firstName\": \"John\", \"lastName\": \"Smith\", \"age\": 25, " +
        "\"address\": { \"streetAddress\": \"21 2nd Street\", \"city\": \"New York\", \"state\": \"NY\", \"postalCode\": \"10021\" }," +
        " \"phoneNumber\": [ { \"type\": \"home\", \"number\": \"212 555-1234\" }, { \"type\": \"fax\", \"number\": \"646 555-4567\" } ]," +
        " \"gender\":{ \"type\":\"male\" }  }";

    JSONParser *parser = new JSONParser();

    JSONValue *jv = parser.parse(json_data);

    if (jv == NULL) {
        Print("error:" + (string)parser.getErrorCode() + parser.getErrorMessage());
    }
    else {
        Print("PARSED:" + jv.toString());

        if (jv.isObject()) { // check root value is an object. (it can be an array)

            JSONObject *jo = jv;

            // Direct access - will throw null pointer if wrong getter used.
            Print("firstName:" + jo.getString("firstName"));
            Print("city:" + jo.getObject("address").getString("city"));
            Print("phone:" + jo.getArray("phoneNumber").getObject(0).getString("number"));

            // Safe access in case JSON data is missing or different.
            if (jo.getString("firstName", json_data)) Print("firstName = " + json_data);

            // Loop over object keys
            JSONIterator *it = new JSONIterator(jo);
            for (; it.hasNext(); it.next()) {
                Print("loop:" + it.key() + " = " + it.val().toString());
            }
            delete it;
        }
        delete jv;
    }
    delete parser;
}