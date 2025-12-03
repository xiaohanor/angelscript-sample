struct FSketchbookHorseCapabilityActivatedParams
{
	ASketchbookHorse Horse;
}

class USketchbookHorseGroundMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USketchbookHorsePlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USketchbookHorsePlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookHorseCapabilityActivatedParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;
			
		Params.Horse = PlayerComp.Horse;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookHorseCapabilityActivatedParams Params)
	{
		if(PlayerComp.Horse == nullptr)
			PlayerComp.Horse = Params.Horse;
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

		if (HasControl())
		{
			FVector Input = MoveComp.MovementInput;

			Movement.AddHorizontalVelocity(Input * 250);

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();
			Movement.AddPendingImpulses();
			Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.45));
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		if(MoveComp.HorizontalVelocity.Size() > SMALL_NUMBER)
		{
			const bool bIsMovingToTheRight = MoveComp.HorizontalVelocity.DotProduct(FVector::RightVector) > 0;
			
			if(bIsMovingToTheRight)
				PlayerComp.Horse.MeshRootComp.SetWorldRotation(FRotator(0, 90, 0));
			else
				PlayerComp.Horse.MeshRootComp.SetWorldRotation(FRotator(0, -90, 0));

			PlayerComp.Horse.PerchPointComp.SetWorldRotation(FRotator(0, PlayerComp.Horse.ActorRotation.Yaw, 0));
		}

		MoveComp.ApplyMove(Movement);
	}
};