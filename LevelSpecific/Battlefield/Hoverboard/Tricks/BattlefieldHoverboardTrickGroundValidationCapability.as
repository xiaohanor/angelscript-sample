class UBattlefieldHoverboardTrickGroundValidationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrick);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;

	UPlayerMovementComponent MoveComp;

	UBattlefieldHoverboardTrickSettings TrickSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);

		TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HoverboardComp.IsOn())
			return false;

		if(MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HoverboardComp.IsOn())
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TrickComp.bIsFarEnoughFromGroundToDoTrick = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithPlayer(Player);
		FVector Start = Player.ActorLocation;
		FVector End = Start - Player.ActorUpVector * TrickSettings.TrickGroundValidationTraceLength;

		auto Hit = TraceSettings.QueryTraceSingle(Start, End);
		if(Hit.bBlockingHit)
			TrickComp.bIsFarEnoughFromGroundToDoTrick = false;
		else
			TrickComp.bIsFarEnoughFromGroundToDoTrick = true;

		TEMPORAL_LOG(Player, "Tricks").HitResults("Ground Validation", Hit, FHazeTraceShape::MakeCapsule(Player.ScaledCapsuleRadius, Player.ScaledCapsuleHalfHeight));
	}
};