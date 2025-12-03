class USummitWyrmHurtReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UAdultDragonTailSmashModeResponseComponent TailResponseComponent;
	UAcidResponseComponent AcidResponseComp;
	UBasicAIHealthComponent HealthComp;
	USummitWyrmTailComponent TailComp;
	USummitWyrmSettings WyrmSettings;

	TSet<USummitWyrmTailSegmentComponent> HitSegments;

	float OnHitCooldownTime = 0;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TailResponseComponent = UAdultDragonTailSmashModeResponseComponent::GetOrCreate(Owner);
		TailResponseComponent.bShouldStopPlayer = false;
		AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		TailComp = USummitWyrmTailComponent::Get(Owner);
		TailResponseComponent.OnHitBySmashMode.AddUFunction(this, n"OnHitByTailDragon");
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnHitByTailDragon(FTailSmashModeHitParams Params)
	{		
		OnHit(Params.HitComponent, false, 1.0, Params.PlayerInstigator);
	}	

	UFUNCTION()
	private void OnAcidHit(FAcidHit Params)
	{	
		OnHit(Params.HitComponent, true, 1.0, Params.PlayerInstigator);
	}

	private void OnHit(USceneComponent HitComponent, bool bIsMetal, float Damage, AHazeActor Attacker)
	{
		if (!Attacker.HasControl())
			return;

		if (HitComponent == nullptr)
			return;

		USummitWyrmTailSegmentComponent Segment = Cast<USummitWyrmTailSegmentComponent>(HitComponent.AttachParent);
		
		if (Segment == nullptr)
			return;

		if (Segment.bIsMetal != bIsMetal)
		{			
			if (!bIsMetal) // Taildragon hit metal segment
				return;

			// More generous hitbox for metal segment
			// Try to get a neighbouring segment and replace the Segment that was hit.
			// Currently not taking actual distance into account, just number of segments.
			auto MetalSegment = TailComp.GetNearestMetalNeighbour(Segment, WyrmSettings.HurtReactionAcidHitOffsetSteps);
			if (MetalSegment != nullptr)
				Segment = MetalSegment;
			else
				return;
		}

		if (!Segment.IsAlive()) // TODO: might skip health altogether for one hit kills.
			return;

		if (Segment.IsDisabled())
			return;

		if (OnHitCooldownTime > Time::GameTimeSeconds)
			return;

		OnHitCooldownTime = Time::GameTimeSeconds + 0.5;		
		TArray<USummitWyrmTailSegmentComponent> SegmentSequence = TailComp.GetSegmentSequence(Segment);
		CrumbHitSegment(SegmentSequence);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitSegment(TArray<USummitWyrmTailSegmentComponent> SegmentSequence)
	{
		for (auto Seg : SegmentSequence)
		{
			HitSegments.Add(Seg);
		}		
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (HealthComp.IsDead())
			return false;

		if (HitSegments.Num() == 0)
			return false;
				
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > WyrmSettings.HurtReactionDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		HitSegments.Reset();
		
		TailComp.OnEndHurtReaction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + Owner.ActorForwardVector * 1000.0, WyrmSettings.HurtReactionMoveSpeed );

		if (HitSegments.Num() > 0)
			TailComp.OnSegmentDestroyed(WyrmSettings.HurtReactionDuration);
		for (auto Segment : HitSegments)
		{
			// one hit kill for whole sequence
			Segment.TakeDamage(1.0);
			Segment.Disable();
			Segment.TriggerDestroyedEffect();
		
		}
		HitSegments.Reset();

	}

}