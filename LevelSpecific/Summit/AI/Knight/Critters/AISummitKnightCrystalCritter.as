UCLASS(Abstract)
class AAISummitKnightCrystalCritter : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIGroundMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightCritterBehaviourCompoundCapability");
	
	default CapsuleComponent.CapsuleRadius = 100.0;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe); // So it's easy for Zoe to hit
		Super::BeginPlay();

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 89.0, this, EHazeSettingsPriority::Defaults);

		OnRespawn();
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");

		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (HealthComp.IsDead())
			return;
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Params.PlayerInstigator);
		USummitKnightCritterEventhandler::Trigger_OnDeath(this);		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		// Always go for the tail dragon
		TargetingComponent.SetTarget(Game::Mio);
	}
}
