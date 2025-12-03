
struct FMedallionHydraPlayerData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}
class AMedallionHydraWaveAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRootRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRootRoot)
	USceneComponent HeadRoot1;

	UPROPERTY(DefaultComponent, Attach = HeadRootRoot)
	USceneComponent HeadRoot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaveMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent WaveQueue;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra Hydra1;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra Hydra2;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor FallCamera;

	UPROPERTY()
	FRuntimeFloatCurve HeadCurve;

	UPROPERTY()
	TPerPlayer<UHazeActionQueueComponent> PlayerQueue;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY()
	FApplyPointOfInterestSettings PoISettingsLaunch;
	default PoISettingsLaunch.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Medium;

	UPROPERTY()
	FApplyPointOfInterestSettings PoISettingsLanded;
	default PoISettingsLanded.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Medium;



	const float StartHeight = 3000.0;
	const float EndHeight = -500.0;
	const float StartPitch = 45.0;
	const float EndPitch = -45.0;
	const float IncreaseRadiusSpeed = 4.0;
	const float PlayerLaunchHeight = 2500.0;

	bool bWaveActive = false;
	int WaveActivationCounter = 0;

	float XYScale;
	float ZScale;

	TPerPlayer<bool> bPlayerLaunched;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerQueue[Game::Mio] = UHazeActionQueueComponent::Create(this);
		PlayerQueue[Game::Zoe] = UHazeActionQueueComponent::Create(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bWaveActive)
			return;

		XYScale += IncreaseRadiusSpeed * DeltaSeconds;

		for (auto Player : Game::Players)
		{
			if (bPlayerLaunched[Player])
				continue;

			if (InWaveRange(Player.ActorLocation, 100.0))
				WaveLaunchPlayer(Player);
		}

		WaveMeshComp.SetWorldScale3D(FVector(XYScale, XYScale, ZScale));
	}

	bool InWaveRange(FVector Location, float ErrorTolerance = 500.0)
	{
		float DistanceToCenter = Location.Dist2D(ActorLocation, FVector::UpVector);
		return Math::IsNearlyEqual(DistanceToCenter, XYScale * 440.0, ErrorTolerance);
	}

	UFUNCTION()
	void Activate()
	{
		WaveActivationCounter++;
		HeadRootRoot.SetRelativeLocation(FVector::UpVector * StartHeight);

		Hydra1.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot1, 
			EMedallionHydraMovePivotPriority::High, 
			1.5);

		Hydra2.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot2, 
			EMedallionHydraMovePivotPriority::High, 
			1.5);

		QueueComp.Duration(2.5, this, n"SmashHeadUpdate");
		QueueComp.Event(this, n"SmashHeadFinished");

		UMedallionHydraWaveAttackEventHandler::Trigger_OnStartWaveAttack(this);
	}

	UFUNCTION()
	private void SmashHeadUpdate(float Alpha)
	{
		float CurrentValue = HeadCurve.GetFloatValue(Alpha);

		FVector Location = FVector::UpVector * Math::Lerp(StartHeight, EndHeight, CurrentValue) + FVector::ForwardVector * -1000.0;
		FRotator Rotation = FRotator(Math::Lerp(StartPitch, EndPitch, CurrentValue), 0.0, 0.0);

		HeadRootRoot.SetRelativeLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void SmashHeadFinished()
	{
		BP_Splash();

		Hydra1.MoveHeadPivotComp.Clear(this);
		Hydra2.MoveHeadPivotComp.Clear(this);

		ActivateWave();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Splash(){}

	UFUNCTION()
	private void ActivateWave()
	{
		bWaveActive = true;
		XYScale = 0.0;

		WaveMeshComp.SetRelativeLocation(FVector::UpVector * -200.0);

		WaveQueue.Empty();
		WaveQueue.Duration(2.0, this, n"WaveHeightUpdate");
		WaveQueue.Idle(5.0);
		WaveQueue.Event(this, n"DeactivateSplash");
		WaveQueue.Duration(2.0, this, n"WaveSinkUpdate");
		WaveQueue.Event(this, n"DeactivateWave");

		for (auto Player : Game::Players)
			bPlayerLaunched[Player] = false;
	} 

	UFUNCTION()
	private void WaveHeightUpdate(float Alpha)
	{
		ZScale = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha) * 10.0;

		WaveMeshComp.SetScalarParameterValueOnMaterials(n"WpoAmount", Math::EaseInOut(0.0, 830.0, Alpha, 2.0));
	}

	UFUNCTION()
	private void DeactivateSplash()
	{
		BP_DeactivateSplash();
	}

	UFUNCTION()
	private void WaveSinkUpdate(float Alpha)
	{
		ZScale = Curve::SmoothCurveZeroToOne.GetFloatValue(1-Alpha) * 10.0;

		float ZHeight = Math::EaseIn(-200.0, -2000.0, Alpha, 2.0);

		WaveMeshComp.SetRelativeLocation(FVector::UpVector * ZHeight);
	}

	private void WaveLaunchPlayer(AHazePlayerCharacter Player)
	{
		if (bPlayerLaunched[Player])
			return;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(Player.ActorLocation + FVector::UpVector * 100.0, Player.ActorLocation + FVector::UpVector * -1000.0);

		// if (!HitResult.bBlockingHit)
		// 	Player.DamagePlayerHealth(0.5);

		PlayerQueue[Player].Empty();
		FMedallionHydraPlayerData Data;
		Data.Player = Player;
		PlayerQueue[Player].Event(this, n"LaunchPlayer", Data);
		PlayerQueue[Player].Idle(1.0);
		PlayerQueue[Player].Event(this, n"ResetPlayerJump", Data);
		PlayerQueue[Player].Duration(3.5, this, n"CheckPlayerGroundContact", Data);
		PlayerQueue[Player].Event(this, n"ClearPlayerCamera", Data);

		UMedallionHydraWaveAttackEventHandler::Trigger_OnWaveAttackPlayerLaunch(this, Data);
	}

	UFUNCTION()
	private void LaunchPlayer(FMedallionHydraPlayerData Data)
	{
		bPlayerLaunched[Data.Player] = true;

		auto InteractionsComp = UPlayerInteractionsComponent::Get(Data.Player);
		InteractionsComp.KickPlayerOutOfAnyInteraction();
		
		Data.Player.BlockCapabilities(PlayerMovementTags::Perch, this);
		Data.Player.AddPlayerLaunchImpulseToReachHeight(PlayerLaunchHeight);
		Data.Player.ApplyCameraSettings(CameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
		Data.Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Data.Player.BlockCapabilities(PlayerMovementTags::AirDash, this);

		FHazePointOfInterestFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToComponent(Data.Player.RootComponent);
		FocusTarget.WorldOffset = FVector(-2000.0, 0.0, -3000.0);

		Data.Player.ApplyPointOfInterest(this, FocusTarget, PoISettingsLaunch, BlendInTime = 3.0);
	}

	UFUNCTION()
	private void ResetPlayerJump(FMedallionHydraPlayerData Data)
	{
		Data.Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Data.Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Data.Player.UnblockCapabilities(PlayerMovementTags::Perch, this);
		Data.Player.ResetAirDashUsage();
		Data.Player.ResetAirJumpUsage();

		Data.Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION()
	private void CheckPlayerGroundContact(float Alpha, FMedallionHydraPlayerData Data)
	{
		auto MovementComp = UPlayerMovementComponent::Get(Data.Player);

		if (MovementComp.IsOnAnyGround())
		{
			PlayerQueue[Data.Player].Empty();
			PlayerQueue[Data.Player].Event(this, n"ClearPlayerCamera", Data);
		}
	}

	UFUNCTION()
	private void ClearPlayerCamera(FMedallionHydraPlayerData Data)
	{
		Data.Player.ClearCameraSettingsByInstigator(this, 3.0);

		FHazePointOfInterestFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToComponent(Data.Player.RootComponent);
		FocusTarget.WorldOffset = FVector(-3000.0, 0.0, -300.0);

		Data.Player.ClearPointOfInterestByInstigator(this);
		Data.Player.ApplyPointOfInterest(this, FocusTarget, PoISettingsLanded, BlendInTime = 3.0);
		PrintToScreen("ClearCamera", 3.0);
	}

	UFUNCTION()
	private void DeactivateWave()
	{
		bWaveActive = false;
		BP_DeactivateWave();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_DeactivateWave(){}

	UFUNCTION(BlueprintEvent)
	private void BP_DeactivateSplash(){}
};