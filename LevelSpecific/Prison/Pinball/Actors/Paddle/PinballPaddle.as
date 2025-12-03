struct FPinballPaddleHitResult
{
	float LaunchSpeed = 0;
	FVector LaunchDirection;
	
	float HitAngle;
	FPinballPaddleAutoAimTargetData AutoAimTargetData;
	bool bSquish;
};

struct FPinballPaddleDelayedHold
{
	float GameTime;
	bool bHeld;
	float Intensity;

	FPinballPaddleDelayedHold(float InGameTime, bool bInHeld, float InIntensity)
	{
		GameTime = InGameTime;
		bHeld = bInHeld;
		Intensity = InIntensity;
	}
};

enum EStupidChaos
{
	OldBroken,
	StaticBroken,
	StaticFixed,
	NewFixed,
};

UCLASS(Abstract, HideCategories = "ActorTick Rendering Disable Actor Replication Cooking DataLayers")
class APinballPaddle : AHazeActor
{
	// Ticking is handled by HackablePinballCapability
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UPinballPaddleComponent PaddleComp;

	UPROPERTY(DefaultComponent, Attach = PaddleComp)
	UStaticMeshComponent Flipper;
	default Flipper.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default Flipper.RemoveTag(ComponentTags::InheritVerticalDownMovementIfGround);

	UPROPERTY(DefaultComponent)
	UHackablePinballResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPinballLauncherComponent LauncherComp;
	default LauncherComp.NetworkBallSideLerpBackSettings.bLerpBack = true;

	UPROPERTY(DefaultComponent, Attach = PaddleComp)
	UPinballPredictionRecordTransformComponent PredictionRecordTransformComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3000;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalLogTransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogSubframeTransformLoggerComponent TemporalLogSubframeTransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Paddle")
	float MinimumAngleFromTopToHit = 10;

	UPROPERTY(EditInstanceOnly, Category = "Network")
	bool bDelayActivationOnPaddleSide = false;

	protected bool bFlipperHeld = false;
	protected float InputIntensity = -1;
	protected bool bHasReachedTop = false;
	protected bool bCanHit = true;
	protected float FlipperAngle;
	protected float FlipperAngularVelocity = 0;
	protected float LastMoveTime = 0;
	protected bool bLastMoveWasUp = false;
	protected uint LastSweepFrame = 0;

