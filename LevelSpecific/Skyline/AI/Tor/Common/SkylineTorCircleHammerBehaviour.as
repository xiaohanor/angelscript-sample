
// Move towards enemy
class USkylineTorCircleHammerBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USkylineTorHoldHammerComponent HoldHammerComp;
	FVector HammerLocation;
	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
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
		HammerLocation = Owner.ActorLocation;
		Target = TargetComp.Target;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Disarmed)
			HammerLocation = HoldHammerComp.Hammer.ActorLocation;

		FVector Dir = (Target.ActorLocation - HammerLocation).GetSafeNormal2D();
		FVector TargetLocation = HammerLocation + Dir * 400;

		if (Owner.ActorLocation.IsWithinDist(TargetLocation, 50))
		{
			Cooldown.Set(0.5);
			return;
		}

		DestinationComp.MoveTowards(TargetLocation, 200);
	}
}