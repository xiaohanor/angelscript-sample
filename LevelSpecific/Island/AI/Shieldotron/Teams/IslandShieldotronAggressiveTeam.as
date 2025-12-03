class UIslandShieldotronAggressiveTeam : UHazeTeam
{
	TPerPlayer<AHazeActor> CurrentChaser;

	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		Super::OnMemberJoined(Member);		
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		Super::OnMemberLeft(Member);
		if (CurrentChaser[Game::Mio] == Member)
			CurrentChaser[Game::Mio] = nullptr;
		if (CurrentChaser[Game::Zoe] == Member)
			CurrentChaser[Game::Zoe] = nullptr;
	}

	bool IsOtherTeamMemberChasingTarget(AHazeActor Target, AHazeActor Chaser)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		check(PlayerTarget != nullptr);

		if (CurrentChaser[PlayerTarget] == nullptr || CurrentChaser[PlayerTarget] == Chaser)
			return false;
		
		return true;
	}

	bool IsOtherTeamMemberChasingAnyPlayer(AHazeActor QueryingChaser)
	{
		for (AHazeActor Chaser : CurrentChaser)
		{
			if (Chaser != nullptr && Chaser != QueryingChaser)
				return false;	
		}
		
		return true;
	}

	bool TryReportChasing(AHazeActor Target, AHazeActor Chaser)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		if (PlayerTarget == nullptr)
			return false;

		if (CurrentChaser[PlayerTarget] != nullptr && CurrentChaser[PlayerTarget] != Chaser)
			return false;

		ClearChasing(Chaser);
		CurrentChaser[PlayerTarget] = Chaser;
		return true;
	}

	void ReportStopChasing(AHazeActor Target, AHazeActor Chaser)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		check(PlayerTarget != nullptr);
		if (PlayerTarget == nullptr)
			return;

		if (CurrentChaser[PlayerTarget] != nullptr && CurrentChaser[PlayerTarget] != Chaser)
			return;
		
		CurrentChaser[PlayerTarget] = nullptr; // Clear chaser
	}
	
	private void ClearChasing(AHazeActor Chaser)
	{
		if (CurrentChaser[Game::Mio] == Chaser)
			CurrentChaser[Game::Mio] = nullptr;
		if (CurrentChaser[Game::Zoe] == Chaser)
			CurrentChaser[Game::Zoe] = nullptr;
	}
}