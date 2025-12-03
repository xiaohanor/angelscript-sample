struct FSkylineInnerPlayerBackwardsSomersaultJumpActionActivateParams
{
	float Duration;
	float TimeDilation;
	float Impulse;
	FVector StartGravityDirection;
	FVector TargetGravityDirection;
}

struct FSkylineInnerPlayerBackwardsSomersaultJumpActionDeactivateParams
{
	bool bNormalDeactivate = false;
}

class USkylineInnerPlayerBackwardsSomersaultJumpActionCapability : UHazePlayerCapability
{
	FSkylineInnerPlayerBackwardsSomersaultJumpActionActivateParams ActionParams;

	default DebugCategory = SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault;
	default CapabilityTags.Add(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault);

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;
	UPlayerInteractionsComponent InteractionComp;

	FVector StartGravityDirection;
	FVector StartVelocity;
	FQuat GravityStartRotation;
	FQuat GravityTargetRotation;

	FQuat StartRotation;
	FQuat TargetRotation;

	USkylineInnerPlayerBackwardsSomersaultComponent ActionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		ActionComp = USkylineInnerPlayerBackwardsSomersaultComponent::GetOrCreate(Owner);
		InteractionComp = UPlayerInteractionsComponent::Get(Owner);
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineInnerPlayerBackwardsSomersaultJumpActionActivateParams& ActivationParams) const
	{
		if (ActionComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineInnerPlayerBackwardsSomersaultJumpActionDeactivateParams & DeactivationParams) const
	{
		if (!ActionComp.ActionQueue.IsActive(this))
			return true;
		if (ActiveDuration > ActionParams.Duration)
		{
			DeactivationParams.bNormalDeactivate = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineInnerPlayerBackwardsSomersaultJumpActionActivateParams ActivationParams)
	{
		ActionParams = ActivationParams;
		StartGravityDirection = ActivationParams.StartGravityDirection;
		StartVelocity = -StartGravityDirection * ActionParams.Impulse;
		MoveComp.Reset(true);
	
		GravityStartRotation = FQuat::MakeFromZY(-StartGravityDirection, Player.ActorRightVector);
		GravityTargetRotation = FQuat::MakeFromZY(-ActionParams.TargetGravityDirection, Player.ActorRightVector);

		StartRotation = Player.ActorQuat;
		TargetRotation = TargetRotation;

		Player.PlaySlotAnimation(Animation =ActionComp.Animation, bLoop = true);
		if (ActionComp.Data.bModifyCamera)
			Player.ApplyCameraSettings(ActionComp.CameraSettings, 2.0, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator, EHazeCameraPriority::High);
	
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::Swimming, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineInnerPlayerBackwardsSomersaultJumpActionDeactivateParams DeactivationParams)
	{
		ActionComp.ActionQueue.Finish(this);

		if(DeactivationParams.bNormalDeactivate)
			Player.SetActorTimeDilation(ActionParams.TimeDilation, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);

		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swimming, this);
		if (ActionComp.Data.bModifyCamera)
			Player.ClearCameraSettingsByInstigator(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		Player.OverrideGravityDirection(-GravityTargetRotation.UpVector, Skyline::GravityProxy, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / ActionParams.Duration);
		FVector UpDirection = FQuat::Slerp(GravityStartRotation, GravityTargetRotation, Alpha).UpVector;
		Player.OverrideGravityDirection(-UpDirection, Skyline::GravityProxy);
		
		const float TimeDilation = Math::Lerp(1, ActionParams.TimeDilation, Alpha);
		Player.SetActorTimeDilation(TimeDilation, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator, EInstigatePriority::High);

		if (InteractionComp.ActiveInteraction != nullptr)
			return;

		if(MoveComp.PrepareMove(MoveData, UpDirection))
		{
			FVector Velocity = Math::Lerp(StartVelocity, FVector::ZeroVector, Alpha);
			MoveData.AddVelocity(Velocity);
			FQuat Rotation = FQuat::Slerp(StartRotation, TargetRotation, Alpha);
			MoveData.SetRotation(Rotation);
			MoveComp.ApplyMove(MoveData);
		}
	}
}
