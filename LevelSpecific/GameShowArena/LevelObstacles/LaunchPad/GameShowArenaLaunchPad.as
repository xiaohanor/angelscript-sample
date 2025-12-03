class AGameShowArenaLaunchPad : AGameShowArenaDynamicObstacleBase
{
#if EDITOR
	UPROPERTY(DefaultComponent, NotVisible, NotEditable)
	UGameShowArenaLaunchPadVisualizerComponent VisualizerComp;
#endif
	UPROPERTY(EditAnywhere)
	FLinearColor Tint = FLinearColor::Green;

	UPROPERTY(EditAnywhere)
	UTexture2D Texture;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	UPROPERTY(EditAnywhere)
	UTexture2D LaunchTexture;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBoxComponent LaunchBox;
	default LaunchBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default LaunchBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaPlatformPlayerReactionCapability);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditAnywhere)
	float LaunchCooldown = 2;

	UPROPERTY(EditAnywhere)
	float LaunchImpulse = 2500;

	UPROPERTY(EditAnywhere)
	float LaunchTimeInitialOffset = 0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchFF;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaPlatformArm AttachmentArm;

	UPROPERTY(EditInstanceOnly)
	bool bIsFinalLaunchPad = false;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaLaunchPad OtherFinalLaunchPad;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DisplayDecalComp;

	UPROPERTY(EditInstanceOnly)
	bool bNetworkZoeControlled = false;

	FHazeAcceleratedVector AccDecalScale;
	FRotator DecalRotation;

	TPerPlayer<bool> OverlappingPlayers;
	TPerPlayer<bool> LaunchedPlayers;

	TPerPlayer<bool> NonClearingLaunchedPlayers;

	TPerPlayer<UGameShowPlayerLaunchComponent> PlayerLaunchComps;
	float LaunchTelegraphDuration = 0.25;
	float LaunchActiveDuration = 0.25;
	float LaunchChargeUpDuration = 0.5;
	bool bHasTriggeredEventForLaunch = false;

	float DecalRotationSpeed = 0;
	float CurrentOpacity = 0;
	UTexture2D CurrentDecalTexture;
	float TimeStarted;

	TPerPlayer<bool> PlayerBlockedInputs;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisplayDecalComp.AssignTarget(MeshComp, AttachmentArm.PanelMaterial);
		LaunchBox.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		LaunchBox.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		DecalRotation = FRotator::MakeFromZ(MeshComp.UpVector);
		if (bNetworkZoeControlled)
			SetActorControlSide(Game::Zoe);
		else
			SetActorControlSide(Game::Mio);

		if (HasControl())
		{
			ActionQueueComp.Idle(1.0 + LaunchTimeInitialOffset);
			ActionQueueComp.Event(this, n"FinishWaiting");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DecalRotation.Yaw += DecalRotationSpeed * DeltaSeconds;
		FVector Scale = AccDecalScale.Value;
		FVector Location = MeshComp.WorldLocation - FVector::ForwardVector * 15 - FVector::RightVector * 15;
		DisplayDecalComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(
			Location,
			DecalRotation,
			Scale,
			CurrentDecalTexture,
			CurrentOpacity,
			Tint), bIsAlternateDecal);
		ActionQueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime - TimeStarted);
	}

	UFUNCTION()
	private void FinishWaiting()
	{
		CrumbFinishWaiting(Time::PredictedGlobalCrumbTrailTime);
	}
	UFUNCTION(CrumbFunction)
	private void CrumbFinishWaiting(float StartTime)
	{
		PlayerLaunchComps[Game::Mio] = UGameShowPlayerLaunchComponent::GetOrCreate(Game::Mio);
		PlayerLaunchComps[Game::Zoe] = UGameShowPlayerLaunchComponent::GetOrCreate(Game::Zoe);
		ActionQueueComp.Empty();
		ActionQueueComp.Duration(LaunchChargeUpDuration, this, n"ChargeUp");
		ActionQueueComp.Duration(LaunchTelegraphDuration, this, n"Telegraph");
		ActionQueueComp.Duration(LaunchActiveDuration, this, n"TriggerLaunch");
		ActionQueueComp.Duration(LaunchCooldown, this, n"ResetCharge");
		ActionQueueComp.SetLooping(true);
		TimeStarted = StartTime;
		ActionQueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime - TimeStarted);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void ChargeUp(float Alpha)
	{
		CurrentOpacity = 40;
		CurrentDecalTexture = Texture;
		bHasTriggeredEventForLaunch = false;
		DecalRotationSpeed = Math::Lerp(360, 480, Alpha);
	}

	UFUNCTION()
	private void Telegraph(float Alpha)
	{
		DecalRotationSpeed = Math::Lerp(480, 720, Alpha);
		AccDecalScale.AccelerateTo(FVector::OneVector * 150, LaunchTelegraphDuration, Time::GetActorDeltaSeconds(this));
	}

	UFUNCTION()
	private void TriggerLaunch(float Alpha)
	{
		CurrentDecalTexture = LaunchTexture;
		DecalRotationSpeed = 0;
		CurrentOpacity = 80;
		AccDecalScale.AccelerateTo(FVector::OneVector * 170, LaunchActiveDuration, Time::GetActorDeltaSeconds(this));

		for (auto Player : Game::Players)
		{
			if (!OverlappingPlayers[Player] || LaunchedPlayers[Player])
				continue;

			auto MoveComp = UHazeMovementComponent::Get(Player);
			if (MoveComp == nullptr)
				continue;

			if (HasControl())
			{
				CrumbLaunch(Player, MoveComp);
			}
		}

		if (!bHasTriggeredEventForLaunch)
		{
			FGameShowArenaLaunchPadLaunchParams Params;
			Params.LaunchPad = this;
			UGameShowArenaLaunchPadEffectHandler::Trigger_OnLaunch(this, Params);
			bHasTriggeredEventForLaunch = true;
		}
	}

	UFUNCTION()
	private void ResetCharge(float Alpha)
	{
		CurrentDecalTexture = Texture;
		DecalRotationSpeed = Math::Lerp(0, 360, Alpha);
		AccDecalScale.SpringTo(FVector::OneVector * 130, 50, 1, Time::GetActorDeltaSeconds(this));
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(AHazePlayerCharacter Player, UHazeMovementComponent MoveComp)
	{
		NonClearingLaunchedPlayers[Player] = true;
		float VerticalDist = Player.ActorLocation.Z - MeshComp.WorldLocation.Z;
		Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * (LaunchImpulse - MoveComp.VerticalSpeed - VerticalDist));
		Player.PlayCameraShake(CameraShakeClass, this);
		Player.PlayForceFeedback(LaunchFF, false, true, this);
		Player.KeepLaunchVelocityDuringAirJumpUntilLanded(0.4);
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
		LaunchedPlayers[Player] = true;
		PlayerLaunchComps[Player].TimeWhenLaunched = Time::GameTimeSeconds;
		if (!PlayerBlockedInputs[Player])
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		PlayerBlockedInputs[Player] = true;
		if (Player.IsMio())
			Timer::SetTimer(this, n"UnblockMioInput", 0.5);
		else
			Timer::SetTimer(this, n"UnblockZoeInput", 0.5);
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerLaunchedByLaunchpad(Player, FGameShowArenaPlayerLaunchedByLaunchpadParams(Player));

		if (bIsFinalLaunchPad)
		{
			float TimeBetweenLaunches = Math::Abs(PlayerLaunchComps[Game::Mio].TimeWhenLaunched - PlayerLaunchComps[Game::Zoe].TimeWhenLaunched);

			if (TimeBetweenLaunches <= 5.0 && Time::GetGameTimeSince(PlayerLaunchComps[Game::Mio].TimeWhenLastFinalLaunch) >= 2.0)
			{
				PlayerLaunchComps[Game::Mio].TimeWhenLastFinalLaunch = Time::GameTimeSeconds;
				FGameShowArenaFinalLaunchPadParams FinalParams;
				FinalParams.TimeBetweenPlayerLaunches = TimeBetweenLaunches;
				UGameShowArenaLaunchPadEffectHandler::Trigger_FinalLaunchpadBothPlayersLaunched(this, FinalParams);
			}
		}
	}

	UFUNCTION()
	private void UnblockMioInput()
	{
		Game::Mio.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerBlockedInputs[Game::Mio] = false;
	}
	UFUNCTION()
	private void UnblockZoeInput()
	{
		Game::Zoe.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerBlockedInputs[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		AttachmentArm.AttachActorToPlatformPosition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		AttachmentArm.DetachActorFromPlatform(this);
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
					  UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		OverlappingPlayers[Player] = false;
		LaunchedPlayers[Player] = false;
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
						UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
						const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		OverlappingPlayers[Player] = true;
	}
};

