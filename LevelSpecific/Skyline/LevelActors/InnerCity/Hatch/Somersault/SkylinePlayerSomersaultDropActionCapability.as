struct FSkylineInnerPlayerBackwardsSomersaultDropActionData
{
	float Duration;
	float TimeDilation;
	float GravityScale;
}

class USkylineInnerPlayerBackwardsSomersaultDropActionCapability : UHazePlayerCapability
{
	FSkylineInnerPlayerBackwardsSomersaultDropActionData ActionParams;
	default DebugCategory = SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault;
	default CapabilityTags.Add(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault);

	USkylineInnerPlayerBackwardsSomersaultComponent ActionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = USkylineInnerPlayerBackwardsSomersaultComponent::GetOrCreate(Owner);
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineInnerPlayerBackwardsSomersaultDropActionData& ActivationParams) const
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
		if (ActiveDuration > ActionParams.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineInnerPlayerBackwardsSomersaultDropActionData Params)
	{
		ActionParams = Params;
		UMovementGravitySettings::SetGravityScale(Player, 0.02, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
		UMovementGravitySettings::ClearGravityScale(Player, this);
		ActionComp.OnBackwardsSomersaultComplete.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / ActionParams.Duration);
		const float TimeDilation = Math::Lerp(ActionParams.TimeDilation, 1, Alpha);
		Player.SetActorTimeDilation(TimeDilation, SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersaultInstigator);
		const float GravityScale = Math::Lerp(ActionParams.GravityScale, 1, Alpha);
		UMovementGravitySettings::SetGravityScale(Player, GravityScale, this);
	}
}