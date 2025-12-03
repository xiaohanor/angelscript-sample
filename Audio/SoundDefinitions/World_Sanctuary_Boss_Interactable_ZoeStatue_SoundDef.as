
UCLASS(Abstract)
class UWorld_Sanctuary_Boss_Interactable_ZoeStatue_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryBowMegaCompanions StatueBow;

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryBowDarkMegaCompanion DarkMegaCompanion;

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryBowLightMegaCompanion LightMegaCompanion;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		StatueBow = Cast<ASanctuaryBowMegaCompanions>(HazeOwner);	
		DarkMegaCompanion = StatueBow.DarkMegaCompanion;
		LightMegaCompanion = StatueBow.LightMegaCompanion;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMegaCompanion.SpawnedPortal != nullptr;
	}
}