class USanctuaryProwlerBehaviourSwapCapability : UHazeCapability
{
	AAISanctuaryProwler Prowler;

	FVector ProwlerLocation;
	FVector PlayerLocation;	

	FHazeAcceleratedVector ProwlerAccVector;
	FHazeAcceleratedVector PlayerAccVector;	
	
	float SwapDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Prowler = Cast<AAISanctuaryProwler>(Owner);
		check(Prowler != nullptr, "Only a Sanctuary Prowler can use this Swap capability.");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Prowler.SwapPlayer != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SwapDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Prowler.BlockCapabilities(n"Movement", this);
		Prowler.BlockCapabilities(n"Behaviour", this);
		Prowler.AddActorCollisionBlock(this);
		Prowler.SwapPlayer.BlockCapabilities(n"Movement", this);
		Prowler.SwapPlayer.BlockCapabilities(n"Input", this);
		Prowler.SwapPlayer.BlockCapabilities(n"Collision", this);

		ProwlerLocation = Prowler.ActorLocation;
		PlayerLocation = Prowler.SwapPlayer.ActorLocation;		

		ProwlerAccVector.Value = ProwlerLocation;
		PlayerAccVector.Value = PlayerLocation;

		Prowler.SmoothTeleportActor(PlayerLocation, Prowler.ActorRotation, this, SwapDuration);
		Prowler.SwapPlayer.SmoothTeleportActor(ProwlerLocation, Prowler.SwapPlayer.ActorRotation, this, SwapDuration);

		auto Poi = Prowler.SwapPlayer.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToWorldLocation(PlayerLocation);
		Poi.Settings.Duration = SwapDuration;
		Poi.Apply(this, SwapDuration);

		USanctuaryProwlerEventHandler::Trigger_SwapStart(Prowler);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Prowler.UnblockCapabilities(n"Movement", this);
		Prowler.UnblockCapabilities(n"Behaviour", this);
		Prowler.RemoveActorCollisionBlock(this);
		Prowler.SwapPlayer.UnblockCapabilities(n"Movement", this);
		Prowler.SwapPlayer.UnblockCapabilities(n"Input", this);
		Prowler.SwapPlayer.UnblockCapabilities(n"Collision", this);	
		Prowler.SwapPlayer = nullptr;
		USanctuaryProwlerEventHandler::Trigger_SwapEnd(Prowler);
	}
}