class UIslandShieldotronSidescrollerAvoidBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		float EvadeHorizontalRange = 200;
		float ToTargetX = Math::Abs(TargetComp.Target.ActorLocation.X - Owner.ActorLocation.X);
		if (ToTargetX > EvadeHorizontalRange)
			return false;
		if (Math::Abs(TargetComp.Target.ActorLocation.Z - Owner.ActorLocation.Z) < 200)
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc);
		AwayFromTarget.Y = 0.0;
		AwayFromTarget.Z = 0.0;
		AwayFromTarget.Normalize();

		// Switch direction if cornered.
		if (DestinationComp.MoveFailed())
			AwayFromTarget.X = AwayFromTarget.X * -1.0;

		FVector AwayLoc = OwnLoc + AwayFromTarget * (DestinationComp.MinMoveDistance + 60);
		AwayLoc.Y = Owner.ActorLocation.Y;
		//Debug::DrawDebugSphere(AwayLoc, 20, 12, Duration = 1.0);

		DestinationComp.MoveTowards(AwayLoc, BasicSettings.EvadeMoveSpeed);
	}
}