UCLASS(Abstract)
class ATundra_River_GeyserPlatform : AHazeActor
{
	// This has a different tick group because UAnimFootTraceComponent uses the impact point of the ground contact to determine where the feet should be placed so the faux physics has to run before player movement to not make snow monkey/otter (that uses the foot trace) lag behind the platform.
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent MoveRoot;
	default MoveRoot.bConstrainX = true;
	default MoveRoot.bConstrainY = true;
	default MoveRoot.bConstrainZ = true;
	default MoveRoot.MinZ = 0.0;
	default MoveRoot.MaxZ = 100000.0;
	default MoveRoot.ConstrainBounce = 0.0;
	default MoveRoot.Friction = 2.4;
	default MoveRoot.PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformVisualComp;
	default PlatformVisualComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformColliderComp;
	default PlatformColliderComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GeyserRoot;

	UPROPERTY(DefaultComponent, Attach = GeyserRoot)
	UStaticMeshComponent GeyserMeshComp;

	/* This is used to determine the hover height for the platform when the otter interacts */
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent WaterSurface;
	default WaterSurface.RelativeLocation = FVector(0,0,400);

	/* This is only used to determine when the break water surface vfx events should be called! */
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent ActualWaterSurface;
	default ActualWaterSurface.RelativeLocation = FVector(0,0,400);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent HighPoint;
	default HighPoint.RelativeLocation = FVector(0,0,2000);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent LowPoint;
	default LowPoint.RelativeLocation = FVector(0,0,0);

	UPROPERTY(DefaultComponent, Attach = GeyserRoot)
	UTundraPlayerOtterSonarBlastTargetable OtterTargetable;
	default OtterTargetable.RelativeLocation = FVector(-0.000004, -0.000004, -416.353648);
	default OtterTargetable.bIsImmediateTrigger = true;
	default OtterTargetable.UsableByPlayers = EHazeSelectPlayer::Mio;
	default OtterTargetable.MovementSettings.Type = EMoveToType::NoMovement;
	default OtterTargetable.ActionShape.Type = EHazeShapeType::Box;
	default OtterTargetable.ActionShape.BoxExtents = FVector(900.0, 900.0, 600.0);
	default OtterTargetable.WidgetVisualOffset = FVector();
	default OtterTargetable.ActionShapeTransform = FTransform(FRotator::ZeroRotator, FVector(0.0, 00, -175.0));
	default OtterTargetable.FocusShape.SphereRadius = 2200;

	UPROPERTY(DefaultComponent, Attach=PlatformRoot)
	USquishTriggerBoxComponent PlatformSquishBox;
	default PlatformSquishBox.Polarity = ESquishTriggerBoxPolarity::Down;
	default PlatformSquishBox.BoxExtent = FVector(300.0, 300.0, 70.0);

	UPROPERTY(DefaultComponent, Attach=GeyserRoot)
	USquishTriggerBoxComponent GeyserSquishBox;
	default GeyserSquishBox.Polarity = ESquishTriggerBoxPolarity::Up;
	default GeyserSquishBox.BoxExtent = FVector(300.0, 300.0, 70.0);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent MoveRootTransformLogger;
	default MoveRootTransformLogger.bIsEditorOnly = true;
#endif

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponse;

	UPROPERTY(EditInstanceOnly, Category = "Tree Interaction Settings")
	ATundraRangedLifeGivingActor TreeInteract;

	UPROPERTY(EditInstanceOnly, Category = "Tree Interaction Settings")
	bool bRaisedAtStart = true;

	UPROPERTY(EditAnywhere, Category = "Tree Interaction Settings")
	float PlatformMoveSpeed = 2000;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float GravityForce = 7000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float MaxGeyserForce = 15000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float FalloffDistance = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float ForceStartupDuration = 0.3;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeImpulse = 400.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeImpulse = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeImpulse = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float MonkeyGroundSlamImpulse = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeForce = 400.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeForce = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeForce = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float SmallShapeGeyserLiftSpeed = 10000;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float PlayerShapeGeyserLiftSpeed = 7500;

	UPROPERTY(EditAnywhere, Category = "Forces")
	float BigShapeGeyserLiftSpeed = 5000;

	UPROPERTY(EditAnywhere)
	float GeyserLiftRadius = 100;

