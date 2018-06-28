public class CWLib_Describe {

    private static Map<String, CWLib_Describe> cache {
        get {
            if(cache == null) {
                return new Map<String, CWLib_Describe>();
            }
            return cache;
        }
        set;
    }

    private Schema.SobjectType token;
    private Schema.DescribeSObjectResult describe {
        get {
            if(describe == null) {
                describe = token.getDescribe();
            }

            return describe;
        }
        set;
    }

    public static CWLib_Describe describe(Schema.SObjectType token) {
        return describe(String.valueOf(token));
    }

    public static CWLib_Describe describe(String token) {
        CWLib_Describe instance = cache.get(token);

        if(instance == null) {
            instance = new CWLib_Describe(token);
        }

        return instance;
    }

    public CWLib_Describe(Schema.SobjectType sObjectType) {
        register(sObjectType);
    }

    public CWLib_Describe(String sObjectType) {
        if(!cache.containsKey(sObjectType)) {
            register(sObjectType);
        }
    }

    private void register(Schema.SObjectType sObjectType) {
        String sObjectTypeString = String.valueOf(sObjectType);
        if(!cache.containsKey(sObjectTypeString)) {
            this.token = sObjectType;
            cache.put(String.valueOf(sObjectType), this);
        }
    }

    private void register(String sObjectType) {
        if(!cache.containsKey(sObjectType)) {
            this.describe = describeStringType(sObjectType);
            this.token = describe.getSObjectType();
            cache.put(sObjectType, this);
        }
    }

    private Schema.DescribeSObjectResult describeStringType(String sObjectType) {
        Schema.DescribeSObjectResult[] describeResults = Schema.DescribeSObjects(new String[] {sObjectType});
        return describeResults[0];
    }

    public String getNameField() {
        if(token == Schema.CampaignMember.SObjectType) {
            return Schema.CampaignMember.Name.getDescribe().getName();
        }

        for(Schema.DescribeFieldResult fieldDescribe : getFieldsByName().values()) {
            if(fieldDescribe.isNameField()) return fieldDescribe.getName();
        }

        return null;
    }

    public List<String> getFieldNames() {
        return new List<String>(getFieldMap().keySet());
    }

    public Map<String, Schema.SobjectField> getFieldMap() {
        return describe.fields.getMap();
    }

    public Map<String, Schema.DescribeFieldResult> getFieldsByName(Integer relationshipDepth) {
        Map<String, Schema.DescribeFieldResult> result = new Map<String, Schema.DescribeFieldResult>();

        while(relationshipDepth >= 0) {
            result.putAll(getFieldsByName());
            for(String fieldName : result.keySet()) {
                if(result.get(fieldName).getType() == Schema.DisplayType.Reference) {
                    result.putAll(getFieldsByName(--relationshipDepth));
                }
            }
        }

        return result;
    }

    public Map<String, Schema.DescribeFieldResult> getFieldsByName() {
        return getFieldsByName((IFieldFilter)null);
    }

    public Map<String, Schema.DescribeFieldResult> getFieldsByName(IFieldFilter filter) {
        Map<String, Schema.DescribeFieldResult> result = new Map<String, Schema.DescribeFieldResult>();
        
        for(Schema.SObjectField field : getFieldMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if(filter == null || filter.match(fieldDescribe)) {
                result.put(fieldDescribe.getName(), fieldDescribe);
            }
        }

        return result;
    } 

    public interface IFieldFilter {
        Boolean match(Schema.DescribeFieldResult fieldDescribe);
    }

    public class PhoneFieldFilter implements IFieldFilter {
        public Boolean match(Schema.DescribeFieldResult fieldDescribe) {
            String fieldName = fieldDescribe.getName();

            Boolean isFaxField = fieldName.toLowerCase().contains('fax');
            Boolean isPhoneField = fieldDescribe.getType() == Schema.DisplayType.Phone || fieldName.toLowerCase().contains('phone');

            return isPhoneField && !isFaxField;
        }
    }

    public class IsReferenceToTypeFilter implements IFieldFilter {
        Schema.SobjectType token;
        public IsReferenceToTypeFilter(Schema.SobjectType token) {
            this.token = token;
        }

        public Boolean match(Schema.DescribeFieldResult fieldDescribe) {
            Boolean result = false;
            if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
                for (Schema.sObjectType referenceType : fieldDescribe.getReferenceTo()) {
                    if (referenceType == token) {
                        result = true;
                        break;
                    }
                }
            }

            return result;
        }
    }

    public class FilterableFields implements IFieldFilter {
        public Boolean match(Schema.DescribeFieldResult fieldDescribe) {
            Boolean result = false;
            return fieldDescribe.isAccessible() && fieldDescribe.isFilterable();
        }
    }
}