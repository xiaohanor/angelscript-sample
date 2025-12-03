namespace SkylineBossFocusBeam
{
	USkylineFocusBeamManagerComponent GetManager()
	{
		return USkylineFocusBeamManagerComponent::GetOrCreate(Game::GetMio());
	}
};

event void OnFocusBeamImpactPoolAddLocation(const int PoolIndex, const FVector Location);
event void OnFocusBeamImpactPoolRemoveLocation(const int PoolIndex);

struct FSkylineBossFocusBeamImpactPool
{
	int Index = 0;
	TArray<FVector> Locations;

	FSkylineBossFocusBeamImpactPool(const int InIndex)
	{
		Index = InIndex;
	}

	OnFocusBeamImpactPoolAddLocation OnAddLocation;
	OnFocusBeamImpactPoolRemoveLocation OnRemoveLocation;
}

UCLASS(NotBlueprintable)
class USkylineFocusBeamManagerComponent : UActorComponent
{
	access InternalWithFocusBeam = private, ASkylineBossFocusBeamHit;

	access:InternalWithFocusBeam
	TArray<FSkylineBossFocusBeamImpactPool> ActivePools;

	int NextIndex = 100;
	int LastUsedIndex;

	private int GetNextIndex() const
	{
		int Highest = 0;
		if(ActivePools.Num() > 0)
		{
			for(auto& Pool : ActivePools)
			{
				Highest = Math::Max(Highest, Pool.Index);
			}

			++Highest;
		}

		return Highest;	
	}

	void StartNewImpactPool()
	{
		int Highest = GetNextIndex();
		int Index = Math::Min(NextIndex, Highest);
		auto NewPool = FSkylineBossFocusBeamImpactPool(Index);	
	
		ActivePools.Add(NewPool);	
		NextIndex = Highest + 1;
		LastUsedIndex = Index;
	}

	void RegisterToPool(UObject Object, const FName OnPoolAddLocationCallbackFunction, const FName OnPoolRemoveLocationCallbackFunction)
	{
		if(ActivePools.Num() > 0)
		{
			auto& LastPool = ActivePools.Last();
			LastPool.OnAddLocation.AddUFunction(Object, OnPoolAddLocationCallbackFunction);
			LastPool.OnRemoveLocation.AddUFunction(Object, OnPoolRemoveLocationCallbackFunction);
		}
	}
	
	access:InternalWithFocusBeam
	int AddLocationToPool(const FVector InLocation)
	{
		int WantedPoolIdx = -1;

		for(int i = 0; i < ActivePools.Num(); ++i)
		{
			if(ActivePools[i].Index == LastUsedIndex)
			{
				WantedPoolIdx = i;
				break;
			}
		}

		if(WantedPoolIdx < 0)
			return -1;		

		auto& LatestPool = ActivePools[WantedPoolIdx];
		LatestPool.Locations.Add(InLocation);
		LatestPool.OnAddLocation.Broadcast(LatestPool.Index, InLocation);

		return LatestPool.Index;
	}

	access:InternalWithFocusBeam
	void RemoveFromPool(const int PoolIndex)
	{
		int IndexToRemove = -1;
		int LastIndex = ActivePools.Num() - 1;

		for(int i = 0; i < ActivePools.Num(); ++i)
		{
			if(ActivePools[i].Index == PoolIndex)
			{
				IndexToRemove = i;
				break;
			}
		}

		if(IndexToRemove < 0)
		{
			devCheck(false, f"Failed to remove from impact pool: {PoolIndex}");
			return;
		}

		auto& PoolToRemoveFrom = ActivePools[IndexToRemove];	
		PoolToRemoveFrom.Locations.RemoveAt(0);
		PoolToRemoveFrom.OnRemoveLocation.Broadcast(PoolToRemoveFrom.Index);

		if(PoolToRemoveFrom.Locations.Num() == 0)
		{	
			PoolToRemoveFrom.OnAddLocation.Clear();
			PoolToRemoveFrom.OnRemoveLocation.Clear();

			if(IndexToRemove != LastIndex)
			{	
				auto& LastPool = ActivePools[LastIndex];

				//LastPool.Index = IndexToRemove;
				NextIndex = PoolToRemoveFrom.Index;


				ActivePools[IndexToRemove] = LastPool;	
			}

			ActivePools.RemoveAt(LastIndex);					
		}
	}

	bool GetPool(const int Index, FSkylineBossFocusBeamImpactPool& OutPool)
	{
		for(auto& Pool : ActivePools)
		{
			if(Pool.Index == Index)
			{
				OutPool = Pool;
				return true;
			}			
		}	

		return false;
	}

	int GetLastPoolIndex() const
	{
		return ActivePools.Num() - 1;
	}

	int GetNumPools() const
	{
		return ActivePools.Num();
	}

	int GetLastUsedIndex() const
	{
		return LastUsedIndex;
	}
};