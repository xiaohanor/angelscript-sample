UCLASS(Abstract)
class APrisonBossBrain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BrainRoot;

	UPROPERTY(DefaultComponent, Attach = BrainRoot)
	USceneComponent PulsateRoot;

	UPROPERTY(DefaultComponent, Attach = PulsateRoot)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = PulsateRoot)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UPrisonBossBrainEditorComponent EditorComp;
#endif

	UPROPERTY(EditAnywhere)
	bool bPreviewOpen = false;

	UPROPERTY(EditAnywhere)
	AActor LaunchBackTarget;
	
	UPROPERTY(EditAnywhere)
	APrisonBossBrainPlatform FirstButtonPlatform;

	UPROPERTY(EditAnywhere, Category = "Movement")
	bool bPreviewBob = true;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float BobDistance = 20.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float BobSpeed = 1.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	FVector2D ScaleRange = FVector2D(0.99, 1.01);

	UPROPERTY(EditAnywhere, Category = "Movement")
	float ScaleSpeed = 1.5;
	
	UPROPERTY(EditAnywhere, Category = "BrainPulse")
	float BrainPulseSpeed = 2.5;

	UPROPERTY(EditAnywhere, Category = "BrainPulse")
	float BrainPulseStrength = 15.0;

	UPROPERTY(EditAnywhere, Category = "BrainPulse")
	float BrainPulseWavelength = 1500.0;

	float BrainPulseTime = 0.0;
	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewOpen)
		{
			LeftRoot.SetRelativeRotation(FRotator(0.0, -15.0, 0.0));
			RightRoot.SetRelativeRotation(FRotator(0.0, 15.0, 0.0));
		}
		else
		{
			LeftRoot.SetRelativeRotation(FRotator::ZeroRotator);
			RightRoot.SetRelativeRotation(FRotator::ZeroRotator);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BobTick(DeltaTime);
	}

	UFUNCTION(BlueprintEvent)
	TArray<UStaticMeshComponent> GetBrainMeshes(){ return TArray<UStaticMeshComponent>(); }

	void BobTick(float DeltaTime)
	{
		/*float Time = Time::PredictedGlobalCrumbTrailTime;
		FVector CurrentScale = FVector(Math::Lerp(ScaleRange.X, ScaleRange.Y, Math::Cos(Time * ScaleSpeed + 3.14152128) * 0.5 + 0.5));
		PulsateRoot.SetRelativeScale3D(CurrentScale);

		FVector BobLocation = (GetActorTransform().TransformVector(FVector::UpVector)) * Math::Sin(Time * BobSpeed) * BobDistance;
		PulsateRoot.SetRelativeLocation(BobLocation);*/


		BrainPulseTime += DeltaTime * BrainPulseSpeed;
		auto Meshes = GetBrainMeshes();
		for (int i = 0; i < Meshes.Num(); i++)
		{
			if(Meshes[i] == nullptr)
				continue;
			
			Meshes[i].SetScalarParameterValueOnMaterials(n"BrainPulseTime", BrainPulseTime);
			Meshes[i].SetScalarParameterValueOnMaterials(n"BrainPulseStrength", BrainPulseStrength);
			Meshes[i].SetScalarParameterValueOnMaterials(n"BrainPulseWavelength", BrainPulseWavelength);
		}

	}

#if EDITOR
	void EditorTick(float DeltaSeconds)
	{
		if (bPreviewBob)
			BobTick(DeltaSeconds);
		else
		{
			PulsateRoot.SetRelativeScale3D(FVector::OneVector);
			PulsateRoot.SetRelativeLocation(FVector::ZeroVector);
		}
	}
#endif

	UFUNCTION(DevFunction)
	void OpenBrain(bool bSnap)
	{
		if (bSnap)
		{
			LeftRoot.SetRelativeRotation(FRotator(0.0, -15.0, 0.0));
			RightRoot.SetRelativeRotation(FRotator(0.0, 15.0, 0.0));
			return;
		}

		BP_OpenBrain();

		UPrisonBossBrainEffectEventHandler::Trigger_OpenBrain(this);
	}

	UFUNCTION(DevFunction)
	void CloseBrain()
	{
		BP_CloseBrain();

		UPrisonBossBrainEffectEventHandler::Trigger_CloseBrain(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenBrain() {}

	UFUNCTION(BlueprintEvent)
	void BP_CloseBrain() {}

	UFUNCTION()
	void LaunchPlayerBackToPlatform()
	{
		FPlayerLaunchToParameters LaunchToParams;
		LaunchToParams.Duration = 2.0;
		LaunchToParams.LaunchToLocation = LaunchBackTarget.ActorLocation;
		LaunchToParams.bRotate = false;
		Game::Mio.LaunchPlayerTo(this, LaunchToParams);
	}

	UFUNCTION(BlueprintPure)
	bool IsMioOnFirstButtonPlatform()
	{
		AHazePlayerCharacter Mio = Game::Mio;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(Mio.ActorCenterLocation, Mio.ActorCenterLocation - (FVector::UpVector * 800.0));
		if (Hit.bBlockingHit)
		{
			APrisonBossBrainPlatform Platform = Cast<APrisonBossBrainPlatform>(Hit.Actor);
			if (Platform != nullptr)
			{
				if (Platform == FirstButtonPlatform)
					return true;
			}
		}
		
		return false;
	}

	UFUNCTION()
	void MagneticBlastTriggered()
	{
		UPrisonBossBrainEffectEventHandler::Trigger_MagneticBlastTriggered(this);
	}
}

UCLASS()
class UPrisonBossBrainEditorComponent : USceneComponent
{
	bool bInitialized = false;

	default bTickInEditor = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Disable ticking the component if it begins play, that means we're in a PIE world
		// so the actor's tick will take care of all the movement.
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Editor::IsPlaying())
			Cast<APrisonBossBrain>(Owner).EditorTick(DeltaSeconds);
	}
#endif
};