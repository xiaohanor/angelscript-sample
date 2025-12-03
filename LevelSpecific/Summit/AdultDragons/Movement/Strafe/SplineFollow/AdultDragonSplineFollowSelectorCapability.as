struct FAdultDragonSplineSelectorDeactivationParams
{
	AActor BestSpline;
	float BlendTime;
}

class UAdultDragonSplineFollowSelectorCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UAdultDragonSplineFollowManagerComponent Manager;
	UAdultDragonStrafeSettings StrafeSettings;
	const float DefaultSplineSwitchBlendTime = 3.0;

	float NextSplineSelectionTime = 0;
	float SplineSwitchBlendTime = DefaultSplineSwitchBlendTime;
	AActor BestSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UAdultDragonSplineFollowManagerComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
		UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION()
	private void OnDeath()
	{
		BestSpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Manager.AutoSelectableSplines.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAdultDragonSplineSelectorDeactivationParams& Params) const
	{
		if(Manager.AutoSelectableSplines.Num() == 0)
		{
			Params.BestSpline = BestSpline;
			Params.BlendTime = SplineSwitchBlendTime;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAdultDragonSplineFollowData CurrentSplineData = Manager.GetSplineFollowData();
		if (CurrentSplineData.SplineTag == NAME_None)
		{
			BestSpline = CurrentSplineData.GetMostActiveSplinePosition().CurrentSpline.Owner;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAdultDragonSplineSelectorDeactivationParams Params)
	{
		if (IsBlocked())
			return;

		if (Params.BestSpline != nullptr && HasControl())
		{
			Manager.SetSplineToFollow(Params.BestSpline, false, BlendTime = Params.BlendTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("BestSpline", BestSpline);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < NextSplineSelectionTime)
			return;

		TArray<ASplineActor> AutoSelectableSplines;
		for (auto It : Manager.AutoSelectableSplines)
		{
			AutoSelectableSplines.Append(It.Value.AutoSelectableSplines);
		}

		FVector PlayerLocation = Player.ActorLocation;
		FVector PlayerForward = Player.ActorForwardVector;

		float BestScore = BIG_NUMBER;
		ASplineActor BestActor = nullptr;
		for (auto It : AutoSelectableSplines)
		{
			auto SplineFollowComp = USummitAdultDragonSplineFollowComponent::Get(It);
			if (SplineFollowComp == nullptr)
				continue;

			auto SplinePoint = It.Spline.GetClosestSplinePositionToWorldLocation(PlayerLocation);
			float DistScore = SplinePoint.WorldLocation.DistSquared(PlayerLocation);
			float Dot = (1 - PlayerForward.DotProductNormalized(SplinePoint.WorldForwardVector));
			float AngleScore = Dot * 1000;
			float TotalScore = DistScore + AngleScore;
			if (TotalScore > BestScore)
				continue;

			// End of the spline
			if (!SplinePoint.Move(1))
				continue;

			BestScore = TotalScore;
			BestActor = It;
		}

		if (BestActor == nullptr)
			return;

		auto CurrentSplineData = Manager.GetSplineFollowData().GetMostActiveSplinePosition();
		if (CurrentSplineData.CurrentSpline != nullptr && CurrentSplineData.CurrentSpline.Owner == BestActor)
			return;

		if (Manager.SelectionZone != nullptr)
			SplineSwitchBlendTime = Manager.SelectionZone.SplineSwitchBlendTime;
		else
			SplineSwitchBlendTime = DefaultSplineSwitchBlendTime;

		//FName SplineTag = NAME_None;
		// if(BestActor != BestSpline)
		// SplineTag = n"BranchingSpline";
		BestSpline = BestActor;
		//Note (David): NAME_None overrides the "main" spline on the manager, currently we have no need to traverse to a previous spline so just override.
		Manager.SetSplineToFollow(BestActor, false, NAME_None, SplineSwitchBlendTime);
		NextSplineSelectionTime = Time::GameTimeSeconds + 2;
	}
};