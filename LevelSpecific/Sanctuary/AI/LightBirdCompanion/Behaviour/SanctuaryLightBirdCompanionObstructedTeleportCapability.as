struct FLightBirdCompanionObstructedTeleportParams
{
	FVector TeleportLoc;
	FVector TeleportVelocity;
}

class USanctuaryLightBirdCompanionObstructedTeleportCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(n"Teleport");
	default CapabilityTags.Add(n"ObstructionAvoidance");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement; 
	default TickGroupOrder = 118; // After free-flying, before regular obstructed return

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp; 
	USanctuaryLightBirdCompanionSettings Settings;
	UTeleportingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLightBirdCompanionObstructedTeleportParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!Settings.bObstructedAllowNoLOSTeleport)
			return false;
		if (Time::GameTimeSeconds < CompanionComp.FollowTeleportCooldown)
			return false;
		// HACK: This relies on obtructed return capability for now
		if (CompanionComp.State != ELightBirdCompanionState::Obstructed)
			return false;
		if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.FocusLocation, Settings.ObstructedTeleportRange))
			return false;
		if (!CompanionComp.FollowObstruction.IsValidBlockingHit())
			return false;
		if (Time::GetGameTimeSince(CompanionComp.FollowObstructedTime) > 0.2)	
			return false;
		if (CompanionComp.Player.IsPlayerDead())
			return false;

		// Teleport to near side of obstruction
		OutParams.TeleportLoc = CompanionComp.FollowObstruction.Location;
		FVector ClampedVelocity = Owner.ActorVelocity.ClampInsideCone(CompanionComp.Player.FocusLocation - OutParams.TeleportLoc, 30.0);
		OutParams.TeleportVelocity = ClampedVelocity.GetClampedToMaxSize(Settings.FollowFarSpeed);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true; 
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLightBirdCompanionObstructedTeleportParams Params)
	{
		Owner.TeleportActor(Params.TeleportLoc, Params.TeleportVelocity.Rotation(), this);
		Owner.SetActorVelocity(Params.TeleportVelocity);

		// Do not teleport again for a while
		CompanionComp.FollowTeleportCooldown = Time::GameTimeSeconds + 1.0;

		// Abort any other obstruction return
		Owner.BlockCapabilities(n"ObstructionAvoidance", this);
		Owner.UnblockCapabilities(n"ObstructionAvoidance", this);
	}
};