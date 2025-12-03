
UCLASS(Abstract)
class UWorld_Skyline_Shared_Spot_Commercial_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UBinkMediaPlayer BinkMediaPlayer;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BinkMediaPlayer != nullptr && BinkMediaPlayer.IsPlaying())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BinkMediaPlayer == nullptr || !BinkMediaPlayer.IsPlaying())
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetDuration()
	{
		if (BinkMediaPlayer == nullptr)
			return 0.0;

		return BinkMediaPlayer.GetDuration().GetTotalSeconds();
	}

	UFUNCTION(BlueprintPure)
	float GetPlayPositionInMs()
	{
		if (BinkMediaPlayer == nullptr)
			return 0.0;

		return BinkMediaPlayer.GetTime().GetTotalMilliseconds();
	}
}