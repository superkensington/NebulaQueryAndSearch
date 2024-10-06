/*******************************************************************************************************
 * This file is part of the Nebula Query & Search project, released under the MIT License.             *
 * See LICENSE file or go to https://github.com/jongpie/NebulaQueryAndSearch for full license details. *
 ******************************************************************************************************/

@SuppressWarnings(
  'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CyclomaticComplexity, PMD.EagerlyLoadedDescribeSObjectResult, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.UnusedLocalVariable'
)
@isTest(IsParallel=true)
private class Query_Tests {

    @isTest
    static void it_should_build_a_query_without_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Account WHERE CreatedDate >= THIS_MONTH';
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        accountQuery.filterWhere(
            new SOQL.QueryFilter(
                Schema.Account.CreatedDate,
                SOQL.Operator.GREATER_THAN_OR_EQUAL_TO,
                new SOQL.DateLiteral(SOQL.FixedDateLiteral.THIS_MONTH)
            )
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_with_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Account WHERE CreatedDate >= :dateFilter';
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        accountQuery.filterWhere(
            new SOQL.QueryFilter(
                Schema.Account.CreatedDate,
                SOQL.Operator.GREATER_THAN_OR_EQUAL_TO,
                Date.today().addMonths(-1),
                'dateFilter'
            )
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_correctly_represent_sets_in_query_filters()
    {
        // SETUP
        String expectedName = 'someName';
        String expectedQueryString = 'SELECT Id FROM Account WHERE Name IN (\'' + expectedName + '\')';
        Query acccountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        acccountQuery.filterWhere(
            Schema.Account.Name,
            SOQL.Operator.IS_IN,
            new Set<String> { expectedName }
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, acccountQuery.getQuery());
    }

    @isTest
    static void it_should_build_an_advanced_query()
    {
        // SETUP
        Datetime now = System.now();
        String expectedQueryString =
            'SELECT Alias, Email, Id, IsActive, ProfileId' +
            ' FROM User USING SCOPE MINE' +
            ' WHERE IsActive = true' +
            ' AND Profile.Id != \'' +
            System.UserInfo.getProfileId() +
            '\'' +
            ' AND LastModifiedDate <= ' +
            now.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time') +
            ' AND LastLoginDate >= LAST_N_DAYS:3' +
            ' AND CreatedDate <= LAST_WEEK' +
            ' AND Email != null' +
            ' ORDER BY Profile.CreatedBy.LastModifiedDate ASC NULLS FIRST, Name ASC NULLS FIRST, Email ASC NULLS FIRST' +
            ' LIMIT 100 OFFSET 1 FOR VIEW';
        List<Schema.SObjectField> fieldsToQuery = new List<Schema.SObjectField>{ Schema.User.IsActive, Schema.User.Alias };

        // TEST
        Query userQuery = new Query(Schema.User.getSObjectType())
            .addFields(fieldsToQuery)
            .addField(Schema.User.ProfileId)
            .addField(Schema.User.Email, SOQL.FieldCategory.UPDATEABLE)
            // .removeField(new SOQL.QueryField(Schema.User.Name))
            // .removeField(Schema.User.UserRoleId)
            .includeLabels()
            .includeFormattedValues()
            .usingScope(SOQL.Scope.MINE)
            .filterWhere(Schema.User.IsActive, SOQL.Operator.EQUALS, true)
            .filterWhere(new SOQL.QueryField(Schema.User.getSObjectType(), 'Profile.Id'), SOQL.Operator.NOT_EQUAL_TO, System.UserInfo.getProfileId())
            .filterWhere(Schema.User.LastModifiedDate, SOQL.Operator.LESS_THAN_OR_EQUAL_TO, now)
            .filterWhere(Schema.User.LastLoginDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, new SOQL.DateLiteral(SOQL.RelativeDateLiteral.LAST_N_DAYS, 3))
            .filterWhere(Schema.User.CreatedDate, SOQL.Operator.LESS_THAN_OR_EQUAL_TO, new SOQL.DateLiteral(SOQL.FixedDateLiteral.LAST_WEEK))
            .filterWhere(Schema.User.Email, SOQL.Operator.NOT_EQUAL_TO, null)
            .orderByField(new SOQL.QueryField(Schema.User.getSObjectType(), 'Profile.CreatedBy.LastModifiedDate'))
            .orderByField(Schema.User.Name, SOQL.SortOrder.ASCENDING)
            .orderByField(Schema.User.Email)
            .limitTo(100)
            .offsetBy(1)
            .forView();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, userQuery.getQuery());
    }

    @isTest
    static void it_should_include_grandparent_query_field()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id, Profile.UserLicense.LicenseDefinitionKey FROM User LIMIT 1';
        List<Schema.SObjectField> fieldChain = new List<Schema.SObjectField>{
            Schema.User.ProfileId,
            Schema.Profile.UserLicenseId,
            Schema.UserLicense.LicenseDefinitionKey
        };
        SOQL.QueryField queryField = new SOQL.QueryField(fieldChain);
        Query userQuery = new Query(Schema.User.getSObjectType());

        // TEST
        userQuery.addField(queryField)
            .limitTo(1);

        // VERIFY
        System.Assert.areEqual(expectedQueryString, userQuery.getQuery());
    }

