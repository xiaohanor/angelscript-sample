class USummitStoneBallMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASummitStoneBall Ball;
	bool bWasGrounded = false;

	UHazeMovementComponent MoveComp;
	USummitBallMovementData Movement;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitStoneBall>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USummitBallMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TEMPORAL_LOG(Ball)
			.DirectionalArrow("Mio Push Velocity", Ball.ActorLocation, Ball.PushDirMio.Value)
			.DirectionalArrow("Zoe Push Velocity", Ball.ActorLocation, Ball.PushDirZoe)
		;	
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
				FVector PushTargetVelocity = Ball.PushDirMio.GetValue() * Ball.MovementPushSpeed[EHazePlayer::Mio] + Ball.PushDirZoe * Ball.MovementPushSpeed[EHazePlayer::Zoe];
				if(!PushTargetVelocity.IsNearlyZero())
					HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, PushTargetVelocity, DeltaTime, 1);

				FVector VerticalVelocity = MoveComp.VerticalVelocity;

				if(MoveComp.IsOnAnyGround())
					HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Ball.HorizontalSpeedGroundDeceleration);

				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				Movement.AddVelocity(HorizontalVelocity + VerticalVelocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			auto Impacts = MoveComp.AllImpacts;

			for(auto Impact : Impacts)
			{
				FVector DirToImpact = (Impact.ImpactPoint - Ball.ActorLocation).GetSafeNormal();
				float SpeedTowardsImpact = MoveComp.PreviousVelocity.DotProduct(DirToImpact);

				TEMPORAL_LOG(Ball, "Impacts")
					.DirectionalArrow("Dir to Impact", Ball.ActorLocation, DirToImpact * 500, 10, 400, FLinearColor::Red)
					.Value("Speed towards Impact", SpeedTowardsImpact)
				;

				if(SpeedTowardsImpact < 600)
					continue;	

				TEMPORAL_LOG(Ball, "Impacts").Event("Impacted!");

				FSummitStoneBallLandedOnGroundParams Params;
				Params.LandLocation = Impact.ImpactPoint;
				USummitStoneBallEffectHandler::Trigger_OnBallLandedOnGround(Ball, Params);
				bWasGrounded = true;

				float VelocitySize = (MoveComp.HorizontalVelocity + MoveComp.VerticalVelocity).Size();
				float FeedbackAlpha = Math::Clamp(VelocitySize / 9000.0, 0.0, 1.0);
				// Print(f"{FeedbackAlpha}");

				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.PlayWorldCameraShake(Ball.CameraShake, this, Ball.ActorLocation, 200.0, 5500.0, Scale = FeedbackAlpha);
					float Distance = Player.GetDistanceTo(Ball);

					if (Distance < 4500.0)
					{
						float Alpha = Distance / 4000.0;
						Alpha = Math::Clamp(Alpha, 0.0, 1.0);
						Player.PlayForceFeedback(Ball.Rumble, false, false, this, FeedbackAlpha * Alpha);
						// Print(f"{FeedbackAlpha * Alpha}");
					}
				}
				// Only allow for one impact per frame
				return;
			}
		}
		else if(bWasGrounded)
		{
			USummitStoneBallEffectHandler::Trigger_OnBallBecameAirborne(Ball);
			bWasGrounded = false;
		}
	}
};