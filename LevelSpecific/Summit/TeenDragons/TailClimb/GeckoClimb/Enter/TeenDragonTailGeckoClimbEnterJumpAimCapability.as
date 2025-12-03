class UTeenDragonTailGeckoClimbEnterJumpAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonClimbEnterJumpRampAim);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Gameplay;

	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	UHazeMovementComponent MoveComp;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UCameraUserComponent CameraUserComp;

	UTeenDragonTailGeckoClimbEnterJumpSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		Settings = UTeenDragonTailGeckoClimbEnterJumpSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TailDragonComp.bRampClimbEnterMode)
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(TailDragonComp.IsClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TailDragonComp.bRampClimbEnterMode)
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(TailDragonComp.IsClimbing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonClimbEnterJumpRampAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonClimbEnterJumpRampAim, this);
		Player.RemoveWidget(GeckoClimbComp.JumpOntoWallWidget);
		GeckoClimbComp.bHasWallEnterLocation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CheckForClimbableWall();
	}

	void CheckForClimbableWall()
	{
		// Check if looking at wall
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);

		Trace.UseLine();
		Trace.IgnoreActor(Player);
		//Trace.IgnoreActor(TeenDragon);

		FVector Start = CameraUserComp.ViewLocation;
		FVector End = Start + CameraUserComp.ViewRotation.ForwardVector * Settings.MaxActivationJumpLength;
		
		FHitResult Hit = Trace.QueryTraceSingle(Start, End);
		
		if(Hit.Actor == nullptr)
		{
			DisableJump();
			return;
		}

		auto ClimbComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
		if(!Hit.bBlockingHit ||  ClimbComp == nullptr)
		{
			DisableJump();
			return;
		}

		if(!ClimbComp.ClimbDirectionIsAllowed(Hit.Normal))
		{
			DisableJump();
			return;
		}
		
		float MaxHeight = Player.ActorLocation.Z + Settings.MaxActivationJumpHeight;
		float MinHeight = Player.ActorLocation.Z + Settings.MinActivationJumpHeight;

		float TargetHeight = Math::Clamp(Hit.Location.Z, MinHeight, MaxHeight);
		FVector TargetLocation = Hit.Location;
		TargetLocation.Z = TargetHeight;

		GeckoClimbComp.WallEnterClimbParams.Location = TargetLocation;
		GeckoClimbComp.WallEnterClimbParams.WallNormal = Hit.ImpactNormal;
		GeckoClimbComp.WallEnterClimbParams.ClimbUpVector = Hit.ImpactNormal;
		GeckoClimbComp.WallEnterClimbParams.ClimbComp = ClimbComp;
		GeckoClimbComp.JumpOntoWallSpeed = Settings.ActivationJumpSpeed;
		GeckoClimbComp.bHasWallEnterLocation = true;
		
		if(!GeckoClimbComp.JumpOntoWallWidget.bIsAdded)
			Player.AddExistingWidget(GeckoClimbComp.JumpOntoWallWidget);
		GeckoClimbComp.JumpOntoWallWidget.SetWidgetWorldPosition(TargetLocation);
	}

	void DisableJump()
	{
		GeckoClimbComp.bHasWallEnterLocation = false;
		if (GeckoClimbComp.JumpOntoWallWidget.bIsAdded)
			Player.RemoveWidget(GeckoClimbComp.JumpOntoWallWidget);
	}
};