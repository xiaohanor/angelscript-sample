UCLASS(Abstract)
class AMagnetDroneSwitchBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent EdgeMeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	float ExtendedScale = 5;

	UPROPERTY(EditDefaultsOnly)
	float ExtendDuration = 0.1;

	UPROPERTY(EditDefaultsOnly)
	float RetractedScale = 0.1;

	UPROPERTY(EditDefaultsOnly)
	float RetractDuration = 1;

	private bool bExtend = false;
	private float Alpha = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Controlled on Swarm Drone side, so that it will match up with the crumb synced position of Mio
		SetActorControlSide(Drone::GetSwarmDronePlayer());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bExtend)
		{
			Alpha = Math::FInterpConstantTo(Alpha, 1, DeltaSeconds, 1.0 / ExtendDuration);
		}
		else
		{
			Alpha = Math::FInterpConstantTo(Alpha, 0, DeltaSeconds, 1.0 / RetractDuration);
		}

		{
			const float SmoothAlpha = Math::EaseOut(0, 1, Alpha, 2);

			FVector RelativeScale3D = MeshComp.RelativeScale3D;
			RelativeScale3D.Y = Math::Lerp(RetractedScale, ExtendedScale, SmoothAlpha);

			MeshComp.SetRelativeScale3D(RelativeScale3D);

			float EdgeY = Math::Lerp(0, -500, SmoothAlpha);
			EdgeMeshComp.SetRelativeLocation(FVector(-400, EdgeY, 2));
		}

		if((bExtend && Alpha > 1.0 - KINDA_SMALL_NUMBER) || (!bExtend && Alpha < KINDA_SMALL_NUMBER))
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintCallable)
	void Enable()
	{
		RemoveActorDisable(DisableComp.StartDisabledInstigator);
	}

	UFUNCTION(BlueprintCallable)
	void MoveOut()
	{
		if(Network::IsGameNetworked())
		{
			// Only allow the Mio side to decide when to move out
			if(Drone::MagnetDronePlayer.HasControl())
				return;
		}

		CrumbMioToZoeMoveOut();
	}

	UFUNCTION(BlueprintCallable)
	void MoveIn()
	{
		if(Network::IsGameNetworked())
		{
			// Only allow the Mio side to decide when to move in
			if(Drone::MagnetDronePlayer.HasControl())
				return;
		}

		CrumbMioToZoeMoveIn();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMioToZoeMoveOut()
	{
		bExtend = true;

		UMagnetDroneSwitchBridgeEventHandler::Trigger_MoveOut(this);

		SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMioToZoeMoveIn()
	{
		bExtend = false;

		UMagnetDroneSwitchBridgeEventHandler::Trigger_MoveIn(this);
		
		SetActorTickEnabled(true);
	}
};