class UGravityBikeWhipThrowableGrabbedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeWhipThrowableComponent ThrowableComp;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = UGravityBikeWhipThrowableComponent::Get(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Grabbed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Grabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeWhipThrowableEventHandler::Trigger_OnGrabbed(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Location = GrabTargetComp.GrabMoveData.GetWorldLocation();

		FVector Delta = Location - Owner.ActorLocation;
		FVector Velocity = Delta / DeltaTime;

		Owner.SetActorVelocity(Velocity);

		if(GrabTargetComp.HasThrowTarget() && ThrowableComp.bAimDirection)
		{
			FQuat TargetRotation = FQuat::MakeFromXZ(GrabTargetComp.GetThrowTargetWorldLocation() - Owner.ActorLocation, GravityBikeSpline::GetGlobalUp());
			FQuat Rotation = Math::QInterpConstantTo(Owner.ActorQuat, TargetRotation, DeltaTime, 5);
			//Rotation = Rotation * FQuat(FVector::ForwardVector, Time::GameTimeSeconds * 0.01);
			Owner.SetActorRotation(Rotation);
		}

		Owner.SetActorLocation(Location);
	}
};