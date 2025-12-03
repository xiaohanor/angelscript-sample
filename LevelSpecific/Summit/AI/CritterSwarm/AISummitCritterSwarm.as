UCLASS(Abstract)
class AAISummitCritterSwarm : ABasicAICharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapsuleComponent.CapsuleRadius = 2000;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;
	default CapsuleComponent.RemoveTag(ComponentTags::HideOnCameraOverlap); // We don't want critters to be hidden when camera is inside collision!

	default DisableComp.AutoDisableRange = 40000.0;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmAcidResponseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmDisperseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmFlockingCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterSwarmConstrainToAreaCapability");

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	// UPROPERTY(DefaultComponent)
	// UAdultDragonAcidAutoAimComponent AutoAimComp;
	// default AutoAimComp.MaximumDistance = 50000.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitCritterSwarmComponent SwarmComp;

	// Use special component to detect acid hits
	UPROPERTY(DefaultComponent)
	USummitCritterSwarmAcidHittableComponent AcidHittableComp;
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore); // Currently acid projectile uses the WorldDynamic trace channel for some reason.

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Ignore pathfinding
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this);

		OnRespawn(); // In case not spawned by spawner
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");
		
		// Mio will interact the most with swarm
		SetActorControlSide(Game::Mio);

		Super::BeginPlay();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Always go for the acid shooter
		TargetingComponent.SetTarget(Game::Mio);
	}
}