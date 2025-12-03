// Move towards enemy
class UIslandZoomotronChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandZoomotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandZoomotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.ChaseMaxRange))
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
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.ChaseMinRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ChaseLocation = TargetComp.Target.ActorLocation;
		ChaseLocation.Z += Settings.FlyingChaseHeight;

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, Settings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, Settings.ChaseMoveSpeed);
		
		//auto MeshComp = UStaticMeshComponent::Get(Owner);
		//MeshComp.AddRelativeRotation(FRotator(1, 1, 1));
		//FVector DirStart = Owner.ActorForwardVector.RotateAngleAxis(DeltaTime, Owner.ActorRightVector).GetSafeNormal(); // TODO: make setting		
		//Owner.SetActorRotation(DirStart.ToOrientationQuat());
	}
}