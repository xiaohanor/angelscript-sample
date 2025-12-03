UCLASS(Abstract)
class AAIIslandTentaclytron : ABasicAICharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyingMovementCapability"); 
	//default CapabilityComp.DefaultCapabilities.Add(n"IslandTentaclytronMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTentaclytronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTentaclytronTentaclesCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ProjectileResponseComp;
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandTentaclytronTentaclesComponent TentaclesComp;
}
