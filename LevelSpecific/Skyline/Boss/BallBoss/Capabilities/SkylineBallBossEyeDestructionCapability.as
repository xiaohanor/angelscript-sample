class USkylineBallBossEyeDestructionCapability : UHazeCapability
{
	// local
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	
	ASkylineBallBoss BallBoss;
	UBasicAIHealthComponent HealthComp;

	bool bHasActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(BallBoss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.EmberEyePanelMaterial0 == nullptr)
			return false;
		if (BallBoss.EmberEyePanelMaterial1 == nullptr)
			return false;
		if (BallBoss.RedLampEyePanelMaterial == nullptr)
			return false;
		if (BallBoss.RedLampPulseEyePanelMaterial == nullptr)
			return false;
		if (ShouldDestroyEyePart())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float AccumulatedDamage = BallBoss.Settings.DetonatorDamage;
		int PreviousHurtStage = BallBoss.FaceHurtStage;
		if (BallBoss.FaceHurtStage > 0)
			Event(false);
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 0)
		{
			BallBoss.EyePanelPart1.SetVisibility(false);
			BallBoss.EyePanelPart2.SetVisibility(false);

			BallBoss.EyePanelPart3.SetMaterial(0, BallBoss.EmberEyePanelMaterial0);
			BallBoss.EyePanelPart3.SetMaterial(1, BallBoss.EmberEyePanelMaterial1);

			BallBoss.EyePanelPart4.SetMaterial(0, BallBoss.EmberEyePanelMaterial0);
			BallBoss.EyePanelPart4.SetMaterial(1, BallBoss.EmberEyePanelMaterial1);
			BallBoss.FaceHurtStage = 1;
		}
		AccumulatedDamage += BallBoss.Settings.DetonatorDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 1)
		{
			BallBoss.EyePanelPart3.SetVisibility(false);
			BallBoss.EyePanelPart5.SetMaterial(0, BallBoss.EmberEyePanelMaterial0);
			BallBoss.EyePanelPart5.SetMaterial(1, BallBoss.EmberEyePanelMaterial1);
			BallBoss.FaceHurtStage = 2;
		}
		AccumulatedDamage += BallBoss.Settings.DetonatorDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 2)
		{
			BallBoss.EyePanelPart4.SetVisibility(false);
			BallBoss.FaceHurtStage = 3;
		}
		AccumulatedDamage += BallBoss.Settings.ChargeLaserDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 3)
		{
			// break lamps A
			BallBoss.EyePanelPart5.SetVisibility(false);
			BallBoss.FaceHurtStage = 4;
		}
		AccumulatedDamage += BallBoss.Settings.ChargeLaserDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 4)
		{
			// break lamps B
			BallBoss.FaceHurtStage = 5;
		}
		bool bShouldSetMaterials = BallBoss.GetPhase() >= ESkylineBallBossPhase::TopMioOnEyeBroken && BallBoss.bHasResetMaterials;
		if (bShouldSetMaterials)
		{
			BallBoss.FaceHurtStage = 6;
			BallBoss.bHasResetMaterials = false;
		}
		if (PreviousHurtStage != BallBoss.FaceHurtStage)
			Event(true);
		bHasActivated = true;
	}

	bool ShouldDestroyEyePart() const
	{
		float AccumulatedDamage = BallBoss.Settings.DetonatorDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 0)
			return true;
		AccumulatedDamage += BallBoss.Settings.DetonatorDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 1)
			return true;
		AccumulatedDamage += BallBoss.Settings.DetonatorDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 2)
			return true;
		AccumulatedDamage += BallBoss.Settings.ChargeLaserDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 3)
			return true;
		AccumulatedDamage += BallBoss.Settings.ChargeLaserDamage;
		if (HasTakenDagage(AccumulatedDamage) && BallBoss.FaceHurtStage <= 4)
			return true;
		bool bShouldSetMaterials = BallBoss.GetPhase() >= ESkylineBallBossPhase::TopMioOnEyeBroken && BallBoss.bHasResetMaterials;
		if (bShouldSetMaterials)
			return true;
		return false;
	}

	bool HasTakenDagage(float Damage) const
	{
		return HealthComp.GetCurrentHealth() - KINDA_SMALL_NUMBER <= 1.0 - Damage;
	}

	void Event(bool bStart)
	{
		if (BallBoss.FaceHurtStage == 0)
			return;
		FSkylineBallBossUpdateDamageEventHandlerParams Params;
		Params.HatchComponent = BallBoss.HatchLocationComp;
		Params.bIsBeginPlay = DeactiveDuration < 0.1 && !bHasActivated;
		switch (BallBoss.FaceHurtStage)
		{
			case 1:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt1Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt1End(BallBoss, Params);
				break;
			}
			case 2:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt2Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt2End(BallBoss, Params);
				break;
			}
			case 3:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt3Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt3End(BallBoss, Params);
				break;
			}
			case 4:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt4Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt4End(BallBoss, Params);
				break;
			}
			case 5:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt5Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt5End(BallBoss, Params);
				break;
			}
			case 6:
			{
				if (bStart)
					USkylineBallBossEventHandler::Trigger_OnHurt6Start(BallBoss, Params);
				else
					USkylineBallBossEventHandler::Trigger_OnHurt6End(BallBoss, Params);
				break;
			}
		}
	}
};