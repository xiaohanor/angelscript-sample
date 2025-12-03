class USkylineInnerPlayerBackwardsSomersaultActionCapability : UHazePlayerCapability
{
	default DebugCategory = SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault;
	default CapabilityTags.Add(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 96;

	UCameraUserComponent CameraUserComp;
	UPlayerMovementComponent MoveComp;
	USkylineInnerPlayerBackwardsSomersaultComponent ActionComp;

	float ActivateTime;

	private bool bIsGravityAlignedThisFrame = false;
	private bool bWasGravityAlignedLastFrame = false;

	FQuat InitialWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComp = UCameraUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		ActionComp = USkylineInnerPlayerBackwardsSomersaultComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ActionComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActionComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialWorldUp = FQuat::MakeFromZ(-Player.GetGravityDirection());

		ActivateTime = Time::GameTimeSeconds;

		Player.BlockCapabilities(PlayerMovementTags::AirDash, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		MoveComp.ClearCurrentGroundedState();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearActorTimeDilation(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		Player.ClearCameraSettingsByInstigator(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);

		Player.StopSlotAnimationByAsset(ActionComp.Animation);
		if (Player.IsZoe())
			Player.ClearGravityDirectionOverride(Skyline::GravityProxy);

		Player.UnblockCapabilities(PlayerMovementTags::AirDash, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActionComp.Data.bModifyCamera)
		{
			const float Alpha = Math::Saturate(ActiveDuration / 3.0);
			const FQuat WorldUpRotation = FQuat::Slerp(InitialWorldUp, FQuat::MakeFromZ(-ActionComp.Data.TargetGravityDirection), Alpha);
			const FRotator DesiredRotation = CameraUserComp.GetDesiredRotation();
			const FVector DesiredForward = DesiredRotation.ForwardVector;
			const FRotator NewRotation = FRotator::MakeFromXZ(DesiredForward, WorldUpRotation.UpVector);
			CameraUserComp.SetDesiredRotation(NewRotation, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		}
	}
}