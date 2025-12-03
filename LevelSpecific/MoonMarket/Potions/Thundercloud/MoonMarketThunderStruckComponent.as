struct FMoonMarketThunderStruckData
{
	AHazePlayerCharacter InstigatingPlayer;
}

event void MoonMarketOnRainedOnEvent(FMoonMarketInteractingPlayerEventParams Data);
event void OnStruckByThunderEvent(FMoonMarketThunderStruckData Data);

class UMoonMarketThunderStruckComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams ThunderStruckAnimation;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ThunderStruckForceFeedback;

	UPROPERTY(EditAnywhere)
	const float StunDuration = 1.5;

	bool bThunderStruck = false;

	uint LastRainFrame = 0;
	float LastRainTime = -100;

	OnStruckByThunderEvent OnStruckByThunder;
	MoonMarketOnRainedOnEvent OnRainedOn;
	FVector ThunderDirection;

	UFUNCTION(NetFunction)
	void NetStrike(FVector Direction, AHazePlayerCharacter InstigatingPlayer)
	{
		ThunderDirection = Direction;
		bThunderStruck = true;
		FMoonMarketThunderStruckData Data;
		Data.InstigatingPlayer = InstigatingPlayer;
		OnStruckByThunder.Broadcast(Data);
	}

	bool WasRainedOnRecently() const
	{
		return Time::GetGameTimeSince(LastRainTime) < 0.7;
	}
};