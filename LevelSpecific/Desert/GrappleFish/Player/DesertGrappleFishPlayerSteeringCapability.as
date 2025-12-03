class UDesertGrappleFishPlayerSteeringCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Input";

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UDesertGrappleFishPlayerComponent PlayerComp;

	FHazeAcceleratedFloat AccTurn;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;
		
		if (PlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccTurn.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.GrappleFish.PlayerHorizontalInput = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccTurn.AccelerateTo(MoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Y, 1.0, DeltaTime);
		PlayerComp.TurnBS.X = AccTurn.Value;

		float Horizontal = GetAttributeFloat(AttributeNames::MoveRight);
		PlayerComp.GrappleFish.PlayerHorizontalInput = Horizontal;
	}
};