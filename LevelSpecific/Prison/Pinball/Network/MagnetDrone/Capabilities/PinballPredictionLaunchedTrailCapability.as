class UPinballPredictionLaunchedTrailCapability : UPinballMagnetDronePredictionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballMagnetDroneLaunchedComponent ControlLaunchedComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;

		Super::Setup();

		ControlLaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(Proxy.LaunchedComp.PushedByPlunger != nullptr)
			return true;

		if(Proxy.RailComp.IsInAnyRail())
			return false;

		if(Proxy.LaunchedComp.WasLaunchedThisFrame())
			return true;

		if(ControlLaunchedComp.WasLaunchedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Proxy.LaunchedComp.PushedByPlunger != nullptr)
			return false;

		if(Proxy.RailComp.IsInAnyRail())
			return true;

		if(!Proxy.LaunchedComp.WasLaunched())
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
};