class ASketchbookKillPlayersOffScreenActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	bool bActive;

	float BeginTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BeginTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bActive)
			return;

		if(Time::GetGameTimeSince(BeginTime) < 2)
			return;

		for(auto Player : Game::Players)
		{
			// Only let a player commit seppuku if it has control
			if(!Player.HasControl())
				continue;

			if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
				continue;

			const auto GoatComp = USketchbookGoatPlayerComponent::Get(Player);
			if(GoatComp != nullptr && GoatComp.HasMountedGoat())
			{
				if(GoatComp.MountedGoat.bIsDead)
					continue;
			}

			if(Sketchbook::IsLocationOffScreen(Player, Player.ActorLocation))
			{
				Player.KillPlayer(DeathEffect = DeathEffect);
			}
		}
	}
}

namespace Sketchbook
{
	bool IsLocationOffScreen(AHazePlayerCharacter Player, FVector Location)
	{
		const float KillMargin = 0.05;

		FVector2D ScreenRelativePos;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, Location, ScreenRelativePos);

		if(ScreenRelativePos.X < 0 - KillMargin || ScreenRelativePos.X > 1 + KillMargin || ScreenRelativePos.Y < 0 - KillMargin || ScreenRelativePos.Y > 1 + KillMargin)
			return true;

		return false;
	}
}