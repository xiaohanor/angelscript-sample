UFUNCTION()
void ActivateLightBirdShield(AHazePlayerCharacter Player, FInstigator Instigator, USanctuaryLightBirdShieldSettings Settings)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
	{
		UserComp.Settings = Settings;

		if (IsValid(UserComp.LightBirdShield))
		{
			UserComp.LightBirdShield.DestroyActor();
			UserComp.LightBirdShield = SpawnActor(UserComp.Settings.LightBirdShieldClass);
//			UserComp.LightBirdShield.AttachToActor(UserComp.Owner, n"LeftHand");
		}

		if (IsValid(UserComp.DarknessComp))
		{
			UserComp.DarknessComp.DestroyComponent(Player);
			UserComp.DarknessComp = Niagara::SpawnLoopingNiagaraSystemAttached(UserComp.Settings.DarknessVFX, Player.Mesh);
			UserComp.DarknessComp.SetTranslucentSortPriority(UserComp.Settings.DarknessVFXSorting);
		}

		UserComp.DarknessRate.Apply(Settings.DarknessRate, Player);
		UserComp.bIsActive = true;	
	}
}

UFUNCTION()
void DeactivateLightBirdShield(AHazePlayerCharacter Player)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
	{
		UserComp.DarknessRate.Clear(Player);
		UserComp.bIsActive = false;
	}
}

UFUNCTION()
void ApplyLightBirdShieldDarknessRate(AHazePlayerCharacter Player, float DarknessRate, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.DarknessRate.Apply(DarknessRate, Instigator);
}

UFUNCTION()
void ClearLightBirdShieldDarknessRate(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.DarknessRate.Clear(Instigator);
}

UFUNCTION()
void ApplyLightBirdShieldCrawling(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.bIsCrawling.Apply(true, Instigator);	
}

UFUNCTION()
void ClearLightBirdShieldCrawling(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.bIsCrawling.Clear(Instigator);	
}

UFUNCTION()
void ApplyLightBirdShieldFocusCamera(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.bUseFocusCamera.Apply(true, Instigator);	
}

UFUNCTION()
void ClearLightBirdShieldFocusCamera(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
	if (UserComp != nullptr)
		UserComp.bUseFocusCamera.Clear(Instigator);	
}