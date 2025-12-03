struct FSanctuaryBossHydraPlayerTetherEventParams
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
}

class UMedallionPlayerTetherEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnTetherActivated() {};

	UFUNCTION(BlueprintEvent)
	void OnTetherDeactivated() {};

	UFUNCTION(BlueprintEvent)
	void OnStartHydraGloryKill(FSanctuaryBossHydraPlayerTetherEventParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnHydraGloryKillCompleted(FSanctuaryBossHydraPlayerTetherEventParams Params) {};
}