	protected TArray<FPinballPaddleDelayedHold> DelayedHoldTimes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetPaddlePlayer());

		ResponseComp.OnPinballInputStart.AddUFunction(this, n"StartFlip");
		ResponseComp.OnPinballInputEnd.AddUFunction(this, n"StopFlip");

		FlipperAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Bottom);
		PaddleComp.SetRelativeRotation(PaddleComp.GetPaddleRelativeRotation(FlipperAngle));

		if(!HasControl())
		{
			// On Ball side, always follow movement up to not end up below the paddles
			Flipper.AddTag(ComponentTags::InheritVerticalUpMovementIfGround);
		}
	}

	void TickPaddle(float DeltaTime)
	{
		if(bDelayActivationOnPaddleSide)
			ProcessDelayedHoldQueue();

		float OldFlipperAngle = FlipperAngle;

		if(bFlipperHeld)
		{
			if(bHasReachedTop)
				return;

			const float TopAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Top);

			FlipperAngle = Math::FInterpConstantTo(FlipperAngle, TopAngle, DeltaTime, PaddleComp.UpAcceleration);
			FlipperAngularVelocity = (FlipperAngle - OldFlipperAngle) / DeltaTime;

			if(FlipperAngle > TopAngle - KINDA_SMALL_NUMBER)
			{
				FlipperAngle = TopAngle;
				FlipperAngularVelocity = 0;
				bHasReachedTop = true;
			}
		}
		else
		{
			bHasReachedTop = false;

			FlipperAngularVelocity = Math::Min(FlipperAngularVelocity, 0);
			FlipperAngularVelocity -= PaddleComp.FallAcceleration * DeltaTime;
			FlipperAngle += FlipperAngularVelocity * DeltaTime;

			const float BotAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Bottom);

			if(FlipperAngle < BotAngle + KINDA_SMALL_NUMBER)
			{
				FlipperAngle = BotAngle;
				FlipperAngularVelocity = 0;
			}
		}

		float DistanceToPlayer = ActorLocation.Distance(Pinball::GetBallPlayer().ActorLocation);
		if(DistanceToPlayer > PaddleComp.PaddleCullDistance)
			return;

		bool bMoved = (!Math::IsNearlyEqual(OldFlipperAngle, FlipperAngle) || FlipperAngularVelocity > KINDA_SMALL_NUMBER);
		bool bMovedUp = bMoved && (FlipperAngle > OldFlipperAngle || FlipperAngularVelocity > 0);

		if(bMoved)
		{
			LastMoveTime = Time::GameTimeSeconds;
			bLastMoveWasUp = bMovedUp;
		}
		else if(Time::GetGameTimeSince(LastMoveTime) < Pinball::PaddleMoveGraceTime)
		{
			// Add a grace period, since it feels shit when you feel like you hit, but the paddle stopped just before the ball
			bMoved = true;
			bMovedUp = bLastMoveWasUp;
		}

		if(bMoved && bCanHit)
			OnPaddleMoved(OldFlipperAngle, bMovedUp);
	}
	
	bool SweptThisFrame() const
	{
		return LastSweepFrame == Time::FrameNumber;
	}

	private void ProcessDelayedHoldQueue()
	{
		for(int i = 0; i < DelayedHoldTimes.Num(); i++)
		{
			if(Time::GetGameTimeSince(DelayedHoldTimes[i].GameTime) > Network::PingOneWaySeconds)
			{
				if(DelayedHoldTimes[i].bHeld)
					StartFlipInternal(DelayedHoldTimes[i].Intensity);
				else
					StopFlipInternal();

				DelayedHoldTimes.RemoveAt(0);
				i--;
			}
		}
	}

	void ApplyPaddleRotation()
	{
		PaddleComp.SetRelativeRotation(PaddleComp.GetPaddleRelativeRotation(FlipperAngle));
	}

	private void OnPaddleMoved(float OldFlipperAngle, bool bMovedUp)
	{
		if(Pinball::GetPaddlePlayer().HasControl())
		{
			SweepForBalls(OldFlipperAngle, bMovedUp);
		}
		else
		{
			BallSidePreventPenetration(OldFlipperAngle, bMovedUp);
		}
	}

	private void SweepForBalls(float OldFlipperAngle, bool bMovedUp)
	{
		check(Pinball::GetPaddlePlayer().HasControl());
		
		for(UPinballBallComponent Ball : Pinball::GetManager().Balls)
		{
			if(Ball == nullptr)
				continue;

			if(Ball.GetLaunchedByDelegate.Execute() == LauncherComp)
				continue;
			
			FPinballPaddleHitResult PaddleHitResult;
			if(!SweepForBall(Ball.BallType, Ball.Owner.ActorLocation, Ball.GetRadius(), OldFlipperAngle, FlipperAngle, bMovedUp, PaddleHitResult))
				continue;

			if(PaddleHitResult.bSquish)
			{
				Ball.Squish();
				continue;
			}

			const FPinballBallLaunchData LaunchData(
				Ball.Owner.ActorLocation,
				Ball.GetVisualLocation(),
				GetVelocityFromHit(Ball.BallType, Ball.Owner.ActorLocation, bMovedUp, PaddleHitResult),
				LauncherComp,
				false
			);

			Ball.Launch(LaunchData);

			FPinballPaddleLaunchEventParams Params;
			Params.Intensity = Math::GetMappedRangeValueClamped(FVector2D(1000, 3000), FVector2D(0.0, 1.0), LaunchData.LaunchVelocity.Size());
			Params.InputIntensity = InputIntensity;
			NetOnLaunchEvent(Params);
		}

		LastSweepFrame = Time::FrameNumber;
	}

	private void BallSidePreventPenetration(float OldFlipperAngle, bool bMovedUp)
	{
		check(!Pinball::GetPaddlePlayer().HasControl());

		AHazePlayerCharacter BallPlayer = Pinball::GetBallPlayer();
		UPinballBallComponent Ball = UPinballBallComponent::Get(BallPlayer);
		if(Ball == nullptr)
			return;

		if(Ball.GetLaunchedByDelegate.Execute() == LauncherComp)
			return;

		FPinballPaddleHitResult PaddleHitResult;
		if(!SweepForBall(Ball.BallType, Ball.Owner.ActorLocation, Ball.GetRadius(), OldFlipperAngle, FlipperAngle, bMovedUp, PaddleHitResult))
			return;

		// Move the ball with the paddle, to prevent penetration
		FQuat DeltaRotation = FQuat(FVector::ForwardVector, -Math::DegreesToRadians(FlipperAngle - OldFlipperAngle));
		FVector OffsetFromPaddle = Ball.Owner.ActorLocation - ActorLocation;
		OffsetFromPaddle = DeltaRotation * OffsetFromPaddle;
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Ball.Owner);
		FVector TargetLocation = ActorLocation + OffsetFromPaddle;
		FVector Delta = TargetLocation - Ball.Owner.ActorLocation;
		MoveComp.HandlePlayerMoveInto(Delta, PaddleComp, false, "Paddle");
	}

	UFUNCTION(NetFunction)
	void NetOnLaunchEvent(FPinballPaddleLaunchEventParams Params)
	{
		UPinballPaddleEventHandler::Trigger_PaddleLaunch(this, Params);
	}

	UFUNCTION()
	private void StartFlip(float Intensity)
	{
		if((bDelayActivationOnPaddleSide) && Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			DelayedHoldTimes.Add(FPinballPaddleDelayedHold(Time::GameTimeSeconds, true, Intensity));
			return;
		}

		StartFlipInternal(Intensity);
	}

	UFUNCTION()
	private void StopFlip()
	{
		if((bDelayActivationOnPaddleSide) && Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			DelayedHoldTimes.Add(FPinballPaddleDelayedHold(Time::GameTimeSeconds, false, 0));
			return;
		}

		StopFlipInternal();
	}

	private void StartFlipInternal(float Intensity)
	{
		bFlipperHeld = true;
		InputIntensity = Intensity;

		const float TopAngle = PaddleComp.GetRelativeAngle(EPinballPaddleTransformType::Top);
		if(FlipperAngle < TopAngle - MinimumAngleFromTopToHit)
		{
			bCanHit = true;
		}
		else
		{
			bCanHit = false;
		}

		FPinballPaddleEventParams Params;
		Params.PositionAlpha = PaddleComp.GetPaddlePositionAlpha();
		Params.Intensity = Intensity;
		UPinballPaddleEventHandler::Trigger_PaddleUp(this, Params);
	}

	private void StopFlipInternal()
	{
		bFlipperHeld = false;
		InputIntensity = -1;

		FPinballPaddleEventParams Params;
		Params.PositionAlpha = PaddleComp.GetPaddlePositionAlpha();
		UPinballPaddleEventHandler::Trigger_PaddleDown(this, Params);
	}

	FVector GetVelocityFromHit(EPinballBallType BallType, FVector PlayerLocation, bool bTop, FPinballPaddleHitResult& PaddleHitResult) const
	{
		bool bUseAutoAim = PaddleComp.bAutoAim;
		
#if EDITOR
		if(!Editor::IsPlaying() && PaddleComp.bSimulateHit)
		{
			if(PaddleComp.bSimulationIgnoresAutoAim)
				bUseAutoAim = false;
		}
#endif

		FPinballPaddleAutoAimTargetData AutoAimTargetData;
		if(bUseAutoAim && Pinball::FindAutoAim(PlayerLocation, PaddleHitResult.LaunchDirection, PaddleComp.AutoAimTargets, AutoAimTargetData))
		{
			PaddleHitResult.AutoAimTargetData = AutoAimTargetData;
			PaddleHitResult.LaunchDirection = AutoAimTargetData.GetDirectionToAutoAimFrom(PlayerLocation).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();

			if(PaddleHitResult.AutoAimTargetData.bOverrideImpulse)
				PaddleHitResult.LaunchSpeed = PaddleHitResult.AutoAimTargetData.Impulse;
			else
				PaddleHitResult.LaunchSpeed = PaddleComp.GetLaunchSettings(BallType).GetPaddleImpulse(bTop);
		}

		return (PaddleHitResult.LaunchDirection * PaddleHitResult.LaunchSpeed);
	}

	bool SweepForBall(EPinballBallType BallType, FVector BallLocation, float BallRadius, float FlipperAngleStart, float FlipperAngleEnd, bool bTop, FPinballPaddleHitResult&out OutPaddleHitResult) const
	{
		bool bHitTip = false;
		if(!IsSphereWithinPaddleCone(BallLocation, BallRadius, FlipperAngleStart, FlipperAngleEnd, bTop, bHitTip))
		{
			// It's impossible for the player to be hit by the paddle
			return false;
		}

		const FTransform StartPaddleTransform = PaddleComp.GetPaddleWorldTransform(FlipperAngleStart);
		const FVector RelativeToPaddle = StartPaddleTransform.InverseTransformPositionNoScale(BallLocation);
		const float DistanceFromPivot = RelativeToPaddle.Size();

		if(PaddleComp.bAllowTipHits)
		{
			if(bHitTip || DistanceFromPivot > PaddleComp.PaddleLength)
			{
				// The player will be hit by the tip of the paddle, not the flat top
				OutPaddleHitResult = HandleTipHit(BallType, BallLocation, BallRadius, FlipperAngleStart, bTop);

#if !RELEASE
				FTemporalLog TemporalLog = TEMPORAL_LOG(this);
				TemporalLog.Status("Tip Hit", FLinearColor::Green);
				TemporalLogPaddleHitResult(OutPaddleHitResult, BallLocation, "Tip Hit");
#endif

				return true;
			}
		}

		if(DistanceFromPivot < BallRadius)
		{
#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Status("Too Far Back", FLinearColor::Red);
#endif

			// The player is on the back part of the paddle, and should thus not be affected
			return false;
		}

		// The player will be hit by the flat top
		OutPaddleHitResult =  HandleHit(BallType, BallLocation, BallRadius, FlipperAngleStart, bTop);

		if(!bTop && PaddleComp.bSquishPlayerIfUnder)
		{
			if(OutPaddleHitResult.HitAngle < PaddleComp.SquishAngle || DistanceFromPivot < PaddleComp.SquishDistance)
			{
#if !RELEASE
				FTemporalLog TemporalLog = TEMPORAL_LOG(this);
				TemporalLog.Status("Squish", FLinearColor::Yellow);
#endif
				OutPaddleHitResult.bSquish = true;
			}
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Status("Flat Hit", FLinearColor::Green);
		TemporalLogPaddleHitResult(OutPaddleHitResult, BallLocation, "Flat Hit");
#endif

		return true;
	}

	private bool IsSphereWithinPaddleCone(FVector Location, float PlayerRadius, float FlipperAngleStart, float FlipperAngleEnd, bool bTop, bool&out bHitTip) const
	{
		bHitTip = false;
		const float DistanceToPlayer = Location.Distance(PaddleComp.GetCenterPivot());
		const float DistanceToPlayerEdge = DistanceToPlayer - PlayerRadius;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("IsSphereWithinPaddleCone", 1);
		TemporalLog.Section("Distance", 1)
			.Sphere("Ball Location", Location, PlayerRadius, FLinearColor::Yellow)
			.Circle("Length From Pivot To Tip", PaddleComp.GetCenterPivot(), PaddleComp.GetLengthFromPivotToTip(), FRotator::MakeFromX(FVector::UpVector), FLinearColor::Yellow)
			.Value("Distance To Player Edge", DistanceToPlayerEdge)
		;
#endif

		if(DistanceToPlayerEdge > PaddleComp.GetLengthFromPivotToTip())
		{
#if !RELEASE
			TemporalLog.Status("Too far away", FLinearColor::Red);
#endif
			// Is too far away
			return false;
		}

		FVector RelativeLocation = PaddleComp.WorldTransform.InverseTransformPosition(Location);

#if !RELEASE
		TemporalLog.Section("Pivot", 2)
			.Value("RelativeLocation.X", RelativeLocation.X)
			.Plane("Pivot Plane", PaddleComp.WorldLocation, PaddleComp.ForwardVector, PaddleComp.PaddleLength * 0.5, Color = FLinearColor::Purple)
		;
#endif

		if(RelativeLocation.X < 0)
		{
#if !RELEASE
			TemporalLog.Status("Behind Pivot", FLinearColor::Red);
#endif
			// Behind pivot
			return false;
		}

		const float DistanceFromPlayerToStartTip = Location.Distance(PaddleComp.GetCenterTip(FlipperAngleStart));
		const float DistanceFromPlayerToEndTip = Location.Distance(PaddleComp.GetCenterTip(FlipperAngleEnd));
		const float DistanceToTip = Math::Min(DistanceFromPlayerToStartTip, DistanceFromPlayerToEndTip);
		if((DistanceToTip - PlayerRadius) < PaddleComp.TipRadius && (DistanceToPlayer - PlayerRadius) > PaddleComp.PaddleLength)
		{
			// Hit tip
			bHitTip = true;
			return true;
		}
		
		FVector Origin;
		FVector Normal;
		PaddleComp.GetBackPlane(FlipperAngleStart, bTop, Origin, Normal);
		const FPlane StartPlane(Origin, Normal);

		const float DistanceToStartPlane = StartPlane.PlaneDot(Location) - PlayerRadius;

#if !RELEASE
		TemporalLog.Section("Start Plane", 3)
			.Value("DistanceToStartPlane", DistanceToStartPlane)
			.Value("Start Extra Sweep Distance", PaddleComp.StartExtraSweepDistance)
			.Plane("Start Plane", Origin, Normal, PaddleComp.PaddleLength * 0.5, Color = FLinearColor::Green)
			.Plane("Start Plane + Extra Sweep Distance", Origin - Normal * PaddleComp.StartExtraSweepDistance, Normal, PaddleComp.PaddleLength * 0.5, Color = FLinearColor::Green)
		;
#endif

		if(DistanceToStartPlane + PaddleComp.StartExtraSweepDistance < 0)
		{
#if !RELEASE
			TemporalLog.Status("Behind Paddle", FLinearColor::Red);
#endif
			// Is behind paddle
			return false;
		}

		PaddleComp.GetFrontPlane(FlipperAngleEnd, bTop, Origin, Normal);
		const FPlane EndPlane(Origin, Normal);

		const float DistanceToEndPlane = EndPlane.PlaneDot(Location) - PlayerRadius;

#if !RELEASE
		TemporalLog.Section("End Plane", 4)
			.Value("Distance To End Plane", DistanceToEndPlane)
			.Value("End Extra Sweep Distance", PaddleComp.EndExtraSweepDistance)
			.Plane("End Plane Plane", Origin, Normal, PaddleComp.PaddleLength * 0.5, Color = FLinearColor::Red)
			.Plane("End Plane + Extra Sweep Distance", Origin - Normal * PaddleComp.EndExtraSweepDistance, Normal, PaddleComp.PaddleLength * 0.5, Color = FLinearColor::Red)
		;
#endif

		if(DistanceToEndPlane - PaddleComp.EndExtraSweepDistance > 0)
		{
#if !RELEASE
			TemporalLog.Status("In Front of Paddle", FLinearColor::Red);
#endif
			// Is in front of paddle
			return false;
		}

		return true;
	}

	// Handle the player being hit by the tip of the pinball paddle
	private FPinballPaddleHitResult HandleTipHit(EPinballBallType BallType, FVector PlayerLocation, float PlayerRadius, float FlipperAngleStart, bool bTop) const
	{
		FPinballPaddleHitResult PaddleHitResult;

		// Calculate the arc distance the paddle must travel to hit the player
		const FVector ToPlayerFromPivot = PlayerLocation - PaddleComp.GetCenterPivot();
		const float AngleToPlayerRad = ToPlayerFromPivot.AngularDistance(PaddleComp.GetPaddleWorldTransform(FlipperAngleStart).Rotation.ForwardVector);

		const float DistanceFromPivot = PlayerLocation.Distance(PaddleComp.GetCenterPivot());
		const float ArcDistanceToPlayer = AngleToPlayerRad * DistanceFromPivot;
		const float ArcDistanceToHitPlayer = ArcDistanceToPlayer - (PlayerRadius + PaddleComp.TipRadius);

		if(ArcDistanceToHitPlayer < 0)
		{
			PaddleHitResult.HitAngle = FlipperAngleStart;

			// If the player is "behind" the top of the paddle, assume that it hits the current plane
			const FVector TipLocation = PaddleComp.GetCenterTip(FlipperAngleStart);

			// Calculate the direction out from the tip center
			PaddleHitResult.LaunchDirection = (PlayerLocation - TipLocation).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();
		}
		else
		{
			// Calculate the direction from where the top of the paddle will be when it hits the player
			const float AngleToHitPlayerDeg = Math::RadiansToDegrees(ArcDistanceToHitPlayer / DistanceFromPivot);
			PaddleHitResult.HitAngle = bTop ? FlipperAngleStart + AngleToHitPlayerDeg : FlipperAngleStart - AngleToHitPlayerDeg;

			float Pitch = FlipperAngleStart + AngleToHitPlayerDeg;
			const FVector TipLocation = PaddleComp.GetCenterTip(Pitch);

			// Calculate the direction out from the tip center
			PaddleHitResult.LaunchDirection = (PlayerLocation - TipLocation).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();
		}

		PaddleHitResult.LaunchSpeed = PaddleComp.GetLaunchSettings(BallType).GetPaddleImpulse(bTop);

		return PaddleHitResult;
	}

	// Handle the player being hit by the flat part of the pinball paddle
	private FPinballPaddleHitResult HandleHit(EPinballBallType BallType, FVector PlayerLocation, float PlayerRadius, float FlipperAngleStart, bool bTop) const
	{
		FPinballPaddleHitResult PaddleHitResult;

		const FVector ToPlayerFromPivot = PlayerLocation - PaddleComp.GetCenterPivot();

		// Calculate the arc distance the paddle must travel to hit the player
		const float AngleToPlayerRad = ToPlayerFromPivot.AngularDistance(PaddleComp.GetPaddleWorldTransform(FlipperAngleStart).Rotation.ForwardVector);
		const float DistanceFromPivot = PlayerLocation.Distance(PaddleComp.GetCenterPivot());
		const float ArcDistanceToPlayer = AngleToPlayerRad * DistanceFromPivot;
		const float RadiusAtDistance = PaddleComp.GetPaddleWidthAtDistanceFromPivot(DistanceFromPivot);
		
		float PaddleRadius = (PlayerRadius + RadiusAtDistance);

		const float ArcDistanceToHitPlayer = ArcDistanceToPlayer - PaddleRadius;


		if(ArcDistanceToHitPlayer < 0)
		{
			// If the player is "behind" the top of the paddle, assume that it hits the current plane
			PaddleHitResult.HitAngle = FlipperAngleStart;
			PaddleHitResult.LaunchDirection = PaddleComp.GetPaddleNormal(BallType, DistanceFromPivot, PaddleHitResult.HitAngle, bTop).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();
		}
		else
		{
			// Calculate the direction from where the top of the paddle will be when it hits the player
			const float AngleToHitPlayerDeg = Math::RadiansToDegrees(ArcDistanceToHitPlayer / DistanceFromPivot);
			PaddleHitResult.HitAngle = bTop ? FlipperAngleStart + AngleToHitPlayerDeg : FlipperAngleStart - AngleToHitPlayerDeg;
			PaddleHitResult.LaunchDirection = PaddleComp.GetPaddleNormal(BallType, DistanceFromPivot, PaddleHitResult.HitAngle, bTop).VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();
		}

		// Base the impulse on how far along the paddle the player currently is
		PaddleHitResult.LaunchSpeed = PaddleComp.GetPaddleLaunchSpeedAtDistanceFromPivot(BallType, DistanceFromPivot, bTop);

		return PaddleHitResult;
	}

#if !RELEASE
	private void TemporalLogPaddleHitResult(FPinballPaddleHitResult PaddleHitResult, FVector BallLocation, FString Category) const
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Section("HitResult", 2).DirectionalArrow(f"{Category};Launch Velocity", BallLocation, PaddleHitResult.LaunchDirection * PaddleHitResult.LaunchSpeed);
	}
#endif
};