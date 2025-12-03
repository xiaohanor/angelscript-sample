class UVerticalSerpentPlayerFreefallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10.0;

	AVerticalSerpent VerticalSerpent;

	USteppingMovementData Movement;
	UPlayerMovementComponent MoveComp;

	FVector VerticalLocation;
	float Gravity = 1000.0;
	float MoveSpeed = 1500.0;

	float Timer;
	float Duration = 3.0;

	FVector StartLoc;
	FVector RelativeStart;
	FVector RelativeEnd;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		VerticalSerpent = TListedActors<AVerticalSerpent>().GetSingle();
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!VerticalSerpent.bVerticalAllowed)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!VerticalSerpent.bVerticalAllowed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);

		VerticalLocation = VerticalSerpent.ActorLocation - FVector::UpVector * 20000.0;
		VerticalLocation.X = 0.0;
		VerticalLocation.Y = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			VerticalLocation -= FVector::UpVector * Gravity * DeltaTime;
			FVector DesiredLocation = VerticalSerpent.ActorLocation;
			DesiredLocation.Z = VerticalLocation.Z;

			FVector PlayerOffsets;
			PlayerOffsets = Player.IsZoe() ? VerticalSerpent.ActorRightVector * 300.0 : -VerticalSerpent.ActorRightVector * 300.0;
			DesiredLocation += PlayerOffsets;

			FVector MoveToDirection = (DesiredLocation - Player.ActorLocation).GetSafeNormal();

			FVector FrameMove = MoveToDirection * MoveSpeed * DeltaTime;
			FVector Delta = DesiredLocation - Player.ActorLocation;

			if (Delta.Size() < FrameMove.Size())
			{
				FrameMove = Delta;
			}

			Movement.AddDelta(FrameMove);
			// Movement.AddOwnerVerticalVelocity();
			// Movement.AddGravityAcceleration();

			// if (Player.IsMio())
			// {
			// 	Debug::DrawDebugSphere(DesiredLocation, 500.0, 12, FLinearColor::Red, 20.0);
			// 	Debug::DrawDebugLine(Player.ActorLocation, DesiredLocation, FLinearColor::Red, 10.0);
			// }
			// else
			// {
			// 	Debug::DrawDebugSphere(DesiredLocation, 500.0, 12, FLinearColor::Green, 20.0);
			// 	Debug::DrawDebugLine(Player.ActorLocation, DesiredLocation, FLinearColor::Green, 10.0);
			// }	
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
	}
};