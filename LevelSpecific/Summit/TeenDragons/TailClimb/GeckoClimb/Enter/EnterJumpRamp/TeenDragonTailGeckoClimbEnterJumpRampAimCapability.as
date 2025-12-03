struct FTeenDragonTailGeckoClimbEnterJumpRampParams
{
	float AttachMinHeightAbovePlatform;
	float AttachMaxHeightAbovePlatform;
	float AttachJumpSpeed;
	float WallMaxDistance;
	bool bOverrideDefaultJumpCurve;
	FRuntimeFloatCurve JumpSpeedCurve;
}

class UTeenDragonTailGeckoClimbEnterJumpRampAimCapability : UHazePlayerCapability
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

	FTeenDragonTailGeckoClimbEnterJumpRampParams CurrentParams;

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
	bool ShouldActivate(FTeenDragonTailGeckoClimbEnterJumpRampParams& Params) const
	{
		if(!TailDragonComp.bRampClimbEnterMode)
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(TailDragonComp.IsClimbing())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;
		
		// Check if on ramp
		FMovementHitResult GroundHit = MoveComp.GroundContact;
		auto RampComp = USummitTailGeckoClimbJumpRampComponent::Get(GroundHit.Actor);

		if(RampComp == nullptr)
			return false;
		
		Params.AttachJumpSpeed = RampComp.AttachJumpSpeed;
		Params.AttachMaxHeightAbovePlatform = RampComp.AttachMaxHeightAbovePlatform;
		Params.AttachMinHeightAbovePlatform = RampComp.AttachMinHeightAbovePlatform;
		Params.WallMaxDistance = RampComp.WallMaxDistance;
		Params.bOverrideDefaultJumpCurve = RampComp.bOverrideDefaultJumpCurve;
		Params.JumpSpeedCurve = RampComp.JumpSpeedCurve;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TailDragonComp.bRampClimbEnterMode)
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(TailDragonComp.IsClimbing())
			return true;
		
		// Check if on ramp
		FMovementHitResult GroundHit = MoveComp.GroundContact;
		auto RampComp = USummitTailGeckoClimbJumpRampComponent::Get(GroundHit.Actor);

		if(RampComp == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailGeckoClimbEnterJumpRampParams Params)
	{
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonClimbEnterJumpRampAim, this);
		CurrentParams = Params;
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

		float MaxHeight = Player.ActorLocation.Z + CurrentParams.AttachMaxHeightAbovePlatform;
		float MinHeight = Player.ActorLocation.Z + CurrentParams.AttachMinHeightAbovePlatform;

		float TargetHeight = Math::Clamp(Hit.Location.Z, MinHeight, MaxHeight);
		FVector TargetLocation = Hit.Location;
		TargetLocation.Z = TargetHeight;
		
		GeckoClimbComp.WallEnterClimbParams.Location = TargetLocation;
		GeckoClimbComp.WallEnterClimbParams.WallNormal = Hit.ImpactNormal;
		GeckoClimbComp.WallEnterClimbParams.ClimbUpVector = Hit.ImpactNormal;
		GeckoClimbComp.WallEnterClimbParams.ClimbComp = ClimbComp;
		GeckoClimbComp.JumpOntoWallSpeed = CurrentParams.AttachJumpSpeed;

		if(CurrentParams.bOverrideDefaultJumpCurve)
			GeckoClimbComp.CurrentJumpOntoWallCurve = CurrentParams.JumpSpeedCurve;
		else
			GeckoClimbComp.CurrentJumpOntoWallCurve = Settings.DefaultJumpSpeedCurve;
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