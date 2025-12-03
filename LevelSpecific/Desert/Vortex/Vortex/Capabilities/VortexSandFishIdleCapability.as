class UVortexSandFishIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVortexSandFish SandFish;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Vortex)
			return false;

		if(!SandFish.bVortexMovementActive)
			return false;

		if(SandFish.bVortexFollowSpline)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Vortex)
			return true;

		if(!SandFish.bVortexMovementActive)
			return true;

		if(SandFish.bVortexFollowSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector CurLoc = Math::VInterpConstantTo(SandFish.ActorLocation, SandFish.TargetSplineComp.GetWorldLocationAtSplineDistance(0), DeltaTime, SandFish.MovementSpeed);
			SandFish.CurRot = FRotator(SandFish.TargetSplineComp.GetWorldRotationAtSplineDistance(0));

			SandFish.SetActorLocation(CurLoc);

			if(SandFish.ActorLocation.PointsAreNear(SandFish.TargetSplineComp.GetWorldLocationAtSplineDistance(0), 0.1))
			{	
				SandFish.bVortexFollowSpline = true;
				SandFish.CurrentDistanceAlongSpline = 0;
			}

			SandFish.SetActorRotation(Math::RInterpConstantTo(SandFish.ActorRotation, SandFish.CurRot, DeltaTime, 100));
		}
		else
		{
			auto SyncedPosition = SandFish.SyncedActorPositionComp.GetPosition();
			SandFish.SetActorLocationAndRotation(SyncedPosition.WorldLocation, SyncedPosition.WorldRotation);
		}
	}
};