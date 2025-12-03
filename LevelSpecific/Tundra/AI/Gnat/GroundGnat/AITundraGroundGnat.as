UCLASS(Abstract)
class AAITundraGroundGnat : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"GroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIClimbAlongSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGroundGnatMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGroundGnatBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatSquashedReactionCapability");

    default MoveToComp.DefaultSettings = BasicAICharacterGroundPathfollowingSettings;

	UPROPERTY(DefaultComponent)
	UTundraGnatComponent GnatComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SquashComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TundraGnatPlayerAnnoyedCapability");

	UTundraGnatSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UTundraGnatSettings::GetSettings(this);

		// We can climb a lot
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 60.0, this, EHazeSettingsPriority::Defaults);

		// Set spline entrance speed
		UBasicAISettings::SetSplineEntranceMoveSpeed(this, Settings.SplineClimbMoveSpeed, this, EHazeSettingsPriority::Gameplay);

		Super::BeginPlay();
	}
}
