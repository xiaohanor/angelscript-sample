struct FDarkPortalCompanionOutOfViewTeleportParams
{
	FVector TeleportLoc;
	FVector TeleportVelocity;
}

class USanctuaryDarkPortalCompanionOutOfViewTeleportCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(n"Teleport");
	default CapabilityTags.Add(n"ObstructionAvoidance");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement; 
	default TickGroupOrder = 116; // After free-flying, before regular obstructed return

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp; 
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;

	TPerPlayer<UTargetTrailComponent> TrailComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
		TrailComps[Game::Mio] = UTargetTrailComponent::GetOrCreate(Game::Mio);
		TrailComps[Game::Zoe] = UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalCompanionOutOfViewTeleportParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!Settings.bObstructedAllowOutOfViewTeleport)
			return false;
		if (Time::GameTimeSeconds < CompanionComp.FollowTeleportCooldown)
			return false;
		// HACK: This relies on obtructed return capability for now
		if (CompanionComp.State != EDarkPortalCompanionState::Obstructed)
			return false;
		if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.FocusLocation, Settings.ObstructedTeleportRange))
			return false;
		if (SceneView::IsInView(CompanionComp.Player, Owner.ActorLocation))
			return false;

		// Teleport in behind player 
		AHazePlayerCharacter ViewPlayer = SceneView::FullScreenPlayer;
		if (ViewPlayer == nullptr)
			ViewPlayer = CompanionComp.Player;
		OutParams.TeleportLoc = DarkPortalCompanion::GetWatsonTeleportLocation(ViewPlayer);
		FVector Velocity = TrailComps[CompanionComp.Player].GetAverageVelocity(0.5);
		if (!Velocity.IsNearlyZero(50.0))
			Velocity = Velocity.GetSafeNormal() * Math::Max(0.0, Velocity.DotProduct(ViewPlayer.ViewRotation.ForwardVector));
		OutParams.TeleportVelocity = Velocity.GetClampedToMaxSize(Settings.FollowFarSpeed);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true; 
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDarkPortalCompanionOutOfViewTeleportParams Params)
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