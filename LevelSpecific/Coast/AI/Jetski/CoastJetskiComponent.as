class UCoastJetskiComponent : UActorComponent
{
	ACoastTrainDriver Train;
	FSplinePosition RailPosition;
	TInstigated<float> TrainFollowSpeedAdjustment;
	UHazeActorRespawnableComponent RespawnComp;
	FWaveData WaveData;
	bool bHasDeployed = false;
	TArray<FSplinePosition> SplinePositions; 
	TArray<ACoastJetskiSplineActor> AheadSplines; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner); 
		OnRespawn();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasDeployed = false;

		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
		{
			Train = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor).Driver;
			return;
		}
		if (Owner.AttachParentActor != nullptr)
		{
			Train = Cast<ACoastTrainCart>(Owner.AttachParentActor).Driver;
			return;
		}
		for (AHazePlayerCharacter Player: Game::Players)
		{
			UCoastWaterskiPlayerComponent WaterSkiComp = UCoastWaterskiPlayerComponent::Get(Player);
			if ((WaterSkiComp != nullptr) && (WaterSkiComp.CurrentWaterskiAttachPoint != nullptr))
			{
				ACoastTrainCart TrainCart = Cast<ACoastTrainCart>(WaterSkiComp.CurrentWaterskiAttachPoint.Owner);
				if (TrainCart == nullptr)
					TrainCart = Cast<ACoastTrainCart>(WaterSkiComp.CurrentWaterskiAttachPoint.Owner.AttachParentActor);
				if (TrainCart != nullptr)
					Train = TrainCart.Driver;
				if (Train != nullptr)
				{
					// If spawned from spawner we attach to train cart until deployment.
					if (Owner.AttachParentActor == nullptr)
						Owner.AttachToActor(TrainCart, NAME_None, EAttachmentRule::KeepWorld);	
					return;
				}
			}
		}

		float ClosestDistSqr = BIG_NUMBER;
		ACoastTrainDriver ClosestTrain = nullptr;
		TListedActors<ACoastTrainDriver> Trains;
		for (ACoastTrainDriver TrainDriver : Trains)
		{
			float DistSqr = Owner.ActorLocation.DistSquared2D(TrainDriver.ActorLocation);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				ClosestTrain = TrainDriver;
			}
		}
		Train = ClosestTrain;
	}

	float GetSubmersion() property
	{
		if (WaveData.PointOnWaveNormal == FVector::ZeroVector)
			return 0.0;
		return (WaveData.PointOnWave.Z - Owner.ActorLocation.Z);
	}

	FSplinePosition GetCurrentSplinePosition(UHazeSplineComponent Spline)
	{
		for (FSplinePosition Pos : SplinePositions)
		{
			if (Pos.CurrentSpline == Spline)
				return Pos;
		}
		return FSplinePosition();
	}

	FSplinePosition GetBestSplinePosition(float AheadBuffer)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector VelDir = Owner.ActorVelocity.GetSafeNormal2D();
		FSplinePosition BestPos;
		float BestScore = -1.0;
		FSplinePosition BackupPos;
		float ClosestDist = BIG_NUMBER;
		for (FSplinePosition Pos : SplinePositions)
		{
			// Sanity check in case rail position is out of whack and lets through splines 
			// that are too far ahead/behind (can happen when we get stuck for example)
			float FwdDist = Pos.WorldForwardVector.DotProduct(Pos.WorldLocation - OwnLoc);
			if (Math::Abs(FwdDist) > 1000.0)
				continue;

			// Find spline which we're nearest to edge of as backup
			float HalfWidth = Pos.WorldScale3D.Y * CoastJetskiSpline::WidthScale;
			float SideDist = Math::Abs(Pos.WorldRightVector.DotProduct(OwnLoc - Pos.WorldLocation)) - HalfWidth;
			if (SideDist < ClosestDist)
			{
				BackupPos = Pos;
				ClosestDist = SideDist;
			}

			// Skip any splines we are outside of
			if (SideDist > 0.0)
				continue;	

			// Spline is good if we're well inside of it...
			float Score = 2.0 * Math::Min(0.5, -SideDist / HalfWidth);
			// ...matching velocity direction
			Score += 1.0 * VelDir.DotProduct(Pos.WorldForwardVector);  
			// ...and feeling lucky
			Score += Math::RandRange(0.0, 1.0);
			if (Score > BestScore)
			{
				BestScore = Score;
				BestPos = Pos;
			}
		}

		if (BestPos.IsValid())
			return BestPos;
		return BackupPos;
	}

	bool IsInsideAnySpline(float Buffer = 0.0) const
	{
		for (FSplinePosition Pos : SplinePositions)
		{
			if (IsInsideSplineWidth(Pos, Buffer))
				return true;	
		}
		return false;
	}

	FVector MoveWithinClosestSpline(FVector Location, float Buffer) const
	{
		float ClosestDistSqr = BIG_NUMBER;
		FVector WithinLocation = Location;
		for (FSplinePosition Pos : SplinePositions)
		{
			// Note that this is inaccurate, but should be good enough
			float FwdOffset = Pos.WorldForwardVector.DotProduct(Location - Pos.WorldLocation);
			FTransform Transform = Pos.CurrentSpline.GetWorldTransformAtSplineDistance(Pos.CurrentSplineDistance + FwdOffset);
			FVector RightDir = Transform.Rotation.RightVector;
			float SideOffset = RightDir.DotProduct(Location - Transform.Location);
			float HalfWidth = Transform.Scale3D.Y * CoastJetskiSpline::WidthScale;
			float WithinOffset = Math::Clamp(Math::Abs(SideOffset), 0.0, HalfWidth - Buffer) * Math::Sign(SideOffset);
			FVector MovedLoc = Transform.Location + RightDir * WithinOffset;
			float DistSqr = Location.DistSquared2D(MovedLoc);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				WithinLocation = MovedLoc;
			}
#if EDITOR			
			if (bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugLine(MovedLoc, MovedLoc + FVector(0,0,300), FLinearColor::Gray, 5);		
				Debug::DrawDebugLine(Location, MovedLoc, FLinearColor::Gray, 3);		
			}
#endif
		}

