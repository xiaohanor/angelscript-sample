asset GravityBikeSplineAttackShipSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGravityBikeSplineEnemyTickTriggersCapability);
	Capabilities.Add(UGravityBikeSplineEnemyBlockFireCapability);
	Capabilities.Add(UGravityBikeSplineEnemyCutsceneCapability);

	Capabilities.Add(UGravityBikeSplineAttackShipMoveCapability);
	Capabilities.Add(UGravityBikeSplineAttackShipVeerCapability);
	Capabilities.Add(UGravityBikeSplineAttackShipExplodeCapability);
	Capabilities.Add(UGravityBikeSplineAttackShipOpenHatchCapability);

    Capabilities.Add(UGravityBikeSplineEnemyMissileLauncherCapability);
};

enum EGravityBikeSplineAttackShipState
{
	Default,
	Veering,
	Dead,
};

UCLASS(Abstract)
class AGravityBikeSplineAttackShip : AGravityBikeSplineFlyingEnemy
{
	access Resolver = private, UGravityBikeSplineAttackShipMovementResolver;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = SphereComp)
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "LeftThruster")
	USkylineAttackShipThrusterComponent LeftThrusterSpawnerComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "RightThruster")
	USkylineAttackShipThrusterComponent RightThrusterSpawnerComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "Hatch")
	UStaticMeshComponent HatchMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeSplineEnemyMissileLauncherComponent MissileLauncherComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarVisibility = EBasicAIHealthBarVisibility::OnlyShowWhenHurt;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineAttackShipSheet);

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
	UGravityBikeSplineAttackShipEditorComponent EditorComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(Category = "Lights")
	float LightsRotationSpeed = 360.0;

	UPROPERTY(EditDefaultsOnly, Category = "Hatch")
	float OpenHatchAngle = 50;

	UPROPERTY(EditAnywhere, Category = "Hatch")
	float OpenDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Hatch")
	float CloseDuration = 1.0;

	EGravityBikeSplineAttackShipState State = EGravityBikeSplineAttackShipState::Default;
	TInstigated<bool> bFacePlayer;
	default bFacePlayer.DefaultValue = false;

	TSet<FInstigator> OpenHatchInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetActorControlSide(GravityBikeWhip::GetPlayer());

		MoveComp.SetupShapeComponent(SphereComp);
		
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
		
		UGravityBikeSplineAttackShipEventHandler::Trigger_OnAttackShipActivated(this);
	}

	void OnDeactivated() override
	{
		Super::OnDeactivated();

		UGravityBikeSplineAttackShipEventHandler::Trigger_OnAttackShipDeactivated(this);
	}

	UFUNCTION()
	private void PreTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		UGravityBikeSplineAttackShipEventHandler::Trigger_OnDamaged(this, DamageData);
	}

	UFUNCTION()
	private void PostTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		if(HealthComp.IsDead() || HealthComp.IsRespawning())
			return;

		if(DamageData.ShouldApplyImpulse())
		{
			const FVector LinearImpulse = DamageData.DamageDirection * GravityBikeSpline::AttackShip::ImpactLocationOffsetImpulse;

			MoveComp.AddPendingImpulse(LinearImpulse);
			AddImpulseAsAngularImpulse(LinearImpulse.GetSafeNormal() * -GravityBikeSpline::AttackShip::ImpactMeshRotationImpulse);

			DamageImpulseTime = Time::GameTimeSeconds;
		}
	}

	UFUNCTION()
	private void OnDeath(FGravityBikeSplineEnemyDeathData DeathData)
	{
		BPOnDeath();
		AccMeshRotation.SnapTo(FQuat::Identity);
	}

	UFUNCTION(BlueprintEvent)
	private void BPOnDeath()
	{
	}

	UFUNCTION()
	private void OnRespawn(FGravityBikeSplineEnemyRespawnData RespawnData)
	{
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

	FVector GetStartOfCargoBay() const
	{
		FVector RelativeLocation = FVector(-120, 0, -80);
		return MeshComp.WorldTransform.TransformPosition(RelativeLocation);
	}

	FVector GetStartOfHatch() const
	{
		FVector RelativeLocation = FVector(0, 0, 20);
		return HatchMeshComp.WorldTransform.TransformPosition(RelativeLocation);
	}

	FVector GetEndOfHatch() const
	{
		FVector RelativeLocation = FVector(-520, 0, 265);
		return HatchMeshComp.WorldTransform.TransformPosition(RelativeLocation);
	}

	UFUNCTION(BlueprintEvent)
	void OnHatchStartOpening() {};
};

#if EDITOR
class UGravityBikeSplineAttackShipEditorComponent : UActorComponent
{
}

class UGravityBikeSplineAttackShipEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineAttackShipEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AttackShip = Cast<AGravityBikeSplineAttackShip>(Component.Owner);
		if(AttackShip == nullptr)
			return;

		DrawLine(
			AttackShip.GetStartOfCargoBay(),
			AttackShip.GetStartOfHatch(),
			FLinearColor::Green,
			3
		);

		DrawLine(
			AttackShip.GetStartOfHatch(),
			AttackShip.GetEndOfHatch(),
			FLinearColor::Red,
			3
		);
	}
}
#endif