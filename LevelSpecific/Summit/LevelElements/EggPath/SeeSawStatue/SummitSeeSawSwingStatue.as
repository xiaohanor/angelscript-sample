event void FVOSpecific(AHazePlayerCharacter Player);

class ASummitSeeSawSwingStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StatueMesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USwingPointComponent LeftSwingPointComp;
	default LeftSwingPointComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default LeftSwingPointComp.SetAbsolute(false, true, false);
	default LeftSwingPointComp.ActivationCooldown = 2.0;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USwingPointComponent RightSwingPointComp;
	default RightSwingPointComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default RightSwingPointComp.SetAbsolute(false, true, false);
	default RightSwingPointComp.ActivationCooldown = 2.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitSeeSawSwingStatueDeactivateSwingCapability);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilityClasses.Add(USummitSeeSawSwingStatuePlayerPickSideCapability);
	default RequestComp.PlayerCapabilityClasses.Add(USummitSeeSawSwingStatuePlayerSwingableSlowDownCapability);
	default RequestComp.PlayerCapabilityClasses.Add(USummitSeeSawSwingStatuePlayerDisableRespawnCapability);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTempLogComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRotateDegrees = 80.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DropSwingDegrees = 30.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ReEnableSwingsDegrees = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeed = 2.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RumbleAtMaxRotationSpeed = 0.6;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRotationSpeedForMaxRumble = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bBlockRespawnAfterDisableSwing = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bBlockRespawnAfterDisableSwing"))
	ARespawnPoint RespawnPointToReEnableRespawn;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FTimeDilationEffect SwingableTimeDilationEffect;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FTimeDilationEffect SwingStartedTimeDilationEffect;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bBaseTimeDilationOnPing = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bBaseTimeDilationOnPing"))
	float PingForMaxTimeDilation = 400.0;

	UPROPERTY()
	FVOSpecific DetachFailSwing;

	AHazePlayerCharacter PlayerSwingingFromLeft;
	AHazePlayerCharacter PlayerSwingingFromRight;

	TPerPlayer<float> LastTimeStoppedSwinging;

	FHazeAcceleratedRotator AccRotation;

	bool bSwingsDeactivated = false;
	bool bHasReEnabledRespawnAfterSwingsDeactivating = false;
	bool bRespawnPointActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftSwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPointAttached");
		LeftSwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPointDetached");

		RightSwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPointAttached");
		RightSwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPointDetached");

		AccRotation.SnapTo(RotationRoot.RelativeRotation);

		if(RespawnPointToReEnableRespawn != nullptr)
			RespawnPointToReEnableRespawn.OnRespawnPointEnabled.BindUFunction(this, n"OnRespawnPointEnabled");
	}

	UFUNCTION()
	private void OnRespawnPointEnabled(AHazePlayerCharacter EnablingPlayer)
	{
		bRespawnPointActivated = true;
	}

	UFUNCTION()
	private void OnPointAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if(SwingPoint == LeftSwingPointComp)
			PlayerSwingingFromLeft = Player;
		else
			PlayerSwingingFromRight = Player;

		auto StatueComp = USummitSeeSawSwingStatuePlayerComponent::GetOrCreate(Player);
		StatueComp.Statue.Set(this);
	}

	UFUNCTION()
	private void OnPointDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if(SwingPoint == LeftSwingPointComp)
			PlayerSwingingFromLeft = nullptr;
		else
			PlayerSwingingFromRight = nullptr;

		LastTimeStoppedSwinging[Player] = Time::GameTimeSeconds;
		auto StatueComp = USummitSeeSawSwingStatuePlayerComponent::GetOrCreate(Player);
		StatueComp.Statue.Reset();
		StatueComp.PreviousStatue = this;
		DetachFailSwing.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float WeightDistribution = 0.0;
		if(PlayerSwingingFromLeft != nullptr)
			WeightDistribution += GetWeightFromSwing(true);
		if(PlayerSwingingFromRight != nullptr)
			WeightDistribution -= GetWeightFromSwing(false);

		if(AnyPlayerIsAttached())
			SetActorTimeDilationToLowestOfAttachedPlayers();
		else if(ActorTimeDilation < 1.0)
			IncreaseTimeDilationToNormal(DeltaSeconds);

		FRotator TargetRotation = FRotator(MaxRotateDegrees * WeightDistribution, 0.0, 0.0);
		AccRotation.AccelerateTo(TargetRotation, RotationSpeed, DeltaSeconds);
		FRotator DeltaRotation = AccRotation.Value - RotationRoot.RelativeRotation;
		float CurrentRotationSpeed = Math::Abs(DeltaRotation.Pitch) / DeltaSeconds;
		if(!Math::IsNearlyZero(CurrentRotationSpeed))
			ApplyRumbleToCurrentlyAttachedPlayers(CurrentRotationSpeed);

		RotationRoot.RelativeRotation = AccRotation.Value;
	}

	void SetActorTimeDilationToLowestOfAttachedPlayers()
	{
		float LowestTimeDilation = MAX_flt;

		if(PlayerSwingingFromLeft != nullptr
		&& PlayerSwingingFromLeft.ActorTimeDilation < LowestTimeDilation)
			LowestTimeDilation = PlayerSwingingFromLeft.ActorTimeDilation;
		if(PlayerSwingingFromRight != nullptr
		&& PlayerSwingingFromRight.ActorTimeDilation < LowestTimeDilation)
			LowestTimeDilation = PlayerSwingingFromRight.ActorTimeDilation;

		SetActorTimeDilation(LowestTimeDilation, this, EInstigatePriority::Normal);
	}

	const float TimeDilationInterpBackSpeed = 0.3;
	void IncreaseTimeDilationToNormal(float DeltaTime)
	{
		float Current = ActorTimeDilation;
		Current = Math::FInterpTo(Current, 1.0, DeltaTime, TimeDilationInterpBackSpeed);
		SetActorTimeDilation(Current, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRotationDegrees() const property
	{
		return RotationRoot.RelativeRotation.Pitch;
	}

	private void ApplyRumbleToCurrentlyAttachedPlayers(float CurrentRotationSpeed)
	{
		FHazeFrameForceFeedback Rumble;
		
		float SpeedAlpha = Math::Saturate(CurrentRotationSpeed / MaxRotationSpeedForMaxRumble);
		float RumbleStrength = RumbleAtMaxRotationSpeed * SpeedAlpha;
		Rumble.LeftMotor = RumbleStrength;
		Rumble.RightMotor = RumbleStrength;

		if(PlayerSwingingFromLeft != nullptr)
			PlayerSwingingFromLeft.SetFrameForceFeedback(Rumble);
		if(PlayerSwingingFromRight != nullptr)
			PlayerSwingingFromRight.SetFrameForceFeedback(Rumble);
	}

	bool AnyPlayerIsAttached() const
	{
		return PlayerSwingingFromLeft != nullptr 
		|| PlayerSwingingFromRight != nullptr;
	}

	float GetWeightFromSwing(bool bLeftSwing) const
	{
		FVector DirToPlayer;
		if(bLeftSwing)
		{
			if(PlayerSwingingFromLeft == nullptr)
				return 0.0;

			DirToPlayer = (PlayerSwingingFromLeft.ActorLocation - LeftSwingPointComp.WorldLocation).ConstrainToPlane(ActorForwardVector).GetSafeNormal();
		}
		else
		{
			if(PlayerSwingingFromRight == nullptr)
				return 0.0;

			DirToPlayer = (PlayerSwingingFromRight.ActorLocation - RightSwingPointComp.WorldLocation).ConstrainToPlane(ActorForwardVector).GetSafeNormal();
		}
		float DirDotDown = DirToPlayer.DotProduct(FVector::DownVector);
		return DirDotDown;
	}

// 	void SetSyncRateBasedOnPlayerDistance()
// 	{
// 		bool bOnePlayerIsCloseEnough = false;
// 		for(auto Player : Game::Players)
// 		{
// 			float DistSqrd = Player.ActorLocation.DistSquared(ActorLocation);
// 			if(DistSqrd < Math::Square(FastSyncRateDistanceThreshold))
// 			{
// 				bOnePlayerIsCloseEnough = true;
// 				break;
// 			}
// 		}
// 		if(bOnePlayerIsCloseEnough)
// 			SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
// 		else
// 			SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
// 	}

// #if EDITOR
// 	UFUNCTION(BlueprintOverride)
// 	void OnVisualizeInEditor() const
// 	{
// 		Debug::DrawDebugSphere(ActorLocation, FastSyncRateDistanceThreshold, 24, FLinearColor::Red, 10);
// 	}
// #endif
};