	/* If a player impacts the bottom of the platform, was just within the geyser radius and their vertical speed is greater or equal to this value. */
	UPROPERTY(EditAnywhere)
	float KillPlayerVelocityThreshold = 300.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveUpDownAnimation;
	default MoveUpDownAnimation.Duration = 6;
	default MoveUpDownAnimation.Curve.AddDefaultKey(0,0);
	default MoveUpDownAnimation.Curve.AddDefaultKey(3, 1);
	default MoveUpDownAnimation.Curve.AddDefaultKey(6,0);

	UPROPERTY(EditDefaultsOnly)
	TArray<UNiagaraComponent> GeyserParticles;

	UTundraLifeReceivingComponent LifeReceivingComp;
	TPerPlayer<bool> bPlayerImpact;
	TPerPlayer<bool> bPlayerInGeyser;
	TPerPlayer<bool> bPlayerWasInGeyser;
	TPerPlayer<UTundraPlayerShapeshiftingComponent> ShapeshiftComps;
	TPerPlayer<UPlayerMovementComponent> MovementComps;

	bool bTriggered = false;
	float Depth;
	float UpDownDepth;
	float MoveAlpha;
	float TimeOfSwitchTarget;
	float PreviousHeight;

	private float Internal_DesiredHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousHeight = MoveRoot.WorldLocation.Z;

		//SetActorControlSide(Game::GetZoe());

