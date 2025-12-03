class UBombTossPlayerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UBombTossTargetComponent> BombTossTargetComponentClass;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem CatchVFX;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ThrowVFX;

	UPROPERTY(EditAnywhere)
	UAnimSequence CatchAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence CatchReadyAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence ThrowAnimation;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BoneFilter;

	UPROPERTY(EditAnywhere)
	float CatchRadius = 400.0;

	UPROPERTY(EditAnywhere)
	float ThrowSpeed = 2200.0;

	AHazePlayerCharacter Player;

	TArray<ABombToss_Bomb> BombTossBombs;

	ABombToss_Bomb BombTossBomb;

	bool bHoldingBomb = false;

	ABombToss_Bomb CurrentBombToss;
	ABombToss_Bomb CurrentGrapplingBombToss;
	UPlayerMovementComponent MoveComp;
	UHazeSplineComponent Spline;

	bool bRecentlyThrown = false;
	bool bInSideScroller = false;
	float RecentlyThrownTimer = 0;
	float RecentlyThrownTimerDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bRecentlyThrown)
			return;
		
		RecentlyThrownTimer += DeltaSeconds;
		if(RecentlyThrownTimer >= RecentlyThrownTimerDuration)
			bRecentlyThrown = false;
	}

	ABombToss_Bomb GetClosestBombToss()
	{
		ABombToss_Bomb ClosestBombTossToPlayer;
		float ClosestDistance = CatchRadius;

		for (auto Bomb : BombTossBombs)
		{
			if (Bomb.Thrower == Player)
				continue;

			if (!Bomb.bIsThrown)
				continue;

			if(Bomb.IsActorDisabled())
				continue;

			if(Time::GetGameTimeSince(Bomb.TimeOfLastChangeToIsThrown) < Bomb.CooldownToCatchAfterThrowing)
				continue;

			float Distance = (Bomb.ActorLocation - Player.FocusLocation).Size();

			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestBombTossToPlayer = Bomb;
			}
		}

		return ClosestBombTossToPlayer;
	}

	UFUNCTION()
	void SetSideScrollerMode(bool bActive, UHazeSplineComponent SplineComp)
	{
		bInSideScroller = bActive;
		Spline = SplineComp;
	}

	FVector GetSideScrollerDirection()
	{
		float Dist = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		FVector SplineForward = Spline.GetWorldForwardVectorAtSplineDistance(Dist);

		if (SplineForward.DotProduct(Player.ActorForwardVector) < 0)
			return -SplineForward;
		else
			return SplineForward;
	}

	bool CatchBombToss()
	{
		if (CurrentBombToss != nullptr)
			return false;

		CurrentBombToss = GetClosestBombToss();

		if (CurrentBombToss != nullptr)
		{
			CurrentBombToss.SetIsThrown(false);
			return true;
		}
		else
			return false;
	}

	void ThrewBomb()
	{
		RecentlyThrownTimer = 0;
		bRecentlyThrown = true;
	}

	void Launch(FVector Velocity, USceneComponent Target)
	{
		if (CurrentBombToss == nullptr)
			return;

		CurrentBombToss.Target = Target;
		CurrentBombToss.Thrower = Player;
		CurrentBombToss.Launch(Velocity);
		CurrentBombToss = nullptr;
	}

	FVector GetLaunchDirection(FVector Origin, FVector Target, float LaunchSpeed, float Gravity)
	{
		FVector Direction;

		FVector ToTarget = Target - Origin;
		float LaunchSpeedSquared = LaunchSpeed * LaunchSpeed;
		float DistanceSquared = ToTarget.SizeSquared();

		float Root = LaunchSpeedSquared * LaunchSpeedSquared - Gravity * (Gravity * DistanceSquared + (2.0 * ToTarget.Z * LaunchSpeedSquared));

		float Angle = 45.0;

		if (Root >= 0.0)
			Angle = Math::RadiansToDegrees(-Math::Atan2(Gravity * Math::Sqrt(DistanceSquared), LaunchSpeedSquared + Math::Sqrt(Root)));

		FVector PitchAxis = ToTarget.CrossProduct(FVector::UpVector).SafeNormal;

		Direction = ToTarget.RotateAngleAxis(Angle, PitchAxis).SafeNormal;

		return Direction;
	}

	bool ShouldGrappleTowardsEachOther(ABombToss_Bomb Ball) const
	{
		bool bBallHasSignificantVelocity = Ball.Velocity.Size() > Ball.GrappleSignificantVelocityThreshold;
		if(!bBallHasSignificantVelocity)
			return false;

		if(Ball.bGrappleTowardsEachOtherRequiresAirborne && MoveComp.HasGroundContact())
			return false;

		return true;
	}
}