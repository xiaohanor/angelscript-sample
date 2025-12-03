event void FIslandOverseerEyeComponentTakeDamageEvent(AHazeActor Actor, AHazeActor Instigator, float Damage, EDamageType DamageType);
event void FIslandOverseerEyeOnLoopedEvent(AAIIslandOverseerEye Eye);
event void FIslandOverseerEyeOnDiedEvent(AAIIslandOverseerEye Eye);
event void FIslandOverseerEyeOnActivatedEvent(AAIIslandOverseerEye Eye);

UCLASS(Abstract)
class AAIIslandOverseerEye : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerEyeMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerEyeSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerEyeCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldBubbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerEyeRegainShieldCapability");
	

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UIslandOverseerEyeHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeTargetable Targetable;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRedBlueDamageComponent RedBlueDamageComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotator;
	default SyncedRotator.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UIslandOverseerEyeSettings Settings;

	AHazeCharacter Boss;

	FVector OriginalScale;
	FHazeAcceleratedVector AccScale;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccSpeed;

	bool Active;
	bool bReturn = false;
	float Speed = 900;
	float ReturnDuration;
	bool bBlue;
	bool bLookAtPlayers;
	float DamageTime;
	float DamagePerSecond = 0.25;
	bool bInAttackSpace;
	AHazePlayerCharacter KillingPlayer;
	float FlashTime;
	float FlashDuration = 0.1;

	FIslandOverseerEyeOnDiedEvent OnDied;
	FIslandOverseerEyeOnActivatedEvent OnActivated;

	UIslandOverseerDeployEyeManagerComponent EyesManagerComp;// Get from Overseer
	UIslandOverseerDeployEyeComponent EyesComp;

	// UMaterialInterface BossEmptyEyeMaterial;
	// UMaterialInterface BossEyeMaterialLeft;
	// UMaterialInterface BossEyeMaterialRight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);
		Settings = UIslandOverseerEyeSettings::GetSettings(Boss);
		BlockCapabilities(n"FlyingMovement", this);

		Targetable.Disable(this);

		EyesManagerComp = UIslandOverseerDeployEyeManagerComponent::GetOrCreate(Boss);
		EyesManagerComp.AddEye(this);

		HealthBarComp.Offset = FVector(0, 0, 10);
		HealthBarComp.Initialize();
		HealthBarComp.SetHealthBarEnabled(false);

		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		RedBlueDamageComp.OnDamage.AddUFunction(this, n"Damage");

		ForceFieldBubbleComp.TakeDamage(100, FVector::ZeroVector);		
		HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");

		// BossEmptyEyeMaterial = Boss.Mesh.GetMaterial(1);
		// BossEyeMaterialLeft = Boss.Mesh.GetMaterial(5);
		// BossEyeMaterialRight = Boss.Mesh.GetMaterial(11);

		AddActorDisable(this);
	}

	void SetMoveRotation(FRotator Rotation)
	{
		MeshOffsetComponent.WorldRotation = Rotation;
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                        EDamageType DamageType)
	{
		if(HealthComp.IsAlive())
			return;
		if(bReturn)
			return;

		Return(0.5);
		KillingPlayer = Cast<AHazePlayerCharacter>(Attacker);
		OnDied.Broadcast(this);
		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION()
	private void Damage(float Damage, AHazeActor Instigator)
	{
		if(!Active)
			return;
		if(!HealthComp.IsAlive())
			return;
		if(!ForceFieldBubbleComp.IsDepleted())
			return;

		HealthComp.TakeDamage(Damage * DamagePerSecond, EDamageType::Projectile, Instigator);

		if(Time::GetGameTimeSince(FlashTime) > FlashDuration + 0.1)
		{
			DamageFlash::DamageFlashActor(this, FlashDuration, FLinearColor(0.9, 0, 0, 1));
			FlashTime = Time::GameTimeSeconds;
			FlashDuration = Math::RandRange(0.1, 0.2);
		}
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		
	}

	void Activate()
	{
		if(Active)
			return;

		UnblockCapabilities(n"FlyingMovement", this);
		Active = true;
		bReturn = false;
		MovementComponent.UnFollowComponentMovement(this);

		AccLocation.SnapTo(ActorLocation);
		HealthComp.Reset();
		HealthBarComp.SetHealthBarEnabled(true);
		OriginalScale = ActorScale3D;
		AccScale.SnapTo(ActorScale3D);

		// Keep las
		OnActivated.Broadcast(this);		

		bool bRight = Boss.ActorRightVector.DotProduct(ActorLocation - Boss.ActorLocation) > 0;
		if(bRight)
		{
			Boss.Mesh.HideBoneByName(n"RightEye", EPhysBodyOp::PBO_None);
			// Boss.Mesh.SetMaterial(11, BossEmptyEyeMaterial);
		}
		else
		{
			Boss.Mesh.HideBoneByName(n"LeftEye", EPhysBodyOp::PBO_None);
			// Boss.Mesh.SetMaterial(5, BossEmptyEyeMaterial);
		}

		RemoveActorDisable(this);
	}

	void Deactivate()
	{
		if(!Active)
			return;
		if(Boss == nullptr)
			return;

		BlockCapabilities(n"FlyingMovement", this);
		ActorLocation = EyesComp.WorldLocation;
		ActorRotation = EyesComp.WorldRotation;
		SetMoveRotation(FRotator::ZeroRotator);
		MovementComponent.FollowComponentMovement(EyesComp, this, FollowType = EMovementFollowComponentType::Teleport, Priority = EInstigatePriority::Normal);
		ActorScale3D = OriginalScale;
		HealthBarComp.SetHealthBarEnabled(false);
		Active = false;

		bool bRight = Boss.ActorRightVector.DotProduct(ActorLocation - Boss.ActorLocation) > 0;
		if(bRight)
		{
			Boss.Mesh.UnHideBoneByName(n"RightEye");
			// Boss.Mesh.SetMaterial(11, BossEyeMaterialRight);
		}
		else
		{
			Boss.Mesh.UnHideBoneByName(n"LeftEye");
			// Boss.Mesh.SetMaterial(5, BossEyeMaterialLeft);
		}

		AddActorDisable(this);
	}

	void Return(float InReturnDuration = 0)
	{
		bReturn = true;
		if(InReturnDuration == 0)
			ReturnDuration = Settings.ReturnDuration;
		else
			ReturnDuration = InReturnDuration;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Mesh.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bInAttackSpace)
			ActorLocation = FVector(ActorLocation.X, Game::Mio.ActorLocation.Y, ActorLocation.Z);
	}
}

enum EIslandOverseerEyeAttack
{
	FlyBy,
	Charge,
}

enum EIslandOverseerAttachedEyePhase
{
	FlyBy,
	ComboFlyBy,
	Charge,
	ComboCharge
}