class USandSharkPlayerOnSandCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(n"SandSharkOnSand");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	bool bOnSandPreviousFrame = false;
	bool bIsOnSand = false;
	float TimeWhenHitSand = 0;

	UHazeMovementComponent MoveComp;
	USandSharkPlayerComponent PlayerComp;

	bool bIsHunted = false;
	bool bWasHunted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = USandSharkPlayerComponent::Get(Player);
		PlayerComp.OnBecameHunted.AddUFunction(this, n"OnBecameHunted");
		PlayerComp.OnStoppedBeingHunted.AddUFunction(this, n"OnStoppedBeingHunted");
	}

	UFUNCTION()
	private void OnBecameHunted()
	{
		bIsHunted = true;
	}

	UFUNCTION()
	private void OnStoppedBeingHunted()
	{
		bIsHunted = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.HasGroundContact())
			bIsOnSand = IsLandscape(MoveComp.GroundContact.Actor);
		else if (PlayerComp.bIsPerformingContextualMove)
			bIsOnSand = false;

		if (!bOnSandPreviousFrame && bIsOnSand)
		{
			TimeWhenHitSand = Time::GetGameTimeSeconds();
		}
		else if (!bOnSandPreviousFrame && !bIsOnSand)
		{
			TimeWhenHitSand = BIG_NUMBER;
		}

		bOnSandPreviousFrame = bIsOnSand;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.bIsPerching)
			return false;

		if (PlayerComp.bOnSafePoint)
			return false;

		if (PlayerComp.bIsPerformingContextualMove)
			return false;

		if (!bIsOnSand)
			return false;

 		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.bOnSafePoint)
			return true;

		if (PlayerComp.bIsPerching)
			return true;

		if (PlayerComp.bIsPerformingContextualMove)
			return true;

		if (!bIsOnSand)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.bHasTouchedSand = true;
		Player.ApplySettings(PlayerComp.DefaultOnSandFloorMotionSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(PlayerComp.DefaultOnSandAirMotionSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(PlayerComp.DefaultOnSandJumpSettings, this, EHazeSettingsPriority::Override);

		Player.ApplySettings(PlayerComp.DashSettingsOnSand, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(PlayerComp.AirDashSettingsOnSand, this, EHazeSettingsPriority::Override);

		Player.ApplySettings(PlayerComp.DefaultOnSandPlayerSlideJumpSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(PlayerComp.DefaultOnSandPlayerSlideSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(PlayerComp.DefaultOnSandPlayerUnwalkableSlideSettings, this, EHazeSettingsPriority::Override);

		Player.BlockCapabilities(PlayerMovementTags::RollDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);
		Player.AddLocomotionFeatureBundle(PlayerComp.FeatureBundle, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.bHasTouchedSand = false;
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(PlayerMovementTags::RollDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);
		Player.RemoveLocomotionFeatureBundle(PlayerComp.FeatureBundle, this);
		Player.StopForceFeedback(this);
		bWasHunted = false;
		bIsHunted = false;
		bOnSandPreviousFrame = false;
		bIsOnSand = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bIsHunted && !bWasHunted)
		{
			Player.PlayForceFeedback(PlayerComp.TargetForceFeedback.ForceFeedbackEffect, true, true, this);
		}
		else if (!bIsHunted && bWasHunted)
		{
			Player.StopForceFeedback(this);
		}
		bWasHunted = bIsHunted;
	}

	bool IsLandscape(AActor Actor) const
	{
		if (Actor != nullptr)
		{
			auto Landscape = UDesertLandscapeComponent::Get(Actor);
			if (Landscape != nullptr)
				return true;
		}

		return false;
	}
}