UCLASS(NotBlueprintable)
class UPinballBossBallLaunchedComponent : UActorComponent
{
	APinballBossBall BossBall;
	UPinballBallComponent BallComp;
	UHazeMovementComponent MoveComp;
	UPinballBossBallLaunchedOffsetComponent LaunchedOffsetComp;

	bool bIsLaunched = false;
	bool bHasBeenConsumed = false;
	float LaunchedTime;
	FPinballBallLaunchData LaunchData;
	uint LaunchedFrame = 0;

	TArray<FPinballRecentLaunch> RecentLaunches;

	bool bLaunchIsTrajectory = false;
	FTraversalTrajectory LaunchTrajectory;
	float LaunchTrajectoryStartTime = 0;

	// Lerp Back
	FVector AccOffset;
	FVector OffsetPlane;
	float ReturnOffsetDuration;

	// Prediction
	float LaunchedPredictedOtherSideTime;
	float PredictedLaunchAheadTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		BallComp = UPinballBallComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		LaunchedOffsetComp = UPinballBossBallLaunchedOffsetComponent::Get(Owner);

		BallComp.OnLaunched.AddUFunction(this, n"OnLaunched");
		BallComp.GetLaunchedByDelegate.BindUFunction(this, n"GetLaunchedBy");

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBossBallLaunched");
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
			TemporalLog.Sphere(f"LaunchLocation", LaunchData.LaunchLocation, BallComp.GetRadius());
			TemporalLog.Value(f"WasLaunchedBy", LaunchData.LaunchedBy);
			TemporalLog.Value(f"LaunchedFrame", LaunchedFrame);
			TemporalLog.DirectionalArrow(f"LaunchVelocity", LaunchData.LaunchLocation, LaunchData.LaunchVelocity, 300, 20);
			TemporalLog.DirectionalArrow(f"LaunchDirection", LaunchData.LaunchLocation, GetLaunchDirection(), 300, 20);
			TemporalLog.Value(f"FromBallSide", LaunchData.bFromBallSide);
		}
#endif
	}

	UFUNCTION()
	private void OnLaunched(FPinballBallLaunchData InLaunchData)
	{
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

		LaunchedTime = Time::GameTimeSeconds;
		LaunchData = InLaunchData;

		LaunchedFrame = Time::FrameNumber;
		bHasBeenConsumed = false;

		if(Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			LaunchedPredictedOtherSideTime = Time::OtherSideCrumbTrailSendTimePrediction;
			PredictedLaunchAheadTime = Time::GetActorDeltaSeconds(BossBall);
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

		FVector VisualLocation = BossBall.MeshRootComp.WorldLocation;
		if(LaunchData.LaunchedBy.ShouldLerpBack())
		{
			const FPinballLauncherLerpBackSettings& LerpBackSettings = LaunchData.LaunchedBy.GetLerpBackSettings();

			ReturnOffsetDuration = LerpBackSettings.GetLerpBackDuration();
			AccOffset = VisualLocation - LaunchData.LaunchLocation;

			if(LerpBackSettings.bOnlyLerpBackHorizontally)
			{
				OffsetPlane = LaunchData.LaunchVelocity.GetSafeNormal();
				AccOffset = AccOffset.VectorPlaneProject(OffsetPlane);
			}
			else
			{
				OffsetPlane = FVector::ZeroVector;
			}

			AccOffset.X = 0;
		}
		
		if(Pinball::bIgnoreCollisionWhenLaunched)
		{
			// Clear any previous ignores
			MoveComp.RemoveMovementIgnoresActor(this);

			// Ignore the launcher actor
			MoveComp.AddMovementIgnoresActor(this, LaunchData.LaunchedBy.Owner);
		}

		MoveComp.Owner.SetActorLocation(LaunchData.LaunchLocation);
		MoveComp.HazeOwner.SetActorVelocity(LaunchData.LaunchVelocity);
		MoveComp.OverrideGroundContact(FHitResult(), this);

		// Just make sure we make the launch data old
		LaunchedFrame -= 2;
	}

	void ResetLaunch()
	{
		if(Pinball::bIgnoreCollisionWhenLaunched)
		{
			MoveComp.RemoveMovementIgnoresActor(this);
		}

		LaunchedTime = 0.0;
		LaunchData = FPinballBallLaunchData();
		LaunchedFrame = 0;
		LaunchedPredictedOtherSideTime = 0.0;
		bIsLaunched = false;
	}

	void ResetLaunchTrajectory()
	{
		bLaunchIsTrajectory = false;
		LaunchTrajectory = FTraversalTrajectory();
		LaunchTrajectoryStartTime = 0;
	}

	UFUNCTION()
	private UPinballLauncherComponent GetLaunchedBy()
	{
		return LaunchData.LaunchedBy;
	}
};