class UGentlemanTokenHolderComponent : UActorComponent
{
	TMap<FName, float> TokenScores;

	bool bProtectedToken;

	UPROPERTY()
	FName TokenName = GentlemanToken::Ranged;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Score = 0.0;
		TokenScores.Find(TokenName, Score);
	}

	bool CanStealToken(FName InTokenName, float StealScore)
	{
		if (!TokenScores.Contains(InTokenName))
			return false;
		
		float CurrentScore = TokenScores[InTokenName];
		return TokenScores[InTokenName] < StealScore;
	}

	void SetTokenScore(FName InTokenName, float Score)
	{
		TokenScores.Add(InTokenName, Score);
	}

	float GetScore(FName InTokenName)
	{
		if (!TokenScores.Contains(InTokenName))
			return 0.0;
		
		return TokenScores[InTokenName];
	}
	
}