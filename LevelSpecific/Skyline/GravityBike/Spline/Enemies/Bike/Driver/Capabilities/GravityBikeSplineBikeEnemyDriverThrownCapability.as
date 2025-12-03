class UGravityBikeSplineBikeEnemyDriverThrownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineBikeEnemyDriver Driver;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
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
		Driver.State = EGravityBikeSplineBikeEnemyDriverState::Thrown;
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
			FVector ToThrowTarget = GrabTargetComp.GetThrowTargetWorldLocation() - Driver.ActorLocation;
			TargetRotation = FQuat::MakeFromX(-ToThrowTarget);
		}
		else
		{
			TargetRotation = FQuat::MakeFromX(-Driver.ActorVelocity);
		}

		FQuat ThrownRotation = Math::QInterpTo(Driver.ActorQuat, TargetRotation, DeltaTime, 100);
		Driver.SetActorRotation(ThrownRotation);
	}
};