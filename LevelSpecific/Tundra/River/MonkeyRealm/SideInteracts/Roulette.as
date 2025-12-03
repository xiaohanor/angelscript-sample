class URouletteBallSyncCapability : UHazeCapability
{
	ARoulette Roulette;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Roulette = Cast<ARoulette>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			Roulette.SyncedBallPosition.SetValue(Roulette.Ball.WorldLocation);
		}
		else
		{
			Roulette.Ball.WorldLocation = Roulette.SyncedBallPosition.Value;
		}
	}
}

UCLASS(Abstract)
class ARoulette : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Ball;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RouletteBottom;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RouletteTop;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingInteractionComponent InteractionComp;
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingInteractionComponent InteractionCompBigShape;
	default InteractionCompBigShape.bPlayerCanCancelInteraction = false;
	default InteractionCompBigShape.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent, Attach = RouletteBottom)
	UBoxComponent BallTrigger;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TopTrigger;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike RotationTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayer;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayerMonkey;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RollAnimPlayerTreeGuardian;

	AHazePlayerCharacter Player;

	UPROPERTY(EditDefaultsOnly)
	float DelayUntilRollingCasino = 0.72;

	float InteractionStarted;
	float WheelStartRotation;
	float RollTarget;
	bool bHasRolled;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedBallPosition;
	default SyncedBallPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(URouletteBallSyncCapability);

	default TickGroup = ETickingGroup::TG_PrePhysics;

	/**
	 * Made ball never distance cull as it was popping in and out when players were still close and looking at it.
	 * Probably not needed when a non downscaled mesh is used.
	 */
	
	default Ball.bNeverDistanceCull = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionCompBigShape.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		RotationTimeLike.BindUpdate(this, n"OnRollUpdate");
		RotationTimeLike.BindFinished(this, n"OnRollFinished");


		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TimeSinceInteractionStarted = Time::GameTimeSeconds - InteractionStarted;
		if (TimeSinceInteractionStarted > DelayUntilRollingCasino)
		{
			if (!bHasRolled && HasControl())
				Roll();

			if (Player != nullptr && Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"Movement", this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void PlayerStartedRoulette()
	{
		UTundra_River_InteractableCasinoEffectHandler::Trigger_OnPlayerStartedRoulette(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter InPlayer)
	{
		if (Player != nullptr)
			return;
		
		SetActorControlSide(InPlayer);

		Ball.SimulatePhysics = HasControl();
		SyncedBallPosition.SetValue(Ball.WorldLocation);

		SetActorTickEnabled(true);

		Player = InPlayer;

		InteractionStarted = Time::GameTimeSeconds;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		// Don't allow small shapes
		if (ShapeshiftingComp.IsSmallShape())
			Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);

		InteractionComp.Disable(this);
		InteractionCompBigShape.Disable(this);

		FHazeAnimationDelegate OnBlendingOut = FHazeAnimationDelegate(this, n"OnPlayerAnimationFinished");
		if (ShapeshiftingComp.IsBigShape())
		{
			UHazeSkeletalMeshComponentBase Mesh = ShapeshiftingComp.GetMeshForShapeType(ETundraShapeshiftShape::Big);
			Mesh.PlaySlotAnimation(FHazeAnimationDelegate(),
								   OnBlendingOut,
								   Player.IsMio() ? RollAnimPlayerMonkey : RollAnimPlayerTreeGuardian);
		}
		else
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut, RollAnimPlayer);
	}

	UFUNCTION()
	void OnPlayerAnimationFinished()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player = nullptr;

		SetActorTickEnabled(false);
	}

	void Roll()
	{
		if (!HasControl())
			return;

		CrumbRoll(Math::RandRange(1500, 1700));
	}

	UFUNCTION(CrumbFunction)
	void CrumbRoll(float NewRollTarget)
	{
		bHasRolled = true;
		RotationTimeLike.PlayFromStart();

		RollTarget = NewRollTarget;

		// FVector TableCenter = RouletteBottom.WorldLocation + FVector(0, 0, 140);
		// // Debug::DrawDebugSphere(TableCenter, 20, Duration = 2);
		// FVector DirToCenter = Ball.WorldLocation - TableCenter;
		// DirToCenter = DirToCenter.GetSafeNormal();
		// // Debug::DrawDebugLine(TableCenter, TableCenter + DirToCenter * 100, Duration = 2);
		// FVector Impulse = DirToCenter + (FVector(0, 1, 0) * 1000);
		Ball.AddImpulse(Ball.ForwardVector * 900);

		TArray<AActor> PlayersOnTop;
		TopTrigger.GetOverlappingActors(PlayersOnTop, AHazePlayerCharacter);

		if(!PlayersOnTop.IsEmpty())
		{
			Cast<AHazePlayerCharacter>(PlayersOnTop[0]).AddKnockbackImpulse(this.GetDirectionTo(PlayersOnTop.Last()), 500, 600);
		}

	}

	UFUNCTION()
	private void OnRollUpdate(float CurveValue)
	{
		RouletteBottom.RelativeRotation = FRotator(
			0,
			Math::Lerp(WheelStartRotation, RollTarget, CurveValue),
			0);

		Ball.SetLinearDamping(Math::Lerp(0.001, 1.5, CurveValue));
	}

	UFUNCTION()
	private void OnRollFinished()
	{
		InteractionComp.Enable(this);
		InteractionCompBigShape.Enable(this);
		bHasRolled = false;
		
		// Update start rotations for the next roll
		WheelStartRotation = Math::Wrap(RollTarget, 0, 360);

		TArray<UPrimitiveComponent> OverlapComponents;
		BallTrigger.GetOverlappingComponents(OverlapComponents);
		for(auto Comp : OverlapComponents)
		{
			if(Comp.Name == "Ball")
			{
				UTundra_River_InteractableCasinoEffectHandler::Trigger_OnPlayerWinRoulette(this);
				// Print("YAAAAAAY", 3);
				return;
			}
		}

		UTundra_River_InteractableCasinoEffectHandler::Trigger_OnPlayerLoseRoulette(this);
	}
};
