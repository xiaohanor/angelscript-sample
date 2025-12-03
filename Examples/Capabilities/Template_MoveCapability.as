class UTemplateMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);	
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	//USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		//Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
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
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			Movement.AddOwnerVelocity();
			Movement.AddGravityAcceleration();

			Movement.SetRotation(Owner.ActorRotation);

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Tag");
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
			//Movement.ApplyCrumbSyncedAirMovement();
		}
	}
}