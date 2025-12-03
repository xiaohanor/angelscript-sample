class UVortexSandFishFollowSplineCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

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

		if(!SandFish.bVortexFollowSpline)
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

		if(!SandFish.bVortexFollowSpline)
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
		SandFish.SyncedActorPositionComp.ClearRelativePositionSync(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			SandFish.CurrentDistanceAlongSpline += SandFish.MovementSpeed * DeltaTime;

			if (SandFish.CurrentDistanceAlongSpline >= SandFish.TargetSplineComp.SplineLength && SandFish.bLooping)
				SandFish.CurrentDistanceAlongSpline = 0.0;

			FVector CurLoc = SandFish.TargetSplineComp.GetWorldLocationAtSplineDistance(SandFish.CurrentDistanceAlongSpline);
			SandFish.CurRot = FRotator(SandFish.TargetSplineComp.GetWorldRotationAtSplineDistance(SandFish.CurrentDistanceAlongSpline));

			SandFish.SetActorLocation(CurLoc);

			SandFish.SetActorRotation( Math::RInterpConstantTo(SandFish.ActorRotation, SandFish.CurRot, DeltaTime, 100));

			auto SplinePosition = FSplinePosition(SandFish.TargetSplineComp, SandFish.CurrentDistanceAlongSpline, true);

			SandFish.SyncedActorPositionComp.ApplySplineRelativePositionSync(this, SplinePosition);
		}
		else
		{
			auto SyncedPosition = SandFish.SyncedActorPositionComp.GetPosition();
			SandFish.SetActorLocationAndRotation(SyncedPosition.WorldLocation, SyncedPosition.WorldRotation);
		}
	}
};