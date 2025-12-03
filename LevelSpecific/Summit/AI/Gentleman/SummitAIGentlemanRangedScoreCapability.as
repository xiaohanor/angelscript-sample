class USummitAIGentlemanRangedScoreCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gentleman");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 200;

	UGentlemanTokenHolderComponent TokenComp;
	UBasicAITargetingComponent TargetComp;

	bool bChangedTarget;

	float CheckInterval = 0.2;
	float IntervalTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TokenComp = UGentlemanTokenHolderComponent::GetOrCreate(Owner); 
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		TargetComp.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TargetComp.GentlemanComponent == nullptr)
			return false;

		if (!TargetComp.GentlemanComponent.IsClaimingToken(GentlemanToken::Ranged, Owner))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bChangedTarget)
			return true;

		if (TargetComp.GentlemanComponent == nullptr) //Not necessary probably lol
			return true;

		if (!TargetComp.GentlemanComponent.IsClaimingToken(GentlemanToken::Ranged, Owner))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bChangedTarget = false;
		UpdateScore();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TokenComp.SetTokenScore(GentlemanToken::Ranged, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > IntervalTime)
		{
		 	UpdateScore();
		}
	}

	UFUNCTION()
	void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{
		bChangedTarget = true;
	}

	void UpdateScore()
	{
		IntervalTime = Time::GameTimeSeconds + CheckInterval;
		float Score = SummitGentlemanToken::GetRangedScore(TargetComp.Target, Owner);
		TokenComp.SetTokenScore(GentlemanToken::Ranged, Score);
	}
}