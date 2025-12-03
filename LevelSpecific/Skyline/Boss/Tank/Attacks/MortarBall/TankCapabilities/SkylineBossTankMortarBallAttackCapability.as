struct FSkylineBossTankMortarBallAttackActivateParams
{
	AHazePlayerCharacter TargetPlayer;
	USkylineBossTankMortarBallComponent ClosestMortar;
	float LaunchHeight;
	FVector TargetLocation;
};

class USkylineBossTankMortarBallAttackCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);
	default CapabilityTags.Add(SkylineBossTankTags::Attacks::SkylineBossTankAttackMortar);

	AHazePlayerCharacter TargetPlayer;
	TArray<USkylineBossTankMortarBallComponent> MortarBallComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.GetComponentsByClass(MortarBallComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankMortarBallAttackActivateParams& Params) const
	{
		if (!BossTank.HasAttackTarget())
			return false;

		if (DeactiveDuration < BossTank.MainAttackInterval.Get()) // 5.0
			return false;

		if(TargetPlayer == nullptr)
		{
			Params.TargetPlayer = Game::Mio;
		}
		else
		{
			// Target the other player
			Params.TargetPlayer = TargetPlayer.OtherPlayer;
		}

		// Find a naive target location in front of the target player bike
		const AGravityBikeFree TargetBike = GravityBikeFree::GetGravityBike(Params.TargetPlayer);
		FVector TargetLocation = CalculateInitialTargetLocation(TargetBike);

		// Find the closest mortar
		USkylineBossTankMortarBallComponent ClosestMortar = GetClosestMortar(TargetLocation);

		// Not to close to the tank
		FVector TankToTargetLocation = (TargetLocation - BossTank.ActorLocation);
		if (TankToTargetLocation.Size() < ClosestMortar.MinRange)
			TargetLocation = BossTank.ActorLocation + TankToTargetLocation.SafeNormal * ClosestMortar.MinRange;

		// Constrain target location to arena circle
		FVector ConstraintOriginToTargetLocation = (TargetLocation - BossTank.ConstraintRadiusOrigin.ActorLocation).VectorPlaneProject(FVector::UpVector);
		if (ConstraintOriginToTargetLocation.Size() > BossTank.ConstraintRadius)
			TargetLocation = BossTank.ConstraintRadiusOrigin.ActorLocation + ConstraintOriginToTargetLocation.SafeNormal * BossTank.ConstraintRadius;

		// Calculate the launch height based on the distance
		const float LaunchHeight = CalculateLaunchHeight(ClosestMortar, TargetLocation);

		// Sync all parameters needed for spawning
		Params.ClosestMortar = ClosestMortar;
		Params.LaunchHeight = LaunchHeight;
		Params.TargetLocation = TargetLocation;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankMortarBallAttackActivateParams Params)
	{
		TargetPlayer = Params.TargetPlayer;

		// Fire!
		Params.ClosestMortar.Fire(TargetPlayer, Params.LaunchHeight, Params.TargetLocation);
	}

	FVector CalculateInitialTargetLocation(const AGravityBikeFree TargetBike) const
	{
		FVector TargetVelocityPrediction = TargetBike.ActorVelocity.SafeNormal * Math::Min(TargetBike.ActorVelocity.Size() * 2.9, 16000.0);
		FVector TargetVelocityAndTurningPrediction = TargetVelocityPrediction.RotateAngleAxis(TargetBike.AccSteering.Value * 90.0, FVector::UpVector);
		return TargetBike.ActorLocation + TargetVelocityAndTurningPrediction;
	}

	USkylineBossTankMortarBallComponent GetClosestMortar(FVector TargetLocation) const
	{
		// Fire Mortar closest to player
		USkylineBossTankMortarBallComponent ClosestMortar;
		float ClosestDistance = BIG_NUMBER;
		for (USkylineBossTankMortarBallComponent MortarBallComponent : MortarBallComponents)
		{
			float Distance = (TargetLocation - MortarBallComponent.WorldLocation).Size();

			if (Distance < ClosestDistance)
			{
				ClosestMortar = MortarBallComponent;
				ClosestDistance = Distance;
			}
		}

		return ClosestMortar;
	}

	float CalculateLaunchHeight(USkylineBossTankMortarBallComponent ClosestMortar, FVector TargetLocation) const
	{
		const float DistanceToTarget = ClosestMortar.WorldLocation.Dist2D(TargetLocation);
		const float LaunchHeight = MortarBall::MinimumLaunchHeight + (MortarBall::AdditionalLaunchHeightOverDistance * DistanceToTarget);
		return Math::Clamp(LaunchHeight, MortarBall::MinimumLaunchHeight, MortarBall::MaximumLaunchHeight);
	}
}