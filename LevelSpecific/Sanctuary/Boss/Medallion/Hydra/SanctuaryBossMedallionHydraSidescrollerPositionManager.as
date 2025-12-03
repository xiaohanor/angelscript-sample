class ASanctuaryBossMedallionHydraSidescrollerPositionManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MioHydrasRotateRoot;

	UPROPERTY(DefaultComponent, Attach = MioHydrasRotateRoot)
	USceneComponent MioHydrasRoot;

	UPROPERTY(DefaultComponent, Attach = MioHydrasRoot)
	USceneComponent MioLeftHydraRoot;

	UPROPERTY(DefaultComponent, Attach = MioHydrasRoot)
	USceneComponent MioRightHydraRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ZoeHydrasRotateRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeHydrasRotateRoot)
	USceneComponent ZoeHydrasRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeHydrasRoot)
	USceneComponent ZoeLeftHydraRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeHydrasRoot)
	USceneComponent ZoeRightHydraRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CenterHydrasRoot;

	UPROPERTY(DefaultComponent, Attach = CenterHydrasRoot)
	USceneComponent CenterLeftHydraRoot;

	UPROPERTY(DefaultComponent, Attach = CenterHydrasRoot)
	USceneComponent CenterRightHydraRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	float PlayerProgressDegrees;

	FHazeEasedQuat EasedRotation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccPlayerHydrasRotation;
	FHazeAcceleratedFloat AccPlayerHydrasAddedRotation;
	FHazeAcceleratedFloat AccPlayerHydrasAddedLocation;

	//Settings
	const FVector PlayerHydrasRootBaseOffset = FVector::ForwardVector * 5000.0;
	const float MinPlayerHydrasRotation = 45.0;
	const float FullyRejoinedAddedRotation = 70.0;
	const float MinPlayerHydrasRotationBeforeLocationOffset = 25.0;
	const float FullyRejoinedAddedSidewaysLocation = 1500.0;

	FRotator BaseRotation;

	FRotator StartRotation;
	float BlendRotationAlpha = 1.0;

	UMedallionPlayerComponent MedallionPlayerComp;
	UMedallionPlayerReferencesComponent RefsComp;

	bool bDidLateSetup = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MedallionPlayerComp = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	void LateSetup()
	{
		if (bDidLateSetup)
			return;
		bDidLateSetup = true;

		//PhaseChanged(RefsComp.Refs.HydraAttackManager.Phase);
		RefsComp.Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"PhaseChanged");
	}

	UFUNCTION()
	private void PhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::FlyingExitReturn1 || Phase == EMedallionPhase::FlyingExitReturn2)
		{
			BlendInRotationOverDuration(MedallionConstants::ReturnAndLand::ReturnDuration);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (RefsComp.Refs == nullptr)
			return;

		LateSetup();
		
		bool bIsActiveThisFrame = ShouldRotateToAverageDirection();

		if (bIsActiveThisFrame)
		{
			//Calculate Player Progress

			FVector MioDirection = (Game::Mio.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FVector ZoeDirection = (Game::Zoe.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			PlayerProgressDegrees = MioDirection.GetAngleDegreesTo(ZoeDirection);

				
			//Calculate Base Rotation

			FVector AverageDirection = ((Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5 - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			BaseRotation = FRotator::MakeFromZX(FVector::UpVector, AverageDirection);


			SetHydraHeadsTransforms(DeltaSeconds);
		}

		AccRotation.AccelerateTo(BaseRotation, 2.0, DeltaSeconds);
		SetActorRotation(AccRotation.Value);
	}

	private void BlendInRotationOverDuration(float BlendTime)
	{
		SnapHydraTransforms();
		StartRotation = ActorRotation;
		QueueComp.Duration(BlendTime, this, n"BlendInRotationUpdate");
	}

	UFUNCTION()
	private void BlendInRotationUpdate(float Alpha)
	{
		BlendRotationAlpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		SetActorRotation(Math::LerpShortestPath(StartRotation, FRotator::ZeroRotator, BlendRotationAlpha));
	}

	bool ShouldRotateToAverageDirection()
	{
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::Flying1 && RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::FlyingExitReturn1)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::Flying2 && RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::FlyingExitReturn2)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::Flying3)
			return false;
		return true;
	}

	private void SetHydraHeadsTransforms(float DeltaSeconds)
	{

		float PlayerHydrasBaseYaw = Math::Max(PlayerProgressDegrees * 0.5, MinPlayerHydrasRotation);
		float PlayerHydrasAddedYaw = Math::Max(MinPlayerHydrasRotation - PlayerProgressDegrees * 0.5, 0.0) * FullyRejoinedAddedRotation / MinPlayerHydrasRotation;
		float PlayerHydrasLocationOffsetAlpha = (MinPlayerHydrasRotationBeforeLocationOffset - Math::Min(MinPlayerHydrasRotationBeforeLocationOffset, PlayerProgressDegrees)) / MinPlayerHydrasRotationBeforeLocationOffset;

		AccPlayerHydrasRotation.AccelerateTo(PlayerHydrasBaseYaw, 2.0, DeltaSeconds);
		AccPlayerHydrasAddedRotation.AccelerateTo(PlayerHydrasAddedYaw, 2.0, DeltaSeconds);
		AccPlayerHydrasAddedLocation.AccelerateTo(PlayerHydrasLocationOffsetAlpha, 2.0, DeltaSeconds);

		MioHydrasRotateRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasRotation.Value, 0.0));
		ZoeHydrasRotateRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasRotation.Value, 0.0));

		MioHydrasRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value, 0.0));
		ZoeHydrasRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value, 0.0));
		CenterLeftHydraRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value * 0.2, 0.0));
		CenterRightHydraRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value * 0.2, 0.0));
		MioHydrasRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value * 0.7, 0.0));
		ZoeHydrasRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value * 0.7, 0.0));
		CenterLeftHydraRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value * 0.5, 0.0));
		CenterRightHydraRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value * 0.5, 0.0));
		MioHydrasRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value, 0.0));
		ZoeHydrasRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value, 0.0));
		CenterLeftHydraRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value * 0.4, 0.0));
		CenterRightHydraRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value * 0.3, 0.0));

		PrintToScreen("" + PlayerHydrasLocationOffsetAlpha);
		
		MioHydrasRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value);
		ZoeHydrasRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * -FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value);
		// CenterLeftHydraRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value * 3);
		// CenterRightHydraRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * -FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value * 2);
	}

	private void SnapHydraTransforms()
	{
		FVector MioDirection = (RefsComp.Refs.GloryKillExitLocationMio.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector ZoeDirection = (RefsComp.Refs.GloryKillExitLocationZoe.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		PlayerProgressDegrees = MioDirection.GetAngleDegreesTo(ZoeDirection);

		float PlayerHydrasBaseYaw = Math::Max(PlayerProgressDegrees * 0.5, MinPlayerHydrasRotation);
		float PlayerHydrasAddedYaw = Math::Max(MinPlayerHydrasRotation - PlayerProgressDegrees * 0.5, 0.0) * FullyRejoinedAddedRotation / MinPlayerHydrasRotation;
		float PlayerHydrasLocationOffsetAlpha = (MinPlayerHydrasRotationBeforeLocationOffset - Math::Min(MinPlayerHydrasRotationBeforeLocationOffset, PlayerProgressDegrees)) / MinPlayerHydrasRotationBeforeLocationOffset;

		AccPlayerHydrasRotation.SnapTo(PlayerHydrasBaseYaw);
		AccPlayerHydrasAddedRotation.SnapTo(PlayerHydrasAddedYaw);
		AccPlayerHydrasAddedLocation.SnapTo(PlayerHydrasLocationOffsetAlpha);

		MioHydrasRotateRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasRotation.Value, 0.0));
		ZoeHydrasRotateRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasRotation.Value, 0.0));

		MioHydrasRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value * 0.1, 0.0));
		ZoeHydrasRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value * 0.1, 0.0));
		CenterLeftHydraRoot.SetRelativeRotation(FRotator(0.0, -AccPlayerHydrasAddedRotation.Value, 0.0));
		CenterRightHydraRoot.SetRelativeRotation(FRotator(0.0, AccPlayerHydrasAddedRotation.Value, 0.0));

		PrintToScreen("" + PlayerHydrasLocationOffsetAlpha);
		
		MioHydrasRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value);
		ZoeHydrasRoot.SetRelativeLocation(PlayerHydrasRootBaseOffset + FVector::RightVector * -FullyRejoinedAddedSidewaysLocation * AccPlayerHydrasAddedLocation.Value);
	}
};