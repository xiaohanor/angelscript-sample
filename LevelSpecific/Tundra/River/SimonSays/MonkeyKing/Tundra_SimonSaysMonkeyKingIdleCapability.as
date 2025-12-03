class UTundra_SimonSaysMonkeyKingIdleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Idle");

	ATundra_SimonSaysMonkeyKing Monkey;
	UTundra_SimonSaysAnimDataComponent AnimComp;
	UTundra_SimonSaysMonkeyKingSettings Settings;
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	ATundra_SimonSaysManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ATundra_SimonSaysMonkeyKing>(Owner);
		AnimComp = UTundra_SimonSaysAnimDataComponent::GetOrCreate(Owner);
		Settings = UTundra_SimonSaysMonkeyKingSettings::GetSettings(Owner);
		Manager = TundraSimonSays::GetManager();
		MoveComp = Monkey.MoveComp;
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(Monkey.CurrentTargetPoint != nullptr)
					Movement.AddDelta(Monkey.CurrentTargetPoint.WorldLocation - Monkey.ActorLocation);
				
				if(Settings.bRotateTowardsDestinationPoint)
				{
					Movement.InterpRotationTo(Monkey.OriginalRotation.Quaternion(), Settings.TurnRate);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FVector PreviousForward = Monkey.ActorForwardVector;
			MoveComp.ApplyMove(Movement);
			AnimComp.UpdateTurnRate(PreviousForward, Monkey.ActorForwardVector, DeltaTime);
			if(Monkey.MeshComp.CanRequestLocomotion())
			{
				Monkey.MeshComp.RequestLocomotion(n"SimonSays", this);
			}
		}
	}
}