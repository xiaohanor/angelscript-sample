
UCLASS(Abstract)
class AHackableLowGravityDevice : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshSphere;	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereTrigger;	
	UPROPERTY(EditAnywhere)
	UMovementGravitySettings Settings;

	UMaterialInstanceDynamic MID;
	FHazeAcceleratedFloat AcceleratedFloatMID;
	FHazeAcceleratedFloat AcceleratedFloatScale;

	bool bGravityFieldActive = false;
	UPROPERTY(EditAnywhere)
	float Timer = 6.0;
	float TimerTemp = 6.0;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	float SizeTarget = -1;
	float RotationAddtion = 0;
	float MeshScaleTarget = 0;
	UPROPERTY(EditAnywhere)
	float ScaleValue = 5;
	
	bool PartialActivation = false;

	FVector SphereMaskOffset = FVector(0.0, 0.0, 75.0);
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereTrigger.OnComponentBeginOverlap.AddUFunction(this, n"ApplyNewGravity");
		SphereTrigger.OnComponentEndOverlap.AddUFunction(this, n"ClearGravity");

		MID = MeshSphere.CreateDynamicMaterialInstance(0);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PartialActivation)
		{
			if(SizeTarget >= -1)
				SizeTarget -= DeltaSeconds/5;
		}
		PrintToScreen("SizeTarget " + SizeTarget);

		FVector PlayerLocation = Game::GetMio().ActorLocation;
		AcceleratedFloatMID.SpringTo(SizeTarget, 15.0, 0.4, DeltaSeconds);
		MID.SetScalarParameterValue(n"Scale", AcceleratedFloatMID.Value);
		MID.SetVectorParameterValue(n"SphereMaskLocation", FLinearColor(PlayerLocation+SphereMaskOffset));

		AcceleratedFloatScale.SpringTo(MeshScaleTarget, 30.0, 0.8, DeltaSeconds);
		MeshSphere.SetWorldScale3D(FVector(AcceleratedFloatScale.Value, AcceleratedFloatScale.Value, AcceleratedFloatScale.Value));


		RotationAddtion += DeltaSeconds/32.0;
		MID.SetScalarParameterValue(n"GlobalRot", RotationAddtion);
		MID.SetScalarParameterValue(n"RotAngle", RotationAddtion);
	


		if(PartialActivation)
			return;

		if(bGravityFieldActive)
		{
			TimerTemp -= DeltaSeconds;
			if(TimerTemp <= 0)
			{
				DeactivateGravityField();
				bGravityFieldActive = false;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void ApplyNewGravity(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
										UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(bGravityFieldActive == false)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.ApplySettings(Settings, this, EHazeSettingsPriority::Gameplay);
	}

	
	UFUNCTION(NotBlueprintCallable)
	private void ClearGravity(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION()
	void ActivateGravityField()
	{
		TimerTemp = Timer;
		SizeTarget = 1;
		MeshScaleTarget = ScaleValue;

		VFX.SetNiagaraVariableFloat("GlimmerSize", 1.1);
		VFX.SetNiagaraVariableFloat("SphereRadius", 1000.0);

		if(bGravityFieldActive)
			return;

		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player !=nullptr)
			{	
				Player.ApplySettings(Settings, this, EHazeSettingsPriority::Gameplay);
			}
		}

		bGravityFieldActive = true;
	}

	UFUNCTION()
	void ActivateGravityFieldPartial()
	{
		PartialActivation = true;
		TimerTemp = Timer;
		SizeTarget += 0.75;
		MeshScaleTarget = ScaleValue;

		/**
		if(SizeTarget >= -5 && SizeTarget < 1.0)
		{
			SizeTarget += 1.0;
			PrintToScreen("AAAAA", 3.0);
		}
		else if(SizeTarget >= 1.0 && SizeTarget < 2.0)
		{
			SizeTarget += 1.0;
			PrintToScreen("BBBBB", 3.0);
		}
		else if(SizeTarget > 2.0)
		{
			SizeTarget += 0;
			PrintToScreen("CCCCC", 3.0);
		}
		*/


		VFX.SetNiagaraVariableFloat("GlimmerSize", 1.1);
		VFX.SetNiagaraVariableFloat("SphereRadius", 1000.0);

		if(bGravityFieldActive)
			return;

		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player !=nullptr)
			{	
				Player.ApplySettings(Settings, this, EHazeSettingsPriority::Gameplay);
			}
		}

		bGravityFieldActive = true;
	}

	UFUNCTION()
	void DeactivateGravityField()
	{
		MeshScaleTarget = 0;
		PartialActivation = false;
		SizeTarget = -1;
		VFX.SetNiagaraVariableFloat("GlimmerSize", 0.0);
		VFX.SetNiagaraVariableFloat("SphereRadius", 1.0);

		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player !=nullptr)
			{	
				Player.ClearSettingsByInstigator(this);
			}
		}
	}
}
