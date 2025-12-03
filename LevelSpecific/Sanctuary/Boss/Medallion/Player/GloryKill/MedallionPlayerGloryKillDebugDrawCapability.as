class UMedallionPlayerGloryKillDebugDrawCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	USanctuaryCompanionMegaCompanionPlayerComponent CompanionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		CompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GloryKillComp.AttackedHydra == nullptr)
			return false;
		if (!SanctuaryMedallionHydraDevToggles::Draw::GloryKill.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GloryKillComp.AttackedHydra == nullptr)
			return true;
		if (!SanctuaryMedallionHydraDevToggles::Draw::GloryKill.IsEnabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Debug::DrawDebugSphere(GloryKillComp.AttackedHydra.ActorLocation, 100, 12, ColorDebug::Rainbow(4), 40, bDrawInForeground = true);
		Debug::DrawDebugSphere(CompanionComp.MegaCompanion.ActorLocation, 40, 12, CompanionComp.MegaCompanion.GetDebugColor(), 40, bDrawInForeground = true);
		Debug::DrawDebugSphere(Player.ActorLocation, 20, 12, Player.GetPlayerUIColor(), 40, bDrawInForeground = true);
		Debug::DrawDebugSphere(GloryKillComp.AttackedHydra.ActorLocation + Player.ActorRelativeLocation, 5, 12, Player.GetPlayerUIColor() * 0.7, 40, bDrawInForeground = true);
	}
};