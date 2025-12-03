enum ETundraCrackBirdState
{
	InNest,
	PickupStarted,
	PickedUp,
	PuttingDown,
	Launched,
	Hover,
	HitByLog,
	HitWall,
	RunningAway,
	Dead,
}

UCLASS(Abstract)
class ABigCrackBird : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UBigCrackBirdInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent RootComp;
	default RootComp.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"OverlapAllDynamic";
	default Collision.SphereRadius = 200.0;
	default Collision.RelativeLocation = FVector(0.0, 0.0, 200.0);
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	// UPROPERTY(DefaultComponent)
	// UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY(EditInstanceOnly)
	AHazeActor TargetToHit;

	UPROPERTY(EditAnywhere)
	ABigCrackBirdCatapult CatapultToAttachTo;

	UPROPERTY(EditAnywhere)
	float Gravity = 400.0;

	UPROPERTY(EditAnywhere)
	float HorizontalResetMoveSpeed = 100.0;

	UPROPERTY(EditAnywhere)
	float ReactRange = 800.0;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 2.0;

	UPROPERTY(EditDefaultsOnly)
	bool bIsEgg = false;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve LaunchCurve;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ThrownInNestFeedback;

	bool bNetWasForcedAttach = false;

	ABigCrackBirdNest TargetNest;
	ABigCrackBirdNest CurrentNest;

	AHazePlayerCharacter InteractingPlayer;

	private ETundraCrackBirdState CurrentState = ETundraCrackBirdState::InNest;

	bool bAttached = true;
	bool bIsPrimed = false;
	bool bIsRotating = false;
	bool bIsLaunched = false;
	bool bIsHovering = false;
	bool bIsHit = false;
	bool bHitWall = false;
	bool bHopOffCatapult = false;
	bool bRunningAway = false;
	bool bEggPickedUp = false;
	float PreviousRotationOfCatapultRad;
	float OldCatapultRotationRad;
	bool bHasHoverHandshake = false;
	bool bCanDetach = true;

	FVector NestRelativeLocation;
	FVector OriginalLocation;
	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RootComp.SetAbsolute(false, false, true);
		ActorScale3D = FVector::OneVector;
		FInteractionCondition InteractionCondition;
		InteractionCondition.BindUFunction(this, n"CanInteract");
		InteractComp.AddInteractionCondition(this, InteractionCondition);
		NestRelativeLocation = ActorRelativeLocation;
		SetActorControlSide(Game::Zoe);
		if(AttachParentActor != nullptr)
		{
			CurrentNest = Cast<ABigCrackBirdNest>(AttachParentActor);
			CurrentNest.Bird = this;
		}
	}

	UFUNCTION()
	private EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		if(IsBeingLaunched())
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	bool IsBeingLaunched() const
	{
		if(bIsPrimed)
		{
			if (Math::Abs(CatapultToAttachTo.FauxAxisRotator.Velocity) > 1)
			{
				return true;
			}
			if(Time::GetGameTimeSince(CatapultToAttachTo.LastSlamTime) < 1)
			{
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Collision.WorldLocation;
	}

	void ReturnHome()
	{
		AttachToActor(CurrentNest);
		CurrentNest.Bird = this;
		CurrentState = ETundraCrackBirdState::InNest;
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbOnBigCrackBirdHitWall(UBigCrackBirdHitResponseComponent ResponseComp)
	{
		ResponseComp.OnBigCrackBirdHit.Broadcast(this, ActorLocation);
		bHitWall = true;
		UBigCrackBirdEffectHandler::Trigger_OnHitWall(this);
		Kill();
	}

	UFUNCTION(NetFunction)
	void NetSetInteractingPlayer(AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	private void NetSendAttachHandshake()
	{
		bCanDetach = true;
	}

	UFUNCTION(BlueprintCallable)
	void Kill()
    {
        AddActorDisable(this);
		
		if(CurrentNest != nullptr)
			CurrentNest.Bird = nullptr;

		CurrentState = ETundraCrackBirdState::Dead;
    }

	void SetState(ETundraCrackBirdState InState)
	{
		if(CurrentState == InState)
			return;

		CurrentState = InState;
	}

	ETundraCrackBirdState GetState() const
	{
		return CurrentState;
	}

	bool IsInNest() const
	{
		if(CurrentState != ETundraCrackBirdState::InNest)
			return false;

		check(CurrentNest != nullptr);
		return true;
	}

	bool IsPickupStarted() const
	{
		return CurrentState == ETundraCrackBirdState::PickupStarted;
	}

	bool IsPickedUp() const
	{
		return CurrentState == ETundraCrackBirdState::PickedUp;
	}

	bool IsDead() const
	{
		return CurrentState == ETundraCrackBirdState::Dead;
	}

	UFUNCTION(CrumbFunction)
    void CrumbHitWithLog()
    {
		UBigCrackBirdEffectHandler::Trigger_OnHitWithLog(this);
        bIsHit = true;
		FVector NewVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetToHit.ActorLocation, Gravity, 10000.0);
        Velocity = NewVelocity;
    }

	void SetOriginalLocation()
	{
		OriginalLocation = ActorLocation;
	}

	void Attach()
	{
		AttachToComponent(CatapultToAttachTo.FauxAxisRotator, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		CatapultToAttachTo.OnBirdAttach();
		bAttached = true;

		bHasHoverHandshake = false;

		if(Game::Mio.HasControl())
			NetSendAttachHandshake();

		UBigCrackBirdEffectHandler::Trigger_CatapultLand(this);
	}

	/**
	 * CrackBirdStuck
	 */

	void OnPlayerBecomeStuck(AHazePlayerCharacter Player)
	{
		FTundraBigCrackBirdPlayerParams Params;
		Params.Player = Player;
		UBigCrackBirdEffectHandler::Trigger_OnPlayerStuck(this, Params);
	}

	void Explode()
	{
		UBigCrackBirdEffectHandler::Trigger_OnExplode(this);
		Kill();
	}
}