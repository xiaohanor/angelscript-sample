class URemoteHackableRobotVacuumCapability : URemoteHackableBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableRobotVacuum RobotVacuum;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	FVector Velocity = FVector::ZeroVector;
	float MoveSpeed = 300.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		RobotVacuum = Cast<ARemoteHackableRobotVacuum>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Velocity = Owner.ActorForwardVector;
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
			FVector Input = PlayerMoveComp.MovementInput;
			Velocity = Math::VInterpTo(Velocity, Input * MoveSpeed, DeltaTime, 2.0);
			FVector DeltaMove = Velocity * DeltaTime;

			FRotator TargetRotation = Velocity.Rotation();
			if (Input.Equals(::FVector::ZeroVector))
				TargetRotation = Owner.ActorRotation;

			PrintToScreen("" + TargetRotation);

			FRotator Rot = Math::RInterpTo(Owner.ActorRotation, TargetRotation, DeltaTime, 4.0);
			Movement.SetRotation(Rot);
			Movement.AddDelta(DeltaMove);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		float VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, MoveSpeed), FVector2D(0.0, 1.0), MoveComp.Velocity.Size());
		RobotVacuum.LeftWheelRoot.AddLocalRotation(FRotator(0.0, 0.0, 500.0 * VelocityAlpha * DeltaTime));
		RobotVacuum.RightWheelRoot.AddLocalRotation(FRotator(0.0, 0.0, -500.0 * VelocityAlpha * DeltaTime));

		MoveComp.ApplyMove(Movement);
	}
}