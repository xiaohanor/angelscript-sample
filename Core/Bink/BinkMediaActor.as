UCLASS(Abstract)
class ABinkMediaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UBinkMediaPlayer BinkMediaPlayer;

	UFUNCTION()
	void ForceInitialize()
	{
		if (BinkMediaPlayer == nullptr)
			return;

		BinkMediaPlayer.InitializePlayer();
	}

	UFUNCTION()
	void Play()
	{
		if (BinkMediaPlayer == nullptr)
			return;

		BinkMediaPlayer.Play();
	}

	UFUNCTION()
	void Stop()
	{
		if (BinkMediaPlayer == nullptr)
			return;

		BinkMediaPlayer.Stop();
	}

	UFUNCTION()
	void Pause()
	{
		if (BinkMediaPlayer == nullptr)
			return;

		BinkMediaPlayer.Pause();
	}

	UFUNCTION()
	float GetDuration()
	{
		if (BinkMediaPlayer == nullptr)
			return 0.0;

		return BinkMediaPlayer.GetDuration().GetTotalSeconds();
	}

	UFUNCTION()
	float GetPlayPosition()
	{
		if (BinkMediaPlayer == nullptr)
			return 0.0;

		return BinkMediaPlayer.GetTime().GetTotalSeconds();
	}
};