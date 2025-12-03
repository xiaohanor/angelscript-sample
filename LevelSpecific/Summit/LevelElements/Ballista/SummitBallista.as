asset SummitBallistaGetLaunchedSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UTeenDragonBallistaGetLaunchedCapability);
	Components.Add(UTeenDragonBallistaComponent);
}

event void FOnSummitBallistaZoeLaunched();
event void FOnSummitBallistaLockedAndLoaded();

class ASummitBallista : AHazeActor
{
	UPROPERTY()
	FOnSummitBallistaZoeLaunched OnSummitBallistaZoeLaunched;

	UPROPERTY()
	FOnSummitBallistaLockedAndLoaded OnSummitBallistaLockedAndLoaded;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent AimRoot;

	UPROPERTY(DefaultComponent, Attach = AimRoot)
	UFauxPhysicsTranslateComponent BasketRoot;
	default BasketRoot.bConstrainX = true;
	default BasketRoot.bConstrainY = true;
	default BasketRoot.bConstrainZ = true;
	default BasketRoot.MaxX = 1000.0;
	default BasketRoot.ConstrainBounce = 0.0;
	default BasketRoot.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;
	default BasketRoot.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	USceneComponent BasketMoveRoot;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = BasketMoveRoot)
	UStaticMeshComponent BasketMeshBaseComp;

	UPROPERTY(DefaultComponent, Attach = BasketMoveRoot)
	USceneComponent WeightedPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = WeightedPlatformRoot)
	UStaticMeshComponent BasketMeshWeightComp;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UStaticMeshComponent TailHitComp;

	UPROPERTY(DefaultComponent, Attach = BasketMeshBaseComp)
	USceneComponent HandleLocation;

	UPROPERTY(DefaultComponent, Attach = TailHitComp)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeMovablePlayerTriggerComponent PlayerInBasketVolume;
	default PlayerInBasketVolume.TriggeredByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent, Attach = BasketRoot)
	UHazeMovablePlayerTriggerComponent PlayerOnBasketVolume;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitBallistaDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitBallistaStatueHandsDownCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitBallistaGoBackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitBallistaLaunchBasketCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitBallistaWeightedPlatformCapability);
	// default CapabilityComp.DefaultCapabilityClasses.Add(USummitBallistaCameraCapability);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerSheets_Zoe.Add(SummitBallistaGetLaunchedSheet);

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitCatapultLauncherStatue Statue;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitCatapultLauncherStatue OtherStatue;

	UPROPERTY(EditAnywhere, Category = "Setup")
	APivotCameraActor PivotCamera;

	UPROPERTY(EditAnywhere, Category = "Setup")
	FRuntimeFloatCurve CameraBlendCurve;
	default CameraBlendCurve.AddDefaultKey(0.0, 0.0);
	default CameraBlendCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Setup")
	FRuntimeFloatCurve BackForceCurve;
	default BackForceCurve.AddDefaultKey(0.0, 0.3);
	default BackForceCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Setup")
	UForceFeedbackEffect LaunchRumble;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RollImpactImpulseSize = 4100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DelayBeforeBasketGoingBackAfterRollHit = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DelayBeforeBasketGoingBackAfterHittingStart = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FHazeRange BasketGoingBackForce = FHazeRange(0.0, 2500.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TimeBeforeMaxGoingBackForce = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StatueHandsDownMaxMove = 1850.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StatueHandsUpMaxMove = 1925.0;

	UPROPERTY(EditAnywhere, Category = "Launch")
	FHazeRange LaunchSpeed = FHazeRange(6000.0, 10000.0);

	UPROPERTY(EditAnywhere, Category = "Launch")
	float DragonLaunchSpeed = 7500.0;

	UPROPERTY(EditAnywhere, Category = "Launch")
	AActor Target;

	UPROPERTY(EditAnywhere, Category = "Launch")
	FVector TargetLocationOffset;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchGravity = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Test")
	bool bShowBasketLocationHandsDown = false;

	UPROPERTY(EditAnywhere, Category = "Test")
	bool bShowBasketLocationHandsUp = false;

	UPROPERTY(EditAnywhere, Category = "Test")
	bool bBasketStartsDown = false;

	bool bIsLaunching = false;
	bool bHandsAreDown = false;
	bool bIsHeld = false;
	bool bBasketRaisingSoundPlaying = false;
	bool bBasketLoweringSoundPlaying = false;
	bool bBasketMoveSoundPlaying = false;

	float TimeLastGotHitByRoll = -MAX_flt;
	float TimeLastHitStart = -MAX_flt;

	TOptional<AHazePlayerCharacter> ZoeInVolume;

	TPerPlayer<bool> bPlayerWeighingDown;
	float WeighDownBufferDuration = 0.25;
	float WeighDownLastTime;
	bool bHasWeight;

	FVector BasketStartRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");	

		BasketMoveRoot.RelativeLocation = FVector::ZeroVector;

		if(Statue != nullptr)
		{
			Statue.OnReachedGrabbingLevel.AddUFunction(this, n"OnStatueReachedGrabbingLevel");
			Statue.OnLeftGrabbingLevel.AddUFunction(this, n"OnStatueLeftGrabbingLevel");
			bHandsAreDown = !Statue.bStartUp;
		}

		if(bHandsAreDown)
		{
			if(bBasketStartsDown)
			{
				BasketRoot.MinX = StatueHandsDownMaxMove;
				BasketRoot.MaxX = StatueHandsUpMaxMove;
			}
			else
			{
				BasketRoot.MinX = 0;
				BasketRoot.MaxX = StatueHandsDownMaxMove;
			}
		}
		else
		{
			BasketRoot.MaxX = StatueHandsUpMaxMove;
			BasketRoot.MinX = 0.0;
		}

		if(bBasketStartsDown)
			BasketRoot.ApplyMovement(BasketRoot.WorldLocation, BasketRoot.ForwardVector * StatueHandsUpMaxMove);
	
		PlayerInBasketVolume.OnPlayerEnter.AddUFunction(this, n"PlayerEnteredBasketVolume");
		PlayerInBasketVolume.OnPlayerLeave.AddUFunction(this, n"PlayerLeftBasketVolume");

		PlayerOnBasketVolume.OnPlayerEnter.AddUFunction(this, n"PlayerIsOnBasket");
		PlayerOnBasketVolume.OnPlayerLeave.AddUFunction(this, n"PlayerIsNoLongerOnBasket");

		BasketRoot.OnConstraintHit.AddUFunction(this, n"OnBasketConstraintHit");

		BasketStartRelativeLocation = BasketRoot.RelativeLocation;
	}

	UFUNCTION()
	private void PlayerIsOnBasket(AHazePlayerCharacter Player)
	{
		bPlayerWeighingDown[Player] = true;
	}

	UFUNCTION()
	private void PlayerIsNoLongerOnBasket(AHazePlayerCharacter Player)
	{
		bPlayerWeighingDown[Player] = false;
	}

	UFUNCTION()
	private void OnBasketConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(HitStrength < 500)
			return;

		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
		{
			if(bHandsAreDown
			&& IsInHeldPart())
			{
				// Hands hit from behind
				FSummitBallistaOnCartHitHandsParams ImpactParams;
				ImpactParams.HandImpactLocation = HandleLocation.WorldLocation;
				ImpactParams.CartSpeedAtImpact = HitStrength;
				USummitBallistaEventHandler::Trigger_OnCartImpactedHands(this, ImpactParams);
				Statue.ApplyRotateImpulse(false);
				OtherStatue.ApplyRotateImpulse(false);

				USummitBallistaEventHandler::Trigger_OnCartStoppedMoving(this);
				bBasketMoveSoundPlaying = false;
			}
			else
			{
				// End hit
				FSummitBallistaOnCartHitConstraintParams ImpactParams;
				ImpactParams.CartLocation = BasketRoot.WorldLocation;
				ImpactParams.CartSpeedAtImpact = HitStrength;
				USummitBallistaEventHandler::Trigger_OnCartImpactedConstraint(this, ImpactParams);
			}
		}
		else if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
		{
			if(bHandsAreDown
			&& !IsInHeldPart())
			{
				// Hands hit from front
				FSummitBallistaOnCartHitHandsParams ImpactParams;
				ImpactParams.HandImpactLocation = HandleLocation.WorldLocation;
				ImpactParams.CartSpeedAtImpact = HitStrength;
				USummitBallistaEventHandler::Trigger_OnCartImpactedHands(this, ImpactParams);
				Statue.ApplyRotateImpulse(true);
				OtherStatue.ApplyRotateImpulse(true);
			}
			else
			{
				// Start hit
				FSummitBallistaOnCartHitConstraintParams ImpactParams;
				ImpactParams.CartLocation = BasketRoot.WorldLocation;
				ImpactParams.CartSpeedAtImpact = HitStrength;
				USummitBallistaEventHandler::Trigger_OnCartImpactedConstraint(this, ImpactParams);
				TimeLastHitStart = Time::GameTimeSeconds;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPlayerWeighingDown[0] || bPlayerWeighingDown[1])
		{
			WeighDownLastTime = Time::GameTimeSeconds + WeighDownBufferDuration;
			if(!bHasWeight)
			{	
				USummitBallistaEventHandler::Trigger_OnCartStartedLowering(this);
				bBasketLoweringSoundPlaying = true;
			}
			bHasWeight = true;
		}
		else if (!bPlayerWeighingDown[0] && !bPlayerWeighingDown[1])
		{
			if (Time::GameTimeSeconds > WeighDownLastTime && bHasWeight)
			{
				if(bHasWeight)
				{
					USummitBallistaEventHandler::Trigger_OnCartStartedRaising(this);
					bBasketRaisingSoundPlaying = true;
				}
				bHasWeight = false;
			}
		}

		if(bBasketMoveSoundPlaying)
		{
			if(BasketRoot.GetVelocity().IsNearlyZero(5))
			{
				// Stop on reach end
				if(Math::IsNearlyEqual(BasketRoot.GetCurrentAlphaBetweenConstraints().Size(), 0.0))
				{
					USummitBallistaEventHandler::Trigger_OnCartStoppedMoving(this);
					bBasketMoveSoundPlaying = false;
				}				
			}
		}
		else
		{	
			if(!BasketRoot.GetVelocity().IsNearlyZero(5) && (BasketRoot.GetCurrentAlphaBetweenConstraints().Size() > KINDA_SMALL_NUMBER) == true)
			{
				USummitBallistaEventHandler::Trigger_OnCartStartedMoving(this);
				bBasketMoveSoundPlaying = true;
			}
		}

		const FVector MovedDelta = BasketRoot.RelativeLocation - BasketStartRelativeLocation;
		const float AlphaBetweenConstraints = MovedDelta.X / StatueHandsUpMaxMove;
		const float AlphaHandsDownConstraints = StatueHandsDownMaxMove / StatueHandsUpMaxMove;

		TEMPORAL_LOG(this)
			.Value("Alpha between constraints", AlphaBetweenConstraints)
			.Value("Alpha Hands down constraints", AlphaHandsDownConstraints)
			.Value("Moved Delta", MovedDelta)
		;
	}

	UFUNCTION()
	private void OnWeightImpactStarted(AHazePlayerCharacter Player)
	{
		bPlayerWeighingDown[Player] = true;
	}

	UFUNCTION()
	private void OnWeightImpactStopped(AHazePlayerCharacter Player)
	{
		bPlayerWeighingDown[Player] = false;
	}

	UFUNCTION()
	private void PlayerEnteredBasketVolume(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			ZoeInVolume.Set(Player);

		// Player.ActivateCamera(CameraComp, 2.5, this);
	}

	UFUNCTION()
	private void PlayerLeftBasketVolume(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			ZoeInVolume.Reset();

		// Player.DeactivateCamera(CameraComp, 2.5);
	}

	UFUNCTION()
	private void OnStatueReachedGrabbingLevel()
	{
		bHandsAreDown = true;
	}

	UFUNCTION()
	private void OnStatueLeftGrabbingLevel()
	{
		bHandsAreDown = false;
	}

	bool IsInHeldPart() const
	{
		if(Statue == nullptr)
			return false;

		const FVector MovedDelta = BasketRoot.RelativeLocation - BasketStartRelativeLocation;
		const float AlphaBetweenConstraints = MovedDelta.X / StatueHandsUpMaxMove;
		const float AlphaHandsDownConstraints = StatueHandsDownMaxMove / StatueHandsUpMaxMove;

		if(AlphaBetweenConstraints < AlphaHandsDownConstraints)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bShowBasketLocationHandsDown)
			BasketMoveRoot.RelativeLocation = FVector(StatueHandsDownMaxMove, 0.0, 0.0);
		else if(bShowBasketLocationHandsUp)
			BasketMoveRoot.RelativeLocation = FVector(StatueHandsUpMaxMove, 0.0, 0.0);
		else
			BasketMoveRoot.RelativeLocation = FVector::ZeroVector;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		FVector FlatHitLocation = Params.HitLocation.ConstrainToPlane(BasketRoot.UpVector);
		FVector FlatPlayerLocation = Params.PlayerInstigator.ActorLocation.ConstrainToPlane(BasketRoot.UpVector);
		FVector DirToHit = (FlatHitLocation - FlatPlayerLocation).GetSafeNormal();

		float DirDotBasketForward = DirToHit.DotProduct(BasketRoot.ForwardVector);

		auto TempLog = TEMPORAL_LOG(this)
			.DirectionalArrow("Dir To Hit", Params.PlayerInstigator.ActorCenterLocation, DirToHit * 500, 20, 4000, FLinearColor::Purple)
			.Value("Dir Dot Basket Forward", DirDotBasketForward)
		;

		if(DirDotBasketForward < 0.4)
			return;

		bool bHitForward = DirDotBasketForward > 0;
		
		FVector ImpulseDir = bHitForward 
			? BasketRoot.ForwardVector
			: -BasketRoot.ForwardVector; 
		FVector Impulse = ImpulseDir * RollImpactImpulseSize;

		TempLog
			.Value("HitForward", bHitForward)
			.DirectionalArrow("Velocity Before Impulse", BasketRoot.WorldLocation, BasketRoot.GetVelocity(), 20, 4000, FLinearColor::Purple)
			.DirectionalArrow("Impulse", BasketRoot.WorldLocation, Impulse, 20, 4000, FLinearColor::Red)
		;
		
		// So the impulse is not smaller if it's going back
		if(BasketRoot.GetVelocity().DotProduct(Impulse) < 0)
			BasketRoot.ResetPhysics();
		BasketRoot.ApplyImpulse(BasketRoot.WorldLocation, Impulse);
		TimeLastGotHitByRoll = Time::GameTimeSeconds;	

		FSummitBallistaOnCartRolledIntoParams EventParams;
		EventParams.ImpactLocation = Params.HitLocation;
		EventParams.SpeedIntoCart = Params.SpeedTowardsImpact;
		USummitBallistaEventHandler::Trigger_OnCartRolledInto(this, EventParams);
	}

	FVector GetTargetLocation() const
	{
		FVector Location = Target.ActorLocation;
		Location += ActorTransform.TransformVector(TargetLocationOffset);
		return Location;
	}

