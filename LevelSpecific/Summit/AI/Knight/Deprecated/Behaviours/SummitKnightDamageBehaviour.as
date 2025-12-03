class USummitKnightDamageBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);

	USummitMeltComponent MeltComp;

	ABasicAICharacter AICharacter;
	FHazeAcceleratedFloat ForceAcc;
	float DownedDuration;
	bool bMove;
	bool bHit;
	FVector Force;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);

		AICharacter = Cast<ABasicAICharacter>(Owner);

		UTeenDragonTailAttackResponseComponent TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(IsActive())
			return;
		if(!MeltComp.bMelted)
			return;
		Force = Params.RollDirection;
		bHit = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!bHit)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ForceAcc.SnapTo(5000);
		bMove = true;
		bHit = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		MeltComp.ImmediateRestore();
		TargetComp.SetTarget(nullptr); // Select a new target
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!bMove)
			return;

		bMove = CanMove(Owner.ActorLocation + Force * 200);
		if(!bMove)
			return;

		ForceAcc.AccelerateTo(0, BasicSettings.KnockdownDuration, DeltaTime); // TODO: investigate frame rate dependency
		DestinationComp.AddCustomAcceleration(Force * ForceAcc.Value);
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