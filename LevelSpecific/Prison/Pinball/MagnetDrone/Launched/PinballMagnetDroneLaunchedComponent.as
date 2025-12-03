struct FPinballRecentLaunch
{
	UPinballLauncherComponent LaunchedBy;
	float LaunchedRealTime;
	bool bFromBallSide;
}

UCLASS(NotBlueprintable, NotPlaceable)
class UPinballMagnetDroneLaunchedComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UPinballBallComponent BallComp;
	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneLaunchedOffsetComponent LaunchedOffsetComp;

	TArray<FPinballRecentLaunch> RecentLaunches;

	bool bIsLaunched = false;
	bool bHasBeenConsumed = false;

	FPinballBallLaunchData LaunchData;
	float LaunchedTime;
	uint LaunchedFrame = 0;

	// Plunger
	APinballPlunger PushedByPlunger;
	float InitialHorizontalOffset = 0;
	float InitialAlpha = 0;

	// Prediction
	float LaunchedPredictedOtherSideTime;
	float PredictedLaunchAheadTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BallComp = UPinballBallComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		LaunchedOffsetComp = UPinballMagnetDroneLaunchedOffsetComponent::Get(Player);

		BallComp.OnPushedByPlunger.AddUFunction(this, n"OnPushedByPlunger");
		BallComp.OnLaunched.AddUFunction(this, n"OnLaunched");
		BallComp.GetLaunchedByDelegate.BindUFunction(this, n"GetLaunchedBy");
		BallComp.GetVisualLocationDelegate.BindUFunction(this, n"GetVisualLocation");

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDroneLaunched");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value(f"WasLaunched", WasLaunched());
		TemporalLog.Value(f"WasLaunchedThisFrame", WasLaunchedThisFrame());

		if(WasLaunched())
		{
			TemporalLog.Sphere(f"LaunchLocation", LaunchData.LaunchLocation, MagnetDrone::Radius);
			TemporalLog.Value(f"WasLaunchedBy", LaunchData.LaunchedBy);
			TemporalLog.Value(f"LaunchedFrame", LaunchedFrame);
			TemporalLog.DirectionalArrow(f"LaunchVelocity", LaunchData.LaunchLocation, LaunchData.LaunchVelocity, 2, 20);
			TemporalLog.DirectionalArrow(f"LaunchDirection", LaunchData.LaunchLocation, GetLaunchDirection() * 300, 2, 20);
		}

		TemporalLog.Value(f"PushedByPlunger", PushedByPlunger);
