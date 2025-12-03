class UCentipedeSwingJumpTargetComponent : UContextualMovesTargetableComponent
{
	default TargetableCategory = n"CentipedeSwing";

	private FVector PreviousLocation;
	private FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		PreviousLocation = WorldLocation;
	}

	FVector GetJumpImpulseForPlayer(AHazePlayerCharacter Player, float GravityMagnitude) const
	{
		return FVector::ZeroVector;
	}

	FVector GetNormalVector() const
	{
		return UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Eman TODO: Maybe optimize by means of swing point (de)activation?
		// Used for moving targets
		Velocity = WorldLocation - PreviousLocation;
		PreviousLocation = WorldLocation;
	}

	FVector GetVelocity() const
	{
		return Velocity;
	}
}