class UGravityBikeSplineBikeEnemyDriverDrivingCapability : UHazeCapability
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
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Driver.State != EGravityBikeSplineBikeEnemyDriverState::Driving)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Driver.State != EGravityBikeSplineBikeEnemyDriverState::Driving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Driver.State = EGravityBikeSplineBikeEnemyDriverState::Driving;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
		{
			FVector RelativeLocation = Math::VInterpConstantTo(Driver.Mesh.RelativeLocation, FVector::ZeroVector, DeltaTime, 1000);
			Driver.Mesh.SetRelativeLocation(RelativeLocation);
		}
		else
		{
			FVector RelativeLocation = Math::VInterpConstantTo(Driver.Mesh.RelativeLocation, FVector(-5, 0, -125), DeltaTime, 1000);
			Driver.Mesh.SetRelativeLocation(RelativeLocation);
		}
	}
};