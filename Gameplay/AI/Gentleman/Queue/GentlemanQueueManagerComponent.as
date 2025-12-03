// Non-struct, to return as reference
class UGentlemanQueue : UObject
{
	private TArray<AActor> Queuers;

	void JoinQueue(AActor Actor)
	{
		Queuers.AddUnique(Actor);
	}

	void LeaveQueue(AActor Actor)
	{
		Queuers.RemoveSingle(Actor);	
	}

	void MoveQueue(AActor Actor, int NewIndex)
	{
		Queuers.RemoveSingle(Actor);
		Queuers.Insert(Actor, NewIndex);
	}

	void ClearQueue()
	{
		Queuers.Empty();
	}	

	TArray<AActor> GetMembers()
	{
		return Queuers;
	}
}

class UGentlemanQueueManagerComponent : UActorComponent
{
	private TMap<FName, UGentlemanQueue> Queues;

	UGentlemanQueue GetQueue(const FName& QueueName)
	{
		if(!Queues.Contains(QueueName))
		{
			Queues.Add(QueueName, NewObject(GetTransientPackage(), UGentlemanQueue));
		}
		return Queues[QueueName];
	}
}