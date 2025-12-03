
UCLASS(Abstract)
class UWorld_Meltdown_SplitTraversal_SplitTraversalCarnivorousPlantActivator_Screen_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus ScreenProxyBus;

	UFUNCTION(NotBlueprintCallable)
	bool ShouldActivateProxyEmitter(UObject SoundDefOwner, FName TagName, float32& InterpolationTime)
	{
		return true; 
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazeProxyEmitterRequest ScreenProxyRequest;

		ScreenProxyRequest.AuxBus = ScreenProxyBus;
		ScreenProxyRequest.Instigator = this;
		ScreenProxyRequest.Priority = 2;
		ScreenProxyRequest.SourcePassthroughAlpha = 1.0;
		ScreenProxyRequest.Target = Game::Zoe;
		ScreenProxyRequest.bSpatialized = false;
		ScreenProxyRequest.OnProxyRequest = FOnProxyEmittersRequest(this, n"ShouldActivateProxyEmitter");

		Game::Zoe.RequestAuxSendProxy(ScreenProxyRequest);
	}
}