namespace GentlemanCostQueueTags
{
	const FName GentlemanCostQueue = n"GentlemanCostQueue";
}

// Should be placed on AI
class UGentlemanCostQueueComponent : UActorComponent
{
	UBasicAITargetingComponent TargetComp;
	TPerPlayer<UGentlemanQueueManagerComponent> GentlemanQueueManagers;
	TArray<FInstigator> Joiners;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		for(auto QueuePlayer: Game::Players)
			GentlemanQueueManagers[QueuePlayer] = UGentlemanQueueManagerComponent::GetOrCreate(QueuePlayer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugString(Owner.ActorLocation, "" + GetQueuePosition());
	}
	
	void JoinQueue(FInstigator Instigator)
	{		
		if(GentlemanQueueManagers[GetPlayer()] == nullptr) 
			return;

		Joiners.AddUnique(Instigator);
		auto OtherQueue = GentlemanQueueManagers[GetOtherPlayer()].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		OtherQueue.LeaveQueue(Owner);
		auto Queue = GentlemanQueueManagers[GetPlayer()].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		Queue.JoinQueue(Owner);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool) 
			Debug::DrawDebugString(Owner.ActorLocation + FVector(0,0,80), "" + Queue.GetMembers().FindIndex(Owner), Scale = 2.0);
#endif
	}

	private void LeaveQueue()
	{
		if(GentlemanQueueManagers[GetPlayer()] == nullptr) 
			return;

		auto Queue = GentlemanQueueManagers[GetPlayer()].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		Queue.LeaveQueue(Owner);
	}

	void LeaveQueue(FInstigator Instigator)
	{
		Joiners.RemoveSingle(Instigator);
		if(Joiners.Num() > 0)
			return;

		LeaveQueue();
	}

	void MoveToNextInQueue(FInstigator Instigator)
	{
		if(GentlemanQueueManagers[GetPlayer()] == nullptr) 
			return;
		Joiners.AddUnique(Instigator);
		auto Queue = GentlemanQueueManagers[GetPlayer()].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		Queue.JoinQueue(Owner);
		Queue.MoveQueue(Owner, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		// Always leave all queues when disable
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UGentlemanQueue Queue = GentlemanQueueManagers[Player].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
			Queue.LeaveQueue(Owner);
		}
		Joiners.Empty();
	}

	bool IsNext(FInstigator Instigator)
	{
		if(GentlemanQueueManagers[GetPlayer()] == nullptr) 
			return false;
		
		if(!Joiners.Contains(Instigator))
			return false;

		auto Queue = GentlemanQueueManagers[GetPlayer()].GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		TArray<AActor> Members = Queue.GetMembers();
		int Index = Members.FindIndex(Owner);
		return Index == 0;
	}

	int GetQueuePosition()
	{
		auto QueueManager = GentlemanQueueManagers[GetPlayer()];
		if(QueueManager == nullptr)
			return -1;

		auto Queue = QueueManager.GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		TArray<AActor> Members = Queue.GetMembers();
		return Members.FindIndex(Owner);
	}

	int GetOtherQueueSize()
	{
		auto QueueManager = GentlemanQueueManagers[GetOtherPlayer()];
		if(QueueManager == nullptr)
			return -1;

		auto Queue = QueueManager.GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		return Queue.GetMembers().Num();
	}

	private AHazePlayerCharacter GetPlayer()
	{
		AHazePlayerCharacter QueuePlayer = Game::Zoe;
		if(TargetComp.Target == Game::Mio)
			QueuePlayer = Game::Mio;
		return QueuePlayer;
	}

	private AHazePlayerCharacter GetOtherPlayer()
	{
		AHazePlayerCharacter QueuePlayer = Game::Mio;
		if(TargetComp.Target == Game::Mio)
			QueuePlayer = Game::Zoe;
		return QueuePlayer;
	}
}