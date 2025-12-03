class UTundra_SimonSaysPerchJumpCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 12;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraSimonSays::SimonSaysPerchJump);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	ATundra_SimonSaysManager Manager;
	UTundra_SimonSaysPlayerComponent PlayerComp;
	UTundra_SimonSaysAnimDataComponent AnimComp;
	UTundra_SimonSaysPlayerSettings Settings;

	UTundra_SimonSaysPerchPointTargetable OriginComp;
	UTundra_SimonSaysPerchPointTargetable DestinationComp;
	ACongaDanceFloorTile Target;

	bool bMoveDone = false;
	FQuat TargetRotation;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		Manager = TundraSimonSays::GetManager();
		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		AnimComp = UTundra_SimonSaysAnimDataComponent::GetOrCreate(Player);
		Settings = UTundra_SimonSaysPlayerSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PlayerComp.CurrentPerchTarget == nullptr)
			return false;

		// Since we are using WasActionStartedDuringTime it is possible that we will trigger a jump to a tile
		// just as the current perched tile is disabled, in this case we want to kill the player so don't allow jumping!
		if(PlayerComp.CurrentPerchedTile.SimonSaysTargetable.IsDisabled())
			return false;

		// If we are rotating, don't jump!
		// if(!Player.ActorQuat.Equals(PlayerComp.GetTargetPlayerRotation()))
		// 	return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
			return false;

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
	void OnActivated()
	{
		if(HasControl())
		{
			bMoveDone = false;
			Target = PlayerComp.CurrentPerchTarget;
			OriginComp = PlayerComp.CurrentPerchedTile.SimonSaysTargetable;
			DestinationComp = Target.SimonSaysTargetable;

			float HorizontalDistance = OriginComp.WorldLocation.DistXY(DestinationComp.WorldLocation);
			FVector TargetLocation = GetTargetLocation(Target);
			FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(OriginComp.WorldLocation, TargetLocation, MoveComp.GetGravityForce(), HorizontalDistance / MoveDuration);
			Player.SetActorVelocity(Velocity);

			TargetRotation = (DestinationComp.WorldLocation - OriginComp.WorldLocation).GetSafeNormal2D().ToOrientationQuat();
		}

		AnimComp.AnimData.bIsJumping = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			CrumbSetCurrentPerchedTile(Target);

		AnimComp.AnimData.bIsJumping = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector CurrentLocation = Player.ActorLocation;
				FVector Delta = MoveComp.Velocity * DeltaTime;
				FVector TargetLocation = CurrentLocation + Delta;
				FVector DestinationToCurrent = (CurrentLocation - DestinationComp.WorldLocation).GetSafeNormal2D(0.0);
				FVector DestinationToTarget = (TargetLocation - DestinationComp.WorldLocation).GetSafeNormal2D(0.0);

				if(DestinationToCurrent.DotProduct(DestinationToTarget) < 0.0 ||
					(TargetLocation.X == DestinationComp.WorldLocation.X && TargetLocation.Y == DestinationComp.WorldLocation.Y))
				{
					bMoveDone = true;
					Movement.AddDelta(DestinationComp.WorldLocation - Player.ActorLocation);
				}
				else
				{
					Movement.AddOwnerVelocity();
					Movement.AddGravityAcceleration();
				}

				Movement.InterpRotationTo(TargetRotation, Settings.RotationInterpSpeed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FVector PreviousForward = Player.ActorForwardVector;
			MoveComp.ApplyMove(Movement);
			AnimComp.UpdateTurnRate(PreviousForward, Player.ActorForwardVector, DeltaTime);
			if(Player.Mesh.CanRequestLocomotion())
			{
				Player.Mesh.RequestLocomotion(n"SimonSays", this);
			}
		}
	}

	float GetMoveDuration() property
	{
		return Settings.PerchJumpDuration;
	}

	/* If tile is moving upwards, predict where it is going to be when player lands. If not moving or moving down, don't predict. */
	FVector GetTargetLocation(ACongaDanceFloorTile Tile)
	{
		FVector TargetLocation = Tile.SimonSaysTargetable.WorldLocation;

		if(Manager.IsTileBeingMoved(Tile))
		{
			FTundra_SimonSaysMovingTileData Data = Manager.GetMovingTileData(Tile);

			// If we are moving down, don't do any prediction.
			if(!Data.bMoveUp)
				return TargetLocation;

			float TimeSinceStartMove = Time::GetGameTimeSince(Data.TimeOfStartMove);
			float TimeSinceStartMoveWhenPlayerLand = TimeSinceStartMove + MoveDuration;
			float Alpha = Math::Saturate(TimeSinceStartMoveWhenPlayerLand / Data.TotalMoveDuration);
			float MoveAlpha = Data.MoveCurve.GetFloatValue(Alpha);
			FVector TargetTileLocation = Math::Lerp(Data.Origin, Data.Destination, MoveAlpha);
			return TargetTileLocation + (TargetLocation - Tile.ActorLocation);
		}

		return TargetLocation;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetCurrentPerchedTile(ACongaDanceFloorTile Tile)
	{
		PlayerComp.CurrentPerchedTile = Tile;
	}
}