	class USanctuaryCompanionAviationToAttackCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;

	float OGHorizontalOffset;
	float OGVerticalOffset;
	FHazeAcceleratedFloat AccHorizontal;
	FHazeAcceleratedFloat AccVertical;

	bool bHasHackyResetSmoothCamera = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		if (!AviationComp.HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!IsInStateHandledByThisCapability())
			return true;

		// Can happen in tutorial if in network
		if (!AviationComp.HasDestination()) 
			return true;

		return false;
	}

	bool IsInStateHandledByThisCapability() const
	{
		if (AviationComp.AviationState == EAviationState::SwoopingBack)
			return true;

		if (AviationComp.AviationState == EAviationState::ToAttack)
			return true;

		if (AviationComp.AviationState == EAviationState::InitAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ArenaManager != nullptr)
		{
			if (Player.IsMio())
				PlaceToAttackCamera(ArenaManager.ToAttackDestinationCameraMio, ArenaManager.SwoopBackCameraMio);
			else
				PlaceToAttackCamera(ArenaManager.ToAttackDestinationCameraZoe, ArenaManager.SwoopBackCameraZoe);
			if (AviationComp.AviationState != EAviationState::InitAttack && AviationDevToggles::Camera::UseStaticCameraSwoopBack.IsEnabled())
			{

				bHasHackyResetSmoothCamera = true;
			}
			ArenaManager.EnableToAttackDestinationCamera(Player, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AviationComp.AviationAllowedInputAlpha = 0.0;
		AviationComp.AviationUseSplineParallelAlpha = 0.0;
		if (ArenaManager != nullptr)
			ArenaManager.EnableToAttackDestinationCamera(Player, false);

		GetSplineCamera().SplineFollowSettings.LocationOffset.Z = OGVerticalOffset;
		GetSplineCamera().SplineFollowSettings.LocationOffset.Y = OGHorizontalOffset;
	}

	private ASplineFollowCameraActor& GetSplineCamera() const
	{
		if (Player.IsMio())
			return ArenaManager.ToAttackDestinationCameraMio;
		return ArenaManager.ToAttackDestinationCameraZoe;
	}

	void PlaceToAttackCamera(ASplineFollowCameraActor ToAttackCamera, AHazeCameraActor SwoopbackCam)
	{
		AviationComp.UpdateCurrentSide();

		FVector DesiredCameraOffsetDirection = GetQuadRimDirection();
		FVector CurrentOffsetFromCenter = ToAttackCamera.ActorLocation - ArenaManager.ActorLocation;
		FVector CurrentCameraDirection = CurrentOffsetFromCenter;
		CurrentCameraDirection.Z = 0.0;
		
		FQuat DiffBetweenTargetAndPart = DesiredCameraOffsetDirection.ToOrientationQuat() * CurrentCameraDirection.ToOrientationQuat().Inverse();
		FVector NewOffsetFromCenter = DiffBetweenTargetAndPart.RotateVector(CurrentOffsetFromCenter);

		ToAttackCamera.SetActorLocation(ArenaManager.ActorLocation + NewOffsetFromCenter);
		ToAttackCamera.SetActorRotation(FRotator::MakeFromXZ(-DesiredCameraOffsetDirection, FVector::UpVector));
		SwoopbackCam.SetActorLocation(ArenaManager.ActorLocation + NewOffsetFromCenter);
		SwoopbackCam.SetActorRotation(FRotator::MakeFromXZ(-DesiredCameraOffsetDirection, FVector::UpVector));

		OGHorizontalOffset = ToAttackCamera.SplineFollowSettings.LocationOffset.Y;
		OGVerticalOffset = ToAttackCamera.SplineFollowSettings.LocationOffset.Z;
		AccHorizontal.SnapTo(OGHorizontalOffset);
		AccVertical.SnapTo(OGVerticalOffset);
	}

	private FVector GetQuadRimDirection()
	{
		float Sign = AviationComp.CurrentQuadrantSide == ESanctuaryArenaSide::Right ? 1.0 : -1.0;
		if (Player.IsMio())
			return FVector::RightVector * Sign;
		return FVector::ForwardVector * Sign;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ArenaManager == nullptr)
			return;
		if (ActiveDuration > 1.0 && bHasHackyResetSmoothCamera)
		{
			bHasHackyResetSmoothCamera = false;
			ArenaManager.EnableSwoopbackCamera(Player, false);
		}

		if (!AviationDevToggles::Camera::NoCameraOffset.IsEnabled() && !bHasHackyResetSmoothCamera)
		{
			float VerticalOffset = OGVerticalOffset;
			float HorizontalOffset = OGHorizontalOffset;
			float OffsetAlpha = AviationComp.SyncedFlyingMinMaxAlphaValue.Value;
			FVector2D FlyingOffset = AviationComp.SyncedFlyingOffsetValue.Value;
			VerticalOffset += FlyingOffset.Y * Math::Lerp(AviationComp.Settings.CameraVerticalDistanceMin, AviationComp.Settings.CameraVerticalDistanceMax, OffsetAlpha);
			HorizontalOffset += FlyingOffset.X * Math::Lerp(AviationComp.Settings.CameraHorizontalDistanceMin, AviationComp.Settings.CameraHorizontalDistanceMax, OffsetAlpha);
			AccHorizontal.AccelerateTo(HorizontalOffset, 0.01, DeltaTime);
			AccVertical.AccelerateTo(VerticalOffset, 0.01, DeltaTime);
			GetSplineCamera().SplineFollowSettings.LocationOffset.Z = AccVertical.Value;
			GetSplineCamera().SplineFollowSettings.LocationOffset.Y = AccHorizontal.Value;
			// PrintToScreen("Vertical" + AccVertical.Value);
		}
	}
};