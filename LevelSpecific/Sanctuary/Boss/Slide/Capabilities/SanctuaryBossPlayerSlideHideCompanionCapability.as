
class USanctuaryBossPlayerSlideHideCompanionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	bool bHasLightBirb = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		bHasLightBirb = Player.IsMio();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsMio() && Player.IsCapabilityTagBlocked(LightBird::Tags::LightBird))
			return true;
		if (Player.IsZoe() &&Player.IsCapabilityTagBlocked(DarkPortal::Tags::DarkPortal))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsMio() && Player.IsCapabilityTagBlocked(LightBird::Tags::LightBird))
			return false;
		if (Player.IsZoe() &&Player.IsCapabilityTagBlocked(DarkPortal::Tags::DarkPortal))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Companion = GetCompanion();
		if (IsValid(Companion))
			Companion.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto Companion = GetCompanion();
		if (IsValid(Companion))
			Companion.SetActorHiddenInGame(false);
	}

	private AHazeCharacter GetCompanion()
	{
		if (bHasLightBirb)
			return LightBirdCompanion::GetLightBirdCompanion();
		return DarkPortalCompanion::GetDarkPortalCompanion();
	}
};