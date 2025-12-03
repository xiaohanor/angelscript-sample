class UPlayerLedgeMantleCloseExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 5;

	UPlayerLedgeMantleComponent MantleComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	float MoveSpeed = 0.0;
	bool bMoveCompleted = false;

	//This capability should bring us from the ledge location to 150 units into the ledge over 0.5 seconds ending in a horizontal velocity of 500
	//Do we expect a constant velocity of 500 (linear translation in animation) OR acceleration up to 500 at the end

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (!MantleComp.Data.bEnterCompleted)
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::LowMantleCloseEnter)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (bMoveCompleted)
			return true;
		
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
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}
};