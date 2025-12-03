UCLASS(Abstract)
class AIslandPhasablePlatformSpline : ASplineActor
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandPhasablePlatform> PhasablePlatformClass;

	UPROPERTY(EditAnywhere)
	float DistanceBetweenPlatforms = 500;

	UPROPERTY(EditAnywhere)
	bool bBlue;

	UPROPERTY(EditAnywhere)
	bool bNoAttachments = false;

	UPROPERTY(EditAnywhere)
	float MaxPhasableTraversalSpeed = 5250;

	UPROPERTY(EditAnywhere)
	float ExitSpeed = 5250;

	UPROPERTY(VisibleAnywhere)
	TArray<AIslandPhasablePlatform> SpawnedPlatforms;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		RefreshPhasables();
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		RefreshPhasables();
	}

	UFUNCTION(CallInEditor)
	void RefreshPhasables()
	{
		// FindAttachedPhasables();
		for (auto Platform : SpawnedPlatforms)
		{
			Platform.bBlue = bBlue;
			Platform.bNoAttachments = bNoAttachments;
			Platform.bIsLastSplinePhasable = false;
			Platform.PlatformSpline = this;
			Platform.RerunConstructionScripts();
		}
		SpawnedPlatforms.Last().bIsLastSplinePhasable = true;
	}

	// void FindAttachedPhasables()
	// {
	// 	TArray<AActor> AttachedActors;
	// 	GetAttachedActors(AttachedActors);
	// 	SpawnedPlatforms.Empty();
	// 	for (auto Actor : AttachedActors)
	// 	{
	// 		auto Phasable = Cast<AIslandPhasablePlatform>(Actor);
	// 		if (Phasable == nullptr)
	// 			continue;

	// 		SpawnedPlatforms.Add(Phasable);
	// 	}
	// }
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float CurrentDistance = 0;
		while (CurrentDistance < Spline.SplineLength)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(CurrentDistance);
			Debug::DrawDebugSphere(SplinePos.WorldLocation, 250, 12, FLinearColor::Purple);
			CurrentDistance += DistanceBetweenPlatforms;
			Debug::DrawDebugArrow(SplinePos.WorldLocation, SplinePos.WorldLocation + SplinePos.WorldForwardVector * 250, 500, FLinearColor::Red, 25);
		}
	}
	UFUNCTION(CallInEditor)
	void SpawnPhasables()
	{
		devCheck(PhasablePlatformClass.IsValid(), "Phasable Platform Class is invalid! Assign class in Spline BP.");
		float CurrentDistance = 0;
		for (int i = SpawnedPlatforms.Num() - 1; i >= 0; i--)
		{
			SpawnedPlatforms[i].DestroyActor();
		}
		SpawnedPlatforms.Empty();
		FScopedTransaction("Spawned Phasables on Spline");
		while (CurrentDistance < Spline.SplineLength)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(CurrentDistance);
			CurrentDistance += DistanceBetweenPlatforms;
			auto Instance = SpawnActor(PhasablePlatformClass, SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), NAME_None, true, Level);
			Instance.bBlue = bBlue;
			Instance.bAlwaysLaunchForward = true;
			Instance.PlatformSpline = this;
			Instance.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
			Instance.AddActorWorldOffset(SplinePos.WorldUpVector * -Instance.Cone.RelativeLocation.Z * 0.5);
			SpawnedPlatforms.Add(Instance);
			FinishSpawningActor(Instance);
		}
		SpawnedPlatforms.Last().bIsLastSplinePhasable = true;
	}
	UFUNCTION(CallInEditor)
	void RemoveAllSpawned()
	{
		// FindAttachedPhasables();
		for (int i = SpawnedPlatforms.Num() - 1; i >= 0; i--)
		{
			if (SpawnedPlatforms[i] != nullptr)
			{
				SpawnedPlatforms[i].DestroyActor();
			}
		}
		SpawnedPlatforms.Empty();
	}
	UFUNCTION(CallInEditor)
	void SelectAllSpawned()
	{
		// FindAttachedPhasables();
		Editor::SelectActors(SpawnedPlatforms);
	}
#endif
};