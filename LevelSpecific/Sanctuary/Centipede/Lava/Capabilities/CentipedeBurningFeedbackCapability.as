class UCentipedeBurningFeedbackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	UPlayerCentipedeComponent MioPlayerCentipedeComponent;
	UPlayerCentipedeComponent ZoePlayerCentipedeComponent;

	TMap<UCentipedeSegmentComponent, float> SegmentToBurnCooldowns;
	TArray<bool> SegmentBurning;
	// TArray<UCentipedeSegmentComponent> SpawnedParticlesOnSegment;
	bool bLastWasBurning = false;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		Centipede = Cast<ACentipede>(Owner);
		Mio = Game::Mio;
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return false;
		if (DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return false;
		if (Mio.IsPlayerDead())
			return false;
		if (Zoe.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return true;
		if (DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return true;
		if (Mio.IsPlayerDead())
			return true;
		if (Zoe.IsPlayerDead())
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
		for (int iSegment = 0; iSegment < Centipede.Segments.Num(); ++iSegment)
		{
			UCentipedeSegmentComponent Segment = Centipede.Segments[iSegment];
			if (Segment.bIsBurning)
				Segment.StopBurn();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		UpdateEventHandler();
		if (LavaIntoleranceComponent.bIsRespawning)
			return;
		
		UpdateParticles(DeltaTime);
		ApplyForceFeedback();
	}

	void UpdateEventHandler()
	{
		bool bIsBurning = LavaIntoleranceComponent.Burns.Num() > 0;
		if (bLastWasBurning != bIsBurning)
		{
			if (bIsBurning)
			{
				UCentipedeEventHandler::Trigger_OnBurningStarted(Game::Mio);
				UCentipedeEventHandler::Trigger_OnBurningStarted(Game::Zoe);
				UCentipedeEventHandler::Trigger_OnBurningStarted(Centipede);
			}
			else
			{
				UCentipedeEventHandler::Trigger_OnBurningStopped(Game::Mio);
				UCentipedeEventHandler::Trigger_OnBurningStopped(Game::Zoe);
				UCentipedeEventHandler::Trigger_OnBurningStopped(Centipede);
			}
		}
		// Debug::DrawDebugString(Centipede.ActorLocation, "Burning: " + bIsBurning);
		bLastWasBurning = bIsBurning;
	}

	private void UpdateParticles(float DeltaSeconds)
	{
		for (auto BurnCooldowns : SegmentToBurnCooldowns)
			BurnCooldowns.Value = BurnCooldowns.Value - DeltaSeconds;

		SegmentBurning.Empty(Centipede.Segments.Num());
		for (int iSegment = 0; iSegment < Centipede.Segments.Num(); ++iSegment)
			SegmentBurning.Add(false);

		for (auto Burn : LavaIntoleranceComponent.Burns)
		{
			for (int SegmentIndex : Burn.SegmentIndexes)
			{
				bool bValidIndex = SegmentIndex >= 0 && SegmentIndex < Centipede.Segments.Num();
				if (!devEnsure(bValidIndex, "Invalid Segment for burning!"))
					return;
				SegmentBurning[SegmentIndex] = true;
			}
		}

		for (int iSegment = 0; iSegment < Centipede.Segments.Num(); ++iSegment)
		{
			UCentipedeSegmentComponent Segment = Centipede.Segments[iSegment];

			if (SanctuaryCentipedeDevToggles::Draw::Burning.IsEnabled())
				Debug::DrawDebugString(Segment.WorldLocation, "Burning", ColorDebug::Ruby);
			
			bool bShouldBeBurning = SegmentBurning[iSegment];
			if (bShouldBeBurning && !Segment.bIsBurning)
				Segment.StartBurn();
			else
				Segment.StopBurn();
		}
	}

	private void ApplyForceFeedback()
	{
		bool bHasForceFeedback = false;
		for (FCentipedeLavaDamageOverTime& Source : LavaIntoleranceComponent.Burns)
		{
			if (Source.bTriggerForceFeedback)
			{
				bHasForceFeedback = true;
				break;
			}
		}

		if (bHasForceFeedback)
		{
			float Intensity = Math::Clamp(1 - LavaIntoleranceComponent.Health.Value, 0.0, 1.0);
			PlayerForceFeedback(ZoePlayerCentipedeComponent, Intensity);
			PlayerForceFeedback(MioPlayerCentipedeComponent, Intensity);
		}
	}

	private void PlayerForceFeedback(UPlayerCentipedeComponent& PlayerCentipedeComp, float Intensity)
	{
		if (PlayerCentipedeComp == nullptr || PlayerCentipedeComp.PlayerOwner == nullptr || PlayerCentipedeComp.LavaImpactForceFeedbackEffect == nullptr)
			return;
		PlayerCentipedeComp.PlayerOwner.PlayForceFeedback(PlayerCentipedeComp.LavaImpactForceFeedbackEffect, false, true, this, Intensity);
	}

	private void DebugPrintHealth()
	{
		for (FCentipedeLavaDamageOverTime& Source : LavaIntoleranceComponent.Burns)
		{
			PrintToScreen("Lava Time " + Source.DamageTimer + " / " + Source.DamageDuration , 0.0, ColorDebug::Ruby);
		}
		
		if (LavaIntoleranceComponent.Health.Value > 1 - KINDA_SMALL_NUMBER)
			PrintToScreen("Lava Healthy " + LavaIntoleranceComponent.Health, 0.0, ColorDebug::Fern);
		else
			PrintToScreen("Lava Healthy " + LavaIntoleranceComponent.Health, 0.0, ColorDebug::Carmine);
	}

	bool TryCacheThings()
	{
		if (ZoePlayerCentipedeComponent == nullptr)
			ZoePlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Zoe);
		if (MioPlayerCentipedeComponent == nullptr)
			MioPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Mio);
		return MioPlayerCentipedeComponent != nullptr && ZoePlayerCentipedeComponent != nullptr;
	}
}