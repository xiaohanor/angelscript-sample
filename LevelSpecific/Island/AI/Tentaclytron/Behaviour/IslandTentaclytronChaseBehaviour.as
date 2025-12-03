
// Move towards enemy
class UIslandTentaclytronChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandTentaclytronSettings Settings;
	AHazePlayerCharacter PlayerTarget;
	FVector TargetOffset;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandTentaclytronSettings::GetSettings(Owner);
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
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetOffset.X = Settings.ChaseTargetOffset.X * Math::RandRange(0.9, 1.0);
		TargetOffset.Y = Settings.ChaseTargetOffset.Y * Math::RandRange(-1.0, 1.0);
		TargetOffset.Z = Settings.ChaseTargetOffset.Z * Math::RandRange(0.9, 1.0);
		UpdateDestination();
	}

	void UpdateDestination()
	{
		Destination = TargetComp.Target.ActorLocation;
		Destination += PlayerTarget.ViewRotation.ForwardVector.GetSafeNormal2D() * TargetOffset.X;
		Destination += PlayerTarget.ViewRotation.RightVector.GetSafeNormal2D() * TargetOffset.Y;
		Destination.Z += TargetOffset.Z;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(Destination, 50.0))
		{
			Cooldown.Set(Settings.ChaseArrivedCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(Destination, BasicSettings.ChaseMoveSpeed);
	}
}