UCLASS(Abstract)
class AAIPrisonGuardBot : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardBotFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardBotRemoteHackableCapability");

	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	bool bIsControlledByPlayer = false;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseComponent RemoteHackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	UPROPERTY(DefaultComponent)
	UBasicAIFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorControlSide(Game::Mio);
		RespawnComp.OnRespawn.AddUFunction(this, n"Respawned");
		RespawnComp.OnRespawn.AddUFunction(FlightComp, n"Reset");
	}

	UFUNCTION()
	private void Respawned()
	{
		RemoteHackingResponseComp.SetHackingAllowed(true);
		bIsControlledByPlayer = false;
	}
}