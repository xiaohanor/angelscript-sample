
event void FOnInfuseEssenceOrbsReset();

class UInfuseEssencePlayerComponent : UActorComponent
{
	UPROPERTY()
	private int OrbsRequiredToInfuse = 3;
	private int OrbsAquired = 0;

	FOnInfuseEssenceOrbsReset OnOrbsShouldReset;
	AHazePlayerCharacter PlayerOwner;

	float ScaleFollowOffsetPerOrb = 0.3;

	USanctuaryLightBirdCompanionSettings BirdSettings;
	USanctuaryDarkPortalCompanionSettings DarkSettings;
	AAISanctuaryLightBirdCompanion LightBird;
	AAISanctuaryDarkPortalCompanion DarkPortal;

	UPROPERTY()
	TSubclassOf<AInfusedEssence> AcquiredEssenceClass;
	TArray<AInfusedEssence> InfusedEssences;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void AddOrb()
	{
		if (OrbsAquired < OrbsRequiredToInfuse)
		{
			++OrbsAquired;
			if (LightBird == nullptr)
				LightBird = LightBirdCompanion::GetLightBirdCompanion();
			if (DarkPortal == nullptr)
				DarkPortal = DarkPortalCompanion::GetDarkPortalCompanion();
			AddInfusedOrb();
			SetCompanionOffset();
		}
	}

	private void AddInfusedOrb()
	{
		if (AcquiredEssenceClass == nullptr)
			return;

		if (InfusedEssences.Num() == 0)
		{
			AHazeCharacter Companion = GetCompanion();
			for (int i = 0; i < OrbsRequiredToInfuse; ++i) 
			{
				auto Essence = SpawnActor(AcquiredEssenceClass, Owner.ActorLocation);
				Essence.EssenceID = i;
				Essence.TotalEssences = OrbsRequiredToInfuse;
				Essence.FollowCompanion = Companion;
				Essence.AddActorDisable(this);
				InfusedEssences.Add(Essence);
			}
		}
		for (int i = 0; i < InfusedEssences.Num(); ++i)
		{
			if (InfusedEssences[i].IsActorDisabled())
			{
				InfusedEssences[i].RemoveActorDisable(this);
				break;
			}
		}
	}

	bool HasEnoughOrbs()
	{
		return OrbsAquired >= OrbsRequiredToInfuse;
	}

	float GetProgress()
	{
		float OrbsFloat = OrbsAquired;
		float RequiredOrbsFloat = OrbsRequiredToInfuse;
		return OrbsFloat / RequiredOrbsFloat;
	}

	void RemoveFloatyOrbs()
	{
		for (int i = 0; i < InfusedEssences.Num(); ++i)
			InfusedEssences[i].AddActorDisable(this);
	}

	void ResetOrbs()
	{
		if (HasControl())
			CrumbResetOrbs();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetOrbs()
	{
		OrbsAquired = 0;
		OnOrbsShouldReset.Broadcast();
		ResetCompanionOffset();
		for (int i = 0; i < InfusedEssences.Num(); ++i)
			InfusedEssences[i].AddActorDisable(this);
	}

	private AHazeCharacter GetCompanion()
	{
		if (PlayerOwner.IsMio())
			return LightBird;
		return DarkPortal;
	}

	private void SetCompanionOffset()
	{
		if (!HasEnoughOrbs())
			return;

		float OffsetFactor = Math::Clamp(1.0 + ScaleFollowOffsetPerOrb * OrbsAquired, 1.0, 2.0);
		if (PlayerOwner.IsMio())
		{
			BirdSettings = USanctuaryLightBirdCompanionSettings::GetSettings(LightBird);
			USanctuaryLightBirdCompanionSettings::SetFollowOffsetMin(LightBird, BirdSettings.FollowOffsetMin * OffsetFactor, this, EHazeSettingsPriority::Gameplay); 
			USanctuaryLightBirdCompanionSettings::SetFollowOffsetMax(LightBird, BirdSettings.FollowOffsetMax * OffsetFactor, this, EHazeSettingsPriority::Gameplay); 
		}
		else
		{
			DarkSettings = USanctuaryDarkPortalCompanionSettings::GetSettings(DarkPortal);
			USanctuaryDarkPortalCompanionSettings::SetFollowOffsetMin(DarkPortal, DarkSettings.FollowOffsetMin * OffsetFactor, this, EHazeSettingsPriority::Gameplay); 
			USanctuaryDarkPortalCompanionSettings::SetFollowOffsetMax(DarkPortal, DarkSettings.FollowOffsetMax * OffsetFactor, this, EHazeSettingsPriority::Gameplay); 
		}
	}

	private void ResetCompanionOffset()
	{
		if (PlayerOwner.IsMio() && LightBird != nullptr)
			LightBird.ClearSettingsByInstigator(this);
		else if (DarkPortal != nullptr)
			DarkPortal.ClearSettingsByInstigator(this);
	}
};