class UBallistaHydraSplinePlatformMoveCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 101;

	ABallistaHydraSplinePlatform Platform;
	UMedallionPlayerReferencesComponent MioRefsComp;

	FHazeAcceleratedFloat AccHeight;
	bool bFirst = true;

	FHazeAcceleratedFloat AccAddedWavePitch;
	float LastWaveHeightVelocity = 0.0;
	FHazeAcceleratedFloat AccAddedWaveHeight;
	bool bInAir = false;

	FQuat OGRotation;

	const float WaveLaunchVelocity = 2500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OGRotation = Owner.ActorRotation.Quaternion();
		Platform = Cast<ABallistaHydraSplinePlatform>(Owner);
		MioRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Platform.ParentSpline == nullptr)
			return false;
		if (Platform.RelativeToSplineDistance < KINDA_SMALL_NUMBER)
			return false;
		if (MioRefsComp.Refs == nullptr)
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	bool IsInPausePhase() const
	{
		if (!Platform.PauseSplineStartPhase.IsSet())
			return false;
		if (!Platform.PauseSplineLastPhase.IsSet())
			return false;
		return MioRefsComp.Refs.HydraAttackManager.Phase >= Platform.PauseSplineStartPhase.Value && MioRefsComp.Refs.HydraAttackManager.Phase <= Platform.PauseSplineLastPhase.Value;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsInPausePhase() && SanctuaryBallistaHydraDevToggles::Draw::Spline.IsEnabled() && Platform.ParentSpline != nullptr)
		{
			float PauseDistance = Platform.ParentSpline.PlatformsSinkDistance - Platform.PauseBeforeSinkingDistance;
			FString Msg = "Pause dist: " + Math::TruncFloatDecimals(Platform.PlatformCurrentSplineDist, 0) + " / " + Math::TruncFloatDecimals(PauseDistance, 0);
			Debug::DrawDebugString(Platform.ActorLocation, Msg);

			FVector PauseLocation = Platform.ParentSpline.Spline.GetWorldLocationAtSplineDistance(PauseDistance);
			Debug::DrawDebugString(PauseLocation, Platform.ActorNameOrLabel + " Pause Location", ColorDebug::Yellow, 0.0, 1.0);
			Debug::DrawDebugSphere(PauseLocation, 100, LineColor = ColorDebug::Yellow, bDrawInForeground = true);
		}

		Platform.PlatformCurrentSplineDist = Math::Clamp(Platform.ParentSpline.SyncedCurrentSplineDistance.Value + Platform.RelativeToSplineDistance, 0.0, Platform.ParentSpline.Spline.SplineLength);
		FTransform SplineTransform = Platform.ParentSpline.Spline.GetWorldTransformAtSplineDistance(Platform.PlatformCurrentSplineDist);
		FVector Location = SplineTransform.Location + SplineTransform.Rotation.RightVector * Platform.RelativeToSplineSideways;
		
		float TargetHeight = 0.0;
		TargetHeight = 0.0;

		if (MioRefsComp.Refs.HydraAttackManager.Phase > Platform.StopFloatToSurfaceDuringPhase)
			TargetHeight += MedallionConstants::Ballista::PlatformSinkHeight;
		if (MioRefsComp.Refs.HydraAttackManager.Phase < Platform.StartFloatToSurfaceDuringPhase)
			TargetHeight += MedallionConstants::Ballista::PlatformSinkHeight;

		if (bFirst)
		{
			AccHeight.SnapTo(TargetHeight);
		}

		if (Platform.PlatformCurrentSplineDist > Platform.ParentSpline.PlatformsSinkDistance)
		{
			TargetHeight += Math::GetMappedRangeValueClamped(
			FVector2D(Platform.ParentSpline.PlatformsSinkDistance, Platform.ParentSpline.Spline.SplineLength), 
			FVector2D(0.0, MedallionConstants::Ballista::PlatformSinkHeight), Platform.PlatformCurrentSplineDist);
			AccHeight.AccelerateTo(TargetHeight, 1.0, DeltaTime);
		}
		else if (Platform.PlatformCurrentSplineDist > Platform.ParentSpline.PlatformsFloatDistance)
		{
			AccHeight.SpringTo(TargetHeight, 2.0, 0.8, DeltaTime);		
		}
		else
		{
			AccHeight.SnapTo(MedallionConstants::Ballista::PlatformSinkHeight);
		}

		if (Platform.PlatformCurrentSplineDist > Platform.ParentSpline.PlatformsFloatDistance)
		{
			if (bInAir)
			{
				AccAddedWaveHeight.ThrustTo(-20000.0, 3000.0, DeltaTime);

				if (AccAddedWaveHeight.Velocity < 0.0 && AccAddedWaveHeight.Value < 100.0)
					bInAir = false;
			}
			else
			{
				AccAddedWaveHeight.SpringTo(0.0, 20.0, 0.4, DeltaTime);
				
				if (Platform.bLaunchPlatform)
					LaunchPlatform();
			}
		}

		Location.Z += AccHeight.Value + AccAddedWaveHeight.Value + Platform.RelativeToSplineHeightwise;
		
		FRotator FromWaveRotation = FRotator::MakeFromXZ((Location - MioRefsComp.Refs.WaveAttackActor.ActorLocation).VectorPlaneProject(FVector::UpVector), FVector::UpVector);
		float PitchDegrees = Math::GetMappedRangeValueUnclamped(FVector2D(0.0, WaveLaunchVelocity), FVector2D(0.0, 60.0), AccAddedWaveHeight.Velocity);
		AccAddedWavePitch.SpringTo(PitchDegrees, 20.0, 0.5, DeltaTime);
		//Debug::DrawDebugString(Owner.ActorLocation, "" + AccAddedWavePitch.Value);
		FQuat WaveModification = FQuat(FromWaveRotation.RightVector, Math::DegreesToRadians(AccAddedWavePitch.Value));
		FQuat TargetRotation = FQuat::ApplyDelta(OGRotation, WaveModification);

		Platform.SetActorLocationAndRotation(Location, TargetRotation);
		if (Platform.bRotating)
			Platform.PlatformMesh.AddRelativeRotation(Platform.RotationPerSecond * DeltaTime);

		if (bFirst)
		{
			bFirst = false;
			Platform.FloatingComp.UpdateTransform();
		}

		if (SanctuaryBallistaHydraDevToggles::Draw::SplinePlatformHeights.IsEnabled())
		{
			bool bIsUnderWater = Platform.GetIsUnderWater();
			FLinearColor Coloring = bIsUnderWater ? ColorDebug::Blue : ColorDebug::White;
			Debug::DrawDebugString(Platform.ActorLocation, Platform.ActorNameOrLabel, Coloring);
		}
	}

	private void LaunchPlatform()
	{
		bInAir = true;
		AccAddedWaveHeight.SnapTo(0.0, WaveLaunchVelocity * Platform.WeightMultiplier);
	}
}