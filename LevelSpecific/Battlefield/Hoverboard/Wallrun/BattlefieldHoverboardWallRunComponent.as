
class UBattlefieldHoverboardWallRunComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	AHazePlayerCharacter OwningPlayer;

	UBattlefieldHoverboardWallRunSettings Settings;
	UBattlefieldHoverboardWallRunJumpSettings JumpSettings;
	UBattlefieldHoverboardWallRunTransferSettings TransferSettings;
	UPlayerWallRunLedgeClimbSettings ClimbSettings;
	UBattlefieldHoverboardWallSettings WallSettings;

	protected EPlayerWallRunState CurrentState = EPlayerWallRunState::None;

	// Maybe this should be renamed to bHaveTouchedGroundSinceLastDeactivation or something to make it clear what it tracks
	bool bCanWallRun = true;	

	FPlayerWallRunData ActiveData;
	FPlayerWallRunData PreviousData;
	FPlayerWallRunClimbData ClimbData;
	FPlayerWallRunLedgeTurnaroundData LedgeTurnaroundData;

	UPROPERTY(BlueprintReadOnly)
	FPlayerWallRunAnimationData AnimData;
	/* ------------------- */

	// Time after the air dash ends that we still do dash-enter
	const float DashEnterGraceTime = 0.2;
	// If we convert an air dash into a wall run, if the air dash lasted shorter than this time, refresh it
	const float DashRefreshThresholdTime = 0.1666;

	bool bTEMPToggleAutomaticEnter = true;
	bool bTEMPToggleHoldEnter = false;
	bool bTEMPToggleDashEnter = true;
	bool bTEMPToggleDashParallelEnter = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		Settings = UBattlefieldHoverboardWallRunSettings::GetSettings(Cast<AHazeActor>(Owner));
		JumpSettings = UBattlefieldHoverboardWallRunJumpSettings::GetSettings(Cast<AHazeActor>(Owner));
		TransferSettings = UBattlefieldHoverboardWallRunTransferSettings::GetSettings(Cast<AHazeActor>(Owner));
		ClimbSettings = UPlayerWallRunLedgeClimbSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UBattlefieldHoverboardWallSettings::GetSettings(Cast<AHazeActor>(Owner));

		{
			FHazeDevInputInfo Info;
			Info.Name = n"Wall Run: Automatic Enter";
			Info.Category = n"Movement";
			Info.OnTriggered.BindUFunction(this, n"ToggleWallRunAutomaticEnter");
			Info.OnStatus.BindUFunction(this, n"GetWallRunAutomaticEnterStatus");
			Info.AddKey(EKeys::Gamepad_FaceButton_Left);
			Info.AddKey(EKeys::R);

			OwningPlayer.RegisterDevInput(Info);
		}

		{
			FHazeDevInputInfo Info;
			Info.Name = n"Wall Run: Hold Enter";
			Info.Category = n"Movement";
			Info.OnTriggered.BindUFunction(this, n"ToggleWallRunHoldEnter");
			Info.OnStatus.BindUFunction(this, n"GetWallRunHoldEnterStatus");
			Info.AddKey(EKeys::Gamepad_FaceButton_Right);
			Info.AddKey(EKeys::G);

			OwningPlayer.RegisterDevInput(Info);
		}

		{
			FHazeDevInputInfo Info;
			Info.Name = n"Wall Run: Dash Enter";
			Info.Category = n"Movement";
			Info.OnTriggered.BindUFunction(this, n"ToggleWallRunDashEnter");
			Info.OnStatus.BindUFunction(this, n"GetWallRunDashEnterStatus");
			Info.AddKey(EKeys::Gamepad_FaceButton_Top);
			Info.AddKey(EKeys::T);

			OwningPlayer.RegisterDevInput(Info);
		}

		{
			FHazeDevInputInfo Info;
			Info.Name = n"Wall Run: Dash Parallel Enter";
			Info.Category = n"Movement";
			Info.OnTriggered.BindUFunction(this, n"ToggleWallRunDashParallelEnter");
			Info.OnStatus.BindUFunction(this, n"GetWallRunDashParallelEnterStatus");
			Info.AddKey(EKeys::Gamepad_RightShoulder);
			Info.AddKey(EKeys::Y);

			OwningPlayer.RegisterDevInput(Info);
		}
	}

	UFUNCTION()
	private void ToggleWallRunDashParallelEnter()
	{
		bTEMPToggleDashParallelEnter = !bTEMPToggleDashParallelEnter;
	}

	UFUNCTION()
	private void GetWallRunDashParallelEnterStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (bTEMPToggleAutomaticEnter)
			return;
		if (!bTEMPToggleDashEnter)
			return;
		if (!bTEMPToggleDashParallelEnter)
		{
			OutDescription = "[ Parallel Enter: OFF ]";
			OutColor = FLinearColor::Red;
		}
		else
		{
			OutDescription = "[ Parallel Enter: ON ]";
			OutColor = FLinearColor::Green;
		}
	}

	UFUNCTION()
	private void ToggleWallRunDashEnter()
	{
		bTEMPToggleDashEnter = !bTEMPToggleDashEnter;
	}

	UFUNCTION()
	private void GetWallRunDashEnterStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (bTEMPToggleAutomaticEnter)
			return;
		if (!bTEMPToggleDashEnter)
		{
			OutDescription = "[ Dash Enter: OFF ]";
			OutColor = FLinearColor::Red;
		}
		else
		{
			OutDescription = "[ Dash Enter: ON ]";
			OutColor = FLinearColor::Green;
		}
	}

	UFUNCTION()
	private void ToggleWallRunAutomaticEnter()
	{
		bTEMPToggleAutomaticEnter = !bTEMPToggleAutomaticEnter;
	}

	UFUNCTION()
	private void GetWallRunAutomaticEnterStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (!bTEMPToggleAutomaticEnter)
		{
			OutDescription = "[ Auto Enter: OFF ]";
			OutColor = FLinearColor::Red;
		}
		else
		{
			OutDescription = "[ Auto Enter: ON ]";
			OutColor = FLinearColor::Green;
		}
	}

	UFUNCTION()
	private void ToggleWallRunHoldEnter()
	{
		bTEMPToggleHoldEnter = !bTEMPToggleHoldEnter;
	}

	UFUNCTION()
	private void GetWallRunHoldEnterStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (bTEMPToggleAutomaticEnter)
			return;
		if (!bTEMPToggleHoldEnter)
		{
			OutDescription = "[ Hold Enter: OFF ]";
			OutColor = FLinearColor::Red;
		}
		else
		{
			OutDescription = "[ Hold Enter: ON ]";
			OutColor = FLinearColor::Green;
		}
	}

	EPlayerWallRunState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EPlayerWallRunState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = CurrentState;
	}

	// Returns true if the state completed was the active state (nothing else took over)
	bool StateCompleted(EPlayerWallRunState CompletedState)
	{
		if (State == CompletedState)
		{
			ResetWallRun();
			return true;
		}
		return false;
	}

	// Reset wall run data
	void ResetWallRun()
	{
		State = EPlayerWallRunState::None;
		ActiveData.Reset();
		AnimData.Reset();
	}

	bool HasActiveWallRun() const
	{
		return ActiveData.Component != nullptr;
	}

	void StartWallRun(FPlayerWallRunData WallRunData)
	{
		if (WallRunData.Component == nullptr)
			return;
		
		FPlayerWallRunData NewWallRunData = WallRunData;
		if (NewWallRunData.InitialVelocity.IsNearlyZero())
		{
			const float DirectionCorrection = Math::Sign(NewWallRunData.WallRight.DotProduct(OwningPlayer.ActorVelocity));
			NewWallRunData.InitialVelocity = NewWallRunData.WallRight * TransferSettings.WallRunEnterSpeed * DirectionCorrection;
			NewWallRunData.InitialVelocity = FQuat(NewWallRunData.WallNormal, Math::DegreesToRadians(TransferSettings.WallRunEnterVelocityAngle * DirectionCorrection)) * NewWallRunData.InitialVelocity;
		}

		ActiveData = NewWallRunData;
	}

	/*
		Traces in the specific direction, testing head and feet
		bTraceFullCapsule true will trace the entire player capsule. False will trace a smaller sphere. Good for activation vs active test (maybe?)
	*/
	FPlayerWallRunData TraceForWallRun(AHazePlayerCharacter Player, FVector TraceDirection, bool bDebug = false) const
	{	
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		FPlayerWallRunData WallRunData;

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		//FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
		
		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart;
		TraceEnd += TraceDirection * Math::Max(WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);
		if(bDebug)
			Debug::DrawDebugArrow(TraceStart, TraceEnd, 20, FLinearColor::Red, 10);
		
		if (bDebug)
			TraceSettings.DebugDrawOneFrame();

		FHitResult WallHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		if (!WallHit.bBlockingHit)
			return FPlayerWallRunData();

		if (!WallHit.Component.HasTag(ComponentTags::WallRunnable))
			return FPlayerWallRunData();

		FVector WallRight = Player.MovementWorldUp.CrossProduct(WallHit.ImpactNormal).GetSafeNormal();
		FVector WallUp = WallHit.ImpactNormal.CrossProduct(WallRight).GetSafeNormal();

		WallRunData.Component = WallHit.Component;
		WallRunData.WallRotation = FRotator::MakeFromXY(WallHit.ImpactNormal, WallRight);
		WallRunData.Location = WallHit.ImpactPoint;

		// Check for the verticality of the surface
		float WallPitch = 90.0 - Math::RadiansToDegrees(WallRunData.WallNormal.AngularDistance(Player.MovementWorldUp));
		if (WallPitch > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return FPlayerWallRunData();

		/* Head & Foot trace
			Test to see if the head and feet land on something valid
			Take the hit location and trace towards to find head and foot location towards the normal
			Could probably move this into a "TraceForPlanting" function
		*/
		FHazeTraceSettings HeadFootTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		HeadFootTraceSettings.UseLine();

		if (bDebug)
			HeadFootTraceSettings.DebugDrawOneFrame();
		
		const FVector FlattenedTraceNormal = WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FVector HeadFootTraceStart = WallHit.Location + (Player.MovementWorldUp * 100.0);
		FVector HeadFootTraceEnd = HeadFootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		FHitResult HeadFootHit = HeadFootTraceSettings.QueryTraceSingle(HeadFootTraceStart, HeadFootTraceEnd);
		if (!HeadFootHit.bBlockingHit)
			return FPlayerWallRunData();
		
		HeadFootTraceStart = WallHit.Location + (Player.MovementWorldUp * 25.0);
		HeadFootTraceEnd = HeadFootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		HeadFootHit = HeadFootTraceSettings.QueryTraceSingle(HeadFootTraceStart, HeadFootTraceEnd);
		if (!HeadFootHit.bBlockingHit)
			return FPlayerWallRunData();

		return WallRunData;
	}

	TOptional<FRotator> TraceForWallRotation(AHazePlayerCharacter Player, FVector TraceStartLocation, FVector TraceDirection, bool bDebug = false) const
	{
		TOptional<FRotator> WallRotation;
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		
		FVector TraceStart = TraceStartLocation;
		FVector TraceEnd = TraceStart;
		TraceEnd += TraceDirection * Math::Max(WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);
		if(bDebug)
			Debug::DrawDebugArrow(TraceStart, TraceEnd, 20, FLinearColor::Red, 10);
		
		if (bDebug)
			TraceSettings.DebugDrawOneFrame();

		FHitResult WallHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		if (!WallHit.bBlockingHit)
			return WallRotation;

		if (!WallHit.Component.HasTag(ComponentTags::WallRunnable))
			return WallRotation;

		FVector WallRight = Player.MovementWorldUp.CrossProduct(WallHit.ImpactNormal).GetSafeNormal();
		WallRotation.Set(FRotator::MakeFromXY(WallHit.ImpactNormal, WallRight));

		return WallRotation;
	}

	bool ShouldTransfer(AHazePlayerCharacter Player, bool bDebug = false)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		FVector DashInitialHorizontalVelocity = (MoveComp.GetHorizontalVelocity() + ActiveData.WallNormal * TransferSettings.HorizontalImpulse).GetSafeNormal();

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart;
		TraceEnd += DashInitialHorizontalVelocity.GetSafeNormal() * UBattlefieldHoverboardWallRunTransferSettings::GetSettings(Player).TransferDistance;

		if (bDebug)
			TraceSettings.DebugDraw(5.0);

		FHitResult TraceHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		
		if (!TraceHit.bBlockingHit)
			return false;

		if (!TraceHit.Component.HasTag(ComponentTags::WallRunnable))
			return false;

		const float WallPitch = 90.0 - Math::RadiansToDegrees(TraceHit.Normal.AngularDistance(Player.MovementWorldUp));
		if (WallPitch > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return false;
		
		const FVector FlattenedWallNormal = ActiveData.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		const FVector FlattenedTraceNormal = TraceHit.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		if (Math::RadiansToDegrees(FlattenedWallNormal.AngularDistance(FlattenedTraceNormal)) < 160.0)
			return false;


		/* Head & Foot trace
			Test to see if the head and feet land on something valid
			Take the hit location and trace towards to find head and foot location towards the normal
			Could probably move this into a "TraceForPlanting" function
		*/
		FHazeTraceSettings HeadFootTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		HeadFootTraceSettings.UseLine();

		if (bDebug)
			HeadFootTraceSettings.DebugDraw(5.0);
		
		FVector HeadFootTraceStart = TraceHit.Location + (Player.MovementWorldUp * 100.0);
		FVector HeadFootTraceEnd = HeadFootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		FHitResult HeadFootHit = HeadFootTraceSettings.QueryTraceSingle(HeadFootTraceStart, HeadFootTraceEnd);
		if (!HeadFootHit.bBlockingHit)
			return false;
		
		HeadFootTraceStart = TraceHit.Location + (Player.MovementWorldUp * 25.0);
		HeadFootTraceEnd = HeadFootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		HeadFootHit = HeadFootTraceSettings.QueryTraceSingle(HeadFootTraceStart, HeadFootTraceEnd);
		if (!HeadFootHit.bBlockingHit)
			return false;

		return true;
	}
}