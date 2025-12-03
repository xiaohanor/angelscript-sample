class USummitKnightCirclingIntroBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightSettings Settings;

	FHazeAcceleratedFloat AccSpeed;
	bool bHasCompletedIntro = false;
	float IntroDuration;
	float CirclingDistance;
	bool bMoveToCrittersCutsceneLocation = false;

	USummitKnightCirclingIntroBehaviour(bool bMoveToCrittersCutsceneLoc)
	{
		bMoveToCrittersCutsceneLocation = bMoveToCrittersCutsceneLoc;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasCompletedIntro)
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > IntroDuration)
		 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccSpeed.SnapTo(0.0);
		KnightComp.bCanBeStunned.Apply(false, this);
		CrystalBottom.Retract(this);
		
		CirclingDistance = KnightComp.Arena.Radius + Settings.CirclingOutsideDistance;

		IntroDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::CirclingIntro, NAME_None, Settings.CirclingIntroDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::CirclingIntro, EBasicBehaviourPriority::Medium, this, IntroDuration);

		USummitKnightEventHandler::Trigger_OnStartCirlingAngry(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bHasCompletedIntro = true;
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Face center of arena
		DestinationComp.RotateTowards(KnightComp.Arena.Center);

		if (bMoveToCrittersCutsceneLocation)
		{
			// Move to cutscene location
			FVector CutsceneLoc = KnightComp.Arena.Center + (KnightComp.Arena.DeathPosition.WorldLocation - KnightComp.Arena.Center).GetSafeNormal2D() * (KnightComp.Arena.Radius + 500.0); 
			float Dist = Owner.ActorLocation.Dist2D(CutsceneLoc);
			if (Dist < 2000.0)
				AccSpeed.AccelerateTo(Math::GetMappedRangeValueClamped(FVector2D(2000.0, 0.0), FVector2D(1000.0, 10.0), Dist), 1.0, DeltaTime);
			else
				AccSpeed.AccelerateTo(Settings.CirclingIntroSpeed, IntroDuration * 0.25, DeltaTime);
			if (Dist > 10.0)
				DestinationComp.MoveTowardsIgnorePathfinding(CutsceneLoc, AccSpeed.Value);				
		}
		else
		{
			// Move out of arena to circling distance
			FVector OwnLoc = Owner.ActorLocation;
			FVector ArenaCenter = KnightComp.Arena.Center;
			if (OwnLoc.IsWithinDist2D(ArenaCenter, 1.0))
				OwnLoc -= Owner.ActorForwardVector;
			if (ArenaCenter.IsWithinDist2D(OwnLoc, CirclingDistance - 500.0))
				AccSpeed.AccelerateTo(Settings.CirclingIntroSpeed, IntroDuration * 0.25, DeltaTime);
			else
				AccSpeed.AccelerateTo(0.0, IntroDuration * 0.25, DeltaTime);
			FVector CircleDest = ArenaCenter + (OwnLoc - ArenaCenter).GetSafeNormal2D() * CirclingDistance;
			DestinationComp.MoveTowardsIgnorePathfinding(CircleDest, AccSpeed.Value);				
		}

		if(ActiveDuration < 1.4 || ActiveDuration > IntroDuration - 2)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			float FFFrequency = 100.0;
			float FFIntensity = ActiveDuration;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
			Player.SetFrameForceFeedback(FF);
		}
	}
}

