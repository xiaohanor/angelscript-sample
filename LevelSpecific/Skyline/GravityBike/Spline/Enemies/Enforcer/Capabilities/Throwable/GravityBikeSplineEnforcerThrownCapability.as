class UGravityBikeSplineEnforcerThrownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineEnforcer Enforcer;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
		GrabTargetComp = Enforcer.GrabTargetComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Thrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Thrown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Enforcer.State = EGravityBikeSplineEnforcerState::Thrown;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrabTargetComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat TargetRotation;
		if(GrabTargetComp.HasThrowTarget())
		{
			FVector ToThrowTarget = GrabTargetComp.GetThrowTargetWorldLocation() - Enforcer.ActorLocation;
			TargetRotation = FQuat::MakeFromX(-ToThrowTarget);
		}
		else
		{
			TargetRotation = FQuat::MakeFromX(-Enforcer.ActorVelocity);
		}

		FQuat ThrownRotation = Math::QInterpTo(Enforcer.ActorQuat, TargetRotation, DeltaTime, 100);
		Enforcer.SetActorRotation(ThrownRotation);
	}
};