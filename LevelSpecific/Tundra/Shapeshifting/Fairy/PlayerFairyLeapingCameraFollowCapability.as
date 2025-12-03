class UTundraPlayerFairyCameraFollowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLeap);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLeapCamera);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UTundraPlayerFairyComponent FairyComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;
	UTundraPlayerFairySettings Settings;

	float TimeOfLastCameraMove = -100.0;

	const float AccelerationThreshold = 0.001;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(FairyComp.bIsLeaping && !GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
			TimeOfLastCameraMove = Time::GetGameTimeSeconds();
		else if(!FairyComp.bIsLeaping)
			TimeOfLastCameraMove = -100.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!FairyComp.bIsLeaping)
			return false;

		if(Time::GetGameTimeSeconds() - TimeOfLastCameraMove < Settings.CameraFollowAgainDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if(!FairyComp.bIsLeaping)
			return true;

		if(Time::GetGameTimeSeconds() - TimeOfLastCameraMove < Settings.CameraFollowAgainDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator NewRotation = Math::RInterpShortestPathTo(CameraUserComp.GetDesiredRotation(), Player.Mesh.WorldRotation + Settings.OffsetDesiredRotationInLeap, DeltaTime, Settings.LeapingFollowCameraInterpSpeed);
		CameraUserComp.SetDesiredRotation(NewRotation, this);
	}
}