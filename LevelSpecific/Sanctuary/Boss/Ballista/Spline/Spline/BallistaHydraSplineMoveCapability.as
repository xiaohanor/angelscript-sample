class UBallistaHydraSplineMoveCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ABallistaHydraSpline Spline;
	FHazeAcceleratedFloat AccSplineSpeed;
	UMedallionPlayerReferencesComponent MioRefsComp;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UPlayerInteractionsComponent MioInteractionComp;
	UPlayerInteractionsComponent ZoeInteractionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Spline = Cast<ABallistaHydraSpline>(Owner);
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		MioInteractionComp = UPlayerInteractionsComponent::Get(Mio);
		ZoeInteractionComp = UPlayerInteractionsComponent::Get(Zoe);
		MioRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MioRefsComp.Refs == nullptr)
			return false;
		if (MioRefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return false;
		if (MioRefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaArrowShot3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Spline.Platforms.Num() == 0)
		{
			TArray<AActor> Attacheds;
			Spline.GetAttachedActors(Attacheds, false, true);
			for (AActor AttachedActor : Attacheds)
			{
				ABallistaHydraSplinePlatform Platform = Cast<ABallistaHydraSplinePlatform>(AttachedActor);
				if (Platform != nullptr)
				{
					float ClosestDistance = Spline.Spline.GetClosestSplineDistanceToWorldLocation(Platform.ActorLocation);
					FTransform ClosestTransform = Spline.Spline.GetWorldTransformAtSplineDistance(ClosestDistance);
					FVector Relative = Platform.ActorLocation - ClosestTransform.Location;
					Platform.RelativeToSplineSideways = ClosestTransform.Rotation.RightVector.DotProduct(Relative);
					Platform.RelativeToSplineHeightwise = ClosestTransform.Rotation.UpVector.DotProduct(Relative);
					Platform.RelativeToSplineDistance = ClosestDistance;
					Platform.OriginalHeightOffset = Platform.ActorLocation.Z - Spline.ActorLocation.Z;
					Platform.ParentSpline = Spline;
					Spline.Platforms.Add(Platform);
					if (Platform.PauseSplineStartPhase.IsSet())
					{
						if (Platform.PauseSplineStartPhase.Value == EMedallionPhase::Ballista1)
							Spline.Ballista1Dist = ClosestDistance;
						if (Platform.PauseSplineStartPhase.Value == EMedallionPhase::Ballista2)
							Spline.Ballista2Dist = ClosestDistance;
						if (Platform.PauseSplineStartPhase.Value == EMedallionPhase::Ballista3)
							Spline.Ballista3Dist = ClosestDistance;
					}
				}
			}
		}

		const float GraceDistance = 4500;
		if (MioRefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista2)
			Spline.LocalSplineDistance = (Spline.Spline.SplineLength - Spline.Ballista1Dist) - GraceDistance;
		if (MioRefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista3)
			Spline.LocalSplineDistance = (Spline.Spline.SplineLength - Spline.Ballista2Dist) - GraceDistance;

		if (Spline.bUseDevProgressSetup || SanctuaryBallistaHydraDevToggles::DevStart.IsEnabled())
		{
			if (MioRefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista1)
				Spline.LocalSplineDistance = (Spline.Spline.SplineLength - Spline.Ballista1Dist) - GraceDistance - 650.0;
			if (MioRefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista2)
				Spline.LocalSplineDistance = (Spline.Spline.SplineLength - Spline.Ballista2Dist) - GraceDistance - 650.0;
			if (MioRefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Ballista3)
				Spline.LocalSplineDistance = (Spline.Spline.SplineLength - Spline.Ballista3Dist) - GraceDistance - 650.0;
		}

		AccSplineSpeed.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	bool ShouldStop()
	{
		bool bBothDead = Mio.IsPlayerDead() && Zoe.IsPlayerDead();
		if (bBothDead)
			return true;
		if (Spline.PauseProgressInstigators.Num() > 0)
			return true;
		if (SanctuaryBallistaHydraDevToggles::PauseSpline.IsEnabled())
			return true;
		return false;
	}

	float GetSpeedByPlayerDiff() const
	{
		float MioProgress = Spline.Spline.GetClosestSplineDistanceToWorldLocation(Mio.ActorCenterLocation);
		float ZoeProgress = Spline.Spline.GetClosestSplineDistanceToWorldLocation(Zoe.ActorCenterLocation);

		if (Zoe.IsPlayerDead())
			ZoeProgress = MioProgress;

		if (Mio.IsPlayerDead())
			MioProgress = ZoeProgress;

		float AvgProgress = Math::Lerp(MioProgress, ZoeProgress, 0.5);
		if (SanctuaryBallistaHydraDevToggles::Draw::Spline.IsEnabled())
		{
			Debug::DrawDebugString(Mio.ActorCenterLocation, "Spline Progress: " + MioProgress, Mio.GetPlayerUIColor());
			Debug::DrawDebugString(Zoe.ActorCenterLocation, "Spline Progress: " + ZoeProgress, Zoe.GetPlayerUIColor());
		}
		float SpeedAlpha = Math::GetMappedRangeValueClamped(FVector2D(Spline.PlatformsFloatDistance, Spline.PlatformsSinkDistance), FVector2D(0.0, 1.0), AvgProgress);
		return Math::EaseOut(MedallionConstants::Ballista::MaxPlatformSpeed, MedallionConstants::Ballista::MinPlatformSpeed, SpeedAlpha, 3);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TargetSpeed = ShouldStop() ? 0.0 : GetSpeedByPlayerDiff();
		AccSplineSpeed.AccelerateTo(TargetSpeed, 1.0, DeltaTime);

		Spline.LocalSplineDistance += AccSplineSpeed.Value * DeltaTime;
		Spline.SyncedCurrentSplineDistance.SetValue(Spline.LocalSplineDistance);
		
		FVector NewLocation = Spline.Spline.GetWorldLocationAtSplineDistance(Spline.LocalSplineDistance);
		Spline.PlayerInheritMovementComponent.SetWorldLocation(NewLocation);

		if (SanctuaryBallistaHydraDevToggles::Draw::Spline.IsEnabled())
		{
			PrintToScreenScaled("Spline Progress: " + Spline.LocalSplineDistance, 0.0, ColorDebug::Lavender);
			Spline.Spline.DrawDebug();
			FVector Location = Spline.Spline.GetWorldLocationAtSplineDistance(Spline.LocalSplineDistance);
			Debug::DrawDebugSphere(Location, 500, LineColor = ColorDebug::Rainbow(3.0), bDrawInForeground = true);

			FVector SinkLocation = Spline.Spline.GetWorldLocationAtSplineDistance(Spline.PlatformsSinkDistance);
			Debug::DrawDebugString(SinkLocation, "Start Sink Location", ColorDebug::Cyan, 0.0, 1.5);
			Debug::DrawDebugSphere(SinkLocation, 100, LineColor = ColorDebug::Cyan, bDrawInForeground = true);
			
		}
	}
};