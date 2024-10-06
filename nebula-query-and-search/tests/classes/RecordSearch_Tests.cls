/*******************************************************************************************************
 * This file is part of the Nebula Query & Search project, released under the MIT License.             *
 * See LICENSE file or go to https://github.com/jongpie/NebulaQueryAndSearch for full license details. *
 ******************************************************************************************************/

@SuppressWarnings(
  'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CyclomaticComplexity, PMD.EagerlyLoadedDescribeSObjectResult, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.UnusedLocalVariable'
)
@isTest(IsParallel=true)
private class RecordSearch_Tests {

    @isTest
    static void it_should_return_first_result_for_a_single_sobject_type()
    {
        // SETUP
        Query userQuery = new Query(Schema.User.getSObjectType());
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), userQuery);
        List<List<SObject>> mockResults = new List<List<SObject>> {
            new List<SObject> {
                new User(Id = UserInfo.getUserId())
            }
        };
        SOSL.mockResults(mockResults);

        // TEST
        User userSearchResult = (User)userSearch.getFirstResult();

        // VERIFY
        System.assertEquals(Userinfo.getUserId(), userSearchResult.Id);
    }

    @isTest
    static void it_should_return_results_for_a_single_sobject_type()
    {
        // SETUP
        Query userQuery = new Query(Schema.User.getSObjectType());
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), userQuery);
        List<List<SObject>> mockResults = new List<List<SObject>> {
            new List<SObject> {
                new User(Id = UserInfo.getUserId())
            }
        };
        SOSL.mockResults(mockResults);

        // TEST
        List<User> userSearchResults = userSearch.getFirstResults();

        // VERIFY
        System.assertEquals(1, userSearchResults.size());
        System.assertEquals(Userinfo.getUserId(), userSearchResults[0].Id);

    }

    @isTest
    static void it_should_return_results_for_multiple_sobject_types()
    {
        // SETUP
        List<Query> queries = new List<Query>{
            new Query(Schema.User.getSObjectType()),
            new Query(Schema.Account.getSObjectType())
        };
        RecordSearch search = new RecordSearch(System.UserInfo.getUserEmail(), queries);
        List<List<SObject>> mockResults = new List<List<SObject>> {
            new List<SObject> {
                new User(Id = UserInfo.getUserId())
            },
            new List<SObject> {
                new Account(Name = 'Test Account')
            }
        };
        SOSL.mockResults(mockResults);

        // TEST
        List<List<SObject>> searchResults = search.getResults();

        // VERIFY
        System.assertEquals(2, searchResults.size());
        System.assertEquals(Userinfo.getUserId(), searchResults[0][0].Id);
        System.assertEquals(((Account)mockResults[1][0]).Name, ((Account)searchResults[1][0]).Name);
    }

    @isTest
    static void it_should_build_a_search_with_highlight_enabled()
    {
        // SETUP
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN ALL FIELDS RETURNING User(Id) WITH HIGHLIGHT';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.withHighlight();

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_build_a_search_with_snippet_enabled()
    {
        // SETUP
        Integer snippetTargetLength = 10;
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN ALL FIELDS RETURNING User(Id) WITH SNIPPET (target_length=' + snippetTargetLength + ')';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.withSnippet(snippetTargetLength);

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_build_a_search_in_email_search_group()
    {
        // SETUP
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN EMAIL FIELDS RETURNING User(Id)';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.inSearchGroup(SOSL.SearchGroup.EMAIL_FIELDS);

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_build_a_search_with_spell_correction_enabled()
    {
        // SETUP
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN ALL FIELDS RETURNING User(Id) WITH SPELL_CORRECTION = true';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.withSpellCorrection();

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_build_a_search_with_update_article_reporting_for_tracking_enabled()
    {
        // SETUP
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN ALL FIELDS RETURNING User(Id) UPDATE TRACKING';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.updateArticleReporting(SOSL.ArticleReporting.TRACKING);

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_build_a_search_with_update_article_reporting_for_viewstat_enabled()
    {
        // SETUP
        String expectedSearchQueryString = 'FIND \'' + System.UserInfo.getUserEmail() + '\' IN ALL FIELDS RETURNING User(Id) UPDATE VIEWSTAT';
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), new Query(Schema.User.getSObjectType()));

        // TEST
        userSearch.updateArticleReporting(SOSL.ArticleReporting.VIEWSTAT);

        // VERIFY
        System.assertEquals(expectedSearchQueryString, userSearch.getSearch());
    }

    @isTest
    static void it_should_run_with_system_mode_by_default()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        Query contactQuery = new Query(Schema.Contact.getSObjectType());
        RecordSearch contactSearch = new RecordSearch(System.UserInfo.getUserEmail(), contactQuery);

        // TEST
        System.AccessLevel accessLevel = contactSearch.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_system_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.SYSTEM_MODE;
        Query contactQuery = new Query(Schema.Contact.getSObjectType());
        RecordSearch contactSearch = new RecordSearch(System.UserInfo.getUserEmail(), contactQuery)
            .withAccessLevel(System.AccessLevel.SYSTEM_MODE);

        // TEST
        System.AccessLevel accessLevel = contactSearch.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_run_with_user_mode()
    {
        // SETUP
        System.AccessLevel expectedAccessLevel = System.AccessLevel.USER_MODE;
        Query contactQuery = new Query(Schema.Contact.getSObjectType());
        RecordSearch contactSearch = new RecordSearch(System.UserInfo.getUserEmail(), contactQuery)
            .withAccessLevel(System.AccessLevel.USER_MODE);

        // TEST
        System.AccessLevel accessLevel = contactSearch.doGetAccessLevel();

        // VERIFY
        System.Assert.areEqual(expectedAccessLevel, accessLevel);
    }

    @isTest
    static void it_should_not_cache_search_results_by_default()
    {
        // SETUP
        Integer soslQueriesCount = System.Limits.getSoslQueries();
        Query userQuery = new Query(Schema.User.getSObjectType());
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), userQuery);
        userSearch.getResults();

        // TEST
        userSearch.getResults();

        // VERIFY
        System.Assert.areEqual(soslQueriesCount + 2, System.Limits.getSoslQueries());
    }

    @isTest
    static void it_should_cache_search_results_when_enabled()
    {
        // SETUP
        Integer soslQueriesCount = System.Limits.getSoslQueries();
        Query userQuery = new Query(Schema.User.getSObjectType());
        RecordSearch userSearch = new RecordSearch(System.UserInfo.getUserEmail(), userQuery);

        // TEST
        userSearch.cacheResults();
        userSearch.getResults();
        userSearch.getResults();

        // VERIFY
        System.Assert.areEqual(soslQueriesCount + 1, System.Limits.getSoslQueries());
    }

}
