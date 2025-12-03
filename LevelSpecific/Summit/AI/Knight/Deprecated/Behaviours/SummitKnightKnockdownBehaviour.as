class USummitKnightKnockdownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);

	UBasicAIKnockdownComponent KnockdownComp;
	ABasicAICharacter AICharacter;
	FHazeAcceleratedFloat ForceAcc;
	float DownedDuration;
	bool bMove;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(Owner);
		AICharacter = Cast<ABasicAICharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!KnockdownComp.HasKnockdown())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!KnockdownComp.HasKnockdown())
			return true;
		if(ActiveDuration > BasicSettings.KnockdownDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DownedDuration = BasicSettings.KnockdownDuration-2;
		//AnimComp.RequestFeature(FeatureTagSummitRubyKnight::KnockDown, EBasicBehaviourPriority::Medium, this, DownedDuration);
		ForceAcc.SnapTo(5000);
		bMove = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnockdownComp.ConsumeKnockdown();
		TargetComp.SetTarget(nullptr); // Select a new target
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(ActiveDuration > DownedDuration)
			AnimComp.ClearFeature(this);

		if(!bMove)
			return;

		bMove = CanMove(Owner.ActorLocation + KnockdownComp.LastKnockdown.Force * 200);
		if(!bMove)
			return;

		ForceAcc.AccelerateTo(0, BasicSettings.KnockdownDuration, DeltaTime); // TODO: investigate frame rate dependency
		DestinationComp.AddCustomAcceleration(KnockdownComp.LastKnockdown.Force * ForceAcc.Value);
	}
	
	private bool CanMove(FVector PathDest)
	{
		FVector NavMeshDest;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 100.0, NavMeshDest))
			return false;
		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, NavMeshDest))
			return false;
		return true;
	}
}