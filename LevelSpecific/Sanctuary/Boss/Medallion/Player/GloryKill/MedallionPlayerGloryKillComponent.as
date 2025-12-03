enum EMedallionGloryKillState
{
	None,
	Enter,
	EnterSequence,
	Strangle,
	ExecuteSequence,
	Return,
}

class UMedallionPlayerGloryKillComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);

	access:ReadOnly EMedallionGloryKillState GloryKillState;

	FHazeAcceleratedFloat AccStrangle;
	UHazeCrumbSyncedFloatComponent SyncedStrangle;
	USceneComponent MashUISceneComp;

	bool bTetherToHydra = false;

	access GloryKillCapabilityAccess = private, 
		UMedallionPlayerGloryKill0SelectHydraCapability,
		UMedallionPlayerGloryKill2EnterSequenceCapability,
		UMedallionPlayerGloryKill4ExecuteSequenceCapability,
		UMedallionPlayerGloryKillDebugDrawCapability,
		UMedallionPlayerGloryKillDebugHideOtherHydrasCapability,
		USanctuaryBossMedallionHydraStrangleCapability,
		USanctuaryBossMedallionHydraDeathCapability;
	access:GloryKillCapabilityAccess ASanctuaryBossMedallionHydra AttackedHydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedStrangle = UHazeCrumbSyncedFloatComponent::Create(Owner, n"GloryKillSyncedStrangle");
	}

	void SetGloryKillState(EMedallionGloryKillState NewState, FInstigator Instigator)
	{
		GloryKillState = NewState;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (SanctuaryMedallionHydraDevToggles::Draw::Phase.IsEnabled() && Owner == Game::Mio)
			PrintToScreenScaled("Phase: " + GloryKillState, 0.0, ColorDebug::Bubblegum, 1.2);
#endif
	}

	ASanctuaryBossMedallionHydra GetCutsceneHydra() const
	{
		return AttackedHydra;
	}
};