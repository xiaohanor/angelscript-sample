UCLASS(Abstract)
class AAISummitStoneBeastCritter : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability"); // SummitStoneBeast critters manage death by bypassing healthcomponent to limit number of crumb calls.
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastCritterCompoundCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"BasicAIClimbAlongSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastCritterMoveAlongSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastCritterMovementCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"BasicAIMatchTargetControlSideCapability");

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;
	default SwordResponseComp.ResponseDetailLevel = EDragonSwordResponseDetailLevel::Simple;
	
	UPROPERTY(DefaultComponent)
	USummitStoneBeastCritterCrystalSpikeResponseComponent SpikeResponseComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatTargetComponent SwordTargetComp;
	default SwordTargetComp.bCanRushTowards = false;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(BaseSummitStoneBeastCritterPlayerPinnedKnockdownSheet);

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASummitStoneBeastCritterLandingDecal> DecalClass;
	ASummitStoneBeastCritterLandingDecal Decal;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASummitStoneBeastCritterSpikeActor> GroundSpikeClass;

	UHazeActorNetworkedSpawnPoolComponent GroundSpikeSpawnPool;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	float AnimUpdateInterval = 0.0;
	float AnimUpdateTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GetOrCreateGroundSpikeSpawnPool();

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);	
		UBasicAIHealthSettings::SetTakeDamageCooldown(this, 0.5, this, EHazeSettingsPriority::Defaults);

		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		SpikeResponseComp.OnHit.AddUFunction(this, n"OnCrystalSpikeRuptureHit");
		HealthComp.OnDie.AddUFunction(this, n"Die");
		HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");

		// Update animation at most at 30 FPS on lower settings
		if (Game::IsDetailModeAtLeastHigh())
		{
			AnimUpdateInterval = 0.0;
		}
		else
		{
			AnimUpdateInterval = 1.0 / 30.0;
			AnimUpdateTimer = Math::RandRange(0.0, AnimUpdateInterval);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AnimUpdateTimer -= DeltaSeconds;
		if (AnimUpdateTimer <= 0.0)
		{
			AnimUpdateTimer = Math::Max(AnimUpdateTimer + AnimUpdateInterval, -AnimUpdateInterval);
			Mesh.bNoSkeletonUpdate = false;
		}
		else
		{
			Mesh.bNoSkeletonUpdate = true;
		}
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		// Ensures that control side will die first and set target to nullptr before remote to prevent any behaviours on remote to run OnActivated with a nullptr target.
		if (!HasControl())
			return;
		
		// One hit kill
		CrumbDie();
	}

	UFUNCTION()
	private void Die(AHazeActor ActorBeingKilled)
	{
		UBasicAIDamageEffectHandler::Trigger_OnDeath(this);
		//Needs to get hit direction somehow
		USummitStoneBeastCritterEffectHandler::Trigger_OnDeath(this);
		MovementComponent.Reset();
		AddActorDisable(this);
	}

	UFUNCTION()
	private void Reset()
	{
		HealthComp.Reset();
		RemoveActorDisable(this);
	}

	UHazeActorNetworkedSpawnPoolComponent GetOrCreateGroundSpikeSpawnPool()
	{
		check(GroundSpikeClass != nullptr);
		if (GroundSpikeClass != nullptr)
		{
			GroundSpikeSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(GroundSpikeClass, this);
		}
		return GroundSpikeSpawnPool;
	}

	UFUNCTION()
	private void OnCrystalSpikeRuptureHit(AHazeActor Instigator)
	{
		if (HealthComp.IsDead())
			return;

		// Ensures that control side will die first and set target to nullptr before remote to prevent any behaviours on remote to run OnActivated with a nullptr target.
		if (!HasControl())
			return;
		
		// One hit kill
		CrumbDie();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDie()
	{		
		HealthComp.DieLocal();
		HealthComp.OnDie.Broadcast(this);
	}

	void ActivateDecal(FVector Location)
	{
		if (Decal == nullptr)
		{
			Decal = SpawnActor(DecalClass, Location);
		}

		if (Decal != nullptr)
		{
			Decal.ActorLocation = Location;
			Decal.ShowDecal();
		}
		
		Decal.AttachToActor(RespawnComp.Spawner, NAME_None, EAttachmentRule::KeepWorld);
	}

	void DeactivateDecal()
	{
		if (Decal != nullptr)
			Decal.HideDecal();
	}
}