// Move to current hover scenepoint if not already there
class UEnforcerHoverAtScenepoint : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UEnforcerHoveringSettings HoverSettings;
	UEnforcerHoveringComponent HoveringComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings = UEnforcerHoveringSettings::GetSettings(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (HoveringComp.HoverScenepoint == nullptr)
			return false;
		if (HoveringComp.HoverScenepoint == HoveringComp.StuckWhenMovingToScenepoint)
			return false;
		if (HoveringComp.HoverScenepoint.IsAt(Owner))
			return false; 
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		if (!HoveringComp.HoverScenepoint.CanUse(Owner, true))
		{
			Cooldown.Set(HoverSettings.HoverAtScenepointCooldown);
			return;
		}
		
		HoveringComp.HoverScenepoint.Use(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HoveringComp.HoverScenepoint.Release(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move towards scenepoint until within a fraction of radius
		DestinationComp.MoveTowards(HoveringComp.HoverScenepoint.WorldLocation, HoverSettings.HoverAtScenepointMoveSpeed);

		if (Owner.ActorLocation.IsWithinDist(HoveringComp.HoverScenepoint.WorldLocation, HoveringComp.HoverScenepoint.Radius * 0.25))
		{
			Cooldown.Set(HoverSettings.HoverAtScenepointCooldown);
			return;
		}
	}
}
