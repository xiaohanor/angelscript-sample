
UCLASS(Abstract)
class UVO_STO_Solarflare_Greenhouse_FlareBlast_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SolarFlareVOGreenhouseDestruction_GreenhouseExplosion(){}

	UFUNCTION(BlueprintEvent)
	void SolarFlareGreenhouseLift_OnLiftImpacted(FGreenhouseLiftParams GreenhouseLiftParams){}

	UFUNCTION(BlueprintEvent)
	void SolarFlareGreenhouseLift_OnLiftOpenDoors(FGreenhouseLiftParams GreenhouseLiftParams){}

	UFUNCTION(BlueprintEvent)
	void SolarFlareGreenhouseLift_OnLiftStopped(FGreenhouseLiftParams GreenhouseLiftParams){}

	UFUNCTION(BlueprintEvent)
	void SolarFlareGreenhouseLift_OnLiftStarted(FGreenhouseLiftParams GreenhouseLiftParams){}

	/* END OF AUTO-GENERATED CODE */

/* 

HazePlayVox

HazeVoxStopSystem
 */




/* UFUNCTION(BlueprintCallable)
void StopTalking()
{
	UVoxRuntimeAsset.Init.stop();

}

*/
} 