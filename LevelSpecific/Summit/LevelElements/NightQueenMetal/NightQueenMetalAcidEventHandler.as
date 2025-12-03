class UNightQueenMetalAcidEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnAcidHit(FAcidHit AcidHit) {};

	UFUNCTION(BlueprintEvent)
	void OnFullyMelted() {};

	UFUNCTION(BlueprintEvent)
	void OnStartDissolve() {};

	UFUNCTION(BlueprintEvent)
	void OnStartRegrow() {};

	UFUNCTION(BlueprintEvent)
	void OnFullyRegrown() {};
}