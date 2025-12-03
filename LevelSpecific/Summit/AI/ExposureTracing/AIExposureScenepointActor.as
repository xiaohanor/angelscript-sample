#if EDITOR
class UExposureComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UExposureSceneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UExposureSceneComponent ExposureComp = Cast<UExposureSceneComponent>(Component);
		AAIExposureScenepointActor ExposureActor = Cast<AAIExposureScenepointActor>(ExposureComp.Owner);
		Debug::DrawDebugPoint(FVector(0.0), 199.0, FLinearColor::Red);

		if (ExposureActor == nullptr)
			return;

		for (FVector Point : ExposureActor.BuildPoints())
		{
			DrawWireSphere(Point, 50.0, FLinearColor::Blue);
		}
	}
}
#endif

class UExposureSceneComponent : UActorComponent
{
	// AAIExposureScenepointActor ExposureActor = Cast<AAIExposureScenepointActor>(Owner);

	// TArray<FVector> GetProjectedPoints()
	// {
	// 	TArray<FVector> ProjectedPointsArray = 
	// }
} 

struct FInViewPoints
{
	TArray<FVector> Points;
}

class AAIExposureScenepointActor : AScenepointActor
{
	int GridSize;

	UPROPERTY(DefaultComponent)
	UExposureSceneComponent ExposureSceneComp;

	UPROPERTY(EditAnywhere)
	float Radius = 2500.0;

	UPROPERTY(EditAnywhere)
	float GridOffset = 600.0;

	float ZOffset = 50.0;

	TArray<FVector> TracePoints;
	// FVector Average
	TPerPlayer<float> TargetScore;
	TPerPlayer<FInViewPoints> InViewPoints;

	FHazeTraceDebugSettings DebugSettings;
	default DebugSettings.TraceColor = FLinearColor::Red;

	//Who is tethered to this point
	int ClaimedCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TracePoints = BuildPoints();
	}

	TArray<FVector> BuildPoints()
	{
		TArray<FVector> ProjectedPointsArray;

		GridSize = Math::FloorToInt(Radius / GridOffset);
		
		int HalfValue = Math::FloorToInt((GridSize * GridOffset) / 2);

		for (int x = 0; x < GridSize; x++)
		{
			float XOffset = (GridOffset / 2) + (GridOffset * x) - HalfValue;

			for (int y = 0; y < GridSize; y++)
			{
				float YOffset = (GridOffset / 2) + (GridOffset * y) - HalfValue;

				FVector Start = ActorLocation + FVector(0.0, 0.0, 200.0);
				FVector NewPos = Start + FVector(XOffset, YOffset, 0.0);
				float Dist = (NewPos - Start).Size();

				if (Dist < Radius / 2)
				{
					FHazeTraceSettings DownTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
					DownTrace.UseLine();
					FHitResult Hit = DownTrace.QueryTraceSingle(NewPos, NewPos - FVector(0.0, 0.0, 1000.0));

					if (Hit.bBlockingHit)
					{
						FVector NewPoint = Hit.ImpactPoint + FVector(0.0, 0.0, 100.0);
						ProjectedPointsArray.Add(NewPoint);	
					}
				}
			}
		}

		return ProjectedPointsArray;
	}

	TArray<FVector> GetViewableTracePoints(AHazePlayerCharacter Player)
	{
		return InViewPoints[Player].Points;
	}

	void RunTraceScore(AHazePlayerCharacter Player, float DebugTraceDuration)
	{
		InViewPoints[Player].Points.Empty();

		float InView = 0;

		if (Player == Game::Mio)
			ZOffset = 30.0;
		else
			ZOffset = 20.0;

		// Debug::DrawDebugSphere(ActorLocation + FVector(0.0, 0.0, 100.0), 20.0, 12, FLinearColor::Blue);

		for (FVector Point : TracePoints)
		{
			FVector DebugLoc = Point + (FVector::UpVector * ZOffset);
			FHazeTraceSettings Trace;
			Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseLine();
			Trace.SetTraceComplex(false);
			Trace.IgnoreActor(Player);
			Trace.IgnoreActor(Player.OtherPlayer);

			FHitResult Hit = Trace.QueryTraceSingle(Point, Player.ActorCenterLocation);
			
			if (!Hit.bBlockingHit)
			{
				InView++;
				InViewPoints[Player].Points.Add(Point);
				// Debug::DrawDebugSphere(DebugLoc, 60.0, 12, FLinearColor::Green, Duration = DebugTraceDuration);
			}
			else
			{
				// Debug::DrawDebugSphere(DebugLoc, 40.0, 12, FLinearColor::Red, Duration = DebugTraceDuration);
			}
		}	

		TargetScore[Player] = InView / TracePoints.Num();
	}

	float GetTargetScore(AHazeActor Target, bool bIsClaimed)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);

		if (Player == nullptr)
			return 0;

		if (bIsClaimed)
		{
			return TargetScore[Player];
		}

		if (ClaimedCount > 1)
		{
			return TargetScore[Player] / float(ClaimedCount);
		}	
			
		return TargetScore[Player];
	}

	void AddClaim()
	{
		ClaimedCount++;
	}

	void RemoveClaim()
	{
		ClaimedCount--;
		ClaimedCount = Math::Max(ClaimedCount, 0);
	}
}