event void FTrashCompactorFuseBoxEvent();

UCLASS(Abstract)
class ATrashCompactorHackableFuseBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FuseBoxRoot;

	UPROPERTY(DefaultComponent, Attach = FuseBoxRoot)
	URemoteHackingResponseComponent HackingComp;
	default HackingComp.bAllowHacking = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TrashCompactorHackableFuseBoxCapability");

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditDefaultsOnly)
	FText TutorialText;

	UPROPERTY(EditInstanceOnly)
	ATrashCompactorHackableFuseBoxElectricCharge ElectricCharge;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RotatePieceFF;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailFF;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SuccessFF;

	UPROPERTY()
	FTrashCompactorFuseBoxEvent OnHacked;

	UPROPERTY()
	FTrashCompactorFuseBoxEvent OnReachedEnd;

	float ElectricChargeMoveSpeed = 120.0;
	float SplineDistance = 0.0;

	FSplinePosition SplinePosition;

	bool bMoving = false;
	bool bReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		HackingComp.OnHackingStarted.AddUFunction(this, n"HackingStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackingStopped");

		SplineComp = UHazeSplineComponent::Get(TargetSpline);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted()
	{
		ActivateCharge();

		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_HackStarted(this);

		OnHacked.Broadcast();
	}

	void ActivateCharge()
	{
		ElectricCharge.SetActorHiddenInGame(false);

		bMoving = true;

		ElectricChargeMoveSpeed = 0.0;
		SplinePosition = FSplinePosition(SplineComp, 0.0, true);
		ElectricCharge.SetActorLocation(SplinePosition.WorldLocation);

		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_ActivateCharge(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_HackEnded(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bReachedEnd)
			return;

		if (!bMoving)
			return;

		if (HackingComp.bHacked)
		{
			ElectricChargeMoveSpeed = Math::Clamp(ElectricChargeMoveSpeed + (40.0 * DeltaTime), 0.0, 100.0);
			SplinePosition.Move(ElectricChargeMoveSpeed * DeltaTime);
			ElectricCharge.SetActorLocation(SplinePosition.WorldLocation);
			ElectricCharge.SetActorLocationAndRotation(SplinePosition.WorldLocation, SplinePosition.WorldRotation);
			ElectricCharge.ChargeRootComp.AddLocalRotation(FRotator(200.0 * DeltaTime, 0.0, 0.0));

			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
			Trace.IgnoreActor(this);
			Trace.IgnoreActor(ElectricCharge);
			Trace.IgnorePlayers();
			Trace.UseSphereShape(6.0);

			if (HasControl())
			{
				FHitResult Hit = Trace.QueryTraceSingle(ElectricCharge.ActorLocation, ElectricCharge.ActorLocation + FVector(0.0, 0.0, 0.1));
				if (Hit.bBlockingHit)
				{
					ATrashCompactorHackableFuseBoxObstacle Obstacle = Cast<ATrashCompactorHackableFuseBoxObstacle>(Hit.Actor);
					if (Obstacle != nullptr && Obstacle.bActive)
					{
						CrumbInterruptHacking();
					}
				}

				if (SplinePosition.GetCurrentSplineDistance() >= SplinePosition.CurrentSpline.SplineLength)
				{
					CrumbFinishMiniGame();
				}
			}
		}
	}

	void ToggleObstacleStatus()
	{
		TListedActors<ATrashCompactorHackableFuseBoxObstacle> Obstacles;
		for (ATrashCompactorHackableFuseBoxObstacle Obstacle : Obstacles)
		{
			Obstacle.ToggleActiveStatus();
		}

		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_RotateObstacles(this);
	}

	void InterruptHacking_Local()
	{
		ElectricCharge.SetActorHiddenInGame(true);

		bMoving = false;
		ElectricCharge.HitObstacle();
		Timer::SetTimer(this, n"Restart", 1.0);

		Game::Mio.PlayForceFeedback(FailFF, false, true, this);
		
		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_ChargeCollision(this);
	}

	UFUNCTION()
	void Restart()
	{
		ActivateCharge();
	}

	UFUNCTION(CrumbFunction)
	void CrumbInterruptHacking()
	{
		InterruptHacking_Local();
	}

	UFUNCTION(DevFunction)
	void Dev_FinishMiniGame()
	{
		if (HackingComp.bHacked)
			CrumbFinishMiniGame();
	}

	UFUNCTION(CrumbFunction)
	void CrumbFinishMiniGame()
	{
		bReachedEnd = true;
		OnReachedEnd.Broadcast();

		ElectricCharge.SetActorHiddenInGame(true);

		HackingComp.SetHackingAllowed(false);

		Game::Mio.PlayForceFeedback(SuccessFF, false, true, this);

		UTrashCompactorHackableFuseBoxEffectEventHandler::Trigger_ChargeReachedEnd(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEnd() {}
}

class ATrashCompactorHackableFuseBoxElectricCharge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ChargeRootComp;

	void HitObstacle()
	{
		BP_HitObstacle();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HitObstacle() {}
}

class UTrashCompactorHackableFuseBoxCapability : URemoteHackableBaseCapability
{
	ATrashCompactorHackableFuseBox FuseBox;

	bool bTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FuseBox = Cast<ATrashCompactorHackableFuseBox>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (!bTutorialCompleted)
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::PrimaryLevelAbility;
			Prompt.Text = FuseBox.TutorialText;
			Prompt.DisplayType = ETutorialPromptDisplay::Action;
			Player.ShowTutorialPrompt(Prompt, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (HasControl())
		{
			if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			{
				Player.PlayForceFeedback(FuseBox.RotatePieceFF, false, true, this);
				CrumbToggleObstacleStatus();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbToggleObstacleStatus()
	{
		FuseBox.ToggleObstacleStatus();
		if (!bTutorialCompleted)
		{
			bTutorialCompleted = true;
			Player.RemoveTutorialPromptByInstigator(this);
		}
	}
}

class ATrashCompactorHackableFuseBoxObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObstacleRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditInstanceOnly)
	bool bActive = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bActive)
			ObstacleRoot.SetRelativeLocation(FVector(0.0, 20.0, 0.0));
		else
			ObstacleRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.BindFinished(this, n"FinishMove");
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMove(float CurValue)
	{
		float Loc = Math::Lerp(0.0, 20.0, CurValue);
		ObstacleRoot.SetRelativeLocation(FVector(0.0, Loc, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMove()
	{
		
	}

	void ToggleActiveStatus()
	{
		if (bActive)
			MoveTimeLike.ReverseFromEnd();
		else
			MoveTimeLike.PlayFromStart();

		bActive = !bActive;
	}
}