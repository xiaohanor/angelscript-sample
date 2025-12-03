
UCLASS(Abstract)
class UVO_DES_Sideglitch_SolarFlare_Shared_FlareDeathImminentChar_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSolarFlareDeath(FOnSolarFlareDeathParams OnSolarFlareDeathParams){}

	/* END OF AUTO-GENERATED CODE */


	UFUNCTION(BlueprintPure)
	float GetTimeToNextWaveHit()
	{
		float DeltaTime = Time::GetActorDeltaSeconds(HazeOwner);
		float TimeToImpact = SolarFlareSun::GetSecondsTillHit(DeltaTime); 
		return TimeToImpact;
	}


	UFUNCTION(BlueprintPure)
	FDualValueReturn PlayerIsInCover(AHazePlayerCharacter Player)
	{		
		FDualValueReturn MyStruct;
		MyStruct.PlayerInCover = SolarFlareSun::IsPlayerInCover(Player);
		MyStruct.Player = Player;
		return MyStruct;
	}

}

struct FDualValueReturn 
{
	UPROPERTY()
	bool PlayerInCover;

	UPROPERTY()
	AHazePlayerCharacter Player;
} 