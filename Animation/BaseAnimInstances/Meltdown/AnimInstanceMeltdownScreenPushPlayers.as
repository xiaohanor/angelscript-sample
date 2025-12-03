UCLASS()
class UAnimInstanceMeltdownScreenPushPlayers : UHazeCharacterAnimInstance
{
	AMeltdownScreenPushManager Manager;
	AHazePlayerCharacter Player;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	UAnimSequence MashMh;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	UAnimSequence Struggle;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData ScreenShake;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	bool bIsMio;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	bool bIsPaused;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	bool bIsStruggling;

	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	bool bEnablePlayerHandIK;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		Manager = TListedActors<AMeltdownScreenPushManager>().GetSingle();
		Player = Cast<AHazePlayerCharacter>(HazeOwningActor);

		bIsMio = Player == Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if (Manager == nullptr || Player == nullptr)
			return;

		bIsPaused = Manager.bIsPausedFromMash;

		float MashRate;
		bool bMashRateSufficient;
		Player.GetButtonMashCurrentRate(Manager, MashRate, bMashRateSufficient);
		bIsStruggling = bMashRateSufficient;
		bEnablePlayerHandIK = Manager.bEnablePlayerHandIK;

		if (bIsMio)
		{
			MashMh = Manager.MioMashIdleMH;
			Struggle = Manager.MioMashPushingMH;
		}
		else
		{
			MashMh = Manager.ZoeMashIdleMH;
			Struggle = Manager.ZoeMashPushingMH;
		}
	}
}