    @isTest
    static void it_should_not_include_sobject_type_for_monomorphic_field()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id, OwnerId FROM Account';
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        accountQuery.addField(new SOQL.QueryField(Schema.Account.OwnerId));

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_include_separate_fields_for_for_polymorphic_field()
    {
        // SETUP
        List<String> supportedPolymorphicFieldNames = new List<String>();
        for (Schema.SObjectField field : Schema.Name.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).fields.getMap().values())
        {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (!fieldDescribe.isAccessible())
            {
                continue;
            }
            supportedPolymorphicFieldNames.add(String.valueOf(field));

            // Set<String> referenceFieldNames = new Set<String>{ 'ProfileId', 'RecordTypeId', 'UserRoleId' };
            // if (referenceFieldNames.contains(fieldDescribe.getName()))
            // {
            //     supportedPolymorphicFieldNames.add(fieldDescribe.getRelationshipName() + '.Name');
            // }
        }
        supportedPolymorphicFieldNames.sort();
        String expectedQuery =
            'SELECT Id, TYPEOF Who WHEN Contact THEN AccountId, Id, Name' +
            ' WHEN Lead THEN Company, Id, LeadSource, Name' +
            ' ELSE ' +
            String.join(supportedPolymorphicFieldNames, ', ') +
            ' END' +
            ' FROM Task';

        Map<Schema.SObjectType, List<Schema.SObjectField>> fieldsBySObjectType = new Map<Schema.SObjectType, List<Schema.SObjectField>>();

        // Contact fields
        List<Schema.SObjectField> contactFields = new List<Schema.SObjectField>{ Schema.Contact.Id, Schema.Contact.Name, Schema.Contact.AccountId };
        fieldsBySObjectType.put(Schema.Contact.getSObjectType(), contactFields);

        // Lead fields
        List<Schema.SObjectField> leadFields = new List<Schema.SObjectField>{ Schema.Lead.Id, Schema.Lead.Name, Schema.Lead.Company, Schema.Lead.LeadSource };
        fieldsBySObjectType.put(Schema.Lead.getSObjectType(), leadFields);

        Query taskQuery = new Query(Schema.Task.getSObjectType());

        // TEST

        // Query the task object
        taskQuery.addPolymorphicFields(Schema.Task.WhoId, fieldsBySObjectType);

