struct FSanctuaryGhostEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USanctuaryGhostEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASanctuaryGhost Ghost;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReveal()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttack(FSanctuaryGhostEventData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackDamage()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackEnd(FSanctuaryGhostEventData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIlluminated()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnilluminated()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDie()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartLiftingPlayer()
	{
	}

	UFUNCTION(BlueprintPure)
	FVector GetAttackBeamStart() property
	{
		return Ghost.AttackPivot.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetAttackBeamEnd() property
	{
		if (Ghost.TargetPlayer == nullptr)
			return FVector::ZeroVector;

		return Ghost.TargetPlayer.ActorCenterLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetAttackBeamDirection() property
	{
		if (Ghost.TargetPlayer == nullptr)
			return FVector::ZeroVector;
		
		FVector Direction = (Ghost.TargetPlayer.ActorCenterLocation - Ghost.AttackPivot.WorldLocation).SafeNormal;

		return Direction;
	}
};

event void FSanctuaryGhostSignature();

class ASanctuaryGhost : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UHazeSkeletalMeshComponentBase MeshOutline;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent AttackPivot;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;	

//	UPROPERTY(DefaultComponent, Attach = Pivot)
//	UGodrayComponent Godray;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	ULightBirdTargetComponent LightBirdTargetComp;
	default LightBirdTargetComp.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent, Attach = LightBirdTargetComp)
	UTargetableOutlineComponent LightBirdOutline;
	default LightBirdOutline.bOutlineAttachedActors = true;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;
	default LightBirdChargeComp.ChargeDuration = 1.83;
	default LightBirdChargeComp.DecayDelay = 0.0;
	default LightBirdChargeComp.DecayMultiplier = 2.0; 

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostSwimCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostRevealCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostChaseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostAttackCapability");
//	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostProjectileAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostTargetCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGhostAvoidanceCapability");

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnableComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ChaseAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AttackAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence IlluminatedAnim;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	float SwimSpeed = 500.0;

	UPROPERTY(EditAnywhere)
	float ChaseSpeed = 800.0;

	UPROPERTY(EditAnywhere)
	float RevealDistance = 3000.0;

	UPROPERTY(EditAnywhere)
	float RevealHeightAbovePlayer = 400.0;

	UPROPERTY(EditAnywhere)
	float RevealDuration = 2.0;
	bool bIsRevealed = false;

	UPROPERTY(EditAnywhere)
	float AttackRange = 2000.0;

	UPROPERTY(EditAnywhere)
	float AttackDetachMargin = 1000.0;

	UPROPERTY(EditAnywhere)
	float AttackRadius = 500.0;

	UPROPERTY(EditAnywhere)
	bool bDisableSpawnerOnDeath = true;

	float SurfaceHeight = 0.0;
	float SpawnHeightOffset = -200.0;
	float ExplosionRadius = 50.0;

	UPROPERTY()
	TSubclassOf<ASanctuaryGhostProjectile> ProjectileClass;

	UPROPERTY()
	AHazePlayerCharacter TargetPlayer;

	FHazeAcceleratedFloat AcceleratedFloat;

	FVector Velocity;
	FVector Avoidance;
	float AvoidanceRange = 500.0;

	UPROPERTY()
	FSanctuaryGhostSignature OnReveal;

	UPROPERTY()
	FSanctuaryGhostSignature OnDie;

	UPROPERTY()
	FSanctuaryGhostSignature OnUnSpawn;

	bool bIsChasing = false;
	bool bIsAttacking = false;
	bool bIsIlluminated = false;
	bool bBlockedCapas = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
//		Godray.SetStaticMesh(Godray.Mesh);
//		Godray.ConstructionScript_Hack();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		LightBirdChargeComp.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
		LightBirdChargeComp.OnChargeDepleted.AddUFunction(this, n"HandleChargeDepleted");
		RespawnableComp.OnRespawn.AddUFunction(this, n"HandleRespawn");

		AddActorDisable(this);
		SurfaceHeight = ActorLocation.Z + SpawnHeightOffset;

//		Godray.SetComponentTickEnabled(false);
//		Godray.SetRenderedForPlayer(Game::Mio, false);
//		Godray.SetRenderedForPlayer(Game::Zoe, false);

//		For VO
		for (auto Player : Game::GetPlayers())
			EffectEvent::LinkActorToReceiveEffectEventsFrom(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		USanctuaryGhostEventHandler::Trigger_OnIlluminated(this);

		bIsIlluminated = true;

		// Not sure if we should block attack or not :|
		if (!bBlockedCapas)
			BlockCapabilities(n"SanctuaryGhostAttack", this);
		bBlockedCapas = true;
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		USanctuaryGhostEventHandler::Trigger_OnUnilluminated(this);

		bIsIlluminated = false;

		// Not sure if we should block attack or not :|
		if (bBlockedCapas)
			UnblockCapabilities(n"SanctuaryGhostAttack", this);
		bBlockedCapas = false;
	}	

	UFUNCTION()
	private void HandleFullyCharged()
	{
		auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
		UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::LaunchExit;
	
		//kills other ghosts that are near
		TListedActors<ASanctuaryGhost> ListedGhosts;
		TArray<ASanctuaryGhost> Ghosts = ListedGhosts.CopyAndInvalidate();

		for (auto Ghost : Ghosts)
		{
			if (Ghost == this)
				continue;

			if(GetDistanceTo(Ghost) < ExplosionRadius)
				Ghost.Die();
		}

		Die();
	}

	UFUNCTION()
	private void HandleChargeDepleted()
	{
	}

	UFUNCTION()
	private void HandleRespawn()
	{
		if (IsCapabilityTagBlocked(CapabilityTags::GameplayAction))
			UnblockCapabilities(CapabilityTags::GameplayAction, this);
		if (bBlockedCapas)
			UnblockCapabilities(n"SanctuaryGhostAttack", this);
		bBlockedCapas = false;

		SurfaceHeight = ActorLocation.Z + SpawnHeightOffset;
		Pivot.RelativeLocation = FVector::ZeroVector;
		bIsRevealed = false;
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void Activate()
	{
		if (IsCapabilityTagBlocked(CapabilityTags::GameplayAction))
			UnblockCapabilities(CapabilityTags::GameplayAction, this);

		SurfaceHeight = ActorLocation.Z + SpawnHeightOffset;
		Pivot.RelativeLocation = FVector::ZeroVector;
		bIsRevealed = false;		
		RemoveActorDisable(this);		
	}

	UFUNCTION()
	void Reveal()
	{
		bIsRevealed = true;

		USanctuaryGhostEventHandler::Trigger_OnReveal(this);
		OnReveal.Broadcast();
		BP_OnReveal();
	}

	UFUNCTION()
	void Die()
	{
		// Disable the spawner that spawned this Ghost
		if (bDisableSpawnerOnDeath)
			RespawnableComp.GetSpawner().AddActorDisable(this);

		USanctuaryGhostEventHandler::Trigger_OnDie(this);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		OnDie.Broadcast();
		BP_OnDie();
		UnSpawn();
	}

	UFUNCTION()
	void Attack()
	{
		for (auto Player : Game::Players)
		{
			if (ActorLocation.Distance(Player.ActorLocation) <= AttackRadius)
				Player.KillPlayer();
		}

//		USanctuaryGhostEventHandler::Trigger_OnAttack(this);
		BP_OnAttack();
		UnSpawn();
	}

	UFUNCTION()
	void ProjectileAttack()
	{
		auto Projectile = SpawnActor(ProjectileClass, AttackPivot.WorldLocation, ActorForwardVector.Rotation(), bDeferredSpawn = true);
		Projectile.TargetPlayer = TargetPlayer;
		FinishSpawningActor(Projectile);
	}

	UFUNCTION()
	void UnSpawn()
	{	
		OnUnSpawn.Broadcast();
		if (LightBirdResponseComp.IsAttached())
		{
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
//			UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::LaunchExit;
			UserComp.Hover();
			UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::Obstructed;
		}

		if (!IsCapabilityTagBlocked(CapabilityTags::GameplayAction))
			BlockCapabilities(CapabilityTags::GameplayAction, this);
		AddActorDisable(this);
		RespawnableComp.UnSpawn();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnReveal() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDie() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnAttack() {}
};

UFUNCTION()
void KillAllGhosts()
{
	TListedActors<ASanctuaryGhost> ListedGhosts;
	
	TArray<ASanctuaryGhost> Ghosts = ListedGhosts.CopyAndInvalidate();
	
	
	for (int i = Ghosts.Num() - 1; i >= 0; i--)
        {
			Ghosts[i].Die();
			
        }
}