struct FSanctuaryDarkPortalCompanionTeleportParams
{
	FVector Location;
	FRotator Rotation;
}

class USanctuaryDarkPortalCompanionPlayerTeleportCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalRecall);
	default CapabilityTags.Add(BasicAITags::Behaviour); // If we don't want this tag, make sure to block this when controlled by cutscene
	default CapabilityTags.Add(n"Teleport");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	float PlayerTeleportTime = -1.0;
	FVector PreviousPlayerLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::Get(Owner);
		auto PlayerTeleportComp = UTeleportResponseComponent::GetOrCreate(Game::Zoe);
		PlayerTeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported"); 
		PlayerTeleportTime = Time::GameTimeSeconds; // Initial placement in test levels is not done by teleport
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (CompanionComp.Player == nullptr)
			return;
		PreviousPlayerLoc = CompanionComp.Player.ActorLocation;
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
		if (CompanionComp.Player.ActorLocation.IsWithinDist(PreviousPlayerLoc, 2000.0))
			return;  // Ignore short teleports
		PlayerTeleportTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryDarkPortalCompanionTeleportParams& OutParams) const
	{
		if (PlayerTeleportTime < 0.0)
			return false;
		if (!CompanionComp.IsFreeFlying())
			return false;
		if (Game::Zoe.ViewLocation.IsZero())
			return false; // View has not been initialized
		if (Time::GetGameTimeSince(PlayerTeleportTime) > 1.0)
		{
			// Not a recent teleport, we'll only follow along if obstructed and far away
			if (!CompanionComp.bObstructed)
				return false;
			if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.ActorLocation, 5000.0))
				return false;
		}
		OutParams.Location = DarkPortalCompanion::GetWatsonTeleportLocation(Game::Zoe);
		OutParams.Rotation = Game::Zoe.ViewRotation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryDarkPortalCompanionTeleportParams Params)
	{
		PlayerTeleportTime = -1.0;	

		Owner.TeleportActor(Params.Location, Params.Rotation, this);

		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		UDarkPortalEventHandler::Trigger_CompanionWatsonTeleport(Owner);
		UDarkPortalEventHandler::Trigger_CompanionWatsonTeleport(CompanionComp.Player);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Params.Location, CompanionComp.Player.ActorLocation, FLinearColor::Yellow, 10, 10);
			Debug::DrawDebugSphere(Params.Location, 20, 4, FLinearColor::Yellow, 10, 10);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
	}
};		