class UTundra_SimonSaysPerchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	ATundra_SimonSaysManager Manager;
	UTundra_SimonSaysPlayerComponent PlayerComp;
	UTundra_SimonSaysAnimDataComponent AnimComp;
	UPlayerPerchComponent PerchComp;
	UTundra_SimonSaysPlayerSettings Settings;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		Manager = TundraSimonSays::GetManager();
		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		AnimComp = UTundra_SimonSaysAnimDataComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
		Settings = UTundra_SimonSaysPlayerSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysPerchActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PlayerComp.CurrentPerchedTile == nullptr)
			Params.PerchedTile = Manager.GetTileForPlayer(Player, 0);
		else
			Params.PerchedTile = PlayerComp.CurrentPerchedTile;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysPerchDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(PlayerComp.CurrentPerchedTile == nullptr)
			return true;

		if(PlayerComp.CurrentPerchedTile.SimonSaysTargetable.IsDisabled())
		{
			Params.bShouldKill = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysPerchActivatedParams Params)
	{
		PlayerComp.CurrentPerchedTile = Params.PerchedTile;

		MoveComp.FollowComponentMovement(PlayerComp.CurrentPerchedTile.SimonSaysTargetable, this);
		MoveComp.ApplyCrumbSyncedRelativePosition(this, PlayerComp.CurrentPerchedTile.SimonSaysTargetable);

		PerchComp.Data.bPerching = true;
		PlayerComp.CurrentPerchedTile.SimonSaysOnPlayerImpact(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysPerchDeactivatedParams Params)
	{
		if(Params.bShouldKill)
			Player.KillPlayer();

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		// This might be null when switching level
		if(PlayerComp.CurrentPerchedTile != nullptr)
			PlayerComp.CurrentPerchedTile.SimonSaysOnPlayerImpactEnd(Player);

		PlayerComp.CurrentPerchedTile = nullptr;
		PerchComp.Data.bPerching = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Target = PlayerComp.CurrentPerchedTile.SimonSaysTargetable.WorldLocation;
				Movement.AddDelta((Target - Player.ActorLocation));

				if(AnimComp.AnimData.bIsFalling)
				{
					Movement.SetRotation(Player.ActorRotation);
				}
				else if(PlayerComp.CurrentPerchTarget != nullptr)
				{
					FQuat TargetRotation = PlayerComp.GetTargetPlayerRotation();
					Movement.InterpRotationTo(TargetRotation, Settings.RotationInterpSpeed);
				}
				else
				{
					Movement.InterpRotationTo(Settings.DefaultForwardDirection.ToOrientationQuat(), Settings.RotationInterpSpeed);
				}
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
}

struct FTundra_SimonSaysPerchActivatedParams
{
	ACongaDanceFloorTile PerchedTile;
}

struct FTundra_SimonSaysPerchDeactivatedParams
{
	bool bShouldKill = false;
}