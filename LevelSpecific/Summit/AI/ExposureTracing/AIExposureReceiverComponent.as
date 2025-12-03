class UAIExposureReceiverComponent : UActorComponent
{
	UBasicAITargetingComponent TargetingComp;
	UGentlemanComponent GentlemanComp;

	UPROPERTY(EditAnywhere)
	TArray<AAIExposureScenepointActor> ExposurePoints;

	UPROPERTY(EditAnywhere)
	float MinTargetDistance = 500.0;

	AAIExposureScenepointActor TargetExposurePoint;

	FVector BestLocation;

	float ChangeTargetTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetingComp = UBasicAITargetingComponent::Get(Owner);
		GentlemanComp = UGentlemanComponent::Get(Owner);
		TargetingComp.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ExposurePoints.Num() == 0)
			return;
		
		if (TargetingComp.HasValidTarget())
			BestLocation = GetBestExposedLocation();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{
		if (NewTarget == nullptr)
			return;

		ChangeTargetTime = Time::GameTimeSeconds;
	}

	//Helper function to get visibility
	bool ActiveTargetIsVisible()
	{
		return TargetingComp.HasVisibleTarget();
	}

	//Helper function to get target
	AHazeActor GetTarget()
	{
		return TargetingComp.GetTarget();
	}

	bool WithinDistanceOfTargetExposurePoint()
	{
		if (TargetExposurePoint == nullptr)
			return false;
		
		return (TargetExposurePoint.ActorLocation - Owner.ActorLocation).Size() < ExposureSettings::MinMoveToTargetDistance;
	}

	bool WithinDistanceOfPlayer()
	{
		if (TargetExposurePoint == nullptr)
			return false;

		float CurrentDist = (Owner.ActorLocation - TargetExposurePoint.ActorLocation).Size();
		return CurrentDist < ExposureSettings::MinToPlayerDistanceAllowed;
	}

	private FVector GetBestExposedLocation()
	{
		FVector Location;
		
		if (ExposurePoints.Num() == 0)
			return Location;

		//USE this distance and add it to the score
		for (AAIExposureScenepointActor Point : ExposurePoints)
		{
			float CurrentDist = (Owner.ActorLocation - Point.ActorLocation).Size();
		}

		//Could use Dot product to figure out if moving towards the player (or past them)
		//Could be nice for figuring out which point to player direction is closest to the AI to Player direction towards the player

		AAIExposureScenepointActor ChosenPoint = nullptr;
		float HighestScore = -BIG_NUMBER;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetingComp.Target);
		//Dividers to help scale the scoring
		//The higher the number, the higher the number will go
		float PlayerToPointDistanceScalar = 150.0;
		float EnemyToPointDistanceScalar = 300.0;

		for (AAIExposureScenepointActor Point : ExposurePoints)
		{
			FVector AverageViewLoc = GetAverageLocation(Player, Point);

			FVector PointDirToPlayer = (Player.ActorLocation - AverageViewLoc).GetSafeNormal();
			FVector EnemyDirToPlayer = (Player.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			float Dot = EnemyDirToPlayer.DotProduct(PointDirToPlayer);
			float DistanceScorePlayerToPoint = PlayerToPointDistanceScalar / (Point.ActorLocation - Player.ActorLocation).Size();
			//Limit the player to point score because it gets increasingly higher the closer the player is
			DistanceScorePlayerToPoint = Math::Clamp(DistanceScorePlayerToPoint, 0.0, 0.75);
			
			float DistanceScoreEnemyTopoint = EnemyToPointDistanceScalar / (Point.ActorLocation - Owner.ActorLocation).Size();

			float FinalScore = (Point.GetTargetScore(GetTarget(), TargetExposurePoint == Point) * Dot) + DistanceScorePlayerToPoint + DistanceScoreEnemyTopoint;

			// Debug::DrawDebugString(AverageViewLoc, "Score: " + FinalScore, FLinearColor::LucBlue, 0.0, 1.2);
			// Debug::DrawDebugString(AverageViewLoc, "PlayerDistanceScore: " + DistanceScorePlayerToPoint, FLinearColor::LucBlue, 0.0, 1.0);
			// Debug::DrawDebugLine(Player.ActorLocation, AverageViewLoc, FLinearColor::Green, 20.0);
			// Debug::DrawDebugLine(Player.ActorLocation, Owner.ActorLocation, FLinearColor::Red, 20.0);
		
			if (FinalScore > HighestScore)
			{
				HighestScore = FinalScore;
				ChosenPoint = Point;
			}
		}

		if (TargetExposurePoint == nullptr && ChosenPoint != nullptr)
		{
			TargetExposurePoint = ChosenPoint;
			TargetExposurePoint.AddClaim();
		}

		if (ChosenPoint != nullptr && TargetExposurePoint != nullptr)
		{
			if (ChosenPoint != TargetExposurePoint)
			{
				SwapClaims(ChosenPoint);
				TargetExposurePoint = ChosenPoint;
			}
		}

		if (TargetExposurePoint != nullptr)
		{
			if (Player != nullptr)
				Location = GetAverageLocation(Player, TargetExposurePoint);
		}

		return Location;
	}

	void SwapClaims(AAIExposureScenepointActor NewPoint)
	{
		if (TargetExposurePoint.ClaimedCount > 0)
			TargetExposurePoint.RemoveClaim();

		NewPoint.AddClaim();		
	}

	FVector GetAverageLocation(AHazePlayerCharacter Player, AAIExposureScenepointActor ExposureActor)
	{
		if (Player == nullptr)
			return ExposureActor.ActorLocation;

		FVector AveragePoint;

		for (FVector Point : ExposureActor.GetViewableTracePoints(Player))
		{
			AveragePoint += Point;
		}

		AveragePoint /= ExposureActor.GetViewableTracePoints(Player).Num();

		return AveragePoint;
	}
}