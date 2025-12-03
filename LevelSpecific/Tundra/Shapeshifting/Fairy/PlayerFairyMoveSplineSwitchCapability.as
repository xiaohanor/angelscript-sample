class UTundraPlayerFairyMoveSplineSwitchCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	UTundraPlayerFairyComponent FairyComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UTundraPlayerFairySettings Settings;

	ATundraFairyMoveSplineSwitchTargetableActor CurrentTargetableActor;
	bool bMoveDone = false;
	FVector Velocity;
	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked() && FairyComp.bIsOnMoveSpline)
		{
			TargetablesComp.ShowWidgetsForTargetables(UTundraFairyMoveSplineSwitchTargetableComponent);
			if(IsDebugActive())
			{
				auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UTundraFairyMoveSplineSwitchTargetableComponent);

				if(PrimaryTarget == nullptr)
					return;

				ATundraFairyMoveSplineSwitchTargetableActor Current = Cast<ATundraFairyMoveSplineSwitchTargetableActor>(PrimaryTarget.Owner);
				CalculateTrajectory(Current);
				Trajectory::DebugDrawTrajectoryWithDestination(StartLocation, TargetLocation, Velocity, -FVector::UpVector, MoveComp.GravityForce);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraFairyMoveSplineSwitchCapabilityActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::MovementJump))
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UTundraFairyMoveSplineSwitchTargetableComponent);

		if(PrimaryTarget == nullptr)
			return false;
		
		if(!FairyComp.bIsOnMoveSpline)
			return false;

		Params.TargetableActor = Cast<ATundraFairyMoveSplineSwitchTargetableActor>(PrimaryTarget.Owner);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraFairyMoveSplineSwitchCapabilityActivatedParams Params)
	{
		CurrentTargetableActor = Params.TargetableActor;
		bMoveDone = false;
		FairyComp.bSwitchingSpline = true;

		CalculateTrajectory(CurrentTargetableActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FairyComp.bSwitchingSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Velocity += MoveComp.GravityDirection * MoveComp.GravityForce * DeltaTime;
				FVector Delta = Velocity * DeltaTime;
				FVector CurrentLocation = Player.ActorLocation;

				if(Delta.Size2D() > CurrentLocation.DistXY(TargetLocation))
				{
					Movement.AddDeltaWithCustomVelocity(TargetLocation - CurrentLocation, Velocity);
					bMoveDone = true;
				}
				else
				{
					Movement.AddDelta(Delta);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"FairyWindTunnel");
		}
	}

	void CalculateTrajectory(ATundraFairyMoveSplineSwitchTargetableActor TargetableActor)
	{
		float ActorHalfHeight = Player.ScaledCapsuleHalfHeight;
		StartLocation = Player.ActorLocation;
		TargetLocation = TargetableActor.ActorLocation + FVector::UpVector * (TargetableActor.ParentSpline.StartSpiralRadius - ActorHalfHeight);
		FVector Forward = FairyComp.CurrentMoveSpline.Spline.GetClosestSplineWorldRotationToWorldLocation(StartLocation).ForwardVector;
		float CurrentHorizontalSpeed = TargetableActor.ParentSpline.MaxSpeed / (TargetLocation - StartLocation).GetSafeNormal2D().DotProduct(Forward);
		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(StartLocation, TargetLocation, MoveComp.GravityForce, CurrentHorizontalSpeed);
	}
}

struct FTundraFairyMoveSplineSwitchCapabilityActivatedParams
{
	ATundraFairyMoveSplineSwitchTargetableActor TargetableActor;
}