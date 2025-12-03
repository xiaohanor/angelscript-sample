event void FSkylineHighwayBossVehicleDefeatedSignature();

enum ESkylineHighwayBossVehicleMode
{
	Idle,
	Move,
	Arena,
	Deploy,
	Barrage,
	Defeated
}

class ASkylineHighwayBossVehicle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleArenaMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleSplineMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleBarrageMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleGunBarrageAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleGunVolleyAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleGunAimCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayBossVehicleDefeatedCapability");
	

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;
	default ConeRotateComp.Friction = 5.0;
	default ConeRotateComp.bConstrainTwist = true;
	default ConeRotateComp.SpringStrength = 1;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent, Attach=ConeRotateComp)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach=OffsetComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UStaticMeshComponent GunBaseMesh;
	default GunBaseMesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=GunBaseMesh)
	UStaticMeshComponent GunHingeMesh;
	default GunHingeMesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=GunHingeMesh)
	UStaticMeshComponent GunCaseMesh;
	default GunCaseMesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=GunCaseMesh)
	UStaticMeshComponent GunBarrelLeftMesh;
	default GunBarrelLeftMesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=GunCaseMesh)
	UStaticMeshComponent GunBarrelRightMesh;
	default GunBarrelRightMesh.CollisionProfileName = n"BlockAll";

	UPROPERTY(DefaultComponent, Attach=OffsetComp)
	UGravityWhipSlingAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;	

	UPROPERTY(DefaultComponent, Attach=GunCaseMesh)
	UBasicAIProjectileLauncherComponent BlasterLauncherComponent;

	UPROPERTY(DefaultComponent, Attach=GunBarrelRightMesh)
	USkylineHighwayBossVehicleGunLaunchPoint GunLaunchPointRight;

	UPROPERTY(DefaultComponent, Attach=GunBarrelLeftMesh)
	USkylineHighwayBossVehicleGunLaunchPoint GunLaunchPointLeft;

	UPROPERTY(EditInstanceOnly)
	AHazeNiagaraActor Explosion;

	UPROPERTY(EditInstanceOnly)
	ASplineActor MoveSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ArenaSpline;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> BlasterSplines;

	UPROPERTY()
	TSubclassOf<ASkylineHighwayBossVehicleGunProjectile> GunProjectileClass;

	UPROPERTY()
	FSkylineHighwayBossVehicleDefeatedSignature OnDefeated;

	UPROPERTY()
	FSkylineHighwayBossVehicleDefeatedSignature OnDefeatedCompleted;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipImpactComp;

	private ESkylineHighwayBossVehicleMode CurrentModeInternal;
	FVector PreviousLocation;
	FVector Velocity;
	AHazePlayerCharacter TargetPlayer;
	TArray<AActor> AttachedActors;

	ESkylineHighwayBossVehicleMode GetCurrentMode() property
	{
		return CurrentModeInternal;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Idle;

		WhipImpactComp.OnImpact.AddUFunction(this, n"Impact");

		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0, 0, 500), this);

		GetAttachedActors(AttachedActors);
		for(AActor AttachedActor : AttachedActors)
		{
			AttachedActor.AttachToComponent(ConeRotateComp, NAME_None, EAttachmentRule::KeepRelative);
			AttachedActor.AddActorDisable(AttachedActor);
		}

		BlockCapabilities(n"Attack", this);

		AddActorDisable(this);			
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Velocity = ActorLocation - PreviousLocation;
		FVector Origin = ActorLocation - Velocity.GetSafeNormal2D() * 500;
		float ForceSize = Math::Clamp(Velocity.Size() * 25, 0, 1000);
		FVector Force = FVector::UpVector * ForceSize;
		ConeRotateComp.ApplyForce(Origin, Force);
		PreviousLocation = ActorLocation;
	}

	UFUNCTION()
	private void Impact(FGravityWhipImpactData ImpactData)
	{
		HealthComp.TakeDamage(0.075, EDamageType::Default, this);
		ConeRotateComp.ApplyImpulse(ImpactData.HitResult.Location + FVector::UpVector * 300, (ActorLocation - ImpactData.HitResult.Location).GetSafeNormal() * 300);

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnDamaged(this);

		if(HealthComp.IsDead())
			CrumbDefeat();
	}

	UFUNCTION()
	void Start()
	{
		RemoveActorDisable(this);
		for(AActor Attached : AttachedActors)
			Attached.RemoveActorDisable(this);
		if(CurrentModeInternal == ESkylineHighwayBossVehicleMode::Defeated)
			return;
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Move;
	}

	UFUNCTION()
	void StartArenaMode()
	{
		if(CurrentModeInternal == ESkylineHighwayBossVehicleMode::Defeated)
			return;
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Arena;
	}

	UFUNCTION()
	void StartDeployMode()
	{
		if(CurrentModeInternal == ESkylineHighwayBossVehicleMode::Defeated)
			return;
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Deploy;
	}

	UFUNCTION()
	void StartBlasterMode()
	{
		if(CurrentModeInternal == ESkylineHighwayBossVehicleMode::Defeated)
			return;
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Barrage;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDefeat()
	{
		CurrentModeInternal = ESkylineHighwayBossVehicleMode::Defeated;
		AddActorTickBlock(this);
		AddActorCollisionBlock(this);
		DetachFromActor(EDetachmentRule::KeepWorld);
		Explosion.NiagaraComponent0.Activate();
		OnDefeated.Broadcast();
		USkylineHighwayBossVehicleEffectHandler::Trigger_OnDefeated(this);
		if(!IsCapabilityTagBlocked(n"Attack"))
			BlockCapabilities(n"Attack", this);
	}

	UFUNCTION(DevFunction)
	void Defeat()
	{
		HealthComp.TakeDamage(1, EDamageType::Default, this);
		if(HealthComp.IsDead())
			CrumbDefeat();
	}

	UFUNCTION()
	void StartAttacks()
	{
		if(IsCapabilityTagBlocked(n"Attack"))
			UnblockCapabilities(n"Attack", this);
	}
}