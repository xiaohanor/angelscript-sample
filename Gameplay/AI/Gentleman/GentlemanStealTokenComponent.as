class UGentlemanStealTokenComponent : UActorComponent
{
	bool CanStealToken(FName TokenName, UGentlemanComponent GentlemanComp, float StealScore) const
	{
		if (GentlemanComp == nullptr)
			return false;
		
		TArray<UObject> TokenClaimants;
		GentlemanComp.GetClaimants(TokenName, TokenClaimants);

		for (UObject Object : TokenClaimants)
		{
			if (!devEnsure(Object != Owner, "Trying to steal token from yourself. " + Owner.Name + " for " + TokenName))
			{
				return true;
			}

			AHazeActor Claimant = Cast<AHazeActor>(Object);
			UGentlemanTokenHolderComponent TokenHolderComp = (Claimant != nullptr) ? UGentlemanTokenHolderComponent::Get(Claimant) : nullptr;

			if (TokenHolderComp == nullptr) 
				continue;

			if (TokenHolderComp.bProtectedToken)
				continue;

			if (TokenHolderComp.CanStealToken(TokenName, StealScore))
			{
				return true;
			}
		}

		return false;
	}

	void StealToken(FName TokenName, UGentlemanComponent GentlemanComp)
	{
		TArray<UObject> TokenClaimants;
		GentlemanComp.GetClaimants(TokenName, TokenClaimants);

		float LowestScore = BIG_NUMBER;
		AHazeActor LowestClaimant;

		for (UObject Object : TokenClaimants)
		{
			if (!devEnsure(Object != Owner, "Trying to steal token from yourself. " + Owner.Name + " for " + TokenName))
			{
				return;
			}

			AHazeActor Claimant = Cast<AHazeActor>(Object);
			UGentlemanTokenHolderComponent TokenHolderComp = (Claimant != nullptr) ? UGentlemanTokenHolderComponent::Get(Claimant) : nullptr;

			if (TokenHolderComp == nullptr) 
				continue;

			if (TokenHolderComp.bProtectedToken)
				continue;
			
			if (TokenHolderComp.GetScore(TokenName) < LowestScore)
			{
				LowestScore = TokenHolderComp.GetScore(TokenName);
				LowestClaimant = Claimant;
			}
		}	

		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(LowestClaimant); 
		TargetComp.GentlemanComponent.ReleaseToken(TokenName, LowestClaimant);
	}
}