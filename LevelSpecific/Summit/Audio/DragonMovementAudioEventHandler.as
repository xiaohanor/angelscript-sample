class UDragonMovementAudioEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepPlant_Setup(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepPlant_FrontLeft(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepPlant_FrontRight(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepPlant_BackLeft(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepPlant_BackRight(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepRelease(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepLand(FDragonFootstepParams FootParams) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenWingFlapUp() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenWingFlapDown() {};
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenGlideStart() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenGlideStop() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenGlideInitialUpwardsBoostTriggered() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenBoostRingStart() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidTeenBoostRingStop() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVocalization(FDragonVocalizationParams Params) {};
}