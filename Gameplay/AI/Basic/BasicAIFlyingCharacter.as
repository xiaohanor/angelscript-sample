
asset BasicAIFlyingPathfindingMoveToSettings of UPathfollowingSettings
{
	UpdatePathDistance = 200.0;
	AtDestinationRange = 100.0;
	AtWaypointRange = 60.0;
	OutsideNavmeshEndRange = 100.0;
	OutsideNavmeshStartRange = 100.0;
}

asset BasicAIFlyingIgnorePathfindingMoveToSettings of UPathfollowingSettings
{
	bIgnorePathfinding = true;
	AtDestinationRange = 100.0;
}


UCLASS(Abstract)
class ABasicAIFlyingCharacter : ABasicAICharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	UPROPERTY(DefaultComponent)
	UBasicAIFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		RespawnComp.OnRespawn.AddUFunction(FlightComp, n"Reset");
	}
}