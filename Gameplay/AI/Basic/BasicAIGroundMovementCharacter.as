asset BasicAICharacterGroundPathfollowingSettings of UPathfollowingSettings
{
}

asset BasicAICharacterGroundIgnorePathfindingSettings of UPathfollowingSettings
{
	bIgnorePathfinding = true;
}

UCLASS(Abstract)
class ABasicAIGroundMovementCharacter : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"GroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIGroundMovementCapability"); 

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
    default MoveToComp.DefaultSettings = BasicAICharacterGroundPathfollowingSettings;
}