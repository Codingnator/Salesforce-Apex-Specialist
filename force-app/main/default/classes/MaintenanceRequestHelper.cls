public with sharing class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(List<Case> maintenanceRequests) {
        // TODO: Complete the method to update workorders

        Set<Case> targetRequests = new Set<Case>();
        for (Case mr : maintenanceRequests)
            if (('Repair' == mr.Type || 'Routine Maintenance' == mr.Type) && 'Closed' == mr.Status)
                targetRequests.add(mr);

        List<AggregateResult> results = [
            SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c)
            FROM Work_Part__c
            WHERE Maintenance_Request__c IN :targetRequests
            GROUP BY Maintenance_Request__c
        ];

        Map<Id, Integer> requestToMinCycle = new Map<Id, Integer>();
        for (AggregateResult ar : results)
            requestToMinCycle.put(
                (Id)ar.get('Maintenance_Request__c'),
                ((Double)ar.get('expr0')).intValue()
            );

        List<Case> workOrders = new List<Case>();
        for (Case t : targetRequests)
            if (('Repair' == t.Type || 'Routine Maintenance' == t.Type) && 'Closed' == t.Status)
                workOrders.add(new Case(
                    Vehicle__c=t.Vehicle__c,
                    Type='Routine Maintenance',
                    Subject=t.Subject,
                    Status='New',
                    Date_Reported__c=Date.today(),
                    Date_Due__c=Date.today().addDays(requestToMinCycle.get(t.Id))
                ));
        
        if (!workOrders.isEmpty())
            insert workOrders;
    }        
    
}