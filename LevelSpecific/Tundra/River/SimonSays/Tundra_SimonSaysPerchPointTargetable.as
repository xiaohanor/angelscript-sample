class UTundra_SimonSaysPerchPointTargetable : UTargetableComponent
{
	default TargetableCategory = n"SimonSaysPerch";

	UPROPERTY(EditDefaultsOnly)
	float TargetableRange = 1200.0;

	UPROPERTY(EditDefaultsOnly)
	float CenterMaxAngleDegrees = 30.0;

	UPROPERTY(EditDefaultsOnly)
	float BaseMaxAngleDegrees = 30;

	UPROPERTY(EditDefaultsOnly)
	float CornerMaxAngleDegrees = 89.9;

	UPROPERTY(EditAnywhere)
	bool bDebugAngle = false;

	UPROPERTY(EditAnywhere)
	bool bDebugRange = false;

	ATundra_SimonSaysManager Manager;
	int StageIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Manager = TundraSimonSays::GetManager();
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(Query.DistanceToTargetable < 50.0)
			return false;
		
		Targetable::ApplyTargetableRange(Query, TargetableRange);

		if(Manager.MainState != ETundra_SimonSaysState::PlayerTurn && !IsTileCenterTile())
			return false;

		if(StageIndex < Manager.GetCurrentDanceStageIndex())
			return false;

		if(IsTileCenterTile())
			Query.Result.Score += 1;
		
		float MaxAngle;
		FLinearColor DebugColor;
		if(IsPlayerOnCenterTile(Query.Player))
		{
			MaxAngle = BaseMaxAngleDegrees;
			DebugColor = FLinearColor::Yellow;
		}
		else
		{
			if(IsTileCenterTile())
			{
				MaxAngle = CenterMaxAngleDegrees;
				DebugColor = FLinearColor::Green;
			}
			else
			{
				MaxAngle = CornerMaxAngleDegrees;
				DebugColor = FLinearColor::Red;
			}
		}

		ApplyMovementInputMaxAngle(Query, MaxAngle);

		if(Query.Result.bPossibleTarget)
		{
			if(bDebugAngle)
				Debug::DrawDebugArc(MaxAngle * 2.0, Query.Player.ActorLocation + FVector::UpVector * 10.0, 300.0, (WorldLocation - Query.Player.ActorLocation).GetSafeNormal(), DebugColor, 2.0);

			if(bDebugRange)
				Debug::DrawDebugSphere(WorldLocation, TargetableRange, 12, FLinearColor::Red);
		}
		
		return true;
	}

	bool IsPlayerOnCenterTile(AHazePlayerCharacter Player) const
	{
		auto PlayerComp = UTundra_SimonSaysPlayerComponent::Get(Player);
		return Manager.IsTileCurrentlyIgnored(PlayerComp.CurrentPerchedTile);
	}

	bool IsTileCenterTile() const
	{
		auto Tile = Cast<ACongaDanceFloorTile>(Owner);
		return Manager.IsTileCurrentlyIgnored(Tile);
	}

	void ApplyMovementInputMaxAngle(FTargetableQuery& Query, float MaxAngle) const
	{
		if(!Query.Result.bPossibleTarget)
			return;

		FVector InputVector = Query.PlayerMovementInput;

		if (InputVector.IsNearlyZero())
		{
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return;
		}

		FVector PlayerToTargetableDir = (WorldLocation - Query.PlayerLocation).GetSafeNormal2D();

		float Angle = InputVector.GetAngleDegreesTo(PlayerToTargetableDir);

		if(Angle > MaxAngle)
		{
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
		}

		if(Query.Result.bPossibleTarget)
			Query.Result.Score += (180.0 - Angle) / 180.0;
	}
}