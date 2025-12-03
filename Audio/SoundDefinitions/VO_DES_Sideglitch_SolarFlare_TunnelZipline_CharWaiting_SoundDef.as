
UCLASS(Abstract)
class UVO_DES_Sideglitch_SolarFlare_TunnelZipline_CharWaiting_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnTunnelZiplineStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnTunnelZiplineImpact(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	float GetTimeToNextWaveHit()
	{
		float DeltaTime = Time::GetActorDeltaSeconds(HazeOwner);
		float TimeToImpact = SolarFlareSun::GetSecondsTillHit(DeltaTime); 
		return TimeToImpact;
	}

//// THE BELOW SHOULD BE CLEANED UP, AND THE donut
//	UFUNCTION(BlueprintPure)
//	float GetTimeToNextWave()
//	{
//		float TimeToImpact = SolarFlareFireDonutActor::GetTimeToWaveImpact(); 
//		
//		/* float tempvar = 33.0; */
//		return TimeToImpact;
//	
//	
//		/* return SolarFlareFireDonutActor::GetTimeToWaveImpact(); */
//	}

}