#if EDITOR
	bool bLaunchValuesWereModifiedThisFrame = false;
	float PreviousFrameLaunchHorizontalSpeed;
	float PreviousFrameLaunchGravityAmount;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (PreviousFrameLaunchGravityAmount != LaunchGravity || PreviousFrameLaunchHorizontalSpeed != LaunchSpeed.Max)
			bLaunchValuesWereModifiedThisFrame = true;
		else
			bLaunchValuesWereModifiedThisFrame = false;

		PreviousFrameLaunchHorizontalSpeed = LaunchSpeed.Max;
		PreviousFrameLaunchGravityAmount = LaunchGravity;
	}
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugDirectionArrow(BasketRoot.WorldLocation, BasketRoot.ForwardVector, StatueHandsUpMaxMove, 10000, FLinearColor::LucBlue, 10);
		Debug::DrawDebugString(BasketRoot.WorldLocation + BasketRoot.ForwardVector * StatueHandsUpMaxMove + FVector::UpVector * 50, "Hands Up Max", FLinearColor::LucBlue);

		Debug::DrawDebugDirectionArrow(BasketRoot.WorldLocation + BasketRoot.UpVector * 20, BasketRoot.ForwardVector, StatueHandsDownMaxMove, 10000, FLinearColor::DPink, 10);		
		Debug::DrawDebugString(BasketRoot.WorldLocation + BasketRoot.ForwardVector * StatueHandsDownMaxMove + FVector::UpVector * 50, "Hands Down Max", FLinearColor::DPink);
	}
