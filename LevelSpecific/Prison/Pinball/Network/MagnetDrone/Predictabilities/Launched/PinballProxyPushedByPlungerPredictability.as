class UPinballProxyPushedByPlungerPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	// Player
	UPinballMagnetDroneLaunchedComponent PlayerLaunchedComp;

	// Proxy
	UPinballProxyLaunchedComponent ProxyLaunchedComp;
	UPinballMagnetDroneProxyMovementComponent ProxyMoveComp;
	UPinballProxyTeleportingMovementData MoveData;

	// State
	APinballPlunger PushingPlunger;
	float InitialHorizontalOffset;
	float InitialAlpha;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		PlayerLaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(MagnetDrone);

		ProxyLaunchedComp = UPinballProxyLaunchedComponent::Get(Proxy);
		ProxyMoveComp = UPinballMagnetDroneProxyMovementComponent::Get(Proxy);
		MoveData = ProxyMoveComp.SetupMovementData(UPinballProxyTeleportingMovementData);
	}

	void InitPredictabilityState() override
	{
		Super::InitPredictabilityState();
	}
	
#if !RELEASE
	void LogState(FTemporalLog SubframeLog) const override
	{
		Super::LogState(SubframeLog);
		
		SubframeLog.Value(f"LaunchedFrame", ProxyLaunchedComp.LaunchedFrame)
		.Value(f"TickFrameNumber", Proxy.SubframeNumber)
		.Value(f"WasLaunchedThisFrame()", ProxyLaunchedComp.WasLaunchedThisFrame());
	}
#endif

	bool ShouldActivate(bool bInit) override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return false;

		if(ProxyLaunchedComp.PushedByPlunger == nullptr)
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return true;

		if(ProxyLaunchedComp.PushedByPlunger == nullptr)
			return true;

		if(ProxyLaunchedComp.PushedByPlunger != PushingPlunger)
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		PushingPlunger = ProxyLaunchedComp.PushedByPlunger;
		InitialHorizontalOffset = ProxyLaunchedComp.InitialHorizontalOffset;
		InitialAlpha = ProxyLaunchedComp.InitialAlpha;

		ProxyMoveComp.FollowComponentMovement(PushingPlunger.PlungerComp, this, EMovementFollowComponentType::Teleport);
	}

	void OnDeactivated() override
	{
		PushingPlunger = nullptr;
		ProxyMoveComp.UnFollowComponentMovement(this);
	}
	
	void TickActive(float DeltaTime) override
	{
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime))
			return;

		const FVector Delta = CalculateDelta();
		const FVector Velocity = CalculateVelocity();
		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		//FVector TargetLocation = ProxyLaunchedComp.PushedByPlunger.GetCurrentLaunchLocation(Proxy.ActorLocation, MagnetDrone::Radius);
		//MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(TargetLocation, Velocity);

		ProxyMoveComp.ApplyMove(MoveData);
	}

	void PostPrediction() override
	{
		Super::PostPrediction();

		if(bIsActive)
			ProxyMoveComp.UnFollowComponentMovement(this);
	}

	private FVector CalculateVelocity() const
	{
		const FVector Velocity = Proxy.GetActorVelocity();
		FVector RelativeVelocity = PushingPlunger.PlungerComp.WorldTransform.InverseTransformVectorNoScale(Velocity);

		// Prevent horizontal movement along the paddle
		RelativeVelocity.Y = 0;

		const FVector TargetLaunchLocation = PushingPlunger.GetCurrentLaunchLocation(Proxy.ActorLocation, MagnetDrone::Radius);
		const FVector TargetRelativeLaunchLocation = PushingPlunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(TargetLaunchLocation);
		FVector RelativeLocation = PushingPlunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(Proxy.ActorLocation);
		if(RelativeLocation.Z < TargetRelativeLaunchLocation.Z)
		{
			RelativeVelocity.Z = 0;
			RelativeLocation.Z = TargetRelativeLaunchLocation.Z;
		}

		return PushingPlunger.PlungerComp.WorldTransform.TransformVectorNoScale(RelativeVelocity);
	}

	private FVector CalculateDelta() const
	{
		const FVector TargetLaunchLocation = PushingPlunger.GetCurrentLaunchLocation(Proxy.ActorLocation, MagnetDrone::Radius);
		FVector TargetRelativeLaunchLocation = PushingPlunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(TargetLaunchLocation);

		if(PushingPlunger.bLerpWhileLaunching)
		{
			// Move in to the center of the plunger over time
			float Alpha = PushingPlunger.GetCurrentLaunchForwardAlpha();
			Alpha = Math::GetPercentageBetweenClamped(InitialAlpha, 1.0, Alpha);
			Alpha = Math::EaseIn(0, 1, Alpha, 1.5);

			check(Alpha == Math::Saturate(Alpha));

			// Lerp horizontally
			const float HorizontalOffset = Math::Lerp(InitialHorizontalOffset, TargetRelativeLaunchLocation.Y, Alpha);
			TargetRelativeLaunchLocation.Y = HorizontalOffset;
		}

		const FVector NewLocation = PushingPlunger.PlungerComp.WorldTransform.TransformPositionNoScale(TargetRelativeLaunchLocation);
		return NewLocation - Proxy.ActorLocation;
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);

		const FVector Velocity = CalculateVelocity();
		const FVector Delta = CalculateDelta();

		SubframeLog.DirectionalArrow("Calculated Velocity", Proxy.ActorLocation, Velocity);
		SubframeLog.DirectionalArrow("Calculated Delta", Proxy.ActorLocation, Delta);

		const FVector FullDelta = Delta + (Velocity * Proxy.TickGameTime);
		SubframeLog.DirectionalArrow("Full Delta", Proxy.ActorLocation, FullDelta);

		SubframeLog.Sphere("Location", Proxy.ActorLocation, MagnetDrone::Radius);
		SubframeLog.Sphere("Current Launch Location", PushingPlunger.GetCurrentLaunchLocation(Proxy.ActorLocation, MagnetDrone::Radius), MagnetDrone::Radius);
		SubframeLog.Sphere("Final Launch Location", PushingPlunger.GetFinalLaunchLocation(Proxy.ActorLocation, MagnetDrone::Radius), MagnetDrone::Radius);
		SubframeLog.Sphere("Location after Delta", Proxy.ActorLocation + FullDelta, MagnetDrone::Radius);

		FVector RelativeLocation = PushingPlunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(Proxy.ActorLocation);
		SubframeLog.Value("RelativeLocation", RelativeLocation);
		SubframeLog.Value("InitialAlpha", InitialAlpha);
		SubframeLog.Value("Alpha", PushingPlunger.GetCurrentLaunchForwardAlpha());
		SubframeLog.Value("InitialHorizontalOffset", InitialHorizontalOffset);
	}
#endif
}