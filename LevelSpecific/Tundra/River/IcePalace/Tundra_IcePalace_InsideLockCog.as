class ATundra_IcePalace_InsideLockCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DetailMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditInstanceOnly)
	bool bClockwise = false;

	UPROPERTY(EditInstanceOnly)
	bool bMeshVariant = false;

	UPROPERTY()
	TArray<UStaticMesh> Meshes;

	const float MasterCogRadius = 59.5;
	const float CogRadius = 163.5;
	FRotator CogTargetRotation;

	FQuat StartingRotation;
	FQuat TargetInitialRotation;

	UPROPERTY()
	FHazeTimeLike InitialRotationTimelike;
	default InitialRotationTimelike.Duration = 1;

	bool bDoOnce = false;
	bool bShouldTickCog = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRotationTimelike.BindUpdate(this, n"InitialRotationTimelikeUpdate");
	}

	void StartInitialRotation(float MasterCogRotationAmount)
	{
		float InitialRotationAmount = MasterCogRotationAmount * (MasterCogRadius / (CogRadius * ActorScale3D.X));
		if(!bClockwise)
		{
			InitialRotationAmount *= -1;
		}
		TargetInitialRotation = MeshRoot.RelativeRotation.Compose(FRotator(InitialRotationAmount, 0, 0)).Quaternion();
		InitialRotationTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void InitialRotationTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FQuat::Slerp(StartingRotation, TargetInitialRotation, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickCog)
			return;

		MeshRoot.SetRelativeRotation(Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), CogTargetRotation.Quaternion(), DeltaSeconds, 8));
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UStaticMesh MeshToSet = bMeshVariant ? Meshes[0] : Meshes[1];
		Mesh.SetStaticMesh(MeshToSet);
	}

	void GetNewTargetRotation(float RotationTickAmount)
	{
		float NewRotationTickAmount = RotationTickAmount * (MasterCogRadius / (CogRadius * ActorScale3D.X));
		
		if(!bDoOnce)
		{
			CogTargetRotation = TargetInitialRotation.Rotator();
			bDoOnce = true;
			bShouldTickCog = true;
		}
		
		if(bClockwise)
		{
			NewRotationTickAmount *= -1;
		}
		
		CogTargetRotation = CogTargetRotation.Compose(FRotator(NewRotationTickAmount, 0, 0));
	}

	void LeverStopped()
	{
		bShouldTickCog = false;
		bDoOnce = false;
	}
};