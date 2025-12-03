UCLASS(Abstract)
class UGameShowArenaPlatformPlayerReactionComponent : UActorComponent
{
	UPROPERTY()
	UTexture PlayerReactionTexture;

	TPerPlayer<float> TimeWhenPlayerOnPlatform;
	TPerPlayer<bool> PlayersOnPlatform;

	void HandlePlayerOnPlatform(AHazePlayerCharacter Player)
	{
		if (PlayersOnPlatform[Player])
			return;

		TimeWhenPlayerOnPlatform[Player] = Time::GameTimeSeconds;
		PlayersOnPlatform[Player] = true;
	}

	void HandlePlayerLeavePlatform(AHazePlayerCharacter Player)
	{
		if (!PlayersOnPlatform[Player])
			return;

		TimeWhenPlayerOnPlatform[Player] = Time::GameTimeSeconds;
		PlayersOnPlatform[Player] = false;
	}
};