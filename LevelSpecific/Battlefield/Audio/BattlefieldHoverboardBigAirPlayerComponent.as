struct FBattlefieldHoverboardBigAirInstigatorData
{
	UPROPERTY(EditInstanceOnly)
	FName InstigatorTag = NAME_None;
	UPROPERTY(NotEditable)
	UHazeAudioEffectShareSet EffectShareset = nullptr;
	UPROPERTY(EditInstanceOnly)
	float InterpolationTime = 1;
	UPROPERTY(EditInstanceOnly)
	float GroundedTraceLength = 1000;
}

class UBattlefieldHoverboardBigAirPlayerComponent : UActorComponent
{
	access BigAirPlayerCapability = private, UBattlefieldHoverboardBigAirPlayerCapability;
	access BigAirPlayerVolume = private, ABattlefieldHoverboardBigAirPlayerVolume;

	access:BigAirPlayerCapability TOptional<FBattlefieldHoverboardBigAirInstigatorData> InstigatedBigAirData;

	access:BigAirPlayerVolume void SetBigAirData(FBattlefieldHoverboardBigAirInstigatorData Data)
	{
		InstigatedBigAirData = Data;
	}
}