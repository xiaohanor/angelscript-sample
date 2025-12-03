event void FOnBothPlayersInteracting();

class ASpaceWalkEscapeDropShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DropShip;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DropShipTarget;
	default DropShipTarget.SetHiddenInGame(true);
	default DropShipTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DropShip)
	USceneComponent MioLocation;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	USceneComponent ZoeLocation;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UHazeMovablePlayerTriggerComponent EnterTrigger;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShipMovement;
	default ShipMovement.Duration = 25.0;
	default ShipMovement.UseLinearCurveZeroToOne();
	default ShipMovement.bCurveUseNormalizedTime = true;

	UPROPERTY()
	FOnBothPlayersInteracting BothInteracting;

	FRotator LocalRotation;

	FVector DropShipStart;
	FVector DropShipExit;

	FRotator DropShipStartRotation;
	FRotator DropShipExitRotation;


	TPerPlayer<bool> HasEntered;
	bool bHasStartedMash = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropShipStart = DropShip.WorldLocation;
		DropShipExit = DropShipTarget.WorldLocation;

		DropShipStartRotation = DropShip.WorldRotation;
		DropShipExitRotation = DropShipTarget.WorldRotation;

		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");

	//	LocalRotation = FRotator(2,1,5);

		ShipMovement.BindUpdate(this , n"ShipMoving");
		ShipMovement.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	private void OnPlayerEntered(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			CrumbPlayerEntered(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayerEntered(AHazePlayerCharacter Player)
	{
		HasEntered[Player] = true;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	//	Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		USceneComponent TargetPoint;
		if (Player.IsMio())
			TargetPoint = MioLocation;
		else
			TargetPoint = ZoeLocation;

		Player.SmoothTeleportActor(TargetPoint.WorldLocation, TargetPoint.WorldRotation, this, 1.0);
		Player.AttachToComponent(TargetPoint, AttachmentRule = EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	private void OnFinished()
	{
		LocalRotation = FRotator(0,0,0);
	}

	UFUNCTION(BlueprintCallable)
	void StartShip()
	{
		ShipMovement.PlayFromStart();
	}

	UFUNCTION()
	private void ShipMoving(float CurrentValue)
	{
		DropShip.SetWorldLocation(Math::Lerp(DropShipStart,DropShipExit, CurrentValue));
		DropShip.SetWorldRotation(Math::LerpShortestPath(DropShipStartRotation, DropShipExitRotation, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	if (!LocalRotation.IsNearlyZero())
	//		DropShip.AddLocalRotation(FRotator(LocalRotation) * DeltaSeconds);

		if (HasEntered[EHazePlayer::Mio] && HasEntered[EHazePlayer::Zoe])
		{
			if (!bHasStartedMash)
			{
				bHasStartedMash = true;

				FButtonMashSettings Settings;
				Settings.Mode = EButtonMashMode::ButtonHold;
				Settings.Duration = 1.0;

				ButtonMash::StartDoubleButtonMash(
					Settings, Settings, this,
					FOnButtonMashCompleted(this, n"OnButtonMashCompleted")
				);
			}
			else
			{
				// TODO: Animations?
			}
		}
	}

	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		BothInteracting.Broadcast();
	}
};