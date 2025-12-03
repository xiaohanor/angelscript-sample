class UScifiPlayerGasCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ScifiGas");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");

	default DebugCategory = n"ScifiGas";
	
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 50;

	UScifiPlayerGasZoneComponent GasComp;
	UPlayerMovementComponent MoveComp;
	UPostProcessingComponent PostProcess;

	AScifiGasZone LastBestGasZone = nullptr;

	bool bHasBlockedSprint = false;
	bool bHasBlockedDash = false;
	bool bHasBlockedSlide = false;
	bool bHasBlockedJump = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GasComp = UScifiPlayerGasZoneComponent::Get(Player);
		PostProcess = UPostProcessingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return GasComp.GasZones.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return GasComp.GasZones.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GasComp.CurrentDamageTime = 0;
		MoveComp.ClearMoveSpeedMultiplier(this);
		PostProcess.GasStrength = 0;

		if(bHasBlockedSprint)
		{
			bHasBlockedSprint = false;
			Player.UnblockCapabilities(n"Sprint", this);
		}

		if(bHasBlockedDash)
		{
			bHasBlockedDash = false;
			Player.UnblockCapabilities(n"Dash", this);
		}

		if(bHasBlockedSlide)
		{
			bHasBlockedSlide = false;
			Player.UnblockCapabilities(n"Slide", this);
		}

		if(bHasBlockedJump)
		{
			bHasBlockedJump = false;
			Player.UnblockCapabilities(n"Jump", this);
		}
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float BiggestAlpha = -1;
		AScifiGasZone BestGasZone = nullptr;
		for(AScifiGasZone GasVolume : GasComp.GasZones)
		{
			if(!GasVolume.GasIsActive())
				continue;
			
			float VolumeAlpha = GasVolume.GetGasAlpha();
			if(VolumeAlpha >= BiggestAlpha)
			{
				BiggestAlpha = VolumeAlpha;
				BestGasZone = GasVolume;
			}
		}
				
		UScifiGasZoneSettings Settings = GasComp.Settings;
		if(BestGasZone != nullptr && BestGasZone.CustomSettings != nullptr)
			Settings = BestGasZone.CustomSettings;
		
		float CurrentAlpha = 0.0;
		if(BiggestAlpha > 0)
		{
			GasComp.CurrentDamageTime += DeltaTime;
			float MaxMoveSpeedTime = Settings.bMovementSpeedCountsUpUntilDeath ? Settings.TimeUntilDeath : Settings.TimeUntilCritical;
			CurrentAlpha = Math::Min(GasComp.CurrentDamageTime / MaxMoveSpeedTime, 1.0);
			MoveComp.ApplyMoveSpeedMultiplier(Settings.MovementSpeed.Lerp(1.0 - CurrentAlpha), this);
		
			if(Player.Mesh.CanRequestOverrideFeature())
			{
				Player.Mesh.RequestOverrideFeature(n"Coughing", this);
			}
			
			if(!bHasBlockedSprint && GasComp.CurrentDamageTime >= Settings.TimeUntilSprintBlock)
			{
				bHasBlockedSprint = true;
				Player.BlockCapabilities(n"Sprint", this);
			}

			if(!bHasBlockedDash && GasComp.CurrentDamageTime >= Settings.TimeUntilDashBlock)
			{
				bHasBlockedDash = true;
				Player.BlockCapabilities(n"Dash", this);
			}

			if(!bHasBlockedSlide && GasComp.CurrentDamageTime >= Settings.TimeUntilSlideBlock)
			{
				bHasBlockedSlide = true;
				Player.BlockCapabilities(n"Slide", this);
			}
			
			if(!bHasBlockedJump && GasComp.CurrentDamageTime >= Settings.TimeUntilJumpBlock)
			{
				bHasBlockedJump = true;
				Player.BlockCapabilities(n"Jump", this);
			}

			if(CurrentAlpha >= 1.0 - KINDA_SMALL_NUMBER)
			{
				Player.KillPlayer();
			}
		}
		else if(GasComp.CurrentDamageTime > 0)
		{
			MoveComp.ClearMoveSpeedMultiplier(this);
			GasComp.CurrentDamageTime = 0;

			if(bHasBlockedSprint)
			{
				bHasBlockedSprint = false;
				Player.UnblockCapabilities(n"Sprint", this);
			}

			if(bHasBlockedDash)
			{
				bHasBlockedDash = false;
				Player.UnblockCapabilities(n"Dash", this);
			}

			if(bHasBlockedSlide)
			{
				bHasBlockedSlide = false;
				Player.UnblockCapabilities(n"Slide", this);
			}

			if(bHasBlockedJump)
			{
				bHasBlockedJump = false;
				Player.UnblockCapabilities(n"Jump", this);
			}
		}

		PostProcess.GasStrength = CurrentAlpha;

		// DEBUG
		// {	
		// 	if(CurrentDamageTime < KINDA_SMALL_NUMBER)
		// 		Debug::DrawDebugSphere(Player.ActorCenterLocation, (1.0 - CurrentAlpha) * 200, LineColor = FLinearColor::White);
		// 	else if(CurrentDamageTime < Settings.TimeUntilCritical)
		// 		Debug::DrawDebugSphere(Player.ActorCenterLocation, (1.0 - CurrentAlpha) * 200, LineColor = FLinearColor::Green);
		// 	else
		// 		Debug::DrawDebugSphere(Player.ActorCenterLocation, (1.0 - CurrentAlpha) * 200, LineColor = FLinearColor::Red);
				
		// 	PrintToScreen("CurrentDamageTime: " + CurrentDamageTime);
		// }
	}
};