class USolarFlarePlayerCoverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SolarFlarePlayerCover");

	default TickGroup = EHazeTickGroup::Gameplay;
	USolarFlarePlayerComponent PlayerComp;

	ASolarFlareSun Sun;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USolarFlarePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceDebugSettings Debug;
		Debug.Thickness = 1.0;
		Debug.TraceColor = FLinearColor::Green;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(Player);
		TraceSettings.IgnoreActor(Player.OtherPlayer);
		TraceSettings.UseCapsuleShape(Player.CapsuleComponent.CapsuleRadius * 0.5, Player.CapsuleComponent.CapsuleHalfHeight * 0.3, Player.ActorRotation.Quaternion());
		// TraceSettings.DebugDraw(Debug);
		FVector Start = Player.CapsuleComponent.WorldLocation;
		
		FVector SunDir = (Sun.ActorLocation - Player.ActorLocation).GetSafeNormal();

		FHitResultArray Hits = TraceSettings.QueryTraceMulti(Start, Start + (FVector(1, 0, 0) * 8000.0));
		TArray<USolarFlarePlayerCoverComponent> Covers;

		// Debug::DrawDebugArrow(Start, Start + FVector(1.0, 0.0, 0.0) * 500.0, 15.0, FLinearColor::Red, 10.0);

		for (FHitResult Hit : Hits)
		{
			if (Hit.bBlockingHit)
			{
				auto PlayerCoverComp =  USolarFlarePlayerCoverComponent::Get(Hit.Actor);
				if (PlayerCoverComp == nullptr)
					continue;
				
				//If disabled
				if (!PlayerCoverComp.IsCoverEnabled())
					continue;
				
				FVector Offset = (Hit.ImpactPoint - Player.CapsuleComponent.WorldLocation).ConstrainToDirection(FVector(1, 0, 0));
				// PrintToScreen("Offset.Size(): " + Offset.Size());
				// PrintToScreen("PlayerCoverComp.Distance: " + PlayerCoverComp.Distance);

				if(Offset.Size() <= PlayerCoverComp.Distance)
				{
					// Debug::DrawDebugLine(Player.CapsuleComponent.WorldLocation, Player.CapsuleComponent.WorldLocation + Offset, FLinearColor::Red, 15.0);
					Covers.Add(PlayerCoverComp);
					PlayerCoverComp.ActivateEnteredCover();
					// PrintToScreen("ADDING");
				}
			}
		}

		PlayerComp.SetPlayerCovers(Covers);
	}
};