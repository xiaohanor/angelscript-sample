class UGravityBikeSplineEnforcerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineEnforcer Enforcer;
	AGravityBikeSpline GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Enforcer.IsActive())
			return false;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Enforcer.IsActive())
			return true;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike = GravityBikeSpline::GetGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector ToGravityBike = GravityBike.ActorCenterLocation - Enforcer.ActorCenterLocation;
		FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, ToGravityBike);
		FQuat Rotation = Math::QInterpConstantTo(Enforcer.ActorQuat, TargetRotation, DeltaTime, 500);
		Enforcer.SetActorRotation(TargetRotation);
	}
};