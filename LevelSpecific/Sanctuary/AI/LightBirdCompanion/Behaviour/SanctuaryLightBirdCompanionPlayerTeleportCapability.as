struct FSanctuaryLightBirdCompanionTeleportParams
{
	FVector Location;
	FRotator Rotation;
}

class USanctuaryLightBirdCompanionPlayerTeleportCapability : UHazeCapability
{
	default CapabilityTags.Add(LightBird::Tags::LightBirdRecall);
	default CapabilityTags.Add(BasicAITags::Behaviour); // If we don't want this tag, make sure to block this when controlled by cutscene
	default CapabilityTags.Add(n"Teleport");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	float PlayerTeleportTime = -1.0;
	FVector PreviousPlayerLoc;
	TArray<UNiagaraComponent> AttachedEffects;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::Get(Owner);
		auto PlayerTeleportComp = UTeleportResponseComponent::GetOrCreate(Game::Mio);
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
	bool ShouldActivate(FSanctuaryLightBirdCompanionTeleportParams& OutParams) const
	{
		if (PlayerTeleportTime < 0.0)
			return false;
		if (!CompanionComp.IsFreeFlying())
			return false;
		if (Game::Mio.ViewLocation.IsZero())
			return false; // View has not been initialized
		if (Time::GetGameTimeSince(PlayerTeleportTime) > 1.0)
		{
			// Not a recent teleport, we'll only follow along if obstructed and far away
			if (CompanionComp.State != ELightBirdCompanionState::Obstructed)
				return false;
			if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.ActorLocation, 5000.0))
				return false;
		}
		OutParams.Location = LightBirdCompanion::GetWatsonTeleportLocation(Game::Mio);
		OutParams.Rotation = Game::Mio.ViewRotation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLightBirdCompanionTeleportParams Params)
	{
		PlayerTeleportTime = -1.0;	

		AttachedEffects.Reset(AttachedEffects.Num());
		Owner.GetComponentsByClass(AttachedEffects);
		for (UNiagaraComponent Effect : AttachedEffects)
		{
			// Turn off trail etc so we won't get streaks of these in front of camera when watson teleporting on deactivation
			if (Effect != nullptr)
				Effect.DeactivateImmediately();
		}

		Owner.TeleportActor(Params.Location, Params.Rotation, this);

		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		ULightBirdEventHandler::Trigger_WatsonTeleport(Owner);
		ULightBirdEventHandler::Trigger_WatsonTeleport(CompanionComp.Player);

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

		for (UNiagaraComponent Effect : AttachedEffects)
		{
			// Turn trail etc back on again
			if (Effect != nullptr)
				Effect.Activate();
		}
	}
};		