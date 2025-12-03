class UFitnessTargetCostQueueSortingCapability : UHazePlayerCapability
{
	UGentlemanQueueManagerComponent QueueManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		QueueManager = UGentlemanQueueManagerComponent::GetOrCreate(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UGentlemanQueue Queue = QueueManager.GetQueue(GentlemanCostQueueTags::GentlemanCostQueue);
		TArray<AActor> AllMembers = Queue.GetMembers();

		// No use in sorting less than 2 members
		if(AllMembers.Num() < 2) 
			return;

		TArray<AActor> Members;
		for(AActor Member: AllMembers)
		{
			auto FitnessComp = (Member != nullptr) ? UFitnessUserComponent::Get(Member) : nullptr;
			if(FitnessComp != nullptr) // Only set fitness on queuing members that use fitness
				Members.Add(Member);	
		}

		// No use in sorting less than 2 members
		if(Members.Num() < 2) 
			return;

		TArray<FScoredFitnessUser> ScoredMembers;
		TArray<int> UnsortedIndexes;
		for(AActor Member: Members)
		{		
			UFitnessUserComponent FitnessComp = (Member != nullptr) ? UFitnessUserComponent::Get(Member) : nullptr;
			UFitnessSettings FitnessSettings = UFitnessSettings::GetSettings(Cast<AHazeActor>(Member));
			if (FitnessComp == nullptr)
				continue;
			FScoredFitnessUser Scored = FScoredFitnessUser();
			Scored.FitnessScore = FitnessComp.GetFitnessScore(Player);
			Scored.Actor = Member;

			if(Scored.FitnessScore > FitnessSettings.OptimalThresholdMax)
			{
				Scored.FitnessScore = BIG_NUMBER + FitnessSettings.AdditionalOptimalFitness;
			}
			else
			{
				float MultiplierAdd = DeltaTime / FitnessSettings.ReachMaxMultiplierDuration;
				if(Scored.FitnessScore < FitnessSettings.OptimalThresholdMin)
					MultiplierAdd *= -1;
				FitnessComp.FitnessMultiplier = Math::Clamp(FitnessComp.FitnessMultiplier + MultiplierAdd, 0.1, 1.0);

				// Multiply score after it has been evaluated for suitability since it's only used to rank them for queuing
				Scored.FitnessScore *= FitnessComp.FitnessMultiplier;
			}

			UnsortedIndexes.Add(AllMembers.FindIndex(Member));
			ScoredMembers.Add(Scored);
		}

		ScoredMembers.Sort();
		for(int i = 0; i < ScoredMembers.Num(); i++)
		{
			Queue.MoveQueue(ScoredMembers[i].Actor, UnsortedIndexes[i]);
		}
	}
}

struct FScoredFitnessUser
{
	float FitnessScore;
	AActor Actor;

	int opCmp(const FScoredFitnessUser& Other) const
	{
		if(Other.FitnessScore < FitnessScore)
			return -1;
		else if(Other.FitnessScore > FitnessScore)
			return 1;
		return 0;
	}
}

asset FitnessQueueSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UFitnessTargetCostQueueSortingCapability);	
}