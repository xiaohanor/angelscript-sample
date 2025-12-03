class UBallistaHydraPlayerRespawnCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	UBallistaHydraActorReferencesComponent BallistaRefsComp;
	UMedallionPlayerReferencesComponent MedallionRefsComp;
	UPlayerRespawnComponent RespawnComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallistaRefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Player);
		MedallionRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		RespawnComponent = UPlayerRespawnComponent::Get(Player);
		RespawnComponent.OnPlayerRespawned.AddUFunction(this, n"PlayerRespawned");
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if (IsActive())
			RespawnedPlayer.SnapCameraBehindPlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallistaRefsComp.Refs == nullptr)
			return false;
		if (MedallionRefsComp.Refs == nullptr)
			return false;
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return false;
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaArrowShot3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MedallionRefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaArrowShot3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FOnRespawnOverride Delegate;
		Delegate.BindUFunction(this, n"GetPlatformRespawnLocation");
		RespawnComponent.ApplyRespawnOverrideDelegate(this, Delegate, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComponent.ClearRespawnOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DevTogglesPlayerHealth::DrawRespawnPoint.IsEnabled(Player))
		{
			FRespawnLocation RespawnLoc;
			GetPlatformRespawnLocation(Player, RespawnLoc);
			if (RespawnLoc.RespawnPoint != nullptr)
				Debug::DrawDebugCapsule(RespawnLoc.RespawnPoint.ActorCenterLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, RespawnLoc.RespawnPoint.ActorRotation, Player.GetPlayerUIColor(), 3.0, 0.0, true);
			else
			{
				FVector Location = RespawnLoc.RespawnRelativeTo.WorldTransform.TransformPositionNoScale(RespawnLoc.RespawnTransform.Location);
				FRotator Rotation = RespawnLoc.RespawnRelativeTo.WorldTransform.TransformRotation(RespawnLoc.RespawnTransform.Rotation.Rotator());
				Debug::DrawDebugCapsule(Location, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Rotation, Player.GetPlayerUIColor(), 3.0, 0.0, true);
			}
		}
	}

	UFUNCTION()
	bool GetPlatformRespawnLocation(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		ABallistaHydraSplinePlatform BestPlatform;
		float BestDistance = BIG_NUMBER;
		AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;

		const float GraceSinkDistance = 500.0;
		for (ABallistaHydraSplinePlatform Platform : BallistaRefsComp.Refs.Spline.Platforms)
		{
			// platform is sinking or soon sinking?
			if (Platform.PlatformCurrentSplineDist + GraceSinkDistance > Platform.ParentSpline.PlatformsSinkDistance)
				continue;

			bool bIsUnderWater = Platform.GetIsUnderWater();
			if (bIsUnderWater)
			{
				if (Platform.CustomRespawnPoint != nullptr && Platform.CustomRespawnPoint.ActorLocation.Z >= Platform.ParentSpline.ActorLocation.Z)
				{
					OutLocation.RespawnRelativeTo = Platform.CustomRespawnPoint.RootComponent;
					OutLocation.RespawnPoint = Platform.CustomRespawnPoint;
					bIsUnderWater = false;
				}
				if (bIsUnderWater)
					continue;
			}
			if (!Platform.bAllowRespawnOn)
				continue;
			float Distance = Platform.ActorLocation.Distance(OtherPlayer.ActorLocation);
			if (Distance < BestDistance)
			{
				BestDistance = Distance;
				BestPlatform = Platform;
			}
		}

		if (!IsValid(BestPlatform))
			return false;

		if (BestPlatform.CustomRespawnPoint != nullptr)
		{
			OutLocation.RespawnRelativeTo = BestPlatform.CustomRespawnPoint.RootComponent;
			OutLocation.RespawnPoint = BestPlatform.CustomRespawnPoint;
			return true;
		}

		// trace from on top
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		Trace.IgnorePlayers();
		FHitResult Hit = Trace.QueryTraceSingle(BestPlatform.ActorLocation + FVector::UpVector * 3000, BestPlatform.ActorLocation - FVector::UpVector * 3000);

		if (Hit.bBlockingHit)
		{
			OutLocation.RespawnRelativeTo = BestPlatform.RootComponent;
			FTransform RelativeTransform;

			FVector RelativeSpawnLocation = BestPlatform.ActorTransform.InverseTransformPositionNoScale(Hit.ImpactPoint);
			RelativeTransform.Location = RelativeSpawnLocation + FVector::UpVector * 10;

			FRotator RelativeSpawnRotation = BestPlatform.ActorTransform.InverseTransformRotation(FRotator(0.0, 180.0, 0.0));
			RelativeTransform.Rotation = RelativeSpawnRotation.Quaternion();

			OutLocation.RespawnTransform = RelativeTransform;
			return true;
		}

		return false;
	}
};