struct FSkylineInnerPlayerBackwardsSomersaultSlowAimActionData
{
	float Duration;
	float TimeDilation;
	float GravityScale;
}

class USkylineInnerPlayerBackwardsSomersaultSlowAimActionCapability : UHazePlayerCapability
{
	FSkylineInnerPlayerBackwardsSomersaultSlowAimActionData Params;
	default DebugCategory = SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault;
	default CapabilityTags.Add(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault);

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;
	USkylineInnerPlayerBackwardsSomersaultComponent ActionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		ActionComp = USkylineInnerPlayerBackwardsSomersaultComponent::GetOrCreate(Owner);
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineInnerPlayerBackwardsSomersaultSlowAimActionData& ActivationParams) const
	{
		if (ActionComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ActionComp.ActionQueue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineInnerPlayerBackwardsSomersaultSlowAimActionData ActivationParams)
	{
		Params = ActivationParams;
		Player.SetActorTimeDilation(Params.TimeDilation, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		UMovementGravitySettings::SetGravityScale(Player, Params.GravityScale, this);
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
		Player.StopSlotAnimationByAsset(ActionComp.Animation);
		UMovementGravitySettings::ClearGravityScale(Player,this);
		if (ActionComp.Data.bModifyCamera)
			Player.ClearCameraSettingsByInstigator(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(MoveData))
		{
			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();
			MoveComp.ApplyMove(MoveData);
		}
	}
}
