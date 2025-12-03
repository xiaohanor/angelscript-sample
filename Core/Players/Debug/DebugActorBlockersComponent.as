class UDebugActorBlockersComponent : UActorComponent
{
#if EDITOR
	AHazeActor HazeOwner = nullptr;
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (HazeOwner == nullptr)
			HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner == nullptr)
			return;
		
		TArray<FActorBlockInstigatorDebugStatus> Info;
		HazeOwner.GetBlockInstigatorsDebugInformation(Info);
		FString CategoryName = "Actor Blockers";
		TEMPORAL_LOG(HazeOwner, CategoryName);
		for (int iBlocker = 0; iBlocker < Info.Num(); ++iBlocker)
		{
			FActorBlockInstigatorDebugStatus BlockerInfo = Info[iBlocker];
			if (BlockerInfo.bHasBlockedCollision)
				TEMPORAL_LOG(HazeOwner, CategoryName).Value("Blocked Collision " + iBlocker, BlockerInfo.Instigator);
			if (BlockerInfo.bHasBlockedVisuals)
				TEMPORAL_LOG(HazeOwner, CategoryName).Value("Blocked Visuals " + iBlocker, BlockerInfo.Instigator);
			if (BlockerInfo.bHasBlockedTick)
				TEMPORAL_LOG(HazeOwner, CategoryName).Value("Blocked Tick " + iBlocker, BlockerInfo.Instigator);
		}
		TEMPORAL_LOG(HazeOwner, CategoryName).Value("Hidden", HazeOwner.IsHidden());
#endif
	}
};