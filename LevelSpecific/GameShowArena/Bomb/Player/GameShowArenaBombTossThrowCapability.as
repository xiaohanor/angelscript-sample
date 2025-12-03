class UGameShowArenaBombTossThrowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossThrow");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 92;

	default DebugCategory = n"GameShow";

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	// LAUNCH HOMING SETTINGS
	const float DefaultThrowDistance = 2500;
	const float MinThrowArc = 100;
	const float MaxThrowArc = 550;

	float MinDistance = 100;
	float MinDistanceThrowTravelTime = 0.3;
	float MaxDistance = 5000;
	float MaxDistanceThrowTravelTime = 1.25;

	const float LaunchImpulse = 3750;

	bool bHasLaunchedBomb;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BombTossPlayerComponent.CurrentBomb == nullptr)
			return false;

		if (BombTossPlayerComponent.CurrentBomb.IsActorDisabled())
			return false;

		if (BombTossPlayerComponent.HasRecentlyCaughtBomb())
			return false;

		if (BombTossPlayerComponent.bIsInteracting)
			return false;

		if (BombTossPlayerComponent.CurrentBomb.State.Get() != EGameShowArenaBombState::Held)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BombTossPlayerComponent.CurrentBomb == nullptr)
			return true;

		if (Time::GetGameTimeSince(BombTossPlayerComponent.TimeWhenThrewBomb) > 0.2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BombTossPlayerComponent.TimeWhenThrewBomb = Time::GameTimeSeconds;
		BombTossPlayerComponent.CurrentBomb.StartThrow();
		// BombTossPlayerComponent.CurrentBomb = nullptr;

		BombTossPlayerComponent.AnimParams.bThrow = true;

		FVector ToOtherPlayer = Player.OtherPlayer.ActorCenterLocation - Player.ActorCenterLocation;
		float ThrowAngle = ToOtherPlayer.GetAngleDegreesTo(Player.ActorForwardVector);
		ThrowAngle *= Math::Sign(ToOtherPlayer.DotProduct(Player.ActorRightVector));
		BombTossPlayerComponent.AnimParams.ThrowAngle = ThrowAngle;

		// Spawn VFX
		// Niagara::SpawnOneShotNiagaraSystemAttached(BombTossPlayerComponent.ThrowVFX, Player.Mesh, n"Backpack");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (BombTossPlayerComponent.CurrentBomb != nullptr)
		{
			if (HasControl())
				LaunchBomb();

			BombTossPlayerComponent.RemoveBomb();
		}

		BombTossPlayerComponent.AnimParams.bThrow = false;
	}

	void LaunchBomb()
	{
		Player.PlayForceFeedback(BombTossPlayerComponent.ThrowFF, false, false, this);
		auto AimResult = PlayerAimingComponent.GetAimingTarget(BombTossPlayerComponent);
		auto Bomb = BombTossPlayerComponent.CurrentBomb;
		FVector StartPoint;
		float TravelTime;
		StartPoint = Bomb.ActorLocation;
		TravelTime = MinDistanceThrowTravelTime;
		float Gravity = 1200;
		auto Target = AimResult.AutoAimTarget;
		auto ActorLocation = Bomb.ActorLocation;
		if (Target != nullptr)
		{
			auto PlayerTarget = Player.OtherPlayer;
			FVector TargetVerticalVelocity = FVector::UpVector * PlayerTarget.ActorVelocity.DotProduct(FVector::UpVector);
			FVector TargetVelocity = PlayerTarget.ActorVelocity;
			float Height = Acceleration::GetMaxHeight(TargetVerticalVelocity.Size(), Gravity);
			Height = Math::Clamp(Height, MinThrowArc, MaxThrowArc);

			FVector ToTarget = (PlayerTarget.ActorCenterLocation + TargetVelocity - ActorLocation);
			float Dist = ToTarget.Size();
			TravelTime = Math::GetMappedRangeValueClamped(FVector2D(MinDistance, MaxDistance), FVector2D(MinDistanceThrowTravelTime, MaxDistanceThrowTravelTime), Dist);
			FVector Velocity = Trajectory::CalculateVelocityForPathWithHeight(StartPoint, PlayerTarget.ActorCenterLocation + TargetVelocity * TravelTime, Gravity, Height);
			int Resolution = 16;
			TArray<FVector> Points;
			Points.SetNum(Resolution);
			for (int i = 0; i < Resolution; i++)
			{
				Points[i] = Trajectory::TrajectoryPositionAfterTime(StartPoint, Velocity, Gravity, float(i) / (Resolution - 1) * TravelTime);
			}

			Bomb.CrumbLaunch(Player, FGameShowArenaBombHomingLaunchParams(PlayerTarget, Points, TravelTime));
		}
		else
		{
			FVector TrajectoryLaunchVelocity = (AimResult.AimDirection.VectorPlaneProject(FVector::UpVector) + FVector::UpVector * 0.25).GetSafeNormal() * LaunchImpulse;
			Bomb.CrumbTrajectoryLaunch(Player, TrajectoryLaunchVelocity);
		}
	}
}