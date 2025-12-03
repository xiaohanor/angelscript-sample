
class UPlayerSwingWallJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingWall);
	default CapabilityTags.Add(PlayerSwingTags::SwingMovement);
	default CapabilityTags.Add(PlayerSwingTags::SwingJump);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;	
	UPlayerSwingComponent SwingComp;
	USweepingMovementData Movement;

	const float Duration = 0.6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!IsActioning(ActionNames::MovementJump))
			return false;

		if (!SwingComp.HasActivateSwingPoint())
			return false;

		if (!SwingComp.Data.HasValidWall())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SwingComp.HasActivateSwingPoint())
			return true;

		if (ActiveDuration >= Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.AnimData.State = EPlayerSwingState::Jump;

		FVector Impulse = SwingComp.Data.WallNormal * 600.0;
		Player.SetActorVelocity(MoveComp.Velocity + Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = MoveComp.Velocity;
				
				FVector GravityAcceleration = -MoveComp.WorldUp * SwingComp.Settings.GravityAcceleration * DeltaTime;
				Velocity += GravityAcceleration;

				FVector DeltaMove = Velocity * DeltaTime;
				SwingComp.ConstrainVelocityToSwingPoint(Velocity, DeltaMove);

				Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				SwingComp.UpdateTetherTautness(MoveComp.GetCrumbSyncedPosition().WorldVelocity);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");

			// Debug Draw
			if (IsDebugActive())
				SwingComp.DebugDrawTether();
		}
	}
}