#endif
};
#if EDITOR
class USummitBallistaDummyComponent : UActorComponent {};
class USummitBallistaComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitBallistaDummyComponent;

	ASummitBallista Ballista;

	FVector SimulatedLocation;
	FVector SimulatedVelocity;
	FVector SimulatedTargetLocation;

	float LastTimeStamp;
	float TimeToReachTarget;
	float SimulateDuration;

	const float MaxSimulateDuration = 2.0;
	const float DragonCapsuleRadius = 130.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitBallistaDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		Ballista = Cast<ASummitBallista>(Comp.Owner);
		if(Ballista == nullptr)
			return;

		if(Ballista.Target != nullptr)
			SimulatedTargetLocation = Ballista.GetTargetLocation();
		else
			SimulatedTargetLocation = Ballista.ActorLocation - (Ballista.ActorForwardVector * Ballista.LaunchSpeed.Max);
	
		float Radius = 250.0;
		FLinearColor Color = FLinearColor::Purple;

		DrawWireSphere(SimulatedTargetLocation, Radius, Color, 5, 36);
		Debug::DrawDebugString(SimulatedTargetLocation + FVector::UpVector * Radius, "Target Location", Color);

		VisualizeTrajectory();

		Color = FLinearColor::Yellow;
		DrawWireSphere(Ballista.BasketRoot.WorldLocation, Radius, Color, 5, 36);
		Debug::DrawDebugString(Ballista.BasketRoot.WorldLocation + FVector::UpVector * Radius, "Launch Location", Color);
	
		VisualizeSimulatedPlayer();
	}

	void VisualizeTrajectory()
	{
		FVector Origin = Ballista.BasketRoot.WorldLocation;
		FVector Target = SimulatedTargetLocation;

		const float DragonGravity = Ballista.LaunchGravity; 

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Origin, Target, DragonGravity, Ballista.LaunchSpeed.Max);
		FVector HighestPoint = Trajectory::TrajectoryHighestPoint(Origin, Velocity, DragonGravity, FVector::UpVector);

		FTransform WorldTransform = FTransform::MakeFromXZ(FVector::ForwardVector, FVector::DownVector);
		FVector LocalOrigin = WorldTransform.InverseTransformPosition(Origin);
		FVector LocalDestination = WorldTransform.InverseTransformPosition(Target);
		FVector LocalHighestPoint = WorldTransform.InverseTransformPosition(HighestPoint);

		float ParabolaHeight = LocalHighestPoint.Z - (LocalOrigin.Z < LocalDestination.Z ? LocalOrigin.Z : LocalDestination.Z);
		float ParabolaBase = LocalOrigin.DistXY(LocalDestination);

		float ParabolaLengthSqrRt = Math::Sqrt(2 * Math::Square(ParabolaHeight) + Math::Square(ParabolaBase));
		float ParabolaLength = ParabolaLengthSqrRt + (Math::Square(ParabolaBase) / (2 * ParabolaBase)) * Math::Loge((2 * ParabolaHeight + ParabolaLengthSqrRt) / ParabolaBase);
		// ¯\_(ツ)_/¯
		ParabolaLength *= 2.5;

		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, ParabolaLength, Velocity, DragonGravity, 1.5);

		for (int i = 0; i < Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];
			bool bDone = false;

			if ((HighestPoint - Target).GetSafeNormal().DotProduct((End - Target).GetSafeNormal()) < 0.0)
			{
				End = Target;
				bDone = true;
			}

			DrawLine(Start, End, FLinearColor::Yellow, 10);
			if (bDone)
				break;
		}
	}


	void VisualizeSimulatedPlayer()
	{
		float TimeStamp = Time::GetGameTimeSeconds();
		float DeltaTime = TimeStamp - LastTimeStamp;
		const float DragonGravity = Ballista.LaunchGravity; 
		LastTimeStamp = TimeStamp;

		TimeToReachTarget -= DeltaTime;

		bool bRestartSimulation = TimeToReachTarget <= 0.0;

		if (Ballista.bLaunchValuesWereModifiedThisFrame)
			bRestartSimulation = true;
		if (bRestartSimulation)
		{
			FVector Start = Ballista.BasketRoot.WorldLocation;
			FVector End = SimulatedTargetLocation;

			SimulatedLocation = Start;
			SimulatedVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Start, End, DragonGravity, Ballista.LaunchSpeed.Max);

			FVector DeltaToTarget = (End - Start);
			FVector VerticalToTarget = DeltaToTarget.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalToTarget = DeltaToTarget - VerticalToTarget;
			float HorizontalDistance = HorizontalToTarget.Size();

			FVector VerticalVelocity = SimulatedVelocity.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalVelocity = SimulatedVelocity - VerticalVelocity;
			float HorizontalSpeed = HorizontalVelocity.Size();
			TimeToReachTarget = HorizontalDistance / HorizontalSpeed;
			Ballista.bLaunchValuesWereModifiedThisFrame = false;
		}

		SimulatedVelocity += FVector::DownVector * DragonGravity * DeltaTime;
		SimulatedLocation += SimulatedVelocity * DeltaTime;

		DrawWireSphere(SimulatedLocation, DragonCapsuleRadius, FLinearColor::LucBlue, 5, 48);
	}
}

#endif