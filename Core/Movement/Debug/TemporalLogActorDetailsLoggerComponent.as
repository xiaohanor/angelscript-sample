class UTemporalLogActorDetailsLoggerComponent : UActorComponent
{
#if EDITOR
	AHazeActor HazeOWner;
	TArray<UStaticMeshComponent> Meshes;
	bool bDidSetup = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bDidSetup)
		{
			bDidSetup = true;
			HazeOWner = Cast<AHazeActor>(Owner);
			if (HazeOWner != nullptr)
				HazeOWner.GetComponentsByClass(UStaticMeshComponent, Meshes);
		}
		
		if (HazeOWner == nullptr)
			return;
		
		const FString Category = "Actor Visibility Details";

		TEMPORAL_LOG(HazeOWner, Category).Value("Cutscene Controlled", HazeOWner.bIsControlledByCutscene);
		TEMPORAL_LOG(HazeOWner, Category).Value("Location", HazeOWner.ActorLocation);
		TEMPORAL_LOG(HazeOWner, Category).Value("Rel Location", HazeOWner.ActorRelativeLocation);
		TEMPORAL_LOG(HazeOWner, Category).Value("Rotation", HazeOWner.ActorRotation);
		TEMPORAL_LOG(HazeOWner, Category).Value("Rel Rotation", HazeOWner.ActorRelativeRotation);
		TEMPORAL_LOG(HazeOWner, Category).Value("Parent", HazeOWner.AttachParentActor);

		TEMPORAL_LOG(HazeOWner, Category).Sphere("Visual Loc", HazeOWner.ActorLocation, 20.0, ColorDebug::Ruby);

		TEMPORAL_LOG(HazeOWner, Category).Value("Is Hidden (bool)", HazeOWner.bHidden);
		TEMPORAL_LOG(HazeOWner, Category).Value("Blocked Visibility", HazeOWner.IsHidden() && !HazeOWner.bHidden);

		for (int iMesh = 0; iMesh < Meshes.Num(); iMesh++)
			TEMPORAL_LOG(HazeOWner, Category).Value("Mesh Visibility" + iMesh, Meshes[iMesh].bVisible);

		TArray<FActorBlockInstigatorDebugStatus> DebugInfo;
		HazeOWner.GetBlockInstigatorsDebugInformation(DebugInfo);
		int i = 0;
		for (FActorBlockInstigatorDebugStatus Debuggy : DebugInfo)
		{
			{
				if (Debuggy.bHasBlockedVisuals)
					TEMPORAL_LOG(HazeOWner, Category).Value("Blocker Vis" + i, Debuggy.Instigator);
				// if (Debuggy.bHasBlockedTick)
					// TEMPORAL_LOG(HazeOWner, Category).Value("Blocker Tick" + i, Debuggy.Instigator);
				if (Debuggy.bHasBlockedCollision)
					TEMPORAL_LOG(HazeOWner, Category).Value("Blocker Collision" + i, Debuggy.Instigator);
				i++;
			}
		}
	}
#endif
};