class UMedallionPlayerGloryKillReturnCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryComp;

	AFocusCameraActor Cam;
	FVector StartLocation;
	FVector TargetLocation;
	EMedallionGloryKillState LastState;
	float TimestampSinceReturn = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.GloryKillCamera == nullptr)
			return false;
		if (GloryComp.GloryKillState != EMedallionGloryKillState::Return)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TimestampSinceReturn + MedallionConstants::ReturnAndLand::KeepReturnCameraAfterLandingDuration > Time::GameTimeSeconds)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastState = EMedallionGloryKillState::Return;
		TimestampSinceReturn = BIG_NUMBER;
		Cam = Player.IsMio() ? RefsComp.Refs.ReturnFlyingCameraMio : RefsComp.Refs.ReturnFlyingCameraZoe;
		FTransform SequenceEndTransform = Player.GetViewTransform();
		FRotator Rotation = SequenceEndTransform.Rotator();
		FVector Backwards = Rotation.ForwardVector * MedallionConstants::GloryKill::CameraBackwardsOffset;
		Backwards.Z = 0.0;
		StartLocation = SequenceEndTransform.Location - Backwards;
		Cam.SetActorLocationAndRotation(StartLocation, Rotation);

		TargetLocation = Player.IsMio() ? RefsComp.Refs.GloryKillExitLocationMio.ActorLocation : RefsComp.Refs.GloryKillExitLocationZoe.ActorLocation;
		FVector CameraBackward = (TargetLocation - RefsComp.Refs.SideScrollerSplineLocker.ActorLocation).GetSafeNormal2D(FVector::UpVector);
		FRotator CameraForwardRotation = FRotator::MakeFromXZ(-CameraBackward, FVector::UpVector);
		FVector CameraSideways = Player.IsMio() ? CameraForwardRotation.RightVector : -CameraForwardRotation.RightVector;
		TargetLocation += CameraSideways * MedallionConstants::ReturnAndLand::CameraExitLocationSidewaysOffset;
		TargetLocation += CameraBackward * MedallionConstants::ReturnAndLand::CameraExitLocationOutwardsOffset;
		TargetLocation += FVector::UpVector * MedallionConstants::ReturnAndLand::CameraExitLocationUpwardsOffset;

		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.ActivateCamera(Cam, MedallionConstants::ReturnAndLand::CameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.DeactivateCamera(Cam, MedallionConstants::ReturnAndLand::CameraBlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GloryComp.GloryKillState != EMedallionGloryKillState::Return && LastState == EMedallionGloryKillState::Return)
		{
			LastState = EMedallionGloryKillState::None;
			TimestampSinceReturn = Time::GameTimeSeconds;
		}
		
		float Alpha = Math::Saturate(ActiveDuration / MedallionConstants::ReturnAndLand::ReturnCameraLerpDuration);
		FVector CamLocation = Math::EaseInOut(StartLocation, TargetLocation, Alpha, 3);
		Cam.SetActorLocation(CamLocation);
		if (SanctuaryMedallionHydraDevToggles::Draw::Camera.IsEnabled())
		{
			Debug::DrawDebugSphere(CamLocation);
			Debug::DrawDebugArrow(StartLocation, TargetLocation, 10, Player.GetPlayerUIColor(), 10, 0.0, true);
		}
	}
};