#if EDITOR
class UGameShowArenaLaunchPadVisualizerComponent : UActorComponent
{
}

class UGameShowArenaLaunchPadVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGameShowArenaLaunchPadVisualizerComponent;
	UMaterialInterface DebugMaterial;

	const float PlayerGravity = 2385;
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UGameShowArenaLaunchPadVisualizerComponent>(Component);
		if (Comp == nullptr)
			return;

		if (DebugMaterial == nullptr)
			DebugMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/Materials/M_Wireframe_Main.M_Wireframe_Main"));

		auto LaunchPad = Cast<AGameShowArenaLaunchPad>(Comp.Owner);
		if (LaunchPad.IsTemporarilyHiddenInEditor())
			return;

		FVector StartLocation = LaunchPad.MeshComp.WorldLocation;
		FVector StartLaunchApex = LaunchPad.MeshComp.WorldLocation + FVector::UpVector * Acceleration::GetMaxHeight(LaunchPad.LaunchImpulse, 2385);
		DrawArrow(StartLocation, StartLaunchApex - FVector::UpVector * 80, PlayerColor::Mio, 50, 10);
		DrawWireCapsule(StartLaunchApex, FRotator::ZeroRotator, PlayerColor::Mio, 40, 88, 4, 10);
		DrawWorldString("Launch Apex", StartLaunchApex, PlayerColor::Zoe, 1, 5000, false, true);
	}
}

#endif