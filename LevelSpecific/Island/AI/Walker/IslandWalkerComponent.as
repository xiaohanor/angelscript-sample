enum EISlandWalkerAttackType
{
	None,
	Laser,
	FireBurst,
	SideSlam,
	SpinningLaser,
	Jump,
	Reposition,
	Spawn,
	SprayGas,
	HeadCharge,
}

namespace IslandWalker
{
	const FName SuspendedInstigator = n"SuspendedInstigator";
}	

class UIslandWalkerComponent : UActorComponent
{
	bool bSuspended;
	bool bSpawning;
	float TrackTargetDuration = 0.0;
	float SuspendIntroCompleteTime = BIG_NUMBER;
	int NumSuspendedSprayGasWithNoSpawn = 0;
	bool bFrontCableCut = false;
	bool bRearCableCut = false;
	int LaserAttackCount = 0;
	int FireBurstCount = 0;

	UPROPERTY()
	TSubclassOf<AIslandWalkerShockwave> ShockWaveClass;
	AIslandWalkerShockwave ShockWave;

	AIslandWalkerArenaLimits ArenaLimits;

	EISlandWalkerAttackType LastAttack = EISlandWalkerAttackType::None;

	TArray<AIslandWalkerSuspensionCable> DeployedCables;

	EWalkerHatch CurrentOpenHatch = EWalkerHatch::None;

	UIslandWalkerSettings Settings;

	UIslandWalkerLaserEmitterComponent Laser;

	TArray<FName> DestroyedLegs; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	FVector GetSuspendLocation()
	{
		if (DeployedCables.Num() == 0)
			return Owner.ActorLocation;

		FVector CableLocSum = FVector::ZeroVector;
		for (AIslandWalkerSuspensionCable Cable : DeployedCables)
		{
			CableLocSum += Cable.ActorLocation;
		}
		FVector SuspendLoc = CableLocSum / float(DeployedCables.Num()); // We can only get past lifttime when we deployed cables
		SuspendLoc.Z = ArenaLimits.Height + Settings.SuspendHeight;
		return SuspendLoc;
	}

	bool IsNearArenaEdge(FVector Location, float Range) const
	{
		if (ArenaLimits == nullptr)
			return false;

		FVector Offset = Location - ArenaLimits.ActorLocation;
		float ForwardDist = Math::Abs(Offset.DotProduct(ArenaLimits.ActorForwardVector));   
		if (ForwardDist > ArenaLimits.OuterSize.BoxExtent.X - Range)
			return true;
		float SideDist = Math::Abs(Offset.DotProduct(ArenaLimits.ActorRightVector));   
		if (SideDist > ArenaLimits.OuterSize.BoxExtent.Y - Range)
			return true;
		return false; 
	}

	bool CanPerformAttack(EISlandWalkerAttackType Attack)
	{
		if (Attack == LastAttack)
			return false;

		switch (Attack)
		{
			case EISlandWalkerAttackType::Laser:
			{
				if (LastAttack == EISlandWalkerAttackType::SpinningLaser)	
					return false;
				break;
			}
			case EISlandWalkerAttackType::SpinningLaser:
			{
				if (LastAttack == EISlandWalkerAttackType::Laser)	
					return false;
				break;
			}
			default: 
				return true;
		}
		return true;
	}

	void UpdateCables(float DeltaTime)
	{
		for (AIslandWalkerSuspensionCable Cable : DeployedCables)
		{
			Cable.Update(DeltaTime);
		}
	}

	void MoveCables(FVector CenterDestination, FVector FocusLocation, float MoveDuration)
	{
		if (ArenaLimits == nullptr)
			return;

		// Use walker transform as it would be in a while so cables will lead walker movement
		FTransform WalkerTransform = Owner.ActorTransform;
		FTransform WantedTransform = WalkerTransform;
		WantedTransform.Location = Math::Lerp(WalkerTransform.Location, CenterDestination, 0.25);
		WantedTransform.Rotation = FQuat::Slerp(WalkerTransform.Rotation, (FocusLocation - CenterDestination).GetSafeNormal2D().ToOrientationQuat(), 1.0);

		for (AIslandWalkerSuspensionCable Cable : DeployedCables)
		{
			if (Cable.CouplingComp == nullptr)
				continue;

			FVector CouplingPredictedLoc = WantedTransform.TransformPosition(WalkerTransform.InverseTransformPosition(Cable.CouplingComp.WorldLocation));
			FVector PredictedDir = WantedTransform.TransformVector(Cable.IdealDirectionFromWalkerLocal).GetSafeNormal2D();
			FVector RailLoc = ArenaLimits.GetInnerEdgeLocationFromRay(CouplingPredictedLoc, PredictedDir, 800.0);
			RailLoc.Z = Cable.SplinePos.CurrentSpline.WorldLocation.Z;
			FSplinePosition SplinePos = ArenaLimits.CablesRail.GetClosestSplinePositionToWorldLocation(RailLoc);
			Cable.TargetDistAlongSpline = SplinePos.CurrentSplineDistance;
			Cable.MoveAlongSplineDuration = MoveDuration;	

#if EDITOR
			if (Owner.bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugSphere(CouplingPredictedLoc, 200, 6, FLinearColor::Purple);
				Debug::DrawDebugLine(CouplingPredictedLoc, CouplingPredictedLoc + PredictedDir * 5000.0, FLinearColor::Purple, 20);
				Debug::DrawDebugLine(CouplingPredictedLoc, CouplingPredictedLoc + WantedTransform.Rotation.ForwardVector * 1000.0, FLinearColor::Yellow, 20);
				Debug::DrawDebugSphere(RailLoc - FVector(0,0,500), 200, 4, FLinearColor::Yellow);
			}
#endif
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(ArenaLimits.GetAtFloodedPoolDepth(FocusLocation, 1000), 200, 6, FLinearColor::Green);
			Debug::DrawDebugLine(ArenaLimits.GetAtFloodedPoolDepth(CenterDestination, 1000), ArenaLimits.GetAtFloodedPoolDepth(FocusLocation, 1000), FLinearColor::Green, 20);
		}
#endif
	}

	void SpawnShockWave()
	{
		if (ShockWave != nullptr)
			return;
		ShockWave = SpawnActor(ShockWaveClass, Owner.ActorLocation, Owner.ActorRotation, NAME_None, true, Owner.Level);
		ShockWave.MakeNetworked(this, n"ShockWave");
		ShockWave.Instigator = Cast<AHazeActor>(Owner);
		FinishSpawningActor(ShockWave);
	}
}

