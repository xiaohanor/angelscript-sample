class ASpaceWalkSplineGravityVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	ASplineActor Spline;
	
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Override;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SplineComp = Spline.Spline;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (IsPlayerInside(Player))
			{
				FSplinePosition SplinePosition = SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
				Player.OverrideGravityDirection(-SplinePosition.WorldUpVector, this, Priority);
			}
		}
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Player.ClearGravityDirectionOverride(this);
		Super::TriggerOnPlayerLeave(Player);
	}
};