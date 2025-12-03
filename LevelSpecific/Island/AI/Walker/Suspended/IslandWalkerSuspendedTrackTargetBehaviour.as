class UIslandWalkerSuspendedTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UIslandWalkerSettings Settings;
	AHazePlayerCharacter Target;

	UIslandWalkerNeckRoot NeckRoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
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
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetDir = (Target.ActorCenterLocation - Owner.ActorLocation).GetSafeNormal();
		TargetDir = TargetDir.ClampInsideCone(NeckRoot.ForwardVector, 40.0);
		DestinationComp.RotateInDirection(TargetDir);
	}
}