/*******************************************************************************************************
 * This file is part of the Nebula Query & Search project, released under the MIT License.             *
 * See LICENSE file or go to https://github.com/jongpie/NebulaQueryAndSearch for full license details. *
 ******************************************************************************************************/

@SuppressWarnings(
    'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CyclomaticComplexity, PMD.EagerlyLoadedDescribeSObjectResult, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.UnusedLocalVariable'
)
@isTest(IsParallel=true)
private class AggregateQuery_Tests {

    @isTest
    static void it_should_build_a_count_query_string_without_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT COUNT() FROM Opportunity WHERE AccountId != null';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType());

        // TEST
        aggregateQuery.filterWhere(
            new SOQL.QueryFilter(Schema.Opportunity.AccountId, SOQL.Operator.NOT_EQUAL_TO, null)
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getCountQuery());
    }

    @isTest
    static void it_should_build_a_count_query_string_with_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT COUNT() FROM Opportunity WHERE AccountId != :accountIdFilter';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType());

        // TEST
        aggregateQuery.filterWhere(
            new SOQL.QueryFilter(Schema.Opportunity.AccountId, SOQL.Operator.NOT_EQUAL_TO, null, 'accountIdFilter')
        );

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getCountQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_group_by_cube()
    {
        // SETUP
        String expectedQueryString = 'SELECT Type, StageName, SUM(Amount) SUM__Amount FROM Opportunity GROUP BY CUBE(Type, StageName)';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .groupByField(Schema.Opportunity.Type)
            .groupByField(Schema.Opportunity.StageName)
            .addAggregate(SOQL.Aggregate.SUM, Schema.Opportunity.Amount);

        // TEST
        aggregateQuery.usingGroupingDimension(SOQL.GroupingDimension.CUBE);

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_group_by_rollup()
    {
        // SETUP
        String expectedQueryString = 'SELECT Type, StageName, SUM(Amount) SUM__Amount FROM Opportunity GROUP BY ROLLUP(Type, StageName)';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .groupByField(Schema.Opportunity.Type)
            .groupByField(Schema.Opportunity.StageName)
            .addAggregate(SOQL.Aggregate.SUM, Schema.Opportunity.Amount);

        // TEST
        aggregateQuery.usingGroupingDimension(SOQL.GroupingDimension.ROLLUP);

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_having_aggregate_without_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT Name, COUNT(Id) COUNT__Id FROM Account GROUP BY Name HAVING COUNT(Id) > 2';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .groupByField(Schema.Account.Name)
            .addAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id);

        // TEST
        aggregateQuery.havingAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id, SOQL.Operator.GREATER_THAN, 2);

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_having_aggregate_with_binds()
    {
        // SETUP
        String expectedQueryString = 'SELECT Name, COUNT(Id) COUNT__Id FROM Account GROUP BY Name HAVING COUNT(Id) > :minCount';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .groupByField(Schema.Account.Name)
            .addAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id);

        // TEST
        aggregateQuery.havingAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id, SOQL.Operator.GREATER_THAN, 2, 'minCount');

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_group_by_a_date_function()
    {
        // SETUP
        String expectedQueryString = 'SELECT CALENDAR_MONTH(CloseDate), COUNT(Id) COUNT__Id FROM Opportunity GROUP BY CALENDAR_MONTH(CloseDate)';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .addAggregate(SOQL.Aggregate.COUNT, Opportunity.Id);

        // TEST
        aggregateQuery.groupByField(new SOQL.QueryField(SOQL.DateFunction.CALENDAR_MONTH, Schema.Opportunity.CloseDate));

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_run_with_system_mode_by_default()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .addAggregate(SOQL.Aggregate.COUNT, Opportunity.Id);

        // TEST
        System.AccessLevel accessLevel = aggregateQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_system_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .addAggregate(SOQL.Aggregate.COUNT, Opportunity.Id)
            .withAccessLevel(System.AccessLevel.SYSTEM_MODE);

        // TEST
        System.AccessLevel accessLevel = aggregateQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_user_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.USER_MODE;
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .addAggregate(SOQL.Aggregate.COUNT, Opportunity.Id)
            .withAccessLevel(System.AccessLevel.USER_MODE);

        // TEST
        System.AccessLevel accessLevel = aggregateQuery.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_build_a_ridiculous_query_string()
    {
        // SETUP
        String expectedQueryString =
            'SELECT Account.Type, StageName, AVG(Amount) AVG__Amount, COUNT(AccountId) COUNT__AccountId,' +
            ' COUNT_DISTINCT(AccountId) COUNT_DISTINCT__AccountId, COUNT_DISTINCT(OwnerId) COUNT_DISTINCT__OwnerId, COUNT_DISTINCT(Type) COUNT_DISTINCT__Type,' +
            ' MAX(CreatedDate) MAX__CreatedDate, MIN(CreatedDate) MIN__CreatedDate, SUM(Amount) SUM__Amount' +
            ' FROM Opportunity' +
            ' WHERE AccountId != null AND CreatedDate >= :createdDateFilter' +
            ' GROUP BY Account.Type, StageName' +
            ' ORDER BY Account.Type ASC NULLS FIRST, StageName ASC NULLS FIRST, SUM(Amount) ASC NULLS FIRST,' +
            ' MIN(CloseDate) DESC NULLS FIRST, MAX(Account.LastActivityDate) ASC NULLS FIRST' +
            ' LIMIT 100' +
            ' OFFSET 0';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Opportunity.getSObjectType())
            .addAggregate(SOQL.Aggregate.MAX, Schema.Opportunity.CreatedDate)
            .addAggregate(SOQL.Aggregate.AVG, Schema.Opportunity.Amount)
            .addAggregate(SOQL.Aggregate.COUNT_DISTINCT, Schema.Opportunity.OwnerId)
            .addAggregate(SOQL.Aggregate.MIN, Schema.Opportunity.CreatedDate)
            .groupByField(new SOQL.QueryField(new List<Schema.SObjectField>{ Schema.Opportunity.AccountId, Schema.Account.Type }))
            .addAggregate(SOQL.Aggregate.SUM, Schema.Opportunity.Amount)
            .groupByField(Schema.Opportunity.StageName)
            .addAggregate(SOQL.Aggregate.COUNT, Schema.Opportunity.AccountId)
            .addAggregate(SOQL.Aggregate.COUNT_DISTINCT, Schema.Opportunity.AccountId)
            .addAggregate(SOQL.Aggregate.COUNT_DISTINCT, new SOQL.QueryField(new List<Schema.SObjectField>{ Schema.Opportunity.AccountId, Schema.Account.Type }))
            .orderByField(new SOQL.QueryField(new List<Schema.SObjectField>{ Schema.Opportunity.AccountId, Schema.Account.Type }))
            .orderByField(Schema.Opportunity.StageName)
            .orderByAggregate(SOQL.Aggregate.SUM, Schema.Opportunity.Amount)
            .orderByAggregate(SOQL.Aggregate.MIN, Schema.Opportunity.CloseDate, SOQL.SortOrder.DESCENDING)
            .orderByAggregate(SOQL.Aggregate.MAX, new SOQL.QueryField(new List<Schema.SObjectField>{ Schema.Opportunity.AccountId, Schema.Account.LastActivityDate }))
            .filterWhere(Schema.Opportunity.AccountId, SOQL.Operator.NOT_EQUAL_TO, null)
            .filterWhere(Schema.Opportunity.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today(), 'createdDateFilter')
            .limitTo(100)
            .offsetBy(0);

        // TEST
        String actualQueryString = aggregateQuery.getQuery();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, actualQueryString);
    }

    @isTest
    static void it_should_set_a_bind_variable()
    {
        // SETUP
        String bindKey = 'dateFilter';
        Date expectedBindValue = Date.today().addDays(-1);
        String expectedQueryString = 'SELECT MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE CreatedDate >= :dateFilter';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today().addMonths(-1), bindKey));

        // TEST
        aggregateQuery.setBind(bindKey, expectedBindValue);

        // VERIFY
        System.Assert.areEqual(expectedBindValue, aggregateQuery.doGetBindsMap().get(bindKey), 'bind value');
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_will_set_multiple_bind_variables()
    {
        // SETUP
        String bindKey1 = 'minDateFilter';
        String bindKey2 = 'maxDateFilter';
        Date expectedBindValue1 = Date.today().addDays(-7);
        Date expectedBindValue2 = Date.today();
        String expectedQueryString = 'SELECT MAX(CreatedDate) MAX__CreatedDate, MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE CreatedDate >= :minDateFilter AND CreatedDate < :maxDateFilter';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .addAggregate(SOQL.Aggregate.MAX, Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Date.today().addMonths(-1), bindKey1))
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.LESS_THAN, Date.today().addDays(-1), bindKey2));

        // TEST
        aggregateQuery.setBind(bindKey1, expectedBindValue1);
        aggregateQuery.setBind(bindKey2, expectedBindValue2);

        // VERIFY
        System.Assert.areEqual(expectedBindValue1, aggregateQuery.doGetBindsMap().get(bindKey1), 'bind value 1');
        System.Assert.areEqual(expectedBindValue2, aggregateQuery.doGetBindsMap().get(bindKey2), 'bind value 2');
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    // @isTest
    // static void it_will_remove_a_bind_variable()
    // {
    //     // SETUP
    //     String bindKey = 'dateFilter';
    //     String expectedQueryString = 'SELECT MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE CreatedDate >= 2000-01-01T05:00:00Z';
    //     AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
    //         .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Datetime.newInstance(2000, 1, 1), bindKey));

    //     // TEST
    //     aggregateQuery.removeBind(bindKey);

    //     // VERIFY
    //     System.Assert.isFalse(aggregateQuery.doGetBindsMap().containsKey(bindKey), 'bind key exists in map');
    //     System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    // }

    // @isTest
    // static void it_will_clear_all_bind_variables()
    // {
    //     // SETUP
    //     String expectedQueryString = 'SELECT MAX(CreatedDate) MAX__CreatedDate, MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE CreatedDate >= 2000-01-01T05:00:00Z AND CreatedDate < 2001-01-01T05:00:00Z';
    //     AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
    //         .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
    //         .addAggregate(SOQL.Aggregate.MAX, Schema.Account.CreatedDate)
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, Datetime.newInstance(2000, 1, 1), 'minDateFilter'))
    //         .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.LESS_THAN, Datetime.newInstance(2001, 1, 1), 'maxDateFilter'));

    //     // TEST
    //     aggregateQuery.clearBinds();

    //     // VERIFY
    //     System.Assert.areEqual(0, aggregateQuery.doGetBindsMap().size(), '# of bind keys');
    //     System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    // }

    @isTest
    static void it_will_generate_a_bind_variable_for_a_having_filter()
    {
        // SETUP
        String expectedQueryString = 'SELECT ParentId, MIN(CreatedDate) MIN__CreatedDate FROM Account GROUP BY ParentId HAVING MIN(CreatedDate) >= :bindVar0';
        Date expectedBindValue = Date.today().addMonths(-1);
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .groupByField(Account.ParentId)
            .havingAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, expectedBindValue);

        // TEST
        aggregateQuery.generateBindVariableKeys();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery()); // Below assertions will fail if made before query string is generated
        System.Assert.isTrue(aggregateQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
        System.Assert.areEqual(expectedBindValue, aggregateQuery.doGetBindsMap().get('bindVar0'), 'bind value');
    }

    @isTest
    static void it_will_generate_a_bind_variable_for_a_where_filter()
    {
        // SETUP
        String expectedQueryString = 'SELECT MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE CreatedDate >= :bindVar0';
        Date expectedBindValue = Date.today().addMonths(-1);
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.GREATER_THAN_OR_EQUAL_TO, expectedBindValue));

        // TEST
        aggregateQuery.generateBindVariableKeys();

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery()); // Below assertions will fail if made before query string is generated
        System.Assert.isTrue(aggregateQuery.doGetBindsMap().containsKey('bindVar0'), 'generated bind key exists');
        System.Assert.areEqual(expectedBindValue, aggregateQuery.doGetBindsMap().get('bindVar0'), 'bind value');
    }

    @isTest
    static void it_will_build_a_query_string_with_a_where_clause_based_on_custom_logic()
    {
        // SETUP
        String expectedQueryString = 'SELECT MIN(CreatedDate) MIN__CreatedDate FROM Account WHERE (CreatedDate = :bindVar1 OR LastModifiedDate = :bindVar0) AND (Name LIKE :bindVar3 OR Parent.Name LIKE :bindVar2)';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .generateBindVariableKeys()
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .filterWhere(new SOQL.QueryFilter(Schema.Account.LastModifiedDate, SOQL.Operator.EQUALS, Date.today()))
            .orFilterWhere(
                new List<SOQL.QueryFilter> {
                new SOQL.QueryFilter(new SOQL.QueryField(Schema.Account.getSObjectType(), 'Parent.Name'), SOQL.Operator.IS_LIKE, 'Test%'),
                new SOQL.QueryFilter(Schema.Account.CreatedDate, SOQL.Operator.EQUALS, Date.today().addDays(-1))
                }
            )
            .filterWhere(new SOQL.QueryFilter(Schema.Account.Name, SOQL.Operator.IS_LIKE, 'Smith%'));

        // TEST
        aggregateQuery.setWhereFilterLogic('(2 OR 1) AND (4 OR 3)');

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

    @isTest
    static void it_should_build_a_query_string_with_a_having_clause_based_on_custom_logic()
    {
        // SETUP
        String expectedQueryString = 'SELECT COUNT(Id) COUNT__Id, MIN(CreatedDate) MIN__CreatedDate, MIN(LastModifiedDate) MIN__LastModifiedDate FROM Account HAVING (MIN(CreatedDate) = :bindVar2 OR MIN(LastModifiedDate) = :bindVar1) AND (COUNT(Id) = :bindVar3 OR COUNT(Id) = :bindVar0)';
        AggregateQuery aggregateQuery = new AggregateQuery(Schema.Account.getSObjectType())
            .generateBindVariableKeys()
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate)
            .addAggregate(SOQL.Aggregate.MIN, Schema.Account.LastModifiedDate)
            .addAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id)
            .havingAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id, SOQL.Operator.EQUALS, 10)
            .havingAggregate(SOQL.Aggregate.MIN, Schema.Account.LastModifiedDate, SOQL.Operator.EQUALS, Datetime.newInstance(2000, 1, 1))
            .havingAggregate(SOQL.Aggregate.MIN, Schema.Account.CreatedDate, SOQL.Operator.EQUALS, Datetime.newInstance(2021, 12, 31))
            .havingAggregate(SOQL.Aggregate.COUNT, Schema.Account.Id, SOQL.Operator.EQUALS, 100);

        // TEST
        aggregateQuery.setHavingFilterLogic('(3 OR 2) AND (4 OR 1)');

        // VERIFY
        System.Assert.areEqual(expectedQueryString, aggregateQuery.getQuery());
    }

}
