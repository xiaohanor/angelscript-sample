// Keep height offset relative to target
class UIslandFloatotronHeightOffsetBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandFloatotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandFloatotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Math::Abs(Owner.ActorLocation.Z - TargetComp.Target.ActorLocation.Z) > 100 && Math::Abs(Owner.ActorLocation.Z - TargetComp.Target.ActorLocation.Z) < Settings.FlyingChaseMinHeight + 100)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DestLocation = Owner.ActorLocation;	
		DestLocation.Z = TargetComp.Target.ActorLocation.Z + Settings.FlyingChaseMinHeight;
	
		DestinationComp.MoveTowards(DestLocation, Settings.SidescrollerChaseMoveSpeed*0.5);
	}
}