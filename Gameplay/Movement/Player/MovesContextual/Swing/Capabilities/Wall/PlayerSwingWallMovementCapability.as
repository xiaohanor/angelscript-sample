
class UPlayerSwingWallMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingWall);
	default CapabilityTags.Add(PlayerSwingTags::SwingMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 12;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	
	UPlayerSwingComponent SwingComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!SwingComp.Data.HasValidSwingPoint())
			return;

		SwingComp.TraceForWall(Player, MoveComp.Velocity, SwingComp.Data);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
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

		if (!SwingComp.Data.HasValidWall())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.AnimData.State = EPlayerSwingState::Swing;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;

			FVector PlayerToSwingPointDirection = SwingComp.PlayerToSwingPoint.GetSafeNormal();
			FVector BiTangent = MoveComp.WorldUp.CrossProduct(PlayerToSwingPointDirection);
			FVector SwingSlope = BiTangent.CrossProduct(PlayerToSwingPointDirection);	

			float HorizontalInput = GetAttributeFloat(AttributeNames::MoveRight);
			float VerticalInput = GetAttributeFloat(AttributeNames::MoveForward);

			// Drag;
			FVector Drag = Velocity * 0.8 * DeltaTime;
			Velocity -= Drag;

			/*	Gravity:
				- If you are moving upwards, and tether not taut: Add normal vertical gravity
				- Else: Add swing gravity
			*/
			FVector GravityVelocity;
			if (MoveComp.WorldUp.DotProduct(Velocity) > 0.0 && !SwingComp.Data.bTetherTaut)
				GravityVelocity = -MoveComp.WorldUp * SwingComp.Settings.GravityAcceleration;
			else
			{
				float GravityScale = Math::Pow(SwingSlope.Size(), 0.75);
				GravityVelocity = SwingSlope.GetSafeNormal() * GravityScale * SwingComp.Settings.GravityAcceleration;
			}
			Velocity += GravityVelocity * DeltaTime;

			// Horizontal Movement
			FVector HorizontalAcceleration = -SwingComp.Data.WallRight * HorizontalInput * 800.0 * DeltaTime;
			Velocity += HorizontalAcceleration;

			FVector DeltaMove = Velocity * DeltaTime;
			SwingComp.ConstrainVelocityToSwingPoint(Velocity, DeltaMove);
			
			Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);

			FRotator TargetRotation = FRotator::MakeFromXZ(-SwingComp.Data.WallNormal, MoveComp.WorldUp);
			Movement.SetRotation(Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 620.0));
		
			if (IsDebugActive())
			{
				SwingComp.DebugDrawVelocity(Velocity, MoveComp.WorldUp * 10.0);
				SwingComp.DebugDrawGravity(GravityVelocity, -MoveComp.WorldUp * 10.0);

				Debug::DrawDebugCoordinateSystem(SwingComp.Data.WallLocation, SwingComp.Data.WallRotation, 50.0, 3.0, 0.0);
			}
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
			SwingComp.UpdateTetherTautness(MoveComp.GetCrumbSyncedPosition().WorldVelocity);
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SwingWall");

		SwingComp.DebugDrawTether();
	}
}