class UPinballPredictionRailApplyOffsetCapability : UPinballMagnetDronePredictionCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 110;

	UPinballBallComponent BallComp;
	UPinballProxyRailPredictionComponent ProxyRailComp;

	APinballRail Rail;
	float Speed;
	EPinballRailHeadOrTail ExitSide;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;
		
		Super::Setup();

		BallComp = UPinballBallComponent::Get(Player);
		ProxyRailComp = UPinballProxyRailPredictionComponent::Get(Proxy);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(!ProxyRailComp.IsInAnyRail())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ProxyRailComp.IsInAnyRail())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rail = ProxyRailComp.Rail;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		const FVector VisualLocation = BallComp.GetVisualLocation();
		const FVector ExitLocation = VisualLocation.VectorPlaneProject(FVector::ForwardVector);
		const FVector ExitVelocity = Rail.GetExitVelocity(Speed, ExitSide);

		auto LaunchOffsetComp = UPinballMagnetDroneLaunchedOffsetComponent::Get(Player);
		FPinballLauncherLerpBackSettings LerpBackSettings;
		LerpBackSettings.bLerpBack = true;
		LerpBackSettings.bBaseDurationOnPing = false;
		LaunchOffsetComp.ApplyLaunchedOffset(LerpBackSettings, ExitLocation, ExitVelocity, VisualLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Speed = ProxyRailComp.Speed;
		ExitSide = ProxyRailComp.ExitSide;
	}
};