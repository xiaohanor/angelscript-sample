class UTundra_SimonSaysMonkeyKingDanceJumpCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	FTundra_SimonSaysSequence CurrentSequence;
	TArray<ATundra_SimonSaysMonkeyKingTile> Tiles;

	ATundra_SimonSaysManager Manager;
	ATundra_SimonSaysMonkeyKing Monkey;
	UTundra_SimonSaysAnimDataComponent AnimComp;
	UTundra_SimonSaysMonkeyKingSettings Settings;
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	FVector Origin;
	FVector Destination;
	int TargetTileIndex;
	bool bLit = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = TundraSimonSays::GetManager();
		Monkey = Cast<ATundra_SimonSaysMonkeyKing>(Owner);
		AnimComp = UTundra_SimonSaysAnimDataComponent::GetOrCreate(Monkey);
		Settings = UTundra_SimonSaysMonkeyKingSettings::GetSettings(Monkey);
		MoveComp = Monkey.MoveComp;
		Movement = MoveComp.SetupTeleportingMovementData();
		Manager.GetTilesForMonkeyKing(Tiles);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Manager.MonkeyKingMoveData.bShouldBeActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.MonkeyKingMoveData.bShouldBeActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetTileIndex = Manager.MonkeyKingMoveData.TargetTileIndex;
		Origin = Monkey.ActorLocation;
		Monkey.CurrentTargetPoint = Tiles[TargetTileIndex].MonkeyKingTargetPoint;
		Destination = Monkey.CurrentTargetPoint.WorldLocation;
		AnimComp.AnimData.bIsJumping = true;
		bLit = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Tiles[TargetTileIndex].Disable(this);
		AnimComp.AnimData.bIsJumping = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = Manager.MonkeyKingMoveData.MoveAlpha;
				Alpha /= (1.0 - Settings.MoveRatioToBeStillFor);
				Alpha = Math::Saturate(Alpha);

				if(Alpha > 0.9)
				{
					AnimComp.AnimData.bIsJumping = false;
				}

				if(!bLit && Alpha == 1.0 && !Manager.IgnoredTiles.Contains(TargetTileIndex))
				{
					CrumbEnableTile(Tiles[TargetTileIndex], TargetTileIndex);
					bLit = true;
				}

				FVector CurrentLocation = BezierCurve::GetLocation_2CP_ConstantSpeed(Origin, Origin + FVector::UpVector * Settings.BezierControlPointHeight, Destination + FVector::UpVector * Settings.BezierControlPointHeight, Destination, Alpha);

				Movement.AddDelta(CurrentLocation - Monkey.ActorLocation);

				if(Settings.bRotateTowardsDestinationPoint)
				{
					Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, (Destination - Origin)), Settings.TurnRate);
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

	UFUNCTION(CrumbFunction)
	private void CrumbEnableTile(ATundra_SimonSaysMonkeyKingTile MonkeyKingTile, int TileIndex)
	{
		FTundra_SimonSaysManagerMonkeyKingTileEffectParams Params;
		Params.Tile = MonkeyKingTile;
		Params.TileType = TundraSimonSays::PointIndexToEffectTileType(TileIndex);
		Params.TileColor = MonkeyKingTile.CurrentColor;
		Params.TileTargetColor = MonkeyKingTile.InstigatedColor.Get();
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnMonkeyKingSuccessfulLand(Manager, Params);
		MonkeyKingTile.Enable(this);
	}
}