        // VERIFY
        System.Assert.areEqual(expectedQuery, taskQuery.getQuery());
    }

    // @isTest
    // static void it_should_include_sobject_type_for_polymorphic_field()
    // {
    //     // SETUP
    //     String expectedQueryString = 'SELECT Id, Owner.Type, OwnerId FROM Lead';
    //     Query leadQuery = new Query(Schema.Lead.getSObjectType());

    //     // TEST
    //     leadQuery.addField(new SOQL.QueryField(Schema.Lead.OwnerId));

    //     // VERIFY
    //     System.Assert.areEqual(expectedQueryString, leadQuery.getQuery());
    // }

    @isTest
    static void it_should_include_related_records()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id, Type, (SELECT Email, Id FROM Contacts) FROM Account';
        Query contactQuery = new Query(Schema.Contact.getSObjectType()).addField(Schema.Contact.Email);
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        accountQuery.includeRelatedRecords(Schema.Contact.AccountId, contactQuery)
            .addField(new SOQL.QueryField(Schema.Account.Type));

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_when_filtering_with_an_or_statement()
    {
        // SETUP
        String expectedQueryString = 'SELECT AnnualRevenue, Id FROM Account WHERE ParentId != null AND (AnnualRevenue = null OR Type = null)';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.AnnualRevenue)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.ParentId, SOQL.Operator.NOT_EQUAL_TO, null));

        // TEST
        accountQuery.orFilterWhere(
            new List<SOQL.QueryFilter>{
                new SOQL.QueryFilter(Schema.Account.Type, SOQL.Operator.EQUALS, null),
                new SOQL.QueryFilter(Schema.Account.AnnualRevenue, SOQL.Operator.EQUALS, null)
            }
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_when_filtering_with_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Account WHERE CreatedDate >= :createdDateFilter';
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        accountQuery.filterWhere(
            new SOQL.QueryFilter(
                Schema.Account.CreatedDate,
                SOQL.Operator.GREATER_THAN_OR_EQUAL_TO,
                Date.today(),
                'createdDateFilter'
            )
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_run_with_system_mode_by_default()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        Query accountQuery = new Query(Schema.Account.getSObjectType());

        // TEST
        System.AccessLevel accessLevel = accountQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_system_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .withAccessLevel(System.AccessLevel.SYSTEM_MODE);

        // TEST
        System.AccessLevel accessLevel = accountQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_user_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.USER_MODE;
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .withAccessLevel(System.AccessLevel.USER_MODE);

        // TEST
        System.AccessLevel accessLevel = accountQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_includes_order_by_statement_for_single_field()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Lead ORDER BY CreatedDate ASC NULLS FIRST';
        Query leadQuery = new Query(Schema.Lead.getSObjectType());

        // TEST
        leadQuery.orderByField(Schema.Lead.CreatedDate);

        // VERIFY
        System.Assert.areEqual(expectedQueryString, leadQuery.getQuery());
    }

    @isTest
    static void it_marks_query_for_reference()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Lead FOR REFERENCE';
        Query leadQuery = new Query(Schema.Lead.getSObjectType());

        // TEST
        leadQuery.forReference();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, leadQuery.getQuery());
    }

    @isTest
    static void it_marks_query_for_update()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Lead FOR UPDATE';
        Query leadQuery = new Query(Schema.Lead.getSObjectType());

        // TEST
        leadQuery.forUpdate();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, leadQuery.getQuery());
    }

    @isTest
    static void it_marks_query_for_view()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Lead FOR VIEW';
        Query leadQuery = new Query(Schema.Lead.getSObjectType());

        // TEST
        leadQuery.forView();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, leadQuery.getQuery());
    }

    @isTest
    static void it_should_filter_with_iso_currency()
    {
        // SETUP
        // If multi-currency isn't enabled, then we cannot use IsoCurrency, so skip running this test
        if (!System.UserInfo.isMultiCurrencyOrganization())
        {
            return;
        }
        String expectedQueryString = 'SELECT Id, Name, AnnualRevenue FROM Account WHERE AnnualRevenue < 100';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.AnnualRevenue);

        // TEST
        // If multi-currency is enabled, then execute the test
        accountQuery.filterWhere(
            Schema.Account.AnnualRevenue,
            SOQL.Operator.LESS_THAN,
            new SOQL.IsoCurrency('USD', 100)
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_should_not_cache_query_results_by_default()
    {
        // SETUP
        Integer queriesCount = System.Limits.getQueries();
        Query userQuery = new Query(Schema.User.getSObjectType()).limitTo(1);
        userQuery.getResults();

        // TEST
        userQuery.getResults();

        // VERIFY
        System.Assert.areEqual(queriesCount + 2, System.Limits.getQueries());
    }

    @isTest
    static void it_should_cache_query_results_when_enabled()
    {
        // SETUP
        Integer queriesCount = System.Limits.getQueries();
        Query userQuery = new Query(Schema.User.getSObjectType()).limitTo(1);

        // TEST
        userQuery.cacheResults();
        userQuery.getResults();
        userQuery.getResults();

        // VERIFY
        System.Assert.areEqual(queriesCount + 1, System.Limits.getQueries());
    }

    @isTest
    static void it_should_set_a_bind_variable()
    {
        // SETUP
        String bindKey = 'dateFilter';
        Date expectedBindValue = Date.today().addDays(-1);
        String expectedQueryString = 'SELECT CreatedDate, Id FROM Account WHERE CreatedDate >= :dateFilter ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today().addMonths(-1), bindKey))
            .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
            .limitTo(1);

        // TEST
        accountQuery.setBind(bindKey, Date.today().addDays(-1));

        // VERIFY
        System.Assert.areEqual(expectedBindValue, accountQuery.doGetBindsMap().get(bindKey), 'bind value');
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    @isTest
    static void it_will_set_multiple_bind_keys()
    {
        // SETUP
        String bindKey1 = 'minDateFilter';
        String bindKey2 = 'maxDateFilter';
        Date expectedBindValue1 = Date.today().addDays(-7);
        Date expectedBindValue2 = Date.today();
        String expectedQueryString = 'SELECT CreatedDate, Id FROM Account WHERE CreatedDate >= :minDateFilter AND CreatedDate < :maxDateFilter ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today().addMonths(-1), bindKey1))
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.LESS_THAN, Date.today().addDays(-1), bindKey2))
            .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
            .limitTo(1);

        // TEST
        accountQuery.setBind(bindKey1, expectedBindValue1)
            .setBind(bindKey2, expectedBindValue2);

        // VERIFY
        System.Assert.areEqual(expectedBindValue1, accountQuery.doGetBindsMap().get(bindKey1), 'bind value 1');
        System.Assert.areEqual(expectedBindValue2, accountQuery.doGetBindsMap().get(bindKey2), 'bind value 2');
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

    // @isTest
    // static void it_will_remove_a_bind_key()
    // {
    //     // SETUP
    //     String bindKey = 'dateFilter';
    //     String expectedQueryString = 'SELECT CreatedDate, Id, Name FROM Account WHERE CreatedDate >= 2000-01-01T05:00:00Z';
    //     Query accountQuery = new Query(Schema.Account.getSObjectType())
    //         .addField(Schema.Account.CreatedDate)
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Datetime.newInstance(2000, 1, 1), bindKey));

    //     // TEST
    //     accountQuery.removeBind(bindKey);

    //     // VERIFY
    //     System.Assert.isFalse(accountQuery.doGetBindsMap().containsKey(bindKey), 'bind key exists in map');
    //     System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    // }

    // @isTest
    // static void it_will_clear_all_bind_keys()
    // {
    //     // SETUP
    //     String expectedQueryString = 'SELECT CreatedDate, Id, Name FROM Account WHERE CreatedDate >= 2000-01-01T05:00:00Z AND CreatedDate < 2001-01-01T05:00:00Z';
    //     Query accountQuery = new Query(Schema.Account.getSObjectType())
    //         .addField(Schema.Account.CreatedDate)
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Datetime.newInstance(2000, 1, 1), 'minDateFilter'))
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.LESS_THAN, Datetime.newInstance(2001, 1, 1), 'maxDateFilter'));

    //     // TEST
    //     accountQuery.clearBinds();

    //     // VERIFY
    //     System.Assert.areEqual(0, accountQuery.doGetBindsMap().size(), '# of bind keys');
    //     System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    // }

    @isTest
    static void it_will_generate_a_bind_variable()
    {
        // SETUP
        String expectedQueryString = 'SELECT CreatedDate, Id FROM Account WHERE CreatedDate >= :bindVar0 ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
        Date expectedBindValue = Date.today().addMonths(-1);
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, expectedBindValue))
            .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
            .limitTo(1);

        // TEST
        accountQuery.generateBindVariableKeys();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery()); // Below assertions will fail if made before query string is generated
        System.Assert.isTrue(accountQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
        System.Assert.areEqual(expectedBindValue, accountQuery.doGetBindsMap().get('bindVar0'), 'bind value');
    }

    @isTest
    static void it_will_generate_a_bind_variable_when_instructed_before_filter_is_added()
    {
        // SETUP
        String expectedQueryString = 'SELECT CreatedDate, Id FROM Account WHERE CreatedDate >= :bindVar0 ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
        Date expectedBindValue = Date.today().addMonths(-1);
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.CreatedDate)
            .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
            .limitTo(1);

        // TEST
        accountQuery.generateBindVariableKeys();
        accountQuery.filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, expectedBindValue));

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery()); // Below assertions will fail if made before query string is generated
        System.Assert.isTrue(accountQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
        System.Assert.areEqual(expectedBindValue, accountQuery.doGetBindsMap().get('bindVar0'), 'bind value');
    }

    @isTest
    static void it_will_not_generate_a_bind_variable_if_already_specified()
    {
        // SETUP
        String expectedQueryString = 'SELECT CreatedDate, Id FROM Account WHERE CreatedDate >= :dateFilter ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .addField(Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today().addMonths(-1), 'dateFilter'))
            .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
            .limitTo(1);

        // TEST
        accountQuery.generateBindVariableKeys();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
        System.Assert.isFalse(accountQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
        System.Assert.isTrue(accountQuery.doGetBindsMap().containsKey('dateFilter'), 'generated bind key exists');
        System.Assert.areEqual(Date.today().addMonths(-1), accountQuery.doGetBindsMap().get('dateFilter'), 'bind value');
    }

    // @isTest
    // static void it_will_generate_a_bind_variable_if_removed()
    // {
    //     // SETUP
    //     String expectedQueryString = 'SELECT CreatedDate, Id, Name FROM Account WHERE CreatedDate >= :bindVar0 ORDER BY CreatedDate ASC NULLS FIRST LIMIT 1';
    //     Date expectedBindValue = Date.today().addMonths(-1);
    //     Query accountQuery = new Query(Schema.Account.getSObjectType())
    //         .addField(Schema.Account.CreatedDate)
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, expectedBindValue, 'dateFilter'))
    //         .orderByField(Schema.Account.CreatedDate, SOQL.SortOrder.ASCENDING)
    //         .limitTo(1);

    //     // TEST
    //     accountQuery.removeBind('dateFilter');
    //     accountQuery.generateBindVariableKeys();

    //     // VERIFY
    //     System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    //     System.Assert.isFalse(accountQuery.doGetBindsMap().containsKey('dateFilter'), 'generated bind key exists');
    //     System.Assert.isTrue(accountQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
    //     System.Assert.areEqual(expectedBindValue, accountQuery.doGetBindsMap().get('bindVar0'), 'bind value');
    // }

    @isTest
    static void it_will_construct_a_where_clause_based_on_custom_logic()
    {
        // SETUP
        String expectedQueryString = 'SELECT Id FROM Account WHERE (CreatedDate = :bindVar1 OR LastModifiedDate = :bindVar0) AND (Name LIKE :bindVar3 OR Parent.Name LIKE :bindVar2)';
        Query accountQuery = new Query(Schema.Account.getSObjectType())
            .generateBindVariableKeys()
            .filterWhere(new SOQL.QueryFilter(Schema.Account.LastModifiedDate, SOQL.Operator.EQUALS, Date.today()))
            .orFilterWhere(
                new List<SOQL.QueryFilter> {
                    new SOQL.QueryFilter(new SOQL.QueryField(Schema.Account.getSObjectType(), 'Parent.Name'), SOQL.Operator.IS_LIKE, 'Test%'),
                    new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.EQUALS, Date.today().addDays(-1))
                }
            )
            .filterWhere(new SOQL.QueryFilter(Schema.Account.Name, SOQL.Operator.IS_LIKE, 'Smith%'));

        // TEST
        accountQuery.setWhereFilterLogic('(2 OR 1) AND (4 OR 3)');

        // VERIFY
        System.Assert.areEqual(expectedQueryString, accountQuery.getQuery());
    }

}
