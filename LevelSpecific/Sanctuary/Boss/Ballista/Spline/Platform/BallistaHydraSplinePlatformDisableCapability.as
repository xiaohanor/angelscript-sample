class UBallistaHydraSplinePlatformDisableCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::PreFrameNetworking;

	ABallistaHydraSplinePlatform Platform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ABallistaHydraSplinePlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Platform.ParentSpline == nullptr)
			return false;
		float ClampedDist = Math::Clamp(Platform.ParentSpline.SyncedCurrentSplineDistance.Value + Platform.RelativeToSplineDistance, 0.0, Platform.ParentSpline.Spline.SplineLength);
		if (ClampedDist >= Platform.ParentSpline.Spline.SplineLength - KINDA_SMALL_NUMBER)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<AActor> Attacheds;
		Platform.GetAttachedActors(Attacheds, false, true);
		for (AActor Actor : Attacheds)
		{
			auto WS = Cast<AHazeWorldSettings>(Actor);
			if(WS != nullptr)
			{
				// don't mess with worldsettings pls. WorldSettings owns orphaned niagara effects and audio stuff
				continue;
			}

			Actor.SetActorHiddenInGame(true);
			Actor.SetActorEnableCollision(false);
		}
		Platform.SetActorHiddenInGame(true);
		Platform.SetActorEnableCollision(false);
		Platform.PlatformMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TArray<AActor> Attacheds;
		Platform.GetAttachedActors(Attacheds, false, true);
		for (AActor Actor : Attacheds)
		{
			auto WS = Cast<AHazeWorldSettings>(Actor);
			if(WS != nullptr)
			{
				// don't mess with worldsettings pls. WorldSettings owns orphaned niagara effects and audio stuff
				continue;
			}
			Actor.SetActorHiddenInGame(false);
			Actor.SetActorEnableCollision(true);
		}
		Platform.SetActorHiddenInGame(false);
		Platform.SetActorEnableCollision(true);
		Platform.PlatformMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}
};