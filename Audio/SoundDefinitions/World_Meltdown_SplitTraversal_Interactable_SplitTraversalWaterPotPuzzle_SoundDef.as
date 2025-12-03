
UCLASS(Abstract)
class UWorld_Meltdown_SplitTraversal_Interactable_SplitTraversalWaterPotPuzzle_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPotDestroyed(FSplitTraversalWaterPotSpawnerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSpawnPot(FSplitTraversalWaterPotSpawnerEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	ASplitTraversalWaterPotSpawner Spawner;
	private TArray<FAkSoundPosition> PotSoundPositions;

	UPROPERTY(BlueprintReadOnly)
	float ClosestZoePotDistance;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Spawner = Cast<ASplitTraversalWaterPotSpawner>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<ASplitTraversalWaterPot> WaterPots = TListedActors<ASplitTraversalWaterPot>().GetArray();
		int PotCount = WaterPots.Num();
		if(PotCount > 0)
		{
			const FVector ZoePos = Game::GetZoe().ActorLocation;
			ClosestZoePotDistance = MAX_flt;
			float ClosestZoeDistSqrd = MAX_flt;
			PotSoundPositions.Empty(PotCount);
			PotSoundPositions.SetNum(PotCount);

			for(int i = 0; i < PotCount; ++i)
			{

				const FVector WaterPotLocation = WaterPots[i].ActorLocation;
				PotSoundPositions[i].SetPosition(WaterPotLocation);

				const float ZoeDistSqrd = WaterPotLocation.DistSquared(ZoePos);
				ClosestZoeDistSqrd = Math::Min(ClosestZoeDistSqrd, ZoeDistSqrd);
			}

			DefaultEmitter.SetMultiplePositions(PotSoundPositions);
			ClosestZoePotDistance = Math::Sqrt(ClosestZoeDistSqrd);
		}
	}
}