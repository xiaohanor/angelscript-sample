UCLASS(Abstract)
class ABasicAIWallclimbingCharacter : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"WallclimbingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIWallclimbingMovementCapability"); 
	
	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
	}
}