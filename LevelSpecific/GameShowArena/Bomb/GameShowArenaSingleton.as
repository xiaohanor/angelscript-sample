class UGameShowArenaSingleton : UHazeSingleton
{
	bool bHasStartedFromBeginning = false;
	bool bHasBombEverExploded = false;

	TArray<EBombTossChallenges> RequiredChallenges;
	default RequiredChallenges.Add(EBombTossChallenges::BombTossStart);
	default RequiredChallenges.Add(EBombTossChallenges::BombTossTutorial);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss01);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss03);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss05);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss06);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss07);
	default RequiredChallenges.Add(EBombTossChallenges::BombToss08);

	TSet<EBombTossChallenges> CompletedChallenges;

	void OnGameShowStarted()
	{
		bHasStartedFromBeginning = true;
		bHasBombEverExploded = false;
		CompletedChallenges.Empty();
	}

	void OnBombExploded()
	{
		bHasBombEverExploded = true;
	}

	void OnGameShowChallengeCompleted(EBombTossChallenges Challenge)
	{
		CompletedChallenges.Add(Challenge);
	}

	void OnGameShowCompleted()
	{
		if (!bHasStartedFromBeginning)
			return;

		if (bHasBombEverExploded)
			return;

		for (auto Challenge : RequiredChallenges)
		{
			if (!CompletedChallenges.Contains(Challenge))
				return;
		}

		Online::UnlockAchievement(n"GameshowNoExplosion");
	}
}

namespace GameShowArena
{
	UFUNCTION()
	void OnGameShowStarted()
	{
		Game::GetSingleton(UGameShowArenaSingleton).OnGameShowStarted();
	}

	UFUNCTION()
	void OnBombExploded()
	{
		Game::GetSingleton(UGameShowArenaSingleton).OnBombExploded();
	}

	UFUNCTION()
	void OnGameShowChallengeCompleted(EBombTossChallenges Challenge)
	{
		Game::GetSingleton(UGameShowArenaSingleton).OnGameShowChallengeCompleted(Challenge);
	}

	UFUNCTION()
	void OnGameShowCompleted()
	{
		Game::GetSingleton(UGameShowArenaSingleton).OnGameShowCompleted();
	}
}