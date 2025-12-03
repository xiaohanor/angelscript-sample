class UBattlefieldHoverboardLevelRubberbandingSplineComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldRubberband = true;

	UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Owner);

	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif

		for(auto Player : Game::Players)
		{
			auto LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);
			LevelRubberbandingComp.LevelRubberBandSplineComp = this;
		}
	}
};