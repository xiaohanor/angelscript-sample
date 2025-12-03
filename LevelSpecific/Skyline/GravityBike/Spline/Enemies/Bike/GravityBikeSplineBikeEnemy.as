asset GravityBikeSplineBikeEnemySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGravityBikeSplineEnemyTickTriggersCapability);
	Capabilities.Add(UGravityBikeSplineEnemyBlockFireCapability);
	Capabilities.Add(UGravityBikeSplineEnemyCutsceneCapability);

	Capabilities.Add(UGravityBikeSplineBikeEnemyGroundMovementCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyAirMovementCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyVeerCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyCrashingCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyExplodeCapability);
};

enum EGravityBikeSplineBikeEnemyState
{
	Default,
	Veering,
	Crashing,
	Explode,
};

enum EGravityBikeSplineBikeEnemyMovementState
{
	None,
	Ground,
	Air,
	Drop,
};

UCLASS(Abstract)
class AGravityBikeSplineBikeEnemy : AGravityBikeSplineEnemy
{
	access Driver = private, AGravityBikeSplineBikeEnemyDriver;
	access Passenger = private, AGravityBikeSplineBikeEnemyPassenger, UGravityBikeSplineEnemyFireTriggerComponent;
	access Resolver = protected, UGravityBikeSplineBikeEnemyMovementResolver;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = CollisionProfile::EnemyIgnoreCharacters;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UHazeSkeletalMeshComponentBase SkeletalMeshComp;
	default SkeletalMeshComp.CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp)
	USceneComponent DriverAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp)
	USceneComponent PassengerAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarVisibility = EBasicAIHealthBarVisibility::OnlyShowWhenHurt;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineBikeEnemySheet);
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineBikeEnemyDropSheet);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;
	default MoveComp.bResolveMovementLocally.Apply(true, this, EInstigatePriority::Level);
	default MoveComp.FollowEnablement.DefaultValue = EMovementFollowEnabledStatus::FollowEnabled;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent MeshPoseDebugComp;
#endif

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy")
	float TiltMultiplier = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy")
	float TiltMax = 40;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy")
	float TiltInterpSpeed = 5;

	/**
	 * How far away we want the reference point to be when this object is held.
	 */
	UPROPERTY(EditAnywhere, Category = "Bike Enemy", Meta = (UIMin = "0.0", UIMax = "1.0"))
	float GrabDriverAndPassengerOffsetMultiplier = 1;

	access:Driver
	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Driver")
	TSubclassOf<AGravityBikeSplineBikeEnemyDriver> DriverClass;

	access:Passenger
	UPROPERTY(EditAnywhere, Category = "Bike Enemy|Passenger")
	bool bSpawnPassenger = true;

	access:Passenger
	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Passenger")
	TSubclassOf<AGravityBikeSplineBikeEnemyDriver> PassengerClass;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Crash")
	float CrashVerticalImpulse = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Crash")
	float CrashPitchSpeed = 8;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Crash")
	float CrashGravity = 3000;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|Crash")
	float AfterCrashDelay = 3;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|No Driver")
	float AfterNoDriverDelay = 1.0;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|No Driver")
	float NoDriverTurns = 2.0;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|No Driver")
	float NoDriverTiltMoveDistance = 200;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Enemy|No Driver")
	float NoDriverTiltMultiplier = 0.5;

	EGravityBikeSplineBikeEnemyState State = EGravityBikeSplineBikeEnemyState::Default;
	EGravityBikeSplineBikeEnemyMovementState MovementState = EGravityBikeSplineBikeEnemyMovementState::None;
	float StartNoDriverTime = 0;

	access:Driver
	AGravityBikeSplineBikeEnemyDriver Driver;

	access:Passenger
	AGravityBikeSplineBikeEnemyDriver Passenger;

	FHazeAcceleratedFloat AccRoll;
	FHazeAcceleratedFloat AccPitch;
	int DriverCount = 0;
	int PassengerCount = 0;
	private FQuat LastRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SetActorControlSide(GravityBikeWhip::GetPlayer());

		HealthComp.PreTakeDamage.AddUFunction(this, n"PreTakeDamage");
		HealthComp.OnDeath.AddUFunction(this, n"OnDeath");
		HealthComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		FGravityBikeWhipThrowTargetCondition ThrowTargetCondition;
		ThrowTargetCondition.BindUFunction(this, n"ThrowTargetCondition");
		ThrowTargetComp.AddTargetCondition(this, ThrowTargetCondition);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		UMovementGravitySettings::SetGravityAmount(this, 4000, this);
		USimpleMovementSettings::SetMaintainMovementSizeOnGroundedRedirects(this, true, this);
		USimpleMovementSettings::SetFloatingHeight(this, FMovementSettingsValue::MakePercentage(1.0), this);

		LastRotation = ActorQuat;

		SpawnDriver();

		if(bSpawnPassenger)
			SpawnPassenger();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(IsValid(Driver))
		{
			Driver.DestroyActor();
			Driver = nullptr;
		}

		if(IsValid(Passenger))
		{
			Passenger.DestroyActor();
			Passenger = nullptr;
		}
	}

	void OnActivated() override
	{
		Super::OnActivated();

		UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnEnemyActivated(this);
	}

	void OnDeactivated() override
	{
		Super::OnDeactivated();

		UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnEnemyDeactivated(this);
	}

	void ActivateFromAttackShipDropBike(AGravityBikeSplineAttackShip AttackShip, UGravityBikeSplineAttackShipDropBikeTriggerComponent TriggerComp)
	{
		if(IsActive())
			return;

		Activate(this);
	}

	void ActivateFromActivateEnemiesTrigger(UGravityBikeSplineActivateEnemiesTriggerComponent TriggerComp) override
	{
		if(IsActive())
			return;

		Super::ActivateFromActivateEnemiesTrigger(TriggerComp);
		
		SplineMoveComp.SnapSplinePositionToClosest(ActorLocation, 0);
	}
	
	access:Driver
	void SpawnDriver()
	{
		check(Driver == nullptr);

		Driver = SpawnActor(DriverClass, DriverAttachmentComp.WorldLocation, DriverAttachmentComp.WorldRotation, NAME_None, true);
		Driver.SetBike(this);

		Driver.MakeNetworked(this, n"Driver", DriverCount);
		DriverCount++;
		FinishSpawningActor(Driver);

		Driver.AttachToComponent(DriverAttachmentComp);
		Driver.SetActorRelativeLocation(FVector::ZeroVector);
		Driver.SetActorRelativeRotation(FQuat::Identity);

		Driver.GrabTargetComp.OffsetMultiplier = GrabDriverAndPassengerOffsetMultiplier;
		Driver.GrabTargetComp.OnGrabbed.AddUFunction(this, n"OnDriverGrabbed");
	}

	UFUNCTION()
	private void OnDriverGrabbed(UGravityBikeWhipComponent WhipComp,
	                             UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		check(Driver == GrabTarget.Owner);
		Driver = nullptr;
	}

	bool HasDriver() const
	{
		return IsValid(Driver);
	}

	void EjectDriver()
	{
		if(!HasDriver())
			return;

		const FVector Direction = Math::GetRandomConeDirection(FVector::UpVector, Math::DegreesToRadians(30), 0);
		const FVector Impulse = Direction * 1000;
		Driver.EjectFromBike(ActorVelocity + Impulse);
		Driver = nullptr;
	}

	access:Passenger
	void SpawnPassenger()
	{
		check(Passenger == nullptr);
		check(bSpawnPassenger);

		Passenger = SpawnActor(PassengerClass, PassengerAttachmentComp.WorldLocation, PassengerAttachmentComp.WorldRotation, NAME_None, true);
		Passenger.SetBike(this);

		Passenger.MakeNetworked(this, n"Passenger", PassengerCount);
		PassengerCount++;
		FinishSpawningActor(Passenger);

		Passenger.AttachToComponent(PassengerAttachmentComp);
		Passenger.SetActorRelativeLocation(FVector::ZeroVector);
		Passenger.SetActorRelativeRotation(FQuat::Identity);

		Passenger.GrabTargetComp.OffsetMultiplier = GrabDriverAndPassengerOffsetMultiplier;
		Passenger.GrabTargetComp.OnGrabbed.AddUFunction(this, n"OnPassengerGrabbed");
	}

	UFUNCTION()
	private void OnPassengerGrabbed(UGravityBikeWhipComponent WhipComp,
	                                UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		check(Passenger == GrabTarget.Owner);
		Passenger = nullptr;
	}

	bool HasPassenger() const
	{
		return IsValid(Passenger);
	}

	void EjectPassenger()
	{
		if(!HasPassenger())
			return;

		const FVector Direction = Math::GetRandomConeDirection(FVector::UpVector, Math::DegreesToRadians(30), 0);
		const FVector Impulse = Direction * 1500;
		Passenger.EjectFromBike(ActorVelocity + Impulse);
		Passenger = nullptr;
	}

	UFUNCTION()
	private bool ThrowTargetCondition()
	{
		// Can't target if there's no driver!
		if(Driver == nullptr)
			return false;

		if(HealthComp.IsDead())
			return false;

		return true;
	}

	UFUNCTION()
	private void PreTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnDamaged(this, DamageData);
	}

	UFUNCTION()
	private void OnDeath(FGravityBikeSplineEnemyDeathData DeathData)
	{
		EjectDriver();
		EjectPassenger();
	}

	UFUNCTION()
	private void OnRespawn(FGravityBikeSplineEnemyRespawnData RespawnData)
	{
		if(ensure(Driver == nullptr))
		{
			SpawnDriver();
		}

		if(bSpawnPassenger && ensure(Passenger == nullptr))
		{
			SpawnPassenger();
		}

		FTransform RespawnTransform = SplineMoveComp.GetSplineTransform();
		SetActorLocationAndRotation(RespawnTransform.Location, RespawnTransform.Rotation);
	}

	void RollFromAngularSpeed(float DeltaTime)
	{
		FQuat DeltaRotation = ActorQuat * LastRotation.Inverse();
		const float AngularVelocity = DeltaRotation.GetTwistAngle(MoveComp.WorldUp) / DeltaTime;
		float TargetRoll = Math::RadiansToDegrees(AngularVelocity * TiltMultiplier);
		TargetRoll *= SplineMoveComp.GetThrottle();
		TargetRoll = Math::Clamp(
			TargetRoll,
			-TiltMax,
			TiltMax
		);

		AccRoll.SpringTo(TargetRoll, 20, 0.5, DeltaTime);
		LastRotation = ActorQuat;
	}

	void ApplyMeshPivotRotation()
	{
		const FRotator Rotation(
			AccPitch.Value,
			0,
			AccRoll.Value,
		);

		FVector RelativeLocation = FVector(
			0,
			Math::Sin(Math::DegreesToRadians(-Rotation.Roll)) * (SphereComp.SphereRadius * 2),	// Offset from roll to keep the heartline at the center of the turn
			-SphereComp.SphereRadius
		);

		MeshPivot.SetRelativeLocationAndRotation(
			RelativeLocation,
			Rotation
		);
	}

	UPrimitiveComponent GetCollider() const override
	{
		return SphereComp;
	}

	access:Resolver
	void HitImpactResponseComponent(UGravityBikeSplineImpactResponseComponent ResponseComp, FGravityBikeSplineOnImpactData ImpactData)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("HitImpactResponseComponent")
			.Section("HitImpactResponseComponent")
				.Value("ResponseComponent", ResponseComp)
				.Struct("ImpactData;", ImpactData)
		;
#endif

		if(!HasControl())
			return;

		// Notify the response component of the impact
		ResponseComp.OnImpact.Broadcast(this, ImpactData);
	}
};