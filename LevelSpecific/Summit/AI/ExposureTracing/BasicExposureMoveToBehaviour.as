class UBasicExposureMoveToBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	
	default CapabilityTags.Add(n"BasicBehaviourExposureMoveToCapability");
	
	UAIExposureReceiverComponent ReceiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ReceiveComp = UAIExposureReceiverComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (ReceiveComp.GetTarget() == nullptr)
			return false;

		if (Time::GameTimeSeconds < ReceiveComp.ChangeTargetTime + BasicSettings.FindTargetLineOfSightInterval)
			return false;

		if (ReceiveComp.ActiveTargetIsVisible())
			return false;

		if (ReceiveComp.WithinDistanceOfTargetExposurePoint())
			return false;

		if (ReceiveComp.ExposurePoints.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ReceiveComp.GetTarget() == nullptr)
			return true;

		if (ReceiveComp.WithinDistanceOfTargetExposurePoint() && ReceiveComp.ActiveTargetIsVisible())
			return true;

		if (ReceiveComp.WithinDistanceOfPlayer() && ReceiveComp.ActiveTargetIsVisible())
			return true;

		if (ReceiveComp.ExposurePoints.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);

		// Should we step away from the target?
		FVector TargetLoc = ReceiveComp.BestLocation;
		FVector OwnLoc = Owner.ActorLocation;

		DestinationComp.MoveTowards(OwnLoc + (TargetLoc - OwnLoc).GetSafeNormal() * BasicSettings.GentlemanStepBackRange, 650.0);

		Debug::DrawDebugLine(OwnLoc, TargetLoc, FLinearColor::Yellow, 15.0);

		// Look at target
		DestinationComp.RotateTowards(TargetComp.Target);
	}
}