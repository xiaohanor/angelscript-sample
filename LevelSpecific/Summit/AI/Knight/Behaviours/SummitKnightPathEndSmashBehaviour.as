class USummitKnightPathEndSmashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	
	FBasicAIAnimationActionDurations Durations;

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	AHazePlayerCharacter TrackedPlayer;

	// We slide mesh forward some ways to reach arena
	UHazeSkeletalMeshComponentBase Mesh;
	FVector MeshLoc;

	float ImpactTime = BIG_NUMBER;
	FVector SlideForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		MeshLoc = Mesh.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		// This should only be used when there are at least one player in path end arena
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Durations.Telegraph = Settings.PathEndSmashTelegraphDuration;
		Durations.Anticipation = Settings.PathEndSmashAnticipationDuration;
		Durations.Action = Settings.PathEndSmashActionDuration;
		Durations.Recovery = Settings.PathEndSmashRecoverDuration;
		// KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::PhaseOne, SummitKnightSubTagsPhaseOne::PathEndSmash, Durations);
		// AnimComp.RequestAction(SummitKnightFeatureTags::PhaseOne, SummitKnightSubTagsPhaseOne::PathEndSmash, EBasicBehaviourPriority::Medium, this, Durations);

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		// Hack since we use temp anim for now
		ImpactTime = Durations.PreActionDuration + Durations.Action * 0.2;
		SlideForward.X = Math::Clamp(Owner.ActorLocation.Dist2D(TrackedPlayer.ActorLocation) - 3000.0, 0.0, Settings.PathEndSmashSlideForwardOffset.X);
		SlideForward.Y = Settings.PathEndSmashSlideForwardOffset.Y;
		SlideForward.Z = Settings.PathEndSmashSlideForwardOffset.Z;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Mesh.RelativeLocation = MeshLoc;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ImpactTime)
		{
			ImpactTime = BIG_NUMBER;
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (!Player.ActorLocation.IsWithinDist2D(Sceptre.HeadLocation, Settings.PathEndSmashHitRadius))
					continue;
				// Damage is replicated
				auto HealthComp = UPlayerHealthComponent::Get(Player);
				HealthComp.DamagePlayer(1.0, nullptr, nullptr, false);
			}

			//USummitKnightEventHandler::Trigger_OnPathEndSmashImpact(Owner, FSummitKnightSceptreImpactParams(Sceptre, KnightComp.Arena));
		}

		if (ActiveDuration < Durations.Telegraph)
		{
			FVector TargetLoc = GetTargetLocation();
			DestinationComp.RotateTowards(TargetLoc);	

			// Slide mesh to reach arena
			float Alpha = ActiveDuration / Durations.Telegraph;
			FVector SlideLoc = MeshLoc;
			SlideLoc = Math::EaseInOut(MeshLoc, SlideForward, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if (Durations.IsInRecoveryRange(ActiveDuration))
		{
			// Slide mesh back
			float Alpha = Durations.GetRecoveryRangeAlpha(ActiveDuration);
			FVector SlideLoc = MeshLoc;
			SlideLoc = Math::EaseInOut(SlideForward, MeshLoc, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}
	}

	FVector GetTargetLocation()
	{
		FVector TargetLoc = TrackedPlayer.ActorLocation;
		if (KnightComp.Arena.IsInsideArena(TrackedPlayer.OtherPlayer.ActorLocation))
			TargetLoc = (TrackedPlayer.ActorLocation + TrackedPlayer.OtherPlayer.ActorLocation) * 0.5;
		return TargetLoc;
	}
}

