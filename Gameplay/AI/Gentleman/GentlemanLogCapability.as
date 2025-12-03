class UGentlemanLogCapability : UHazeCapability
{
	UGentlemanComponent GentComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GentComp = UGentlemanComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto TempGentComp = UGentlemanComponent::Get(Owner);
		if(TempGentComp == nullptr)
			return false;

		TArray<FName> Tokens;
		TempGentComp.GetAllSemaphoreTokens(Tokens);
		if(Tokens.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GentComp = UGentlemanComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<FName> Tokens;
		GentComp.GetAllSemaphoreTokens(Tokens);
		for(FName Token: Tokens)
		{
			TEMPORAL_LOG(GentComp)
				.Value("Available tokens of " + Token, float(GentComp.GetNumberOfAvailableTokens(Token)));
		}
	}
}