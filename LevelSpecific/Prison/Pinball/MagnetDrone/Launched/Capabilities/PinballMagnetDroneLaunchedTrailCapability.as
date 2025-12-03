class UPinballMagnetDroneLaunchedTrailCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Pinball::Tags::BlockedOnPrediction);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UPinballBallComponent BallComp;
	UPinballMagnetDroneLaunchedComponent LaunchComp;
	UPinballMagnetDroneRailComponent RailComp;

	UPinballMagnetDronePredictionComponent PredictionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Player);
		LaunchComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
		RailComp = UPinballMagnetDroneRailComponent::Get(Player);

		PredictionComp = UPinballMagnetDronePredictionComponent::Get(Player);
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
		if(LaunchComp.PushedByPlunger != nullptr)
			return true;
		
		if(RailComp.IsInAnyRail())
			return false;

		if(Owner.IsAnyCapabilityActive(Pinball::Tags::PinballLaunched))
			return true;

		if(Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			auto ProxyLaunchedComponent = UPinballProxyLaunchedComponent::Get(PredictionComp.Proxy);
			if(!ProxyLaunchedComponent.WasLaunched())
				return false;

			if(Owner.IsAnyCapabilityActive(Pinball::Tags::PredictionLaunch))
				return true;
		}

		return false;
	}
};