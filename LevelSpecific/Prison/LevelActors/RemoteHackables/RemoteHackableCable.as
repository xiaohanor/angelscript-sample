class URemoteHackableCableSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

class ARemoteHackableCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromMioControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent PlugRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent TutorialAttachComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USphereComponent Trigger;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableCableCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly)
	FText PullOutTutorialText;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> PullPlugCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PlugFF;

	UPROPERTY(EditAnywhere)
	float MoveForce = 2000.0;

	ARemoteHackableCableSocket CurrentSocket = nullptr;

	FHazeAcceleratedFloat AccPlugRotation;
	float TargetPlugRotation = 0.0;
	float FullPlugRotationRate = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HitConstraint");

		HackingComp.OnHackingStarted.AddUFunction(this, n"HackingStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackingStopped");
	}

	UFUNCTION()
	private void HackingStarted()
	{
		URemoteHackableCableEffectEventHandler::Trigger_StartHacking(this);
	}

	UFUNCTION()
	private void HackingStopped()
	{
		URemoteHackableCableEffectEventHandler::Trigger_StopHacking(this);
	}

	UFUNCTION()
	private void HitConstraint(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
			URemoteHackableCableEffectEventHandler::Trigger_HitStartPoint(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentSocket != nullptr)
		{
			FVector Loc = Math::VInterpTo(TranslateComp.WorldLocation, CurrentSocket.PlugTarget.WorldLocation, DeltaTime, 5.0);
			TranslateComp.SetWorldLocation(Loc);
		}

		AccPlugRotation.AccelerateTo(TargetPlugRotation, 1.0, DeltaTime);
		PlugRoot.AddLocalRotation(FRotator(0.0, 0.0, -AccPlugRotation.Value * DeltaTime));
	}

	void EnterSocket(ARemoteHackableCableSocket Socket)
	{
		TargetPlugRotation = FullPlugRotationRate;

		CurrentSocket = Socket;
		FRemoteHackableCableSocketEventData EventData;
		EventData.Socket = Socket;

		Game::Mio.PlayForceFeedback(PlugFF, false, true, this);

		URemoteHackableCableEffectEventHandler::Trigger_ConnectedToSocket(this, EventData);
	}

	void ExitSocket()
	{
		if (CurrentSocket == nullptr)
			return;

		TargetPlugRotation = 0.0;
		
		FRemoteHackableCableSocketEventData EventData;
		EventData.Socket = CurrentSocket;

		CurrentSocket.Unplug();
		CurrentSocket = nullptr;
		TranslateComp.ApplyImpulse(TranslateComp.WorldLocation, -TranslateComp.ForwardVector * 1000.0);

		URemoteHackableCableEffectEventHandler::Trigger_DisconnectedFromSocket(this, EventData);
	}
}

class URemoteHackableCableCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ARemoteHackableCable Cable;

	FHazeAcceleratedFloat AccFloat;

	float PullOutTime = 0.0;

	bool bTutorialActive = false;
	bool bPullOutTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Cable = Cast<ARemoteHackableCable>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bTutorialActive = false;
		PullOutTime = 0.0;

		Cable.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.StopCameraShakeByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);

		if (Cable.CurrentSocket != nullptr)
			Cable.CurrentSocket.OnSocketDeactivated.Broadcast();

		Cable.SyncedRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);

		Cable.ExitSocket();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(HasControl())
		{
			FVector MoveInput = PlayerMoveComp.MovementInput;
			FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			
			if (Cable.CurrentSocket != nullptr)
			{
				if (RawInput.X <= -0.25)
				{
					Player.SetFrameForceFeedback(0.5, 0.5, 0.5, 0.5);
					Player.PlayCameraShake(Cable.PullPlugCamShake, this, 10.0);
					PullOutTime += DeltaTime;
					if (PullOutTime >= 0.15)
					{
						CrumbPullOutOfSocket();
						Player.PlayForceFeedback(Cable.PlugFF, false, true, this);
					}
				}
				else
				{
					PullOutTime = 0.0;
					Player.StopCameraShakeByInstigator(this);

					FHazeFrameForceFeedback FF;
					FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.2;
					FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.2;
					Player.SetFrameForceFeedback(FF);
				}
			}
			else
			{
				Cable.TranslateComp.ApplyForce(Cable.TranslateComp.WorldLocation, MoveInput * Cable.MoveForce);
			}
		}

		if (!bPullOutTutorialCompleted)
		{
			if (Cable.CurrentSocket != nullptr)
				ShowTutorial();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPullOutOfSocket()
	{
		Cable.ExitSocket();
		Player.StopCameraShakeByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);
	}

	void ShowTutorial()
	{
		if (bPullOutTutorialCompleted)
			return;

		if (bTutorialActive)
			return;

		bTutorialActive = true;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Text = Cable.PullOutTutorialText;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Down;
		// Player.ShowTutorialPrompt(TutorialPrompt, this);
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Cable.TutorialAttachComp, FVector::ZeroVector, 0.0);
	}
}


class ARemoteHackableCableSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SocketRoot;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	USphereComponent SocketTrigger;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	USceneComponent PlugTarget;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	USceneComponent SpinningRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	FRemoteHackableCableSocketEvent OnSocketActivated;

	UPROPERTY()
	FRemoteHackableCableSocketEvent OnSocketDeactivated;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ConnectEffect;

	bool bActive = false;

	FHazeAcceleratedFloat AccSocketRotation;
	float TargetSocketRotation = 0.0;
	float FullSocketRotationRate = 200.0;

	float SpeedAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		
		SocketTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!HasControl())
			return;

		ARemoteHackableCable Cable = Cast<ARemoteHackableCable>(OtherActor);
		if (Cable == nullptr)
			return;

		if (Cable.CurrentSocket != nullptr)
			return;

		CrumbEnterTrigger(Cable);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEnterTrigger(ARemoteHackableCable Cable)
	{
		bActive = true;

		Cable.EnterSocket(this);
		
		TargetSocketRotation = FullSocketRotationRate;

		OnSocketActivated.Broadcast();

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ConnectEffect, SocketTrigger.WorldLocation);
	}

	void Unplug()
	{
		bActive = false;
		TargetSocketRotation = 0.0;

		OnSocketDeactivated.Broadcast();

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ConnectEffect, SocketTrigger.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccSocketRotation.AccelerateTo(TargetSocketRotation, 1.0, DeltaTime);
		SpinningRoot.AddLocalRotation(FRotator(0.0, 0.0, -AccSocketRotation.Value * DeltaTime));

		SpeedAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, FullSocketRotationRate), FVector2D(0.0, 1.0), AccSocketRotation.Value);
	}

	UFUNCTION(BlueprintPure)
	float GetSpeedAlpha()
	{
		return SpeedAlpha;
	}
}

event void FRemoteHackableCableSocketEvent();