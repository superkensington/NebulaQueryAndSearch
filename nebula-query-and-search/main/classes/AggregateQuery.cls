/*******************************************************************************************************
 * This file is part of the Nebula Query & Search project, released under the MIT License.             *
 * See LICENSE file or go to https://github.com/jongpie/NebulaQueryAndSearch for full license details. *
 ******************************************************************************************************/

/**
 * @group SOQL Queries
 * @description Handles generating & executing aggregate queries
 * @see SOQL
 * @see Query
 */
@SuppressWarnings(
    'PMD.ApexDoc, PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount, PMD.FieldDeclarationsShouldBeAtStart'
)
global class AggregateQuery extends SOQL {

    private SOQL.GroupingDimension groupingDimension;
    private List<AggregateField> aggregateFields;
    private List<String> havingConditions;
    private String countQuery;

      global AggregateQuery(Schema.SObjectType sObjectType)
      {
        super(sObjectType, false);

        this.aggregateFields = new List<AggregateField>();
        this.havingConditions = new List<String>();
      }

    global AggregateQuery groupByField(Schema.SObjectField field)
    {
        return this.groupByFields(new List<Schema.SObjectField>{ field });
    }

    global AggregateQuery groupByField(SOQL.QueryField queryField)
    {
        return this.groupByFields(new List<SOQL.QueryField>{ queryField });
    }

    global AggregateQuery groupByFields(List<Schema.SObjectField> fields)
    {
        List<SOQL.QueryField> queryFields = new List<SOQL.QueryField>();
        for (Schema.SObjectField field : fields)
        {
            queryFields.add(new SOQL.QueryField(field));
        }
        return this.groupByFields(queryFields);
    }

    global AggregateQuery groupByFields(List<SOQL.QueryField> queryFields)
    {
        super.doAddFields(queryFields, null);
        return this;
    }

    global AggregateQuery groupByFieldSet(Schema.FieldSet fieldSet)
    {
        List<SOQL.QueryField> queryFields = new List<SOQL.QueryField>();
        for (Schema.FieldSetMember fieldSetMember : fieldSet.getFields())
        {
            queryFields.add(new SOQL.QueryField(this.sObjectType, fieldSetMember.getFieldPath()));
        }
        return this.groupByFields(queryFields);
    }

    global AggregateQuery usingGroupingDimension(SOQL.GroupingDimension groupingDimension)
    {
        this.groupingDimension = groupingDimension;
        return (AggregateQuery)super.setHasChanged();
    }

    global AggregateQuery addAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field)
    {
        return this.addAggregate(aggregateFunction, field, null);
    }

    global AggregateQuery addAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field, String fieldAlias)
    {
        return this.addAggregate(aggregateFunction, new SOQL.QueryField(field), fieldAlias);
    }

    global AggregateQuery addAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField)
    {
        return this.addAggregate(aggregateFunction, queryField, null);
    }

    global AggregateQuery addAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, String fieldAlias)
    {
        this.aggregateFields.add(new AggregateField(this.getSObjectType(), aggregateFunction, queryField, fieldAlias));
        return (AggregateQuery)super.setHasChanged();
    }

    global AggregateQuery havingAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field, SOQL.Operator operator, Object value)
    {
        return this.havingAggregate(aggregateFunction, new SOQL.QueryField(field), operator, value);
    }

    global AggregateQuery havingAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field, SOQL.Operator operator, Object value, String bindWithKey)
    {
        return this.havingAggregate(aggregateFunction, new SOQL.QueryField(field), operator, value, bindWithKey);
    }

    global AggregateQuery havingAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, SOQL.Operator operator, Object value)
    {
        return this.havingAggregate(aggregateFunction, queryField, operator, value, null);
    }

    global AggregateQuery havingAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, SOQL.Operator operator, Object value, String bindWithKey)
    {
        this.havingConditions.add(
        String.format(
            '{0}({1}) {2} {3}',
            new List<String> {
                aggregateFunction.name(),
                queryField.toString(),
                SOQL.getOperatorValue(operator),
                (String.isNotBlank(bindWithKey) ? ':' + bindWithKey : new QueryArgument(value).toString())
            }
        )
        );
        if (String.isNotBlank(bindWithKey))
        {
            this.bindsMap.put(bindWithKey, value);
        }
        return (AggregateQuery)super.setHasChanged();
    }

    global AggregateQuery filterWhere(Schema.SObjectField field, SOQL.Operator operator, Object value)
    {
        return this.filterWhere(new SOQL.QueryField(field), operator, value);
    }

    global AggregateQuery filterWhere(Schema.SObjectField field, SOQL.Operator operator, Object value, String bindWithKey)
    {
        return this.filterWhere(new SOQL.QueryField(field), operator, value, bindWithKey);
    }

    global AggregateQuery filterWhere(SOQL.QueryField queryField, SOQL.Operator operator, Object value)
    {
        return this.filterWhere(new SOQL.QueryFilter(queryField, operator, value));
    }

    global AggregateQuery filterWhere(SOQL.QueryField queryField, SOQL.Operator operator, Object value, String bindWithKey)
    {
        return this.filterWhere(new SOQL.QueryFilter(queryField, operator, value, bindWithKey));
    }

    global AggregateQuery filterWhere(SOQL.QueryFilter filter)
    {
        return this.filterWhere(new List<SOQL.QueryFilter>{ filter });
    }

    global AggregateQuery filterWhere(List<SOQL.QueryFilter> filters)
    {
        super.doFilterWhere(filters);
        return this;
    }

    global AggregateQuery orFilterWhere(List<SOQL.QueryFilter> filters)
    {
        super.doOrFilterWhere(filters);
        return this;
    }

    global AggregateQuery withAccessLevel(System.AccessLevel mode)
    {
        super.doWithAccessLevel(mode);
        return this;
    }

    global AggregateQuery orderByField(Schema.SObjectField field)
    {
        return this.orderByField(field, null);
    }

    global AggregateQuery orderByField(SOQL.QueryField queryField)
    {
        return this.orderByField(queryField, null);
    }

    global AggregateQuery orderByField(Schema.SObjectField field, SOQL.SortOrder sortOrder)
    {
        return this.orderByField(field, sortOrder, null);
    }

    global AggregateQuery orderByField(SOQL.QueryField queryField, SOQL.SortOrder sortOrder)
    {
        return this.orderByField(queryField, sortOrder, null);
    }

    global AggregateQuery orderByField(Schema.SObjectField field, SOQL.SortOrder sortOrder, Boolean sortNullsFirst)
    {
        super.doOrderByField(new SOQL.QueryField(field), sortOrder, sortNullsFirst);
        return this;
    }

    global AggregateQuery orderByField(SOQL.QueryField queryField, SOQL.SortOrder sortOrder, Boolean sortNullsFirst)
    {
        super.doOrderByField(queryField, sortOrder, sortNullsFirst);
        return this;
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field)
    {
        return this.orderByAggregate(aggregateFunction, field, null);
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field, SOQL.SortOrder sortOrder)
    {
        return this.orderByAggregate(aggregateFunction, field, sortOrder, null);
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, Schema.SObjectField field, SOQL.SortOrder sortOrder, Boolean sortNullsFirst)
    {
        return this.orderByAggregate(aggregateFunction, new SOQL.QueryField(field), sortOrder, sortNullsFirst);
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField)
    {
        return this.orderByAggregate(aggregateFunction, queryField, null);
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, SOQL.SortOrder sortOrder)
    {
        return this.orderByAggregate(aggregateFunction, queryField, sortOrder, null);
    }

    global AggregateQuery orderByAggregate(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, SOQL.SortOrder sortOrder, Boolean sortNullsFirst)
    {
        super.doOrderByField(aggregateFunction.name() + '(' + queryField + ')', sortOrder, sortNullsFirst);
        return this;
    }

    global AggregateQuery limitTo(Integer numberOfRecords)
    {
        super.doLimitTo(numberOfRecords);
        return this;
    }

    global AggregateQuery offsetBy(Integer offset)
    {
        super.doOffsetBy(offset);
        return this;
    }

    global AggregateQuery setBind(String key, Object value)
    {
        super.doSetBind(key, value);
        return this;
    }

    global AggregateQuery setBinds(Map<String, Object> binds)
    {
        super.doSetBinds(binds);
        return this;
    }

    global AggregateQuery removeBind(String key)
    {
        super.doRemoveBind(key);
        return this;
    }

    global AggregateQuery clearBinds()
    {
        super.doClearBinds();
        return this;
    }

    global AggregateQuery cacheResults()
    {
        super.doCacheResults();
        return this;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    global override String getQuery()
    {
        if (this.query != null && !this.hasChanged)
        {
            return this.query;
        }

        String queryFieldString = super.doGetQueryFieldString();
        String aggregateQueryFieldString = this.getAggregateQueryFieldString();
        String aggregateFieldDelimiter = !String.isEmpty(queryFieldString) && !String.isEmpty(aggregateQueryFieldString) ? ', ' : '';

        String combinedFieldsString = queryFieldString + aggregateFieldDelimiter + aggregateQueryFieldString;
        if (String.isBlank(combinedFieldsString))
        {
            Schema.SObjectField idField = this.getSObjectType().getDescribe().fields.getMap().get('Id');
            combinedFieldsString = new AggregateField(this.getSObjectType(), SOQL.Aggregate.COUNT, new SOQL.QueryField(idField), null).toString();
        }

        this.query =
            'SELECT ' +
            combinedFieldsString +
            ' FROM ' +
            this.sObjectType +
            super.doGetUsingScopeString() +
            super.doGetWhereClauseString() +
            this.getGroupByString() +
            this.getHavingString() +
            super.doGetOrderByString() +
            super.doGetLimitCountString() +
            super.doGetOffetString();

        System.debug(System.LoggingLevel.FINEST, this.query);
        return this.query;
    }

    global String getCountQuery()
    {
        if (this.countQuery != null && !this.hasChanged)
        {
            return this.countQuery;
        }

        this.countQuery =
            'SELECT COUNT()' +
            ' FROM ' +
            this.sObjectType +
            super.doGetUsingScopeString() +
            super.doGetWhereClauseString() +
            this.getGroupByString() +
            this.getHavingString() +
            super.doGetOrderByString() +
            super.doGetLimitCountString() +
            super.doGetOffetString();

        System.debug(System.LoggingLevel.FINEST, this.countQuery);
        return this.countQuery;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    global Integer getCountResults()
    {
        return Database.countQueryWithBinds(
            this.getCountQuery(),
            this.doGetBindsMap(),
            this.doGetAccessLevel()
        );
    }

    global AggregateResult getFirstResult()
    {
        return (AggregateResult)super.doGetFirstResult();
    }

    global List<AggregateResult> getResults()
    {
        return (List<AggregateResult>)super.doGetResults();
    }

    private String getAggregateQueryFieldString()
    {
        if (this.aggregateFields.isEmpty())
        {
            return '';
        }

        List<String> aggregateFieldStrings = new List<String>();
        for (AggregateQuery.AggregateField aggregatedField : this.aggregateFields)
        {
            aggregateFieldStrings.add(aggregatedField.toString());
        }
        aggregateFieldStrings.sort();
        return String.join(aggregateFieldStrings, ', ');
    }

    private String getGroupByString()
    {
        String queryFieldString = super.doGetQueryFieldString();

        String groupByTextString = ' GROUP BY ';
        String groupingDimensionClosingString = '';
        if (this.groupingDimension != null)
        {
            groupByTextString += this.groupingDimension.name() + '(';
            groupingDimensionClosingString = ')';
        }

        return String.isEmpty(queryFieldString) ? '' : groupByTextString + queryFieldString + groupingDimensionClosingString;
    }

    private String getHavingString()
    {
        return this.havingConditions.isEmpty() ? '' : ' HAVING ' + String.join(this.havingConditions, ', ');
    }

    private class AggregateField {

        private Schema.SObjectType sObjectType;
        private String aggregateFieldPath;

        public AggregateField(Schema.SObjectType sObjectType, SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, String fieldAlias)
        {
            this.sObjectType = sObjectType;
            this.aggregateFieldPath = this.getAggregateFieldPath(aggregateFunction, queryField, fieldAlias);
        }

        public override String toString()
        {
            return this.aggregateFieldPath;
        }

        private String getAggregateFieldPath(SOQL.Aggregate aggregateFunction, SOQL.QueryField queryField, String fieldAlias)
        {
            String fieldApiName = queryField.getDescribe().getName();
            fieldAlias = !String.isEmpty(fieldAlias) ? String.escapeSingleQuotes(fieldAlias) : aggregateFunction.name() + '__' + fieldApiName;

            // Example: MIN(Schema.Lead.MyField__c) is auto-aliased to MyField__c__MIN
            return aggregateFunction.name() + '(' + fieldApiName + ') ' + fieldAlias;
        }
    }

}
