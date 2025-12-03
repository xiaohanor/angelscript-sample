class UTeenDragonTailGeckoClimbDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	UHazeMovementComponent MoveComp;
	UTeenDragonTailGeckoClimbSettings ClimbSettings;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		
		Movement = MoveComp.SetupSteppingMovementData();

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GeckoClimbComp.WallClimbRespawnParams.IsSet())
			return true;

		if(DragonComp.IsClimbing())
			return true;

		if(GeckoClimbComp.bForceRespawnOnWall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// The player is now dead,
		// so when it respawns, the tickactive will handle the wall climb setup
		// even if it first spawns on the remote side
		if(Player.IsPlayerDead())
			return false;

		if(GeckoClimbComp.WallClimbRespawnParams.IsSet())
			return false;

		if(DragonComp.IsClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GeckoClimbComp.bWallClimbRespawnAllowed = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoClimbComp.bWallClimbRespawnAllowed = false;
		GeckoClimbComp.WallClimbRespawnParams.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// the player has now been spawned
		if(!Player.IsPlayerDead() && GeckoClimbComp.WallClimbRespawnParams.IsSet())
		{
			FTeenDragonTailClimbParams Params = GeckoClimbComp.WallClimbRespawnParams.GetValue();
			GeckoClimbComp.WallClimbRespawnParams.Reset();

			GeckoClimbComp.UpdateClimbParams(Params);
			GeckoClimbComp.SetCameraTransitionAlphaTarget(1.0, ClimbSettings.CameraTransitionJumpOnWallSpeed);
			GeckoClimbComp.bHasLandedOnWall = true;
			GeckoClimbComp.bHasReachedWall = true;
			
			if (MoveComp.PrepareMove(Movement, GeckoClimbComp.GetClimbUpVector()))
			{
				MoveComp.ApplyMove(Movement);
				DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
			}

			GeckoClimbComp.StartClimbing();
		}
	}
};