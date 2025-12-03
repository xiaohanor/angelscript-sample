
// Move towards enemy
class USkylineGeckoChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	USkylineGeckoSettings Settings;
	FVector Destination;
	AHazePlayerCharacter Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		Destination = GetDestination(SceneView::IsInView(Target, Owner.ActorCenterLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(Target == nullptr)
			return;

		bool bInTargetView = SceneView::IsInView(Target, Owner.ActorCenterLocation);	
		if (bInTargetView && Owner.ActorLocation.IsWithinDist(Destination, Settings.ChaseMinRange))
		{
			Cooldown.Set(Settings.ChaseMinRangeCooldown);
			return;
		}

		if (ShouldUpdateDestination())
			Destination = GetDestination(bInTargetView);

		// Keep moving towards target!
		DestinationComp.MoveTowards(Destination, Settings.ChaseMoveSpeed);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorCenterLocation, Destination);
			Debug::DrawDebugLine(Destination, Destination + FVector(0.0, 0.0, 200.0));
		}
#endif		
	}

	FVector GetDestination(bool bInView) const
	{
		if (bInView)
			return Target.ActorLocation;

		// Not in view, run to side position
		FVector FromTarget = Owner.ActorLocation - Target.ActorLocation;
		FVector Side = Target.ViewRotation.RightVector;
		if (Side.DotProduct(FromTarget) < 0.0)
			Side = -Side;
		FVector Fwd = Target.ViewRotation.ForwardVector;
		return Target.ActorLocation + Fwd * Settings.ChaseMinRange * 2.0 + Side	* Settings.ChaseMinRange;
	}

	bool ShouldUpdateDestination()
	{
		// Has target moved away from destination?
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		if (TargetLoc.IsWithinDist(Destination, Settings.ChaseMinRange * 0.75))
			return false;

		return true;
	}
}