#endif
	}

	UFUNCTION()
	private void OnPushedByPlunger(FPinballBallPushedByPlungerData PushedByPlungerData)
	{
		// Only paddle player can decide if we are pushed or not
		if(Network::IsGameNetworked() && Pinball::GetBallPlayer().HasControl())
			return;

		NetPaddleToBallPushedByPlunger(PushedByPlungerData);
	}

	UFUNCTION(NetFunction)
	private void NetPaddleToBallPushedByPlunger(FPinballBallPushedByPlungerData PushedByPlungerData)
	{
		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return;

		PushedByPlunger = PushedByPlungerData.Plunger;
		InitialHorizontalOffset = PushedByPlungerData.InitialHorizontalOffset;
		InitialAlpha = PushedByPlungerData.InitialAlpha;
	}

	UFUNCTION()
	private void OnLaunched(FPinballBallLaunchData InLaunchData)
	{
		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return;

		if(!Pinball::GetPaddlePlayer().HasControl())
		{
			if(!InLaunchData.LaunchedBy.bAllowLaunchFromBallSide)
				return;

			if(LaunchData.IsValid())
			{
				// Never send a new ball side launch while being launched
				// We would rather have the small delay on the ball side than risk rollbacks
				return;
			}

			FPinballBallLaunchData BallSideLaunchData = InLaunchData;
			BallSideLaunchData.bFromBallSide = true;
			NetLaunch(BallSideLaunchData);
			return;
		}

		NetLaunch(InLaunchData);
	}

	UFUNCTION()
	private FVector GetVisualLocation()
	{
		return Player.MeshOffsetComponent.WorldLocation;
	}

	UFUNCTION(NetFunction)
	private void NetLaunch(FPinballBallLaunchData InLaunchData)
	{
		MoveComp.TransitionCrumbSyncedPosition(this);

		if(LaunchData.IsValid())
		{
			// If the same component triggered a launch from the opposite side within the last two pings,
			// ignore this launch. This prevents the same launch from being triggered multiple times in latency-heavy situations
			if (Network::IsGameNetworked())
			{
				for (FPinballRecentLaunch RecentLaunch : RecentLaunches)
				{
					if (RecentLaunch.bFromBallSide == InLaunchData.bFromBallSide)
						continue;
					if (RecentLaunch.LaunchedBy != InLaunchData.LaunchedBy)
						continue;
					if (RecentLaunch.LaunchedRealTime < Time::RealTimeSeconds - (Network::PingRoundtripSeconds * 2.0 + 0.5))
						continue;

					// We were already launched by this, so ignore this networked launch
					return;
				}
			}

			if(LaunchData.LaunchedBy == InLaunchData.LaunchedBy)
			{
				// We are already launched by this!
				// This often happens when being launched on both the Ball and Paddle side.
				// Simply ignore this launch.
				return;
			}

			if(InLaunchData.bFromBallSide && !Pinball::GetBallPlayer().HasControl())
			{
				// Never allow the ball side to interrupt a launch on the paddle side!
				// Paddle must always have priority, otherwise we get rollbacks
				return;
			}
		}

		BallComp.BroadcastOnLaunchedEvent(InLaunchData);
		InLaunchData.LaunchedBy.BroadcastOnHitByBall(BallComp, InLaunchData.bIsProxy);

		// Never pushed by a plunger after being launched
		PushedByPlunger = nullptr;
		
		LaunchedTime = Time::GameTimeSeconds;
		LaunchData = InLaunchData;

		if(!Pinball::GetPaddlePlayer().HasControl())
		{
			LaunchData.VisualLocation = BallComp.GetVisualLocation();
		}

		LaunchedFrame = Time::FrameNumber;
		bHasBeenConsumed = false;

		if(Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			LaunchedPredictedOtherSideTime = Time::OtherSideCrumbTrailSendTimePrediction;
			PredictedLaunchAheadTime = Time::GetActorDeltaSeconds(Player);
		}

		// Prune recent launch list of stuff that's too old
		for (int i = RecentLaunches.Num() - 1; i >= 0; --i)
		{
			if (RecentLaunches[i].LaunchedRealTime < Time::RealTimeSeconds - 10.0)
				RecentLaunches.RemoveAtSwap(i);
		}

		// Add this launch to the recent launch list so we can check it later
		FPinballRecentLaunch RecentLaunchRecord;
		RecentLaunchRecord.LaunchedBy = InLaunchData.LaunchedBy;
		RecentLaunchRecord.LaunchedRealTime = Time::RealTimeSeconds;
		RecentLaunchRecord.bFromBallSide = InLaunchData.bFromBallSide;
		RecentLaunches.Add(RecentLaunchRecord);

#if !RELEASE
		TEMPORAL_LOG(this)
			.Status(f"Launched by {InLaunchData.LaunchedBy.Owner} on frame {LaunchedFrame}!", FLinearColor::Green)
			.Event(f"Launched by {InLaunchData.LaunchedBy.Owner} on frame {Time::FrameNumber}!")
		;
#endif
	}

	bool WasLaunched() const
	{
		if(LaunchData.LaunchedBy == nullptr)
			return false;

		check(LaunchedFrame > 0);

		return true;
	}

	bool HasLaunchToConsume() const
	{
		if(bHasBeenConsumed)
			return false;

		if(!WasLaunchedThisFrame())
			return false;

		return true;
	}

	bool WasLaunchedThisFrame() const
	{
		if(!WasLaunched())
			return false;

		// We also accept hits from the previous frame, to basically ignore tick order
		if(Time::FrameNumber - LaunchedFrame <= 1)
			return true;

		return false;
	}

	FVector GetLaunchDirection() const
	{
		return LaunchData.LaunchVelocity.GetSafeNormal();
	}

	void ConsumeLaunch()
	{
		check(!bHasBeenConsumed);
		check(WasLaunchedThisFrame());

		if(LaunchData.LaunchedBy.ShouldLerpBack())
		{
			LaunchedOffsetComp.ApplyLaunchedOffset(
				LaunchData.LaunchedBy.GetLerpBackSettings(),
				LaunchData.LaunchLocation,
				LaunchData.LaunchVelocity,
				LaunchData.VisualLocation
			);
		}

		if(Pinball::bIgnoreCollisionWhenLaunched)
		{
			// Clear any previous ignores
			MoveComp.RemoveMovementIgnoresActor(this);

			// Ignore the launcher actor
			MoveComp.AddMovementIgnoresActor(this, LaunchData.LaunchedBy.Owner);
		}

		MoveComp.HazeOwner.SetActorLocation(LaunchData.LaunchLocation);
		MoveComp.HazeOwner.SetActorVelocity(LaunchData.LaunchVelocity);
		MoveComp.OverrideGroundContact(FHitResult(), this);

		bHasBeenConsumed = true;
	}

	void ResetLaunch()
	{
		if(Pinball::bIgnoreCollisionWhenLaunched)
		{
			MoveComp.RemoveMovementIgnoresActor(this);
		}

		bIsLaunched = false;
		LaunchData = FPinballBallLaunchData();
		LaunchedTime = 0.0;
		LaunchedFrame = 0;

		PushedByPlunger = nullptr;
		InitialHorizontalOffset = 0;
		InitialAlpha = 0;

		LaunchedPredictedOtherSideTime = 0;
		PredictedLaunchAheadTime = 0;
	}

	UFUNCTION()
	private UPinballLauncherComponent GetLaunchedBy()
	{
		return LaunchData.LaunchedBy;
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		ResetLaunch();
	}
};