		if(TreeInteract != nullptr)
		{
			LifeReceivingComp = UTundraLifeReceivingComponent::Get(TreeInteract);
			LifeReceivingComp.OnInteractStart.AddUFunction(this, n"TreeInteractStarted");
			LifeReceivingComp.OnInteractStop.AddUFunction(this, n"TreeInteractStopped");
			LifeReceivingComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"RaiseAltGeysers");
			LifeReceivingComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"RaiseDefaultGeysers");
		}

		PlatformRoot.GetChildrenComponentsByClass(UNiagaraComponent, false, GeyserParticles);

		MoveUpDownAnimation.BindUpdate(this, n"TL_MoveUpDownUpdate");
		MoveUpDownAnimation.BindFinished(this, n"TL_MoveUpDownFinished");

		OtterTargetable.OnTriggered.AddUFunction(this, n"InteractionStarted");

		Depth = WaterSurface.RelativeLocation.Z;
		UpDownDepth = Depth;
		DesiredHeight = bRaisedAtStart ? HighPoint.RelativeLocation.Z : LowPoint.RelativeLocation.Z;

		ImpactCallbackComp.AddComponentUsedForImpacts(PlatformColliderComp);
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerGroundImpact");
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerGroundImpactEnd");
		ImpactCallbackComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"OnPlayerCeilingImpact");

		GroundSlamResponse.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		MoveRoot.ApplyImpulse(MoveRoot.WorldLocation, FVector::DownVector * MonkeyGroundSlamImpulse);
		UTundra_River_GeyserPlatformEffectHandler::Trigger_OnGroundSlammed(this);
	}

	UFUNCTION()
	private void OnPlayerGroundImpact(AHazePlayerCharacter Player)
	{
		bPlayerImpact[Player] = true;
		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		float Impulse = 0;
		if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Small)
		{
			Impulse = SmallShapeImpulse;
		}
		else if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Player)
		{
			Impulse = PlayerShapeImpulse;
		}
		else if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Big)
		{
			Impulse = BigShapeImpulse;
		}
		else
			devError("Forgot to add case");

		MoveRoot.ApplyImpulse(MoveRoot.WorldLocation, FVector::DownVector * Impulse);
	}

	UFUNCTION()
	private void OnPlayerGroundImpactEnd(AHazePlayerCharacter Player)
	{
		bPlayerImpact[Player] = false;
	}

	UFUNCTION()
	private void RaiseDefaultGeysers()
	{
		DesiredHeight = bRaisedAtStart ? HighPoint.RelativeLocation.Z : LowPoint.RelativeLocation.Z;

		if(bRaisedAtStart)
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformRise_LifeReceivingInteract(this);
		else if(MoveRoot.RelativeLocation.Z != LowPoint.RelativeLocation.Z)
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformFall_LifeReceivingInteract(this);
	}

	UFUNCTION()
	private void RaiseAltGeysers()
	{
		DesiredHeight = bRaisedAtStart ? LowPoint.RelativeLocation.Z : HighPoint.RelativeLocation.Z;

		if(!bRaisedAtStart)
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformRise_LifeReceivingInteract(this);
		else
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformFall_LifeReceivingInteract(this);
	}

	UFUNCTION()
	private void TreeInteractStopped(bool bForced)
	{
		OtterTargetable.Enable(this);
		GeyserParticles[0].Deactivate();

		UTundra_River_GeyserPlatformEffectHandler::Trigger_OnLifeReceivingInteractionStopped(this);
	}

	UFUNCTION()
	private void TreeInteractStarted(bool bForced)
	{
		MoveUpDownAnimation.Reverse();
		OtterTargetable.Disable(this);
		GeyserParticles[0].Activate();

		RaiseDefaultGeysers();
		TimeOfSwitchTarget = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	private void TL_MoveUpDownFinished()
	{
		OtterTargetable.Enable(this);
		bTriggered = false;

		if(!CheckIsLifeGiving())
			GeyserParticles[0].Deactivate();

		UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformFall(this);
	}

	UFUNCTION()
	private void TL_MoveUpDownUpdate(float CurrentValue)
	{
		//PlatformRoot.RelativeLocation = FVector(0, 0, Math::Lerp(0, Depth, CurrentValue));
		UpDownDepth = Depth * CurrentValue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Apply gravity
		MoveRoot.ApplyForce(MoveRoot.WorldLocation, FVector::DownVector * GravityForce);
		ApplyPlayerForce(DeltaTime);

		CheckPlayersInGeyser(DeltaTime);

		if(bTriggered || CheckIsLifeGiving())
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 30) * 1.25;
			PlatformVisualComp.RelativeRotation = FRotator(Math::Sin(Time::GetGameTimeSeconds() * 10), 0, Math::Sin(Time::GetGameTimeSeconds() * 5)) * SineRotate;
		}
		else
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50) * 0.75;
			PlatformVisualComp.RelativeRotation = FRotator(1, 0, 1) * SineRotate;
		}

		FVector LocalOffset = GeyserParticles[0].GetWorldTransform().InverseTransformPosition(GeyserRoot.WorldLocation);
		GeyserParticles[0].SetVectorParameter(n"BeamEnd", LocalOffset);

		if(CheckIsLifeGiving())
		{
			ApplyGeyserForce(DeltaTime, DesiredHeight);
		}
		else if(bTriggered)
		{
			ApplyGeyserForce(DeltaTime, UpDownDepth);
		}

		float CurrentHeight = MoveRoot.WorldLocation.Z;
		float WaterSurfaceHeight = ActualWaterSurface.WorldLocation.Z;

		if(PreviousHeight > WaterSurfaceHeight && 
			CurrentHeight <= (WaterSurfaceHeight + 150))
		{
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPreImpactWaterSurfaceFromAbove(this);
		}
		else if(PreviousHeight > WaterSurfaceHeight && 
			CurrentHeight <= WaterSurfaceHeight)
		{
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnImpactWaterSurfaceFromAbove(this);
		}
		else if(PreviousHeight < WaterSurfaceHeight && 
			CurrentHeight >= WaterSurfaceHeight)
		{
			UTundra_River_GeyserPlatformEffectHandler::Trigger_OnBreakWaterSurfaceFromBelow(this);
		}

		PreviousHeight = CurrentHeight;
	}

	bool CheckIsLifeGiving()
	{
		if(LifeReceivingComp == nullptr)
			return false;

		if(LifeReceivingComp.IsCurrentlyLifeGiving())
			return true;

		return false;
	}

	void ApplyPlayerForce(float DeltaTime)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!bPlayerImpact[Player])
				continue;

			auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			float Force = 0;
			if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Small)
			{
				Force = SmallShapeForce;
			}
			else if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Player)
			{
				Force = PlayerShapeForce;
			}
			else if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			{
				Force = BigShapeForce;
			}
			else
				devError("Forgot to add case");

			MoveRoot.ApplyForce(MoveRoot.WorldLocation, FVector::DownVector * Force);
		}
	}

	void ApplyGeyserForce(float DeltaTime, float Height)
	{
		float Distance = Height - MoveRoot.RelativeLocation.Z;
		float Force;
		if(Distance < 0.0)
		{
			Force = Math::Lerp(GravityForce, 0.0, Math::Saturate(Math::Abs(Distance / FalloffDistance)));
		}
		else
		{
			float MaxDistance = HighPoint.RelativeLocation.Z - LowPoint.RelativeLocation.Z;
			Force = Math::Lerp(GravityForce, MaxGeyserForce, Distance / MaxDistance);
		}

		Force = Math::Lerp(0.0, Force, Math::Saturate(Time::GetGameTimeSince(TimeOfSwitchTarget) / ForceStartupDuration));

		MoveRoot.ApplyForce(MoveRoot.WorldLocation, FVector::UpVector * Force);
	}

	UFUNCTION()
	private void InteractionStarted(UTundraPlayerOtterSonarBlastTargetable Targetable)
	{
		OtterTargetable.Disable(this);
		MoveUpDownAnimation.PlayFromStart();
		bTriggered = true;
		GeyserParticles[0].Activate();

		if(!CheckIsLifeGiving())
			TimeOfSwitchTarget = Time::GetGameTimeSeconds();

		UTundra_River_GeyserPlatformEffectHandler::Trigger_OnPlatformRise(this);
	}

	void CheckPlayersInGeyser(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			float Dist = Player.ActorLocation.Dist2D(GeyserRoot.WorldLocation, FVector::UpVector);
			if(Dist < GeyserLiftRadius && Player.ActorLocation.Z < PlatformRoot.WorldLocation.Z)
			{
				bPlayerInGeyser[Player] = true;
				bPlayerWasInGeyser[Player] = true;

				float Impulse = 0;
				ETundraShapeshiftShape Shape = GetShape(Player);
				if(Shape == ETundraShapeshiftShape::Small)
				{
					Impulse = SmallShapeGeyserLiftSpeed;
				}
				else if(Shape == ETundraShapeshiftShape::Player)
				{
					Impulse = PlayerShapeGeyserLiftSpeed;
				}
				else if(Shape == ETundraShapeshiftShape::Big)
				{
					Impulse = BigShapeGeyserLiftSpeed;
				}
				
				Player.AddMovementImpulse(FVector::UpVector * (Impulse * DeltaTime));
			}
			else
			{
				bPlayerInGeyser[Player] = false;

				UPlayerMovementComponent MoveComp = GetMovementComponent(Player);
				if(bPlayerWasInGeyser[Player] && MoveComp.VerticalSpeed < KillPlayerVelocityThreshold)
				{
					bPlayerWasInGeyser[Player] = false;
				}
			}
		}
	}

	ETundraShapeshiftShape GetShape(AHazePlayerCharacter Player)
	{
		if(ShapeshiftComps[Player] == nullptr)
			ShapeshiftComps[Player] = UTundraPlayerShapeshiftingComponent::Get(Player);

		return ShapeshiftComps[Player].CurrentShapeType;
	}

	UPlayerMovementComponent GetMovementComponent(AHazePlayerCharacter Player)
	{
		if(MovementComps[Player] == nullptr)
			MovementComps[Player] = UPlayerMovementComponent::Get(Player);

		return MovementComps[Player];
	}

	UFUNCTION()
	private void OnPlayerCeilingImpact(AHazePlayerCharacter Player)
	{
		if(bPlayerWasInGeyser[Player])
			Player.KillPlayer();
	}

	float GetDesiredHeight() const property
	{
		return Internal_DesiredHeight;
	}

	void SetDesiredHeight(float Value) property
	{
		Internal_DesiredHeight = Value;

		if(CheckIsLifeGiving())
			TimeOfSwitchTarget = Time::GetGameTimeSeconds();
	}
}

UCLASS(Abstract)
class UTundra_River_GeyserPlatformEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ATundra_River_GeyserPlatform GeyserPlatform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GeyserPlatform = Cast<ATundra_River_GeyserPlatform>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformRise() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformRise_LifeReceivingInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformFall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformFall_LifeReceivingInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeReceivingInteractionStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakWaterSurfaceFromBelow() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactWaterSurfaceFromAbove() {}

	// Earlier version of water surface break
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPreImpactWaterSurfaceFromAbove() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlammed() {}
}