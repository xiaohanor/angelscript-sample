class UNightQueenMetalDissolvingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenMetal");
	default CapabilityTags.Add(n"NightQueenMetalDissolving");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenMetal NightQueenMetal;

	UNightQueenMetalMeltingSettings MeltingSettings;

	bool bUnDissolving = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NightQueenMetal = Cast<ANightQueenMetal>(Owner);
		MeltingSettings = UNightQueenMetalMeltingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(NightQueenMetal.DissolveAlphaTarget == 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(NightQueenMetal.DissolveAlpha == 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bUnDissolving = false;
		NightQueenMetal.TimeLastDissolveStarted = Time::GameTimeSeconds;

		UNightQueenMetalAcidEventHandler::Trigger_OnStartDissolve(NightQueenMetal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto Crystal : NightQueenMetal.PoweringCrystals)
		{
			if(Crystal == nullptr)
				continue;
			FSummitCrystalObeliskMetalMeltingParams Params;
			Params.MetalLocation = NightQueenMetal.ActorLocation;
			Params.MetalMesh = NightQueenMetal.MeshComp;
			USummitCrystalObeliskEffectsHandler::Trigger_MetalUnDissolveFinished(Crystal, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bUnDissolving && NightQueenMetal.ShouldUnDissolve())
		{
			StartUnDissolving();
		}

		if(bUnDissolving)
		{
			NightQueenMetal.DissolveAlpha = Math::FInterpConstantTo(NightQueenMetal.DissolveAlpha, NightQueenMetal.DissolveAlphaTarget, DeltaTime, MeltingSettings.UnDissolvingSpeed);
		}
		else
		{
			NightQueenMetal.DissolveAlpha = Math::FInterpConstantTo(NightQueenMetal.DissolveAlpha, NightQueenMetal.DissolveAlphaTarget, DeltaTime, MeltingSettings.DissolvingSpeed);
		}

		// PrintToScreenScaled("Dissolve Alpha: " + NightQueenMetal.DissolveAlpha);
		
		NightQueenMetal.SetDissolveMaterials(NightQueenMetal.DissolveAlpha);

		if(NightQueenMetal.bCollisionIsOn 
			&& NightQueenMetal.DissolveAlpha > MeltingSettings.DissolveCollisionThreshold)
		{
			NightQueenMetal.ToggleCollision(false);
			NightQueenMetal.OnNightQueenMetalMelted.Broadcast();
		}
		else if(!NightQueenMetal.bCollisionIsOn
			&& NightQueenMetal.DissolveAlpha < MeltingSettings.DissolveCollisionThreshold)
		{
			if(!MeltingSettings.bDontRegrowWhenPlayerInArea) // Need to kill player if collision turns on when the player is inside
				ClearBlockingVolume();

			NightQueenMetal.ToggleCollision(true);
			NightQueenMetal.OnNightQueenMetalRecovered.Broadcast();
		}
	}

	void ClearBlockingVolume()
	{
		FHazeTraceSettings Trace;
		Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		Trace.UseBoxShape(NightQueenMetal.BlockingVolume.BoundingBoxExtents, NightQueenMetal.BlockingVolume.WorldRotation.Quaternion());
		auto HitResults = Trace.QueryOverlaps(NightQueenMetal.BlockingVolume.WorldLocation);

		if(!HitResults.HasOverlapHit())
			return;

		for(auto Overlap : HitResults.OverlapHits)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);

			if(Player == nullptr)
				continue;

			Player.KillPlayer(); // Add effect?
		}
	}

	void StartUnDissolving()
	{
		NightQueenMetal.bEventRegrowRequested = false;

		NightQueenMetal.SetMeltedAmountInstantly(MeltingSettings.MeltedAmountAtUnDissolveStart);

		NightQueenMetal.DissolveAlphaTarget = 0.0;
		bUnDissolving = true;

		for(auto Crystal : NightQueenMetal.PoweringCrystals)
		{
			FSummitCrystalObeliskMetalMeltingParams Params;
			Params.MetalLocation = NightQueenMetal.ActorLocation;
			Params.MetalMesh = NightQueenMetal.MeshComp;
			USummitCrystalObeliskEffectsHandler::Trigger_MetalUnDissolveStarted(Crystal, Params);
		}
	}
}