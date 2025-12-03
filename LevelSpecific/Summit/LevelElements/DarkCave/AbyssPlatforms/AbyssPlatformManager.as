class AAbyssPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
	default VisualComp.SpriteName = "S_NavP"; 
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;
	default ArrowComp.ArrowSize = 20.0;
	default ArrowComp.RelativeRotation = FRotator(-90, 0, 0);

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorActor AcidStatue;

	UPROPERTY(EditInstanceOnly)
	float ShakeBufferTime = 2.0;

	// UPROPERTY(EditInstanceOnly)
	// int Rows = 1;

	TArray<AAbyssPlatform> AbyssPath;

	float TimeStarted;

	bool bHaveStartedShaking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		AbyssPath.Empty();
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Attached : AttachedActors)
		{
			AAbyssPlatform Path = Cast<AAbyssPlatform>(Attached);
			if (Path == nullptr)
				continue;
			AbyssPath.AddUnique(Path);
		}	

		float ZOffset = 300.0;
		float YOffset = 300.0;

		int ColumnIndex = 0;
		int RowIndex = 0;

		for (int i = 0; i < AbyssPath.Num(); i++)
		{
			FVector NewPoint = ArrowComp.WorldLocation + -FVector::UpVector * RowIndex * ZOffset;
			NewPoint += AcidStatue.ActorRightVector * (ColumnIndex - 1) * YOffset;
			AbyssPath[i].IniateStartTransform(ActorLocation, NewPoint, ArrowComp.WorldRotation.Quaternion());
			ColumnIndex++;
			if (ColumnIndex > 2)
			{
				ColumnIndex = 0;
				RowIndex++;
			}
		}

		AcidStatue.OnAcidActorActivated.AddUFunction(this, n"OnCraftTempleAcidStatueActivated");
		AcidStatue.OnAcidActorDeactivated.AddUFunction(this, n"OnCraftTempleAcidStatueDeactivated");
		// AcidStatue.OnCraftTempleAcidStatueAlmostFinished.AddUFunction(this, n"OnCraftTempleAcidStatueAlmostFinished");
	}

	// void AddPlatformReference(AAbyssPlatform NewPath)
	// {
	// 	AbyssPath.AddUnique(NewPath);
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if (Time::GameTimeSeconds > TimeStarted + (AcidStatue.ActivateDuration - ShakeBufferTime) && !bHaveStartedShaking)
		float TimePassed = AcidStatue.GetAlphaProgress() * AcidStatue.ActivateDuration;
		float BufferTime = AcidStatue.ActivateDuration - ShakeBufferTime;

		if ((AcidStatue.GetAlphaProgress() * AcidStatue.ActivateDuration) > (AcidStatue.ActivateDuration - ShakeBufferTime) && !bHaveStartedShaking)
		{
			bHaveStartedShaking = true;

			for (AAbyssPlatform Platform : AbyssPath)
			{
				Platform.StartShake();
			}
		}
		else if (bHaveStartedShaking && TimePassed < BufferTime)
		{
			bHaveStartedShaking = false;
			
			for (AAbyssPlatform Platform : AbyssPath)
			{
				Platform.ResetShake();
			}
		}
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueActivated()
	{
		for (AAbyssPlatform Platform : AbyssPath)
		{
			Platform.ActivatePlatform();
		}

		TimeStarted = Time::GameTimeSeconds;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueDeactivated()
	{
		for (AAbyssPlatform Platform : AbyssPath)
		{
			Platform.StopShake();
			Platform.DeactivatePlatform();
		}

		bHaveStartedShaking = false;
		SetActorTickEnabled(false);
	}

};