namespace GravityBladeCombatRush
{
	void CalculateTargetLocationAndRotation(bool bIsInAir, AHazePlayerCharacter Player, UGravityBladeCombatTargetComponent Target, FVector StartLocation, FVector&out TargetLocation, FRotator&out TargetRotation)
	{
		if(Target == nullptr)
			return;

		if(bIsInAir)
		{
			TargetLocation = Target.WorldLocation - (Player.MovementWorldUp * Player.CapsuleComponent.ScaledCapsuleHalfHeight);
			FVector ToTarget = TargetLocation - Player.ActorLocation;
			FVector ToTargetDir = ToTarget.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal();
			TargetLocation -= ToTargetDir * GravityBladeCombat::SuctionDistance;	// Move back to end up in front of the enemy

			ToTarget = Target.WorldLocation - StartLocation;
			TargetRotation = FRotator::MakeFromXZ(ToTarget, Player.MovementWorldUp);
		}
		else
		{
			const FVector TargetLocationOnGroundPlane = Target.WorldLocation.PointPlaneProject(Player.ActorLocation, Player.MovementWorldUp);	// FB TODO: Trace down to find ground?
			FVector ToTarget = TargetLocationOnGroundPlane - Player.ActorLocation;
			const FVector ToTargetDir = ToTarget.GetSafeNormal();
			TargetLocation = TargetLocationOnGroundPlane - (ToTargetDir * GravityBladeCombat::SuctionDistance);	// Move back to end up in front of the enemy

			ToTarget = TargetLocation - StartLocation;
			TargetRotation = FRotator::MakeFromXZ(ToTarget, Player.MovementWorldUp);
		}

		//Debug::DrawDebugCoordinateSystem(TargetLocation, TargetRotation, 100);
	}

	#if EDITOR
	void DebugDraw(FVector StartLocation, FVector TargetLocation, float RushSpeed, float TimeForAnimationToHit)
	{
		float DistanceToTarget = StartLocation.Distance(TargetLocation);
		float TimeToTarget = DistanceToTarget / RushSpeed;
		float AlphaToHit = TimeForAnimationToHit / TimeToTarget;
		FVector Delta = TargetLocation - StartLocation;
		Delta *= (1.0 - AlphaToHit);
		Debug::DrawDebugArrow(StartLocation, StartLocation + Delta, 5, FLinearColor::Yellow);
		Debug::DrawDebugArrow(StartLocation + Delta, TargetLocation, 5, FLinearColor::Red);
	}
	#endif
}