class UMedallionPlayerGloryKillCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryComp;

	float ExecuteTimestampExit;
	EMedallionGloryKillState LastState;

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
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (GloryComp.GloryKillState != EMedallionGloryKillState::Strangle)
			return false;
		if (Player.IsZoe())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GloryComp.GloryKillState == EMedallionGloryKillState::EnterSequence)
			return false;
		if (GloryComp.GloryKillState == EMedallionGloryKillState::Strangle)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ExecuteTimestampExit = 0.0;
		FTransform SequenceEndTransform = Player.GetViewTransform();
		FRotator Rotation = SequenceEndTransform.Rotator();
		FVector Backwards = Rotation.ForwardVector * MedallionConstants::GloryKill::CameraBackwardsOffset;
		Backwards.Z = 0.0;
		FVector Location = SequenceEndTransform.Location - Backwards;
		RefsComp.Refs.GloryKillCamera.SetActorLocationAndRotation(Location, Rotation);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.ActivateCamera(RefsComp.Refs.GloryKillCamera, MedallionConstants::GloryKill::CameraBlendInTime, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.DeactivateCamera(RefsComp.Refs.GloryKillCamera, MedallionConstants::GloryKill::CameraBlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GloryComp.GloryKillState == EMedallionGloryKillState::Return && LastState != EMedallionGloryKillState::Return)
			ExecuteTimestampExit = Time::GameTimeSeconds;

		// if (ExecuteTimestampExit > KINDA_SMALL_NUMBER)
		// 	PrintToScreen("execute timer: " + (Time::GameTimeSeconds - ExecuteTimestampExit));
		LastState = GloryComp.GloryKillState;
	}
};