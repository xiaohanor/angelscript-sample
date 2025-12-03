
struct FSkylineBossBeamImpactAudioPool
{
	UPROPERTY()
	UHazeAudioEmitter PoolEmitter;

	UPROPERTY()
	int NumPools = 0;

	int PoolIndex = 0;

	private TArray<FVector> Locations;

	bool IsLocationWithinBounds(const FVector InLocation, const float InRangeSqrd)
	{
		if(Locations.Num() == 0)
			return true;

		for(auto& Loc : Locations)
		{
			if(Loc.DistSquared(InLocation) <= InRangeSqrd)
				return true;
		}

		return false;
	}

	void AddLocation(const FVector InLocation)
	{
		Locations.Add(InLocation);
		++NumPools;
	}

	void RemoveLocation(bool& bIsEmpty)
	{
		bIsEmpty = ((NumPools - 1) <= 0);	

		if(Locations.Num() == 0)		
			return;

		Locations.RemoveAt(0);
		--NumPools;
	}

	TArray<FVector> GetLocations()
	{
		return Locations;
	}

	void LerpTowardsEnd(float DeltaSeconds)
	{
		const int NumLocation = Locations.Num();

		if(NumLocation < 2)
			return;

		int LastIndex = NumLocation - 1;

		Locations[0] = Math::VInterpConstantTo(Locations[0], Locations[LastIndex], DeltaSeconds, 2000.0);
		//Debug::DrawDebugPoint(Locations[0], 25.0, FLinearColor::Blue, bRenderInForground = true);
	}	
}

UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_TripodMech_Beam_Impact_Pools_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	private USkylineFocusBeamManagerComponent BeamManager;
	private FHazeAudioEmitterRotationPool EmitterPool;	

	private FOnInitRotationPoolComponent OnInitRotationPoolEmitter;

	private TArray<FSkylineBossBeamImpactAudioPool> ActivePools;

	UPROPERTY(EditDefaultsOnly)
	int MaxNumPools = 8;

	UPROPERTY(EditDefaultsOnly)
	float AttenuationScaling = 1000;

	const float MAX_POOL_EMITTER_DISTANCE_SQUARED = Math::Square(3000);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		OnInitRotationPoolEmitter.BindUFunction(this, n"InitImpactPoolEmitter");

		BeamManager = SkylineBossFocusBeam::GetManager();
		EmitterPool = GetPooledEmitters(MaxNumPools, OnInitRotationPoolEmitter);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BeamManager.GetNumPools() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return BeamManager.GetNumPools() == 0;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ImpactPoolStart();
	}

	UFUNCTION()
	void ImpactPoolStart()
	{
		PoolStart_Internal(BeamManager.GetLastUsedIndex(), bFetchLocations = true);
	}

	void PoolStart_Internal(const int PoolIndex, bool bFetchLocations = false)
	{
		UHazeAudioEmitter PooledEmitter = nullptr;
		int EmitterIdx = 0;

		AudioEmitterRotationPool::GetNext(EmitterPool, PooledEmitter, EmitterIdx, FVector(), bForceEnable = true);

		FSkylineBossBeamImpactAudioPool AudioPool;
		AudioPool.PoolEmitter = PooledEmitter;	
		AudioPool.PoolIndex = PoolIndex;	

		if(bFetchLocations)
		{
			FSkylineBossFocusBeamImpactPool ImpactPool;
			if(BeamManager.GetPool(PoolIndex, ImpactPool))
			{
				for(const FVector Location : ImpactPool.Locations)
					AudioPool.AddLocation(Location);
			}
		}

		if(ActivePools.Num() == MaxNumPools)
		{
			auto& OldestPool = ActivePools[0];
			StopImpactPool(OldestPool);
			ActivePools.RemoveAt(0);
		}

		ActivePools.Add(AudioPool);
		StartImpactPool(AudioPool);

		BeamManager.RegisterToPool(this, n"OnAddPoolLocation", n"OnRemovePoolLocation");
	}	

	UFUNCTION()
	void OnAddPoolLocation(const int PoolIndex, const FVector Location)
	{
		bool bFoundValidPool = false;
		bool bWasInRange = false;
		for(auto& Pool : ActivePools)
		{
			if(Pool.PoolIndex == PoolIndex)
			{
				bFoundValidPool = true;

				if(Pool.IsLocationWithinBounds(Location, MAX_POOL_EMITTER_DISTANCE_SQUARED))
				{
					bWasInRange = true;
					Pool.AddLocation(Location);
				}			
			}
		}

		// If this new position was part of the same group, but to far away from the rest of the cluster
		// start it up a seperate sound with its own pooled emitter but same index
		if(bFoundValidPool && !bWasInRange)
		{
			PoolStart_Internal(PoolIndex, bFetchLocations = false);
		}
	}

	UFUNCTION()
	void OnRemovePoolLocation(const int PoolIndex)
	{
		bool bFoundValidIndex = false;

		for(int i = ActivePools.Num() - 1; i >= 0; --i)
		{
			auto& Pool = ActivePools[i];

			if(Pool.PoolIndex == PoolIndex)
			{	
				bFoundValidIndex = true;
				bool bIsEmpty = false;
				Pool.RemoveLocation(bIsEmpty);	

				if(bIsEmpty)
				{					
					StopImpactPool(Pool);
					ActivePools.RemoveAt(i);
				}			
			}
		}

		//devCheck(bFoundValidIndex);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		int MaxNumLocations = 0;

		for(auto& AudioPool : ActivePools)
		{	
			TArray<FAkSoundPosition> PoolSoundPositions;
			if(AudioPool.NumPools == 0)
				continue;

			MaxNumLocations = Math::Max(MaxNumLocations, AudioPool.NumPools);

			if(AudioPool.NumPools > 1)	
			{
				for(auto Player : Game::GetPlayers())
				{	
					// FVector ClosestPoolPlayerPos;
					// float ClosestPlayerDistSqrd = MAX_flt;	

					const TArray<FVector> PoolLocations = AudioPool.GetLocations();
					const FVector ClosestPoolPlayerPos = Math::ClosestPointOnLine(PoolLocations[0], PoolLocations.Last(), Player.ActorLocation);				

					// for(const FVector Location : )
					// {
					// 	const float DistSqrd = Location.DistSquared(Player.GetActorLocation());
					// 	if(DistSqrd < ClosestPlayerDistSqrd)
					// 	{
					// 		ClosestPoolPlayerPos = Location;
					// 		ClosestPlayerDistSqrd = DistSqrd;
					// 	}
					// }
					
					PoolSoundPositions.Add(FAkSoundPosition(ClosestPoolPlayerPos));
				}	

				// Keep "tail"-end of the pool path moving towards the "head"-end so that we can simulate the positioning as "sizzling out"
				AudioPool.LerpTowardsEnd(DeltaSeconds);
			}
			else
			{
				PoolSoundPositions.Add(FAkSoundPosition(AudioPool.GetLocations()[0]));
			}			

			AudioPool.PoolEmitter.AudioComponent.SetMultipleSoundPositions(PoolSoundPositions);		
		}

	
		// PrintToScreenScaled(f"Num Audio Pools: {ActivePools.Num()}");
		// PrintToScreenScaled(f"Max Num Locations in Pools: {MaxNumLocations}");
		// PrintToScreenScaled(f"Num Actual Pools: {BeamManager.GetNumPools()}");
		// PrintToScreenScaled(f"Last Used Index: {BeamManager.GetLastUsedIndex()}");
	}


	UFUNCTION(BlueprintEvent)
	void InitImpactPoolEmitter(UHazeAudioEmitter PoolEmitter) {}

	UFUNCTION(BlueprintEvent)
	void StartImpactPool(const FSkylineBossBeamImpactAudioPool& Pool) {}

	UFUNCTION(BlueprintEvent)
	void StopImpactPool(const FSkylineBossBeamImpactAudioPool& Pool) {}

}