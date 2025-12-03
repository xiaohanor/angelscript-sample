class UIslandWalkerIntroEndBehaviour : UBasicBehaviour
{
	UIslandWalkerPhaseComponent PhaseComp;		
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerLegsComponent LegsComp;		

	FBasicAIAnimationActionDurations Durations;
	bool bLanded = false;
	TArray<AHazeActor> HitActors;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);		
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);		
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (PhaseComp.Phase != EIslandWalkerPhase::IntroEnd)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal() - 0.2)
			return true; // Make sure we don't restart intro
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		WalkerAnimComp.FinalizeDurations(FeatureTagWalker::Intro, SubTagWalkerIntro::End, Durations);
		AnimComp.RequestFeature(FeatureTagWalker::Intro, SubTagWalkerIntro::End, EBasicBehaviourPriority::Medium, this, Durations.GetTotal());	
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::Intro, SubTagWalkerIntro::End, EBasicBehaviourPriority::Medium, this, Durations.GetTotal());
		Owner.AddActorCollisionBlock(this);
		bLanded = false;
		HitActors.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		if (!bLanded)
			Owner.RemoveActorCollisionBlock(this);
		PhaseComp.Phase = EIslandWalkerPhase::Walking;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Durations.IsInActionRange(ActiveDuration))
		{
			if (!bLanded)
			{
				bLanded = true;
				Owner.RemoveActorCollisionBlock(this);
			}

			for(AHazePlayerCharacter Player: Game::Players)
			{
				if(HitActors.Contains(Player)) 
					continue;
				if(!Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 2000))
					continue;
				
				HitActors.AddUnique(Player);
				if(Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 1400))
					Player.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
				else 	
					Player.DealTypedDamage(Owner, 0.8, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);

				FKnockdown Knockdown;
				FVector Dir = (Player.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Player.ActorUpVector).GetNormalizedWithFallback(-Player.ActorForwardVector);
				float Force = Math::Max(2000 - Owner.ActorLocation.Distance(Player.ActorLocation), 0);
				Knockdown.Move = Dir * Force;
				Knockdown.Duration = 1;
				Player.ApplyKnockdown(Knockdown);
				UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);
			}
		}
	}
};