namespace GlobalAIEnemy
{
	UAIEnemyGlobalDeathTrackerManagerComponent GetDeathTrackerManager()
	{
		return UAIEnemyGlobalDeathTrackerManagerComponent::GetOrCreate(Game::GetMio());
	}

	UFUNCTION(BlueprintPure)
	int GetTrackedAIEnemyDeathsOfTag(const FName InTag = n"Default") 
	{		
		auto Manager = GetDeathTrackerManager();
		if(Manager != nullptr)
		{
			FAIDeathCounterParams Params;
			if(Manager.DeathCounters.Find(InTag, Params))
				return Params.DeathCounter;
		}

		return -1;
	}
}

struct FAIDeathCounterParams
{
	int DeathCounter;
	float DeathDecrementTime = 0;
	TArray<float> DeathTimers;
}

class UAIEnemyGlobalDeathTrackerManagerComponent : UActorComponent
{
	TMap<FName, FAIDeathCounterParams> DeathCounters;
	default SetComponentTickEnabled(false);
	default TickGroup = ETickingGroup::TG_PostPhysics;

	void RegisterDeath(const FName Tag, const float InDeathDecrementTime = 1.0)
	{		
		auto& DeathParams = DeathCounters.FindOrAdd(Tag);
		DeathParams.DeathCounter++;

		DeathParams.DeathDecrementTime = InDeathDecrementTime;
		DeathParams.DeathTimers.Insert(InDeathDecrementTime);

		SetComponentTickEnabled(true);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<FName> TagsToRemove;

		for(auto& Pair : DeathCounters)
		{			
			auto& DeathParams = Pair.Value;
			if(DeathParams.DeathCounter == 0)
				continue;

			for(int i = DeathParams.DeathTimers.Num() - 1; i >= 0; --i)
			{
				auto& Timer = DeathParams.DeathTimers[i];
				Timer -= DeltaSeconds;

				if(Timer <= 0)
				{
					DeathParams.DeathCounter--;
					DeathParams.DeathTimers.RemoveAtSwap(i);

					if(DeathParams.DeathTimers.Num() == 0)
					{
						TagsToRemove.Add(Pair.Key);
					}
				}
			}
		}		

		// Second pass to remove groups without active deaths
		for(auto& Tag : TagsToRemove)
		{
			DeathCounters.Remove(Tag);
		}

		#if EDITOR	
		auto TemporalLog = TEMPORAL_LOG("Audio/AIEnemyDeathTracker");

		for(auto& Pair : DeathCounters)
		{
			auto Tag = Pair.Key;
			auto DeathParams = Pair.Value;			

			if(DeathParams.DeathCounter > 0)
			{
				auto Group = TemporalLog.Page(Tag.ToString());
				Group.Value(f"{Tag} Death Counter ", DeathParams.DeathCounter);			

				for(auto& Timer : DeathParams.DeathTimers)
				{
					Group.Value("Timer: ", Timer);
				}
			}
		}
		#endif		
	}	 
}