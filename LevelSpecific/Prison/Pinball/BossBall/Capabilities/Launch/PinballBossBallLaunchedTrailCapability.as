class UPinballBossBallLaunchedTrailCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 103;

	UPinballBallComponent BallComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if(!IsLaunched())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsLaunched())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPinballBallEventHandler::Trigger_StartLaunch(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPinballBallEventHandler::Trigger_StopLaunch(Owner);
	}

	bool IsLaunched() const
	{
		if(Owner.IsAnyCapabilityActive(Pinball::Tags::PinballLaunched))
			return true;

		// TODO: This used to take launch input into account
		return false;
	}
};