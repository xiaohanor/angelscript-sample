const FConsoleVariable CVar_MinimumLoadingScreenTime("Haze.MinimumLoadingScreenTime", 0.5);

class UFadeSingleton : UHazeSingleton
{
	bool bIsInLoadingScreen = false;

	FLinearColor LoadingScreenFadeColor;
	bool bWasFadedOutBeforeLoadingScreen = false;

	TArray<UObject> ActiveLoadingTransitions;

	float NextLoadingScreenMinimumDuration = 0.0;
	bool bHasAppliedLoadingScreenMinimumDuration = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateLoadingScreenState();
	}

	void UpdateLoadingScreenState()
	{
		// Store the most recent fade color so the next loading screen can use it
		if (!Game::IsInLoadingScreen())
		{
			AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
			if (FullscreenPlayer != nullptr)
			{
				auto PlayerFadeManager = UFadeManagerComponent::GetOrCreate(FullscreenPlayer);
				FLinearColor CurrentFadeColor = PlayerFadeManager.CurrentFadeColor;

				LoadingScreenFadeColor = CurrentFadeColor;
				LoadingScreenFadeColor.A = 1.0;

				bWasFadedOutBeforeLoadingScreen = (CurrentFadeColor.A > 0.9);
			}
			else if (Lobby::GetLobby() == nullptr)
			{
				LoadingScreenFadeColor = FLinearColor::Black;
				bWasFadedOutBeforeLoadingScreen = false;
			}

			if (bHasAppliedLoadingScreenMinimumDuration)
			{
				NextLoadingScreenMinimumDuration = 0.0;
				bHasAppliedLoadingScreenMinimumDuration = false;
			}
		}
		else
		{
		}

		if (bIsInLoadingScreen != Game::IsInLoadingScreen())
		{
			bIsInLoadingScreen = Game::IsInLoadingScreen();;
			if (bIsInLoadingScreen)
			{
				// If we didn't fade out before the loading screen, make sure it is at least 1 second
				// of fade out, or it will look like a weird black flash.
				// We don't do this if any loading transitions are active, because they count as a pseudo-fade.
				if (NextLoadingScreenMinimumDuration > 0.0)
				{
					Progress::SetMinimumLoadingScreenDuration(Math::Max(CVar_MinimumLoadingScreenTime.GetFloat(), NextLoadingScreenMinimumDuration));
					bHasAppliedLoadingScreenMinimumDuration = true;
				}
				else if (bWasFadedOutBeforeLoadingScreen || ActiveLoadingTransitions.Num() != 0)
				{
					Progress::SetMinimumLoadingScreenDuration(0.0);
				}
				else
				{
					Progress::SetMinimumLoadingScreenDuration(CVar_MinimumLoadingScreenTime.GetFloat());
				}

				// TODO: If we're faded to something that isn't black, and we had letterboxes before, we
				// might want to continue to have those letterboxes during the loading screen
			}
			else
			{
				Progress::SetMinimumLoadingScreenDuration(0.0);
			}
		}
	}
}