class UMoonMarketBouncyBallBlasterRollingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	AMoonMarketBouncyBallBlaster BallBlaster;

	UHazeMovementComponent MoveComp;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBlaster = Cast<AMoonMarketBouncyBallBlaster>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
};