#if EDITOR			
		if (bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Location, Location + FVector(0,0,500), FLinearColor::Yellow, 10);		
			Debug::DrawDebugLine(WithinLocation, WithinLocation + FVector(0,0,600), FLinearColor::Green, 8);		
			Debug::DrawDebugLine(Location, WithinLocation, FLinearColor::Green, 5);		
		}
#endif		
		WithinLocation.Z = Location.Z;
		return WithinLocation;
	}

	bool IsInsideSplineWidth(FSplinePosition Pos, float Buffer = 0.0) const
	{
		if (!Pos.IsValid())
			return false;

		float HalfWidth = Pos.WorldScale3D.Y * CoastJetskiSpline::WidthScale;
		float SideDist = Math::Abs(Pos.WorldRightVector.DotProduct(Owner.ActorLocation - Pos.WorldLocation));
		if (SideDist > HalfWidth - Buffer)
			return false;
		return true;
	}

	bool IsAtChokepoint(float MinWidth, float LookAhead = 0.0) const
	{
		// Considered a chokepoint if there is no spline we're inside which is wider than minwidth
		for (FSplinePosition Pos : SplinePositions)
		{
			float HalfWidth = Pos.WorldScale3D.Y * CoastJetskiSpline::WidthScale; 
			if (LookAhead > 0.0)
				HalfWidth = Pos.CurrentSpline.GetWorldScale3DAtSplineDistance(Pos.CurrentSplineDistance + LookAhead).Y * CoastJetskiSpline::WidthScale;
			float SideDist = Math::Abs(Pos.WorldRightVector.DotProduct(Owner.ActorLocation - Pos.WorldLocation));
			if ((SideDist < HalfWidth) && (HalfWidth > MinWidth * 0.5))
				return false; // Inside spline which is wide enough
		}
		return true;
	}

	float GetSplineHalfWidth(FSplinePosition Pos, float Offset = 0.0)
	{
		if (!Pos.IsValid())
			return 0.0;
		if (Offset > 0.0)
			return Pos.CurrentSpline.GetWorldScale3DAtSplineDistance(Pos.CurrentSplineDistance + Offset).Y * CoastJetskiSpline::WidthScale;
		return Pos.WorldScale3D.Y * CoastJetskiSpline::WidthScale;
	}
}
