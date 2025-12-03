class UFitnessUserComponent : UActorComponent
{
	AHazeActor HazeOwner;
	UFitnessSettings FitnessSettings;
	float FitnessMultiplier;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		FitnessSettings = UFitnessSettings::GetSettings(HazeOwner);
	}

	float GetFitnessScore(AHazePlayerCharacter Player)
	{
		return GetFitnessScoreAtLocation(Player, HazeOwner.ActorCenterLocation);
	}

	float GetFitnessScoreAtLocation(AHazePlayerCharacter Player, FVector Location)
	{	
		if(Player == nullptr)
			return -BIG_NUMBER;

		FVector ViewDir = Player.ViewRotation.Vector();
		FVector ToAIDir = (Location - Player.ActorCenterLocation).GetSafeNormal();
		float Dist = Location.Distance(Player.ActorCenterLocation);
		float Score = (10000.0 / Math::Max(Dist, 1.0)) * Math::Pow(Math::Max(ViewDir.DotProduct(ToAIDir), 0.0), 3.0);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float OptimalRange = (10000.0 / FitnessSettings.OptimalThresholdMax);
			FVector DebugForward = ViewDir; //.VectorPlaneProject(Player.ActorUpVector).GetSafeNormal();
			FVector PrevLoc = Player.ActorCenterLocation + DebugForward * OptimalRange * ViewDir.DotProduct(DebugForward);
			for(float Yaw = 10; Yaw < 361; Yaw += 10)
			{
				FVector Direction = DebugForward.RotateAngleAxis(Yaw, FVector::UpVector);
				float Distance = OptimalRange * Math::Pow(Math::Max(ViewDir.DotProduct(Direction), 0.0), 3.0);
				FVector DebugLoc = Player.ActorCenterLocation + Direction * Distance;
				//FLinearColor LineColor = Score >= FitnessSettings.OptimalThresholdMax ? FLinearColor::Teal : FLinearColor::Red;
				// Debug::DrawDebugLine(PrevLoc, DebugLoc, LineColor, 10.0);
				PrevLoc = DebugLoc;
			}
		}
#endif

		return Score;
	}

	bool ShouldMoveToLocation(AHazePlayerCharacter Player, FVector Location)
	{
		bool CurrentFitness = IsFitnessOptimalAtLocation(Player, HazeOwner.ActorCenterLocation);
		bool TargetFitness = IsFitnessOptimalAtLocation(Player, Location);

		bool BothOptimal = CurrentFitness && TargetFitness;
		bool BothSubOptimal = !CurrentFitness && !TargetFitness;

		bool FromOptimalToSubOptimal = CurrentFitness && !TargetFitness;
		bool BetterFitness = IsFitnessBetterAtLocation(Player, Location);

		return BothOptimal || (BothSubOptimal && BetterFitness) || !FromOptimalToSubOptimal;
	}

	bool IsFitnessBetterAtLocation(AHazePlayerCharacter Player, FVector Location)
	{
		return GetFitnessScoreAtLocation(Player, Location) > GetFitnessScore(Player);
	}

	bool IsFitnessOptimalAtLocation(AHazePlayerCharacter Player, FVector Location)
	{
		return GetFitnessScoreAtLocation(Player, Location) >= FitnessSettings.OptimalThresholdMax;
	}
}