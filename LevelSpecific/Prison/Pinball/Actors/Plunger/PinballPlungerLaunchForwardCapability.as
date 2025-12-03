struct FPinballPlungerLaunchForwardDeactivationParams
{
	bool bHitTop = false;
};

class UPinballPlungerLaunchForwardCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 60;

	APinballPlunger Plunger;
	
	TArray<UPinballBallComponent> BallsBeingPushed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plunger = Cast<APinballPlunger>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return false;

		if(Plunger.State != EPinballPlungerState::PullBack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballPlungerLaunchForwardDeactivationParams& Params) const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return true;

		if(Plunger.State != EPinballPlungerState::LaunchForward)
			return true;

		if(Math::IsNearlyEqual(Plunger.PlungerDistance, Plunger.LaunchForwardDistance))
		{
			// We hit the end of the plunge!
			Params.bHitTop = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Plunger.State = EPinballPlungerState::LaunchForward;

		Plunger.StopPullBackDistance = Plunger.PlungerDistance;
		Plunger.PlungerSpeed = 0;

		// Store an alpha of how far we have pulled back
		float PulledBackSinceStart = Plunger.PlungerDistance - Plunger.StartPullBackDistance;
		Plunger.LaunchPowerAlpha = 1 - Math::Saturate(Math::NormalizeToRange(PulledBackSinceStart, -Plunger.PullBackDistance, 0));

		auto EventData = FPinballPlungerOnLaunchForwardEventData();
		EventData.LaunchDistance = Plunger.LaunchPowerAlpha;

		UPinballPlungerEventHandler::Trigger_OnStartLaunchForward(Plunger, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballPlungerLaunchForwardDeactivationParams Params)
	{
		if(Params.bHitTop)
		{
			UPinballPlungerEventHandler::Trigger_OnHitTop(Plunger);

			// Stop when reaching the max forward distance
			Plunger.PlungerDistance = Plunger.LaunchForwardDistance;

			if(Pinball::GetPaddlePlayer().HasControl())
			{
				// Actually launch all following balls
				LaunchAll();
			}

			Plunger.PlungerSpeed = Plunger.PlungerSpeed * -Plunger.LaunchForwardHitEndBounceFactor;		// Bounce back

			Plunger.ApplyLocation();
		}

		auto EventData = FPinballPlungerOnLaunchForwardEventData();
		EventData.LaunchDistance = Plunger.LaunchPowerAlpha;
		EventData.bHitTop = Params.bHitTop;
	
		UPinballPlungerEventHandler::Trigger_OnStopLaunchForward(Plunger, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		for(int i = 0; i < BallsBeingPushed.Num(); i++)
		{
			const UPinballBallComponent BallComp = BallsBeingPushed[i];
			TemporalLog.Value(f"Ball {i + 1};Name", BallComp);
			TemporalLog.Value(f"Ball {i + 1};In Sweep", Plunger.SweepForBall(BallComp.Owner.ActorLocation, BallComp.GetRadius(), Plunger.StopPullBackDistance));
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ForwardMovement(DeltaTime);

		if(Pinball::GetPaddlePlayer().HasControl())
		{
			SweepForBalls();
		}
		else
		{
			BallSidePreventPenetration();
		}

		Plunger.ApplyLocation();
	}

	private void SweepForBalls()
	{
		check(Pinball::GetPaddlePlayer().HasControl());

		// Find balls that should be launched
		for(UPinballBallComponent Ball : Pinball::GetManager().Balls)
		{
#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Balls").Section(f"{Ball.Owner.Name}");
			TemporalLog.Value("IsValid", IsValid(Ball));
			TemporalLog.Value("IsBeingLaunched", IsBeingLaunched(Ball));
			TemporalLog.Sphere("Location", Ball.Owner.ActorLocation, Ball.GetRadius());
#endif

			if(Ball == nullptr)
				continue;

			// Ignore already launched balls
			if(IsBeingLaunched(Ball))
				continue;

			if(Ball.GetLaunchedByDelegate.Execute() == Plunger.LauncherComp)
				continue;

			if(!Plunger.SweepForBall(Ball.Owner.ActorLocation, Ball.GetRadius(), Plunger.StopPullBackDistance))
				continue;

			StartPushingBall(Ball);
		}
	}

	private void BallSidePreventPenetration()
	{
		check(!Pinball::GetPaddlePlayer().HasControl());

		AHazePlayerCharacter BallPlayer = Pinball::GetBallPlayer();
		UPinballBallComponent Ball = UPinballBallComponent::Get(BallPlayer);
		if(Ball == nullptr)
			return;

		if(Ball.GetLaunchedByDelegate.Execute() == Plunger.LauncherComp)
			return;

		if(!Plunger.SweepForBall(Ball.Owner.ActorLocation, Ball.GetRadius(), Plunger.StopPullBackDistance))
			return;

		// On the ball side in network, we sweep for balls, but only to push the player to prevent depenetration
		FVector LaunchLocation = Plunger.GetCurrentLaunchLocation(Ball.Owner.ActorLocation, Ball.GetRadius());
		FVector RelativeLocation = Plunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(Ball.Owner.ActorLocation);
		FVector RelativeLaunchLocation = Plunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(LaunchLocation);
		RelativeLocation.Z = RelativeLaunchLocation.Z;
		FVector WorldLocation = Plunger.PlungerComp.WorldTransform.TransformPositionNoScale(RelativeLocation);

		FVector Delta = WorldLocation - Ball.Owner.ActorLocation;
		auto MoveComp = UPlayerMovementComponent::Get(BallPlayer);
		MoveComp.HandlePlayerMoveInto(Delta, Plunger.PlungerComp, false, "Plunger");
	}
	
	private void ForwardMovement(float DeltaTime)
	{
		// Accelerate forwards
		Plunger.PlungerSpeed += Plunger.LaunchForwardAcceleration * DeltaTime;

		// Limit max velocity
		if(Plunger.PlungerSpeed > Plunger.LaunchForwardMaxSpeed)
			Plunger.PlungerSpeed = Plunger.LaunchForwardMaxSpeed;

		// Move forward
		Plunger.PlungerDistance = Math::Min(Plunger.PlungerDistance + Plunger.PlungerSpeed * DeltaTime, Plunger.LaunchForwardDistance);
	}

	private void StartPushingBall(UPinballBallComponent Ball)
	{
		check(Pinball::GetPaddlePlayer().HasControl());

		check(!BallsBeingPushed.Contains(Ball));

		// Store them to be launched at the top of the launch
		BallsBeingPushed.AddUnique(Ball);

		// Broadcast that we should start being pushed by a plunger
		const FPinballBallPushedByPlungerData PushedByPlungerData(Plunger, Ball.GetVisualLocation());
		Ball.OnPushedByPlunger.Broadcast(PushedByPlungerData);
	}

	private void LaunchAll()
	{
		check(Pinball::GetPaddlePlayer().HasControl());

		if(!BallsBeingPushed.IsEmpty())
			TEMPORAL_LOG(Owner).Status("Launch All", FLinearColor::Green);

		for(auto BallComp : BallsBeingPushed)
		{
			LaunchBall(BallComp);
		}

		BallsBeingPushed.Reset();
	}

	private void LaunchBall(UPinballBallComponent Ball)
	{
		check(Pinball::GetPaddlePlayer().HasControl());

		const float PullBackAlpha = Plunger.GetStopPullBackAlpha();
		const float LaunchPower = Plunger.GetLaunchPower(PullBackAlpha);	// Base the launch power on the distance we released at

		const FPinballBallLaunchData LaunchData(
			Plunger.GetFinalLaunchLocation(Ball.Owner.ActorLocation, Ball.GetRadius()),
			Ball.GetVisualLocation(),
			Plunger.GetLaunchDirection() * LaunchPower,
			Plunger.LauncherComp,
			false
		);
		
		Ball.Launch(LaunchData);

		Net_OnLaunchBall(Ball);
	}

	UFUNCTION(NetFunction)
	void Net_OnLaunchBall(UPinballBallComponent Ball)
	{
		FPinballPlungerOnLaunchBallEventData EventData;
		EventData.BallComp = Ball;
		UPinballPlungerEventHandler::Trigger_OnLaunchBall(Plunger, EventData);
	}

	bool IsBeingLaunched(const UPinballBallComponent BallComp) const
	{
		check(Pinball::GetPaddlePlayer().HasControl());
		return BallsBeingPushed.Contains(BallComp);
	}
};