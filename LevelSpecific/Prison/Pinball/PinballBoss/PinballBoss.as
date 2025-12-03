asset PinballBossSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPinballBossIdleStateCapability);
	Capabilities.Add(UPinballBossFollowingStateCapability);
	Capabilities.Add(UPinballBossChargeAttackStateCapability);
	Capabilities.Add(UPinballBossBallStateCapability);
	Capabilities.Add(UPinballBossDyingStateCapability);

	Capabilities.Add(UPinballBossVulnerableCapability);
	Capabilities.Add(UPinballBossTriggerGameOverCapability);
};

enum EPinballBossState 
{
	Idle,
	Following,
	ChargeAttack,
	Ball,
	Dying,
};

event void FOpenCoreEvent();
event void FCloseCoreEvent();

event void PinballBossLaunchRocket();

UCLASS(Abstract)
class APinballBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BodyRotationComp;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	USceneComponent BallLookAtComp;

	UPROPERTY(DefaultComponent, Attach = BallLookAtComp)
	USceneComponent BallTwitchComp;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	USceneComponent MissileBoxRoot;

	UPROPERTY(DefaultComponent, Attach = MissileBoxRoot)
	USceneComponent MissilePos1;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	USceneComponent LaserLookAtComp;

	UPROPERTY(DefaultComponent, Attach = BallTwitchComp)
	UStaticMeshComponent BallMeshComp;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	UStaticMeshComponent BallShieldMeshCompA;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	UStaticMeshComponent BallShieldMeshCompB;

	UPROPERTY(DefaultComponent, Attach = BodyRotationComp)
	UStaticMeshComponent BallShieldMeshCompC;

	UPROPERTY(DefaultComponent, Attach = MissileBoxRoot)
	UArrowComponent RocketLauncherComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UMagnetDroneAutoAimComponent MagnetAutoAimComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagnetComp;
	default MagnetComp.bImmediatelyDetach = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(PinballBossSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UPinballGlobalResetComponent GlobalResetComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ChargeAttackDeathEffect;

	UPROPERTY()
	PinballBossLaunchRocket OnLaunchRocket;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Settings")
	const float LaunchPower = 1000;

	UPROPERTY(BlueprintReadWrite)
	float ChaseDistance = 0.0;

	UPROPERTY(BlueprintReadWrite)
	float BallChaseRotationDistance = 0.0;

	UPROPERTY(BlueprintReadWrite, VisibleInstanceOnly)
	bool bVulnerable = false;

	UPROPERTY(BlueprintReadWrite, VisibleInstanceOnly)
	bool bIsCharging = false;

	UPROPERTY(BlueprintReadWrite)
	bool bBallRotationControlledFromBP = false;

	UPROPERTY(EditAnywhere)
	ASplineActor ActiveSpline;

	UPROPERTY()
	float SplineOffset = 0;

	UPROPERTY(VisibleInstanceOnly)
	EPinballBossState BossState;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APinballBossBall> BallFormClass;

	APinballBossBall BallForm;

	UPROPERTY(EditDefaultsOnly)
	const float ChargeAttackDuration = 15;

	UPROPERTY(EditAnywhere)
	ASplineActor DeathSpline;

	UPROPERTY()
	FOpenCoreEvent OnOpenCore;

	UPROPERTY()
	FCloseCoreEvent OnCloseCore;

	const float MagnetDroneHorizontalImpulse = 500;
	const float MagnetDroneVerticalImpulse = 1000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetBallPlayer());

		MagnetComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		MagnetComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");

		GlobalResetComp.PreActivateProgressPoint.AddUFunction(this, n"PreActivateProgressPoint");


		OnOpenCore.AddUFunction(this, n"CoreOpen");
		OnCloseCore.AddUFunction(this, n"CoreClose");
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("State", BossState)
			.Value("Phase", BP_GetPhase())
		;
	}
#endif

	/**
	 * Remove the StartDisabled instigator disabling us
	 */
	UFUNCTION(BlueprintCallable)
	void Enable()
	{
		RemoveActorDisable(DisableComp.StartDisabledInstigator);
	}

	UFUNCTION(BlueprintEvent)
	void CoreClose() {}

	UFUNCTION(BlueprintEvent)
	void CoreOpen() {}

	UFUNCTION()
	private void PreActivateProgressPoint()
	{
		SetBossState(EPinballBossState::Idle);
		bVulnerable = false;
		bIsCharging = false;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateNextSpline(ASplineActor Spline, float Offset, bool bSnapTo)
	{
		if(HasControl())
			CrumbActivateNextSpline(Spline, Offset, bSnapTo);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbActivateNextSpline(ASplineActor Spline, float Offset, bool bSnapTo)
	{
		SplineOffset = Offset;

		ActiveSpline = Spline;

		if(bSnapTo)
		{
			float SnapLocation = Spline.Spline.GetClosestSplineDistanceToWorldLocation(Drone::GetMagnetDronePlayer().GetActorLocation());
			SetActorLocation(Spline.Spline.GetWorldLocationAtSplineDistance(SnapLocation + Offset));
		}
	}

	UFUNCTION(BlueprintEvent)
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		check(bVulnerable);

		if(HasControl())
		{
			CrumbOnMagnetDroneAttached();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnMagnetDroneAttached()
	{
		if(BossState == EPinballBossState::ChargeAttack)
		{
			// Transition to Ball state
			SetBossState(EPinballBossState::Ball);
		}

		bVulnerable = false;
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnMagnetDroneAttached()
	{
	}

	UFUNCTION()
	private void OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		if(Params.Player.HasControl())
		{
			FVector Impulse = FVector::RightVector * -MagnetDroneVerticalImpulse;
			FVector HorizontalDirection = (Params.Player.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			Impulse += HorizontalDirection * MagnetDroneHorizontalImpulse;

			Impulse.Z = 0;

			Params.Player.AddMovementImpulse(Impulse);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetBossState(EPinballBossState State)
	{
		BossState = State;
	}

	bool IsBallFormActive() const
	{
		if(!IsValid(BallForm))
			return false;

		if(BallForm.IsActorDisabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	APinballBossBall GetBallForm() const
	{
		if(IsBallFormActive())
			return BallForm;
		else
			return nullptr;
	}

	void SmallDamage()
	{
		UPinballBossEventHandler::Trigger_OnSmallDamage(this);
		BP_SmallDamage();
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_SmallDamage() {}

	void BarBreak(FVector NewLocation)
	{
		SetActorLocation(NewLocation);
		SetBossState(EPinballBossState::Following);

		BP_BarBreak(NewLocation);
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_BarBreak(FVector NewLocation) {}

	FVector GetBallSocketLocation() const
	{
		return BallMeshComp.WorldLocation;
	}

	FTransform GetBallSocketTransform() const
	{
		return BallMeshComp.WorldTransform;
	}

	// FB TODO: Move to AS
	UFUNCTION(BlueprintEvent)
	FVector BP_GetLaserStartLocation() { return FVector::ZeroVector; }

	// FB TODO: Move to AS
	UFUNCTION(BlueprintEvent)
	int BP_GetPhase() const { return 0; }

	void ActivateLaser()
	{
		UPinballBossEventHandler::Trigger_OnStartLaser(this);
	}

	void DeactivateLaser()
	{
		UPinballBossEventHandler::Trigger_OnStopLaser(this);
	}

	void OnRocketFired()
	{
		UPinballBossEventHandler::Trigger_OnRocketFired(this);

		FauxPhysics::ApplyFauxForceToActorAt(this, RocketLauncherComp.WorldLocation, FVector(125, 0, 0));
	}

	UFUNCTION(BlueprintCallable)
	void StartIntro()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossIntro(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhase1()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossPhase1(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhase2()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossPhase2(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhase25()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossPhase25(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhase3()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossPhase3(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhase35()
	{
		UPinballBossEventHandler::Trigger_StartPinballBossPhase35(this);
	}
};

namespace APinballBoss
{
	APinballBoss Get()
	{
		return TListedActors<APinballBoss>().Single;
	}
};