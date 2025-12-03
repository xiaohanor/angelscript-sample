class USkylineTorHammerExposedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerStateManager HammerStateManager;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FVector FallDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		HammerStateManager = USkylineTorHammerStateManager::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Exposed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Exposed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HammerStateManager.EnableWhipTargetComp(this);
		Owner.AddActorCollisionBlock(this);
		HealthBarComp.SetHealthBarEnabled(false);
		AccLocation.SnapTo(Owner.ActorLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		FallDirection = (Game::Zoe.ActorLocation - HammerComp.HoldHammerComp.Owner.ActorLocation).GetSafeNormal2D();
		HammerComp.HoldHammerComp.Hammer.WhipResponse.bGrabRequiresButtonMash = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HammerStateManager.ClearWhipTargetComp(this);
		Owner.RemoveActorCollisionBlock(this);
		HammerComp.HoldHammerComp.Hammer.WhipResponse.bGrabRequiresButtonMash = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 0.1)
			return;

		AActor HammerOwner = HammerComp.HoldHammerComp.Owner;
		FVector TargetLocation = HammerOwner.ActorLocation + FallDirection * 200 + FVector::UpVector * 25;
		AccLocation.AccelerateTo(TargetLocation, 0.25, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;

		FRotator TargetRotation = HammerOwner.ActorRightVector.Rotation() + FRotator(0, 90,-90);
		AccRotation.AccelerateTo(TargetRotation, 0.25, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;
	}
}