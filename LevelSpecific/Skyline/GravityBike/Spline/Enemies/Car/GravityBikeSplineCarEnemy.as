asset GravityBikeSplineCarEnemySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGravityBikeSplineEnemyTickTriggersCapability);
	Capabilities.Add(UGravityBikeSplineEnemyBlockFireCapability);
	Capabilities.Add(UGravityBikeSplineEnemyCutsceneCapability);

	Capabilities.Add(UGravityBikeSplineCarEnemyMoveCapability);
	Capabilities.Add(UGravityBikeSplineCarEnemyVeerCapability);
	Capabilities.Add(UGravityBikeSplineCarEnemyExplodeCapability);

	Capabilities.Add(UGravityBikeSplineCarEnemyFireTurretCapability);
	Capabilities.Add(UGravityBikeSplineCarEnemyReloadTurretCapability);
	Capabilities.Add(UGravityBikeSplineCarEnemyRotateTurretCapability);
};

enum EGravityBikeSplineCarEnemyState
{
	Default,
	Veering,
	Dead,
};

UCLASS(Abstract)
class AGravityBikeSplineCarEnemy : AGravityBikeSplineFlyingEnemy
{
	access Resolver = private, UGravityBikeSplineCarEnemyMovementResolver;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeSplineCarEnemyTurretComponent TurretComp;

	UPROPERTY(DefaultComponent, Attach = TurretComp)
	USceneComponent TurretYawPivot;

	UPROPERTY(DefaultComponent, Attach = TurretYawPivot)
	USceneComponent TurretPitchPivot;

	UPROPERTY(DefaultComponent, Attach = TurretPitchPivot)
	UGravityBikeSplineCarEnemyTurretMuzzleComponent TurretLeftMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchPivot)
	UGravityBikeSplineCarEnemyTurretMuzzleComponent TurretRightMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	USceneComponent LightsRotationPivot;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarVisibility = EBasicAIHealthBarVisibility::OnlyShowWhenHurt;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineCarEnemySheet);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bResolveMovementLocally.Apply(true, this, EInstigatePriority::Level);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp;

	UPROPERTY(DefaultComponent)
	UTeleportResponseComponent TeleportResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(Category = "Lights")
	float LightsRotationSpeed = 360.0;

	EGravityBikeSplineCarEnemyState State = EGravityBikeSplineCarEnemyState::Default;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetActorControlSide(GravityBikeWhip::GetPlayer());

		HealthComp.PreTakeDamage.AddUFunction(this, n"PreTakeDamage");
		HealthComp.PostTakeDamage.AddUFunction(this, n"PostTakeDamage");
		HealthComp.OnDeath.AddUFunction(this, n"OnDeath");
		HealthComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		TeleportResponseComp.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
#if EDITOR
		TEMPORAL_LOG(this)
			.Value("State", State)
			.Rotation("AccMeshRotation;Value", AccMeshRotation.Value, MeshPivot.WorldLocation, 500)
			.DirectionalArrow("AccMeshRotation;VelocityAxisAngle", MeshPivot.WorldLocation, AccMeshRotation.VelocityAxisAngle)
			.Value("DamageImpulseTime", DamageImpulseTime)
			.Value("ReflectOffWallTime", ReflectOffWallTime)
		;
#endif
	}

	UFUNCTION()
	private void OnTeleported()
	{
		AccMeshRotation.SnapTo(FQuat::Identity);
	}

	void OnActivated() override
	{
		Super::OnActivated();

		UGravityBikeSplineCarEnemyEventHandler::Trigger_OnCarActivated(this);
	}

	void OnDeactivated() override
	{
		Super::OnDeactivated();
		
		UGravityBikeSplineCarEnemyEventHandler::Trigger_OnCarDeactivated(this);
	}

	UFUNCTION()
	private void PreTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		UGravityBikeSplineCarEnemyEventHandler::Trigger_OnDamaged(this, DamageData);
	}

	UFUNCTION()
	private void PostTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		if(HealthComp.IsDead() || HealthComp.IsRespawning())
			return;

		if(DamageData.ShouldApplyImpulse())
		{
			const FVector LinearImpulse = DamageData.DamageDirection * GravityBikeSpline::CarEnemy::ImpactLocationOffsetImpulse;

			MoveComp.AddPendingImpulse(LinearImpulse);
			AddImpulseAsAngularImpulse(LinearImpulse.GetSafeNormal() * -GravityBikeSpline::CarEnemy::ImpactMeshRotationImpulse);

			DamageImpulseTime = Time::GameTimeSeconds;
		}
	}

	UFUNCTION()
	private void OnDeath(FGravityBikeSplineEnemyDeathData DeathData)
	{
		BPOnDeath();
		LightsRotationPivot.SetHiddenInGame(true, true);
		AccMeshRotation.SnapTo(FQuat::Identity);
	}

	UFUNCTION(BlueprintEvent)
	private void BPOnDeath()
	{
	}

	UFUNCTION()
	private void OnRespawn(FGravityBikeSplineEnemyRespawnData RespawnData)
	{
		LightsRotationPivot.SetHiddenInGame(false, true);
	}

	UPrimitiveComponent GetCollider() const override
	{
		return MeshComp;
	}

	void ExplodeFromImpact() override
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("ApplyDeathFromWall");
#endif

		if(!HasControl())
			return;

		HealthComp.bExplode = true;
	}
};