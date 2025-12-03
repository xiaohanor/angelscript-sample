
class UDentistSplitToothAIStartledTurnAroundCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ADentistSplitToothAI SplitToothAI;

	UHazeMovementComponent MoveComp;
	UDentistToothMovementData Movement;

	FQuat InitialRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);

		MoveComp = SplitToothAI.MoveComp;
		Movement = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SplitToothAI.Settings.StartledTurnAroundDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialRotation = SplitToothAI.AccRotation.Value;
		
		UDentistSplitToothAIEventHandler::Trigger_OnStartledStartTurningAround(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();

			FVector HorizontalDirectionToPlayer = (SplitToothAI.OwningPlayer.ActorLocation - SplitToothAI.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, HorizontalDirectionToPlayer);

			const float Alpha = Math::Saturate(ActiveDuration / SplitToothAI.Settings.StartledTurnAroundDuration);
			FQuat Rotation = FQuat::Slerp(InitialRotation, TargetRotation, Alpha);
			Movement.SetRotation(Rotation);

			MoveComp.ApplyMovementInput(FVector::ZeroVector, this);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};