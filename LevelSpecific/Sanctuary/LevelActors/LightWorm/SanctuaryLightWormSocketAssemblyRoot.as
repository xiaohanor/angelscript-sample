event void FSanctuaryAssemblySocketSignature();

class ASanctuaryLightWormSocketAssemblyRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	ULightBirdTargetComponent LightBirdTargetComponent;

	UPROPERTY(EditAnywhere)
	float DisassembleRange = 450.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SocketVFXComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bExclusiveAttachedIllumination = true;

	UPROPERTY()
	FSanctuaryAssemblySocketSignature OnActivated;

	UPROPERTY()
	FHazeTimeLike AssembleTimeLike;
	default AssembleTimeLike.UseSmoothCurveZeroToOne();
	default AssembleTimeLike.Duration = 2.3;

	TArray<ASanctuaryLightWormSocketAssemblyPart> AssembleParts;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY()
	FHazeTimeLike IlluminateTimeLike;
	default IlluminateTimeLike.UseLinearCurveZeroToOne();
	default IlluminateTimeLike.Duration = 0.5;

	UPROPERTY(EditAnywhere)
	float IdleRotationSpeed = 30.0;

	UPROPERTY(EditAnywhere)
	float ActiveRotationSpeed = 180.0;
	
	FHazeAcceleratedFloat AccRotationSpeed;

	UPROPERTY(EditAnywhere)
	float TransitionSpeed = 0.2;

	bool bAssembled = false;
	float AssembleAlpha = 0.0;

	bool bSentActivation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		AssembleTimeLike.BindUpdate(this, n"AssembleTimeLikeUpdate");
		AssembleTimeLike.BindFinished(this, n"AssembleTimeLikeFinished");
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnIlluminated");

		IlluminateTimeLike.BindUpdate(this, n"IlluminateTimeLikeUpdate");
		IlluminateTimeLike.BindFinished(this, n"IlluminateTimeLikeFinished");

		LightBirdTargetComponent.Disable(this);

		AssembleParts = GetParts();
		SetupParts();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAssembled)
		{
			AccRotationSpeed.AccelerateTo((LightBirdResponseComp.IsIlluminated() ? 1.0 : 0.0), TransitionSpeed, DeltaSeconds);
			float RotationSpeed = Math::Lerp(IdleRotationSpeed, ActiveRotationSpeed, AccRotationSpeed.Value);

			RotationPivot1.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0));
			RotationPivot2.AddLocalRotation(FRotator(0.0, 0.0, -RotationSpeed * DeltaSeconds));
		}

		if (AssembleAlpha > SMALL_NUMBER)
		{
			for (auto Part : AssembleParts)
			{
				FVector AssembledLocation = Part.AttachComp.WorldTransform.TransformPositionNoScale(Part.AssembledTransform.Location);
				FVector Location = Math::Lerp(
					Part.DisassembledTransform.Location, 
					AssembledLocation, 
					AssembleAlpha);

				FQuat AssembledRotation = Part.AttachComp.WorldTransform.TransformRotation(Part.AssembledTransform.Rotation);
				FRotator Rotation = Math::LerpShortestPath(
					Part.DisassembledTransform.Rotation.Rotator(), 
					AssembledRotation.Rotator(), 
					AssembleAlpha);

				Part.SetActorLocationAndRotation(Location, Rotation);
			}
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		IlluminateTimeLike.Play();
	}

	UFUNCTION()
	private void HandleUnIlluminated()
	{
		IlluminateTimeLike.Reverse();
	}

	UFUNCTION()
	private void IlluminateTimeLikeUpdate(float CurrentValue)
	{
		HazeSphereComp.SetTemperature(CurrentValue, 0.0, CurrentValue * 30000.0);
	}

	UFUNCTION()
	private void IlluminateTimeLikeFinished()
	{
		if (!IlluminateTimeLike.IsReversed() && HasControl() && !bSentActivation)
		{
			bSentActivation = true;
			CrumbIlluminateTimeLikeFinished();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbIlluminateTimeLikeFinished()
	{
		OnActivated.Broadcast();
	}

	UFUNCTION()
	private void HandlePartGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		AssembleTimeLike.PlayRate = 1.0;
		AssembleTimeLike.Play();
	}

	UFUNCTION()
	private void HandlePartReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		AssembleTimeLike.PlayRate = 0.4;
		AssembleTimeLike.Reverse();
		IlluminateTimeLike.Reverse();
		LightBirdTargetComponent.Disable(this);
		SocketVFXComp.Deactivate();
		bAssembled = false;
	}
	
	UFUNCTION()
	private void AssembleTimeLikeUpdate(float CurrentValue)
	{
		AssembleAlpha = CurrentValue;
	}

	UFUNCTION()
	private void AssembleTimeLikeFinished()
	{
		if (!AssembleTimeLike.IsReversed() && HasControl())
		{
			CrumbRemoteAssembleFinished();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemoteAssembleFinished()
	{
		AssembleAlpha = 1.0;
		BP_Assembled();
		LightBirdTargetComponent.Enable(this);
		SocketVFXComp.Activate();
		bAssembled = true;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Assembled(){}

	UFUNCTION()
	TArray<ASanctuaryLightWormSocketAssemblyPart> GetParts()
	{
		TArray<ASanctuaryLightWormSocketAssemblyPart> Parts;

		TArray<AActor> Actors;
		GetAttachedActors(Actors, true);
		for (AActor Actor : Actors)
		{
			ASanctuaryLightWormSocketAssemblyPart Part = Cast<ASanctuaryLightWormSocketAssemblyPart>(Actor);
			if (Part != nullptr)
				Parts.Add(Part);
		}

		return Parts;
	}

	UFUNCTION()
	private void SetupParts()
	{
		for (auto Part : GetParts())
		{

			Part.AttachComp = Part.bInnerCircle ? RotationPivot2 : RotationPivot1;

			FVector AssembledLocation = Part.AttachComp.WorldTransform.InverseTransformPositionNoScale(Part.ActorLocation);
			FRotator AssembledRotation = Part.AttachComp.WorldTransform.InverseTransformRotation(Part.ActorRotation);
			FTransform AssembledTransform;
			AssembledTransform.Location = AssembledLocation;
			AssembledTransform.Rotation = AssembledRotation.Quaternion();
			Part.AssembledTransform = AssembledTransform;

			Part.DisassembledTransform.Location = ActorLocation + Math::GetRandomPointOnSphere() * DisassembleRange + FVector::UpVector * 200.0;
			Part.DisassembledTransform.Rotation = Math::GetRandomRotation().Quaternion();

			Part.SetActorLocationAndRotation(Part.DisassembledTransform.Location,
											Part.DisassembledTransform.Rotation);

			for (int i = 0; i < 3; i++)
			{
				FSanctuaryFloatingData FloatingData;
				FloatingData.bRotation = true;
				FloatingData.Axis = FVector(Math::RandRange(0.0, 20.0), Math::RandRange(0.0, 20.0), Math::RandRange(0.0, 20.0));
				FloatingData.Rate = Math::RandRange(0.1, 1.0);
				FloatingData.Offset = Math::RandRange(0.0, 3.0);
				Part.FloatingComp.FloatingData.Add(FloatingData);
			}

			FSanctuaryFloatingData FloatingData;
			FloatingData.bRotation = false;
			FloatingData.Axis = FVector(0.0, 0.0, Math::RandRange(20.0, 40.0));
			FloatingData.Rate = Math::RandRange(0.5, 0.7);
			FloatingData.Offset = Math::RandRange(0.0, 3.0);
			Part.FloatingComp.FloatingData.Add(FloatingData);


			Part.DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandlePartGrabbed");
			Part.DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandlePartReleased");
		}
	}
};