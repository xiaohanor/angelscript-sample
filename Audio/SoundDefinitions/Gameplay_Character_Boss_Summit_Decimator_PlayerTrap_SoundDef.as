
UCLASS(Abstract)
class UGameplay_Character_Boss_Summit_Decimator_PlayerTrap_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCrystalSmashed(){}

	UFUNCTION(BlueprintEvent)
	void OnMelted(){}

	UFUNCTION(BlueprintEvent)
	void OnCrystalTrapped(){}

	UFUNCTION(BlueprintEvent)
	void OnMetalTrapped(){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphStarted(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphStopped(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphAborted(){}

	/* END OF AUTO-GENERATED CODE */

	ASummitDecimatorTopdownPlayerTrap PlayerTrap;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PlayerTrap = Cast<ASummitDecimatorTopdownPlayerTrap>(HazeOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Melt Alpha"))
	float GetMeltAlpha()
	{
		if(PlayerTrap.Target != Game::Zoe)
			return 0.0;

		return PlayerTrap.MeltComp.GetMeltAlpha();
	}
}