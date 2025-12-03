class ARemoteHackableSocketRotatingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(2.0);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly)
	ARemoteHackableCableSocket Socket;

	UPROPERTY(EditAnywhere)
	float RotationRate = 30.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Sync from Zoe side
		// This means a lot of delay on the Mio side, but less jank when Zoe jumps onto the pole.
		SetActorControlSide(Game::Zoe);

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			Actor.AttachToComponent(RotationRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		Socket.OnSocketActivated.AddUFunction(this, n"SocketActivated");
		Socket.OnSocketDeactivated.AddUFunction(this, n"SocketDeactivated");
	}

	UFUNCTION()
	private void SocketActivated()
	{
		URemoteHackableSocketRotatingObjectEffectEventHandler::Trigger_StartRotating(this);
	}

	UFUNCTION()
	private void SocketDeactivated()
	{
		URemoteHackableSocketRotatingObjectEffectEventHandler::Trigger_StopRotating(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			float RotRate = 0;

			if (Socket != nullptr)
				RotRate = Socket.GetSpeedAlpha() * RotationRate;
			
			RotationRoot.AddLocalRotation(FRotator(0.0, RotRate * DeltaTime, 0.0));
			SyncedRotation.SetValue(RotationRoot.RelativeRotation);
		}
		else
		{
			RotationRoot.SetRelativeRotation(SyncedRotation.Value);
		}
	}
}