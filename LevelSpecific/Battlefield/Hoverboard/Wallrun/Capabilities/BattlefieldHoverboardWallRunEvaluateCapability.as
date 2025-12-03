
class UBattlefieldHoverboardWallRunEvaluateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunEvaluate);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 31;

	default DebugCategory = n"Hoverboard";

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardWallRunComponent WallRunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WallRunComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (WallRunComp.State == EPlayerWallRunState::WallRun)
			return true;

		if (WallRunComp.State == EPlayerWallRunState::WallRunLedge)
			return true;

		if (WallRunComp.State == EPlayerWallRunState::WallRunLedgeTurnaround)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WallRunComp.State == EPlayerWallRunState::WallRun)
			return false;

		if (WallRunComp.State == EPlayerWallRunState::WallRunLedge)
			return false;

		if (WallRunComp.State == EPlayerWallRunState::WallRunLedgeTurnaround)
			return false;
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WallRunComp.PreviousData.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		WallRunComp.PreviousData = WallRunComp.ActiveData;

		FVector TraceDirection = -WallRunComp.ActiveData.WallRotation.ForwardVector;
		WallRunComp.ActiveData = WallRunComp.TraceForWallRun(Player, TraceDirection);

		// On the remote side it can happen that we don't find the wall (inaccuracy in positions, small desyncs, etc)
		// In that case we want to keep the previous wallrun data, so we can still animate somewhat naturally
		if (!HasControl() && !WallRunComp.ActiveData.HasValidData() && WallRunComp.PreviousData.HasValidData())
			WallRunComp.ActiveData = WallRunComp.PreviousData;
	}
}