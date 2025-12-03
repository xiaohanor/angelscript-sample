
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Attack_Head_FireSwoop_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHeadChaseSprayFireStart(FIslandWalkerSprayFireParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHeadChaseSprayFireStop(){}

	UFUNCTION(BlueprintEvent)
	void OnFireSwoopTelegraphStart(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void StartPools() {};

	UFUNCTION(BlueprintEvent)
	void StopPools() {};

	UPROPERTY(NotVisible)
	UHazeAudioEmitter PoolMultiEmitter;

	AIslandWalkerHead Head;
	AAIIslandWalker Walker;
	
	private bool bHasStartedPools = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Head = Cast<AIslandWalkerHead>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DefaultEmitter.AttachEmitterTo(Head.FuelAndFlameThrower);
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
	void TickActive(float DeltaSeconds)
	{
		const int NumActiveFireWalls = Head.FlameThrower.ActiveFireWalls.Num();
		if(NumActiveFireWalls > 0)
		{
			bool bAnyActivePools = false;
			for(int i = 0; i < NumActiveFireWalls; ++i)
			{
				AIslandWalkerFirewall Firewall = Cast<AIslandWalkerFirewall>(Head.FlameThrower.ActiveFireWalls[i]);
				{							
					if(Firewall.bSpawningFires)
					{
						if(!bHasStartedPools)
						{
							StartPools();
							bHasStartedPools = true;
						}
						
						bAnyActivePools = true;
					}
				}	
			}

			if(!bAnyActivePools && bHasStartedPools)
			{
				StopPools();
				bHasStartedPools = false;
			}

			TArray<FVector> PoolLocations;
			Head.FlameThrower.GetFireSpread(PoolLocations);
			TArray<FAkSoundPosition> PoolSoundPositions;
			for(FVector Pos : PoolLocations)
			{
				PoolSoundPositions.Add(FAkSoundPosition(Pos));
			}

			PoolMultiEmitter.SetMultiplePositions(PoolSoundPositions);
		}
	}

}