UCLASS(Abstract)
class AAISummitKnightCritter : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIGroundMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterLatchOnMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightCritterBehaviourCompoundCapability");
	
	default CapsuleComponent.CapsuleRadius = 100.0;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.DefaultMeltSettings = SummitKnightCritterMeltSettings;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Hips")
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.AutoAimMaxAngle = 20.0;
	default AutoAimComp.TargetShape.SphereRadius = 50.0;
	default AutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Hips")
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape = FHazeShapeSettings::MakeCapsule(300.0, 300.0);

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		Super::BeginPlay();

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 89.0, this, EHazeSettingsPriority::Defaults);

		OnRespawn();
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		// Zoe will be affected most directly by us
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		// Always go for the tail dragon
		TargetingComponent.SetTarget(Game::Zoe);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(!MeltComp.bMelted)
			return;
		if (HealthComp.IsDead())
			return;
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Acid, Hit.PlayerInstigator);
		USummitKnightCritterEventhandler::Trigger_OnDeath(this);		
	}
}

asset SummitKnightCritterMeltSettings of USummitMeltSettings
{
	MaxHealth = 0.6;
}
