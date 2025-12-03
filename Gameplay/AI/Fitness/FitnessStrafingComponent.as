class UFitnessStrafingComponent : UActorComponent
{
	UFitnessUserComponent FitnessComp;
	UBasicAITargetingComponent TargetComp;
	UFitnessSettings FitnessSettings;

	bool bInternalStrafeLeft = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);		
		FitnessSettings = UFitnessSettings::GetSettings(HazeOwner);

		OptimizeStrafeDirection();
	}

	bool GetbStrafeLeft() property
	{
		return bInternalStrafeLeft;
	}

	void RandomizeStrafeDirection()
	{
		bInternalStrafeLeft = Math::RandBool();
	}

	void SetClosestToViewStrafeDirection()
	{
		// Start with randomized strafe for all the early out cases
		RandomizeStrafeDirection();

		if(FitnessComp == nullptr || TargetComp == nullptr || !TargetComp.HasValidTarget())
			return;

		auto Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return;

		// If we're to the left of view, we should strafe left
		FVector FromTarget = Owner.ActorLocation - Player.ActorLocation; 
		bInternalStrafeLeft = (Player.ViewRotation.RightVector.DotProduct(FromTarget) < 0.0);
	}

	void OptimizeStrafeDirection()
	{	
		if(FitnessComp != nullptr && TargetComp != nullptr && TargetComp.HasValidTarget())
		{
			auto Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
			if(Player == nullptr)
				return;

			FVector OwnLoc = Owner.ActorLocation;
			FVector TargetLoc = TargetComp.Target.ActorLocation;
			FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc).GetSafeNormal();

			float RightScore = FitnessComp.GetFitnessScoreAtLocation(Player, OwnLoc + Side * 100.0);
			float LeftScore = FitnessComp.GetFitnessScoreAtLocation(Player, OwnLoc + Side * -100.0);

			if((RightScore > FitnessSettings.OptimalThresholdMax && LeftScore > FitnessSettings.OptimalThresholdMax) || RightScore == LeftScore)
				return;
			
			bInternalStrafeLeft = LeftScore > RightScore;
			
			return;
		}

		RandomizeStrafeDirection();
	}

	void FlipStrafeDirection()
	{
		bInternalStrafeLeft = !bInternalStrafeLeft;
	}
}