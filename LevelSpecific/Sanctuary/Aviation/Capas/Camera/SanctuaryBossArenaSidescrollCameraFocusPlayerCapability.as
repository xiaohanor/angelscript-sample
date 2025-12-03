class USanctuaryBossArenaSidescrollCameraFocusPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent PlayerMoveComp;

	ASanctuaryBossArenaManager ArenaManager;
	AHazeActor SidescrollingFocusActor;

	UMedallionPlayerComponent MedallionComp;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	FHazeAcceleratedVector AcceleratedPosition;
	FVector LastHorizontalOffset;

	const float InterpolationDuration = 3.0;
	const float HorizontalMulitplier = 2.1;
	const float MinHorizontalDist = 50.0;
	const float MaxHorizontalDist = 600.0;
	
	ASplineFollowCameraActor CachedSplineCamera = nullptr;
	ASanctuaryArenaClampCameraFocusSpline CachedClampSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArenaManager == nullptr)
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
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
		if (SidescrollingFocusActor == nullptr)
		{
			if (Player.IsMio())
				SidescrollingFocusActor = ArenaManager.SidescrollingFocusActorMio;
			else
				SidescrollingFocusActor = ArenaManager.SidescrollingFocusActorZoe;
		}
		AcceleratedPosition.SnapTo(Owner.ActorLocation);
		FHitResult Unused;
		TryCacheThings();
		if (SidescrollingFocusActor != nullptr)
			SidescrollingFocusActor.SetActorLocation(AcceleratedPosition.Value, false, Unused, true);
	}

	bool TryCacheThings() 
	{
		CacheClampSpline();
		CacheCamera();
		return CachedSplineCamera != nullptr && CachedClampSpline != nullptr;
	}

	void CacheCamera()
	{
		if (CachedSplineCamera != nullptr)
			return;
		UHazeCameraComponent CurrentCamera = Player.GetCurrentlyUsedCamera();
		CachedSplineCamera = Cast<ASplineFollowCameraActor>(CurrentCamera.Owner);
	}

	void CacheClampSpline()
	{
		if (CachedClampSpline != nullptr)
			return;
		TListedActors<ASanctuaryArenaClampCameraFocusSpline> ClampSplines;
		if (ClampSplines.Num() > 0)
			CachedClampSpline = ClampSplines.Single;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		float VerticalOffset = GetVerticalOffset();
		FVector HorizontalLocation;
		bool bShouldUpdate = UpdateHorizontalLocation(HorizontalLocation);
		if (!bShouldUpdate)
			return;

		AcceleratedPosition.AccelerateTo(HorizontalLocation, InterpolationDuration, DeltaTime);

		FHitResult Unused;
		FVector NewLocation = AcceleratedPosition.Value;
		NewLocation.Z = Owner.ActorCenterLocation.Z + VerticalOffset;
		SidescrollingFocusActor.SetActorLocation(NewLocation, false, Unused, true);

		if (AviationDevToggles::Camera::DrawCameraFocus.IsEnabled())
		{
			Debug::DrawDebugSphere(HorizontalLocation, 100.0, 12, ColorDebug::Flaxen);
			Debug::DrawDebugString(HorizontalLocation, "Target Focus Point", ColorDebug::Flaxen);
			Debug::DrawDebugSphere(NewLocation, 100.0, 12, ColorDebug::Yellow);
			Debug::DrawDebugString(NewLocation, "Accelerated Focus Point", ColorDebug::Yellow);
		}
	}

	bool UpdateHorizontalLocation(FVector& OutHorizontalLocation)
	{
		FVector HorizontalOffset = PlayerMoveComp.GetHorizontalVelocity() * HorizontalMulitplier;
		if (HorizontalOffset.Size() < KINDA_SMALL_NUMBER)
		{
			if (LastHorizontalOffset.Size() < KINDA_SMALL_NUMBER && !PlayerMoveComp.IsFalling())
				return false;
			HorizontalOffset = LastHorizontalOffset.GetSafeNormal() * MinHorizontalDist;
		}
		else
		{
			HorizontalOffset = HorizontalOffset.GetClampedToSize(MinHorizontalDist, MaxHorizontalDist);
		}
		LastHorizontalOffset = HorizontalOffset;

		FVector HorizontalLocation = Owner.ActorCenterLocation + HorizontalOffset;

		// Clamp that Horizontal Location
		CacheClampSpline();
		FTransform Closest = CachedClampSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(Owner.ActorCenterLocation);
		// spline is counter clockwise, aka +splinedistance/forward is rightwards. Player camera perspective 
		FVector RightDirection = Closest.Rotation.ForwardVector;
		FVector LeftDirection = -RightDirection;
		const float CullDistance = 4000.0;

		// for (int iClamp = 0; iClamp < CachedClampSpline.ClampComponents.Num(); ++iClamp)
		// {
		// 	if (!CachedClampSpline.ClampComponents[iClamp].bActiveClamp)
		// 		continue;
		// 	if (CachedClampSpline.ClampComponents[iClamp].WorldLocation.Distance(Player.ActorLocation) > CullDistance)
		// 		continue;

		// 	FVector LocalHorizontalLocation = HorizontalLocation - CachedClampSpline.ClampComponents[iClamp].WorldLocation;
		// 	FVector DotDirection = CachedClampSpline.ClampComponents[iClamp].ClampData.ClampDirection == ESanctuaryArenaSplineClampDirection::Left ? LeftDirection : RightDirection;
		// 	if (DotDirection.DotProduct(LocalHorizontalLocation) > 0.0)
		// 	{
		// 		HorizontalLocation = CachedClampSpline.ClampComponents[iClamp].WorldLocation;
		// 	}
		// }
		OutHorizontalLocation = HorizontalLocation;
		return true;
	}

	float GetVerticalOffset()
	{
		float VerticalOffset = 0.0;
		if (CachedSplineCamera.GuideSpline != nullptr && CachedSplineCamera.GuideSpline.SplinePoints.Num() > 0)
		{
			float TargetOffset = CachedSplineCamera.GuideSpline.WorldLocation.Z - Owner.ActorCenterLocation.Z;
			VerticalOffset = Math::Lerp(0.0, TargetOffset, CompanionAviation::SidescrollingCameraLerpSplineHeightFactor);
			if (AviationDevToggles::Camera::DrawCameraFocus.IsEnabled())
			{
				FVector WithOffset = Owner.ActorCenterLocation;
				WithOffset.Z += VerticalOffset;
				Debug::DrawDebugSphere(WithOffset, 75.0, 12, ColorDebug::Ultramarine);
				FVector CameraSplineDebugPos = Owner.ActorCenterLocation;
				CameraSplineDebugPos.Z = CachedSplineCamera.GuideSpline.WorldLocation.Z;
				Debug::DrawDebugString(WithOffset, "Height Lerp Factor: " + CompanionAviation::SidescrollingCameraLerpSplineHeightFactor, ColorDebug::Cyan);
				Debug::DrawDebugLine(CameraSplineDebugPos + Owner.ActorForwardVector * 300.0, CameraSplineDebugPos - Owner.ActorForwardVector * 300.0, ColorDebug::Ultramarine);
				Debug::DrawDebugLine(WithOffset, CameraSplineDebugPos, ColorDebug::Ultramarine);
				Debug::DrawDebugLine(WithOffset, Owner.ActorCenterLocation, ColorDebug::Lapis, 10.0);
				Debug::DrawDebugString(CameraSplineDebugPos, "Camera Spline Height", ColorDebug::Cyan);
			}
		}

		if (AviationDevToggles::Camera::DrawCameraFocus.IsEnabled() && LastHorizontalOffset.Size() > KINDA_SMALL_NUMBER)
		{
			FVector MaxOffset = LastHorizontalOffset.GetSafeNormal() * MaxHorizontalDist;
			FVector MinOffset = LastHorizontalOffset.GetSafeNormal() * MinHorizontalDist;

			FVector HeightOffsetLocation = Owner.ActorCenterLocation;
			HeightOffsetLocation.Z += VerticalOffset;
			Debug::DrawDebugSphere(HeightOffsetLocation + MaxOffset, 75.0, 12, ColorDebug::Red);
			Debug::DrawDebugString(HeightOffsetLocation + MaxOffset, "Max Offset", ColorDebug::Red);
			Debug::DrawDebugSphere(HeightOffsetLocation + MinOffset, 75.0, 12, ColorDebug::Pumpkin);
			Debug::DrawDebugString(HeightOffsetLocation + MinOffset, "Min Offset", ColorDebug::Pumpkin);
		}
		return VerticalOffset;
	}

};

