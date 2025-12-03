class USummitWyrmAttackPositioningBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	
	USummitWyrmSettings WyrmSettings;

	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, WyrmSettings.AttackPositioningRange))
			return false;
		
		FVector FromTarget = Owner.ActorLocation - TargetComp.Target.ActorLocation;
		if (TargetComp.Target.ActorForwardVector.DotProduct(FromTarget) > 0.0)
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

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);				
		UCameraSettings CameraSettings =  UCameraSettings::GetSettings(Player);
		CameraSettings.IdealDistance.ApplyAsAdditive(WyrmSettings.AttackPositioningCameraExtraDistance, this, WyrmSettings.AttackPositioningCameraBlendTime);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		UCameraSettings CameraSettings =  UCameraSettings::GetSettings(Player);		
		CameraSettings.IdealDistance.Clear(this);
		TargetComp.SetTarget(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Destination = TargetComp.Target.ActorTransform.TransformPosition(WyrmSettings.AttackPositioningTargetOffset);
		
		// Scale MoveSpeed by distance to Destination				
		const float SlowDownRadiusSqr = Math::Square(WyrmSettings.AttackPositioningSlowDownRadius);
		float RemainingDist = Destination.DistSquared(Owner.GetActorLocation());
		float MoveSpeedScale = RemainingDist < SlowDownRadiusSqr ? RemainingDist / SlowDownRadiusSqr : 1.0;

		DestinationComp.MoveTowardsIgnorePathfinding(Destination, WyrmSettings.AttackPositioningMoveSpeed * MoveSpeedScale);
	}
}


