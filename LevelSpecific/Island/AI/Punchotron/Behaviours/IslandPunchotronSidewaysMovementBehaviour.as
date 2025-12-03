
// Sidestep while moving towards enemy
class UIslandPunchotronSidewaysMovementBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandPunchotronSettings Settings;

	float CooldownTime = 0.0;
	float LastActivationTime = 0.0;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		LastActivationTime = Time::GetGameTimeSeconds();
		SetRandomCooldown();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Time::GetGameTimeSince(LastActivationTime) < CooldownTime)
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.SidewaysMinRange))
			return false;		
		if (Owner.ActorForwardVector.DotProduct(TargetComp.Target.ActorForwardVector) > 0) // Only move sideways when target is facing self
			return false;
		return true;
	}

	bool bHasTargetLocation = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, Settings.SidewaysTargetLocationRadius))
			return true;
		if (!bHasTargetLocation)
			return true;
		if (Time::GetGameTimeSince(LastActivationTime) > Settings.SidewaysMaxActiveDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SetRandomCooldown();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		LastActivationTime = Time::GetGameTimeSeconds();
		
		FVector ToTargetActor = TargetComp.Target.ActorLocation - Owner.ActorLocation;
		float Dir = Math::RandBool() ? 1.0 : -1.0;
		
		TargetLocation = Owner.ActorLocation + ToTargetActor.GetSafeNormal() * 300.0 + Owner.ActorRightVector * Dir * 300;
		bHasTargetLocation = Pathfinding::StraightPathExists(Owner.ActorLocation, TargetLocation);
		
		FVector DestNavMesh;		
		if (!Pathfinding::FindNavmeshLocation(TargetLocation, 0.0, 100.0, DestNavMesh))
			bHasTargetLocation = false;
		else
			bHasTargetLocation = Pathfinding::StraightPathExists(Owner.ActorLocation, DestNavMesh);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Keep moving towards target!		
		DestinationComp.MoveTowards(TargetLocation, Settings.SidewaysMoveSpeed);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool) 
			Debug::DrawDebugSphere(TargetLocation, 10.0);
#endif
	}

	private void SetRandomCooldown()
	{
		CooldownTime = Math::RandRange(Settings.SidewaysMinCooldown, Settings.SidewaysMaxCooldown);
	}

}