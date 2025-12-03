namespace TazerBot
{
	bool TryGetLandingTarget(ATazerBot TazerBot, FVector NormalizedMagneticForce, FTazerBotLandingTargetQueryResult& OutLandingTarget)
	{
		FTazerBotLandingTargetQuery TargetQuery;
		TargetQuery.TazerBot = TazerBot;
		TargetQuery.Direction = NormalizedMagneticForce;

		TArray<FTazerBotLandingTargetQueryResult> LandingTargetCandidates;

		// Check if we can use a landing target
		TListedActors<ATazerBotLandingTarget> LandingTargets;
		for (auto LandingTarget : LandingTargets)
		{
			if (LandingTarget.CheckTargetable(TargetQuery))
				LandingTargetCandidates.Add(TargetQuery.Result);
		}

		// Get best candidate
		for (auto LandingTargetCandidate : LandingTargetCandidates)
		{
			if (LandingTargetCandidate.Score > OutLandingTarget.Score)
				OutLandingTarget = LandingTargetCandidate;
		}

		return OutLandingTarget.IsValid();
	}
}