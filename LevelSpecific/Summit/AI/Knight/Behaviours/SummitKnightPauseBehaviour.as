class USummitKnightPauseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	float PauseDuration = 1.0;
	ESummitKnightPhase TestingPhase = ESummitKnightPhase::FinalArenaStart;
	USummitKnightStageComponent StageComp;
	USummitKnightComponent KnightComp;
	AHazePlayerCharacter TrackedPlayer;

	USummitKnightPauseBehaviour(float _PauseDuration, ESummitKnightPhase TestPhase = ESummitKnightPhase::None)
	{
		PauseDuration = _PauseDuration;
		TestingPhase = TestPhase;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StageComp = USummitKnightStageComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > PauseDuration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		ESummitKnightPhase Phase = StageComp.Phase;
		if (StageComp.Phase == ESummitKnightPhase::Test)
			Phase = TestingPhase;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		if (OwnLoc.DistSquared2D(TrackedPlayer.ActorLocation) > Math::Square(1.2) * OwnLoc.DistSquared2D(TrackedPlayer.OtherPlayer.ActorLocation))
			TrackedPlayer = TrackedPlayer.OtherPlayer;
		FVector TargetLoc = TrackedPlayer.ActorLocation;
		if (Game::Mio.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, 5000.0))
			TargetLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		DestinationComp.RotateTowards(TargetLoc);	
	}
}

