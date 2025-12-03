class UPrisonStealthVisionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthVision);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthEnemy Enemy;
	USpotLightComponent SpotlightComp;
	UPrisonStealthVisionComponent VisionComp;
	UPrisonStealthStunnedComponent StunnedComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<APrisonStealthEnemy>(Owner);
		SpotlightComp = USpotLightComponent::Get(Owner);
		VisionComp = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StunnedComp.IsStunned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StunnedComp.IsStunned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpotlightComp.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpotlightComp.SetVisibility(false);

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			
			Enemy.SetDetectionAlpha(Player, 0, true);

			if(Enemy.IsPlayerInSight(Player))
			{
				PrisonStealth::GetStealthManager().OnPlayerExitVision(Enemy, Player);
				Enemy.SetIsPlayerInSight(Player, false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < VisionComp.StartVisionDelay)
			return;

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			ControlTickPlayer(Player, DeltaTime);
		}
	}

	void ControlTickPlayer(AHazePlayerCharacter Player, float DeltaTime)
	{
		if(!Enemy.IsDetectionEnabledForPlayer(Player))
			return;

		if(Enemy.HasDetectedPlayer(Player))
			return;

		const bool bWasPlayerInSight = Enemy.IsPlayerInSight(Player);

		FPrisonStealthPlayerLastSeen LastSeenData = Enemy.GetLastSeenData(Player);

		const FPrisonStealthDetectPlayerResult Result = VisionComp.DetectPlayer(Player, LastSeenData);

		Enemy.SetLastSeenData(Player, LastSeenData);

		const bool bIsPlayerInSight = Result.Result == EPrisonStealthDetectPlayerResult::Visible || Result.Result == EPrisonStealthDetectPlayerResult::InstantDetection;

		if(bIsPlayerInSight != bWasPlayerInSight)
		{
			if(bIsPlayerInSight)
				PrisonStealth::GetStealthManager().OnPlayerEnterVision(Enemy, Player);
			else
				PrisonStealth::GetStealthManager().OnPlayerExitVision(Enemy, Player);
		}

		Enemy.SetIsPlayerInSight(Player, bIsPlayerInSight);

		float DetectionAlpha = Enemy.GetDetectionAlpha(Player);
		switch(Result.Result)
		{
			case EPrisonStealthDetectPlayerResult::InstantDetection:
				DetectionAlpha = 1.0;
				break;

			case EPrisonStealthDetectPlayerResult::Visible:
				DetectionAlpha = Math::FInterpConstantTo(DetectionAlpha, 1, DeltaTime, 1.0 / Result.DetectionTime);
				break;

			case EPrisonStealthDetectPlayerResult::NotVisible:
				DetectionAlpha = Math::FInterpConstantTo(DetectionAlpha, 0, DeltaTime, 1.0 / VisionComp.DetectionReturnTime);
				break;
		}

		DetectionAlpha = Math::Saturate(DetectionAlpha);
		Enemy.SetDetectionAlpha(Player, DetectionAlpha, false);
	}
};