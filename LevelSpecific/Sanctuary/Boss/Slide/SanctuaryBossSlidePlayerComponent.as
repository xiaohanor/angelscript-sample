namespace SanctuaryBossSlide
{
	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Start Slide", Category = "Sanctuary|Boss")
	void BP_StartSlide(AActor SomeActorWithSpline, AActor FloatingDirectionReferenceSpline)
	{
		devCheck(SomeActorWithSpline != nullptr, "That spline is no spline");
		USanctuaryBossSlidePlayerComponent MioComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Mio);
		MioComp.BeginSliding(SomeActorWithSpline, FloatingDirectionReferenceSpline);
		USanctuaryBossSlidePlayerComponent ZoeComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Zoe);
		ZoeComp.BeginSliding(SomeActorWithSpline, FloatingDirectionReferenceSpline);
	}


	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Stop Slide", Category = "Sanctuary|Boss")
	void BP_StopSlide()
	{
		USanctuaryBossSlidePlayerComponent MioComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Mio);
		MioComp.StopSliding();
		USanctuaryBossSlidePlayerComponent ZoeComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Zoe);
		ZoeComp.StopSliding();
	}


	UFUNCTION(BlueprintPure, DisplayName = "Sanctuary Is Sliding", Category = "Sanctuary|Boss")
	bool BP_IsSliding()
	{
		USanctuaryBossSlidePlayerComponent MioComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Mio);
		USanctuaryBossSlidePlayerComponent ZoeComp = USanctuaryBossSlidePlayerComponent::GetOrCreate(Game::Zoe);
		return MioComp.IsSliding() || ZoeComp.IsSliding();
	}

}

class USanctuaryBossSlidePlayerComponent : UActorComponent
{
	//access CapabilityAccess = private, * (readonly), USanctuaryBossPlayerSlideCapability;
	private AActor ActorWithSpline;
	private UHazeSplineComponent SplineComp;
	private UHazeSplineComponent FloatingDirectionReferenceSplineComp;

	void BeginSliding(AActor SomeActorWithSpline, AActor FloatingDirectionReferenceSpline)
	{
		ActorWithSpline = SomeActorWithSpline;
		SplineComp = UHazeSplineComponent::Get(ActorWithSpline);

		if(FloatingDirectionReferenceSpline != nullptr)
			FloatingDirectionReferenceSplineComp = Spline::GetGameplaySpline(FloatingDirectionReferenceSpline);
	}

	void StopSliding()
	{
		ActorWithSpline = nullptr;
	}

	bool IsSliding() const
	{
		return IsValid(ActorWithSpline);
	}

	UHazeSplineComponent GetSpline() const
	{
		return SplineComp;
	}

	UHazeSplineComponent GetFloatingDirectionReferenceSpline() const
	{
		return FloatingDirectionReferenceSplineComp;
	}
};