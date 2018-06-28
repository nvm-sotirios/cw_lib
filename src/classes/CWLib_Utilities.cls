public class CWLib_Utilities {
    public static String getPackageNamespace() {
        String fullClassName = CWLib_Utilities.class.getName();
        String namespace = fullClassName.substringBefore('.');
        if (namespace == fullClassName) {
            return '';
        }
        return namespace;
    }

    public static String getNamespaceFieldPrefix() {
        String namespace = getPackageNamespace();
        if (String.isEmpty(namespace)) {
            return '';
        }
        return namespace + '__';
    }

    public static String getNamespaceClassPrefix() {
        String namespace = getPackageNamespace();
        if (String.isEmpty(namespace)) {
            return '';
        }
        return namespace + '.';
    }
}