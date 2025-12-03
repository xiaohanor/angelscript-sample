struct FMoonMarketWitchOneWaySplineData
{
	ALevitatingWitch Witch;
	float Distance;
	float SplineLength;
	float SpeedMultiplier;
	float SpeedIncreasePerSecond = 0.05;
	UHazeSplineComponent SplineComp;
	bool bDisabledSwing;
	float DropPlayerFromSwingBuffer = 100.0;

	void InitiateWitchTransform()
	{
		Witch.ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Distance);
		Witch.ActorRotation = SplineComp.GetWorldRotationAtSplineDistance(Distance).Rotator();
		ResetSpeedMultiplier();
	}

	void UpdateWitchTransform(float MoveAmount, float DeltaTime, FInstigator Instigator)
	{
		Distance += MoveAmount * SpeedMultiplier;

		//Run check first to drop player. Use move made this frame + a buffer
		if (Distance >= (SplineLength - MoveAmount - DropPlayerFromSwingBuffer) && !bDisabledSwing)
		{
			bDisabledSwing = true;
			Witch.SwingPointComp.Disable(Instigator);
			Witch.FXTrail.Deactivate();
		}

		//Loop back
		if (Distance > SplineLength)
		{
			Distance -= SplineLength;
			ResetSpeedMultiplier();
			Distance *= SpeedMultiplier;

			if (!Witch.bWasEnabled)
			{
				Witch.bWasEnabled = true;
				Witch.SetActorHiddenInGame(false);
				Witch.SwingPointComp.Enable(Instigator);
			}
		}
		
		//Check when to enable swing again
		if (Distance < 100.0 && bDisabledSwing)
		{
			bDisabledSwing = false;
			Witch.SwingPointComp.Enable(Instigator);
			Witch.FXTrail.Activate();
		}
		
		if (Witch.bWasEnabled)
		{
			const FVector Location = SplineComp.GetWorldLocationAtSplineDistance(Distance);
			const FRotator Rotation = SplineComp.GetWorldRotationAtSplineDistance(Distance).Rotator();
			Witch.SetActorLocationAndRotation(Location, Rotation);
		}
		
		SetSpeedMultiplier(DeltaTime);
	}

	void SetSpeedMultiplier(float DeltaTime)
	{
		float LerpSpeed = SpeedIncreasePerSecond;
		float MultTarget = 1;

		if (Witch.bWasEnabled && Distance >= (SplineLength - DropPlayerFromSwingBuffer * 3))
		{
			LerpSpeed = 0.15;
			MultTarget = 0.3;
		}

		SpeedMultiplier = Math::FInterpConstantTo(SpeedMultiplier, MultTarget, DeltaTime, LerpSpeed);
	}

	void ResetSpeedMultiplier()
	{
		SpeedMultiplier = 1;
	}
}

class UWitchSplineRenderComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		OutOrigin = WorldLocation;
		OutBoxExtent = FVector(2000000.0);
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		ALevitatingWitchOneWaySplineManager WitchSplineManager = Cast<ALevitatingWitchOneWaySplineManager>(Owner);

		if (WitchSplineManager == nullptr)
			return;
		
		if (WitchSplineManager.SplineActor == nullptr)
			return;

		FVector ClosestPoint = WitchSplineManager.SplineActor.Spline.GetClosestSplineWorldLocationToWorldLocation(WitchSplineManager.ActorLocation);

		DrawLine(WitchSplineManager.ActorLocation, ClosestPoint, FLinearColor::Purple, 5.0, true);

		float DropDistance = WitchSplineManager.SplineActor.Spline.SplineLength - WitchSplineManager.DropPlayerFromSwingBuffer; 
		FVector DropPoint = WitchSplineManager.SplineActor.Spline.GetWorldLocationAtSplineDistance(DropDistance);

		DrawWireSphere(DropPoint, 50.0, FLinearColor::Red, 2.5);
	}
}

class ALevitatingWitchOneWaySplineManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4));
	default Visual.SpriteName = "S_TriggerSphere";
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp; 

	UPROPERTY(DefaultComponent)
	UWitchSplineRenderComponent RenderComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;
	
	UPROPERTY(EditInstanceOnly)
	bool bStartDeactivated = true;

	UPROPERTY(EditInstanceOnly)
	bool bUseCustomCameras = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = bUseCustomCameras, EditConditionHides))
	ABabaYagaSwingCamera ZoeCam;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = bUseCustomCameras, EditConditionHides))
	ABabaYagaSwingCamera MioCam;
	
	UPROPERTY()
	TSubclassOf<ALevitatingWitch> WitchClass;

	TArray<FMoonMarketWitchOneWaySplineData> DataArray;

	UPROPERTY(EditAnywhere)
	int SpawnNumber = 18;
	float SpawnDistanceInterval = 0.0;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 1200.0;

	UPROPERTY(EditAnywhere)
	float DropPlayerFromSwingBuffer = 150.0;

	int WitchesSpawned = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = SplineActor.Spline;
		SpawnDistanceInterval = SplineComp.SplineLength / SpawnNumber-1;

		MioCam.SetActorControlSide(Game::Mio);
		ZoeCam.SetActorControlSide(Game::Zoe);

		SpawnWitches();

		if (bStartDeactivated)
			DeactivateWitches();

		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (FMoonMarketWitchOneWaySplineData& Data : DataArray)
		{
			Data.UpdateWitchTransform(MoveSpeed * DeltaSeconds, DeltaSeconds, this);
		}
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		ActivateWitches();
	}

	private void SpawnWitches()
	{
		float DistanceAlong = 0;
		while (DistanceAlong <= SplineComp.SplineLength)
		{
			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(DistanceAlong);
			FRotator Rotation = SplineComp.GetWorldRotationAtSplineDistance(DistanceAlong).Rotator();
			ALevitatingWitch Witch = Cast<ALevitatingWitch>(SpawnActor(WitchClass, Location, Rotation, bDeferredSpawn = true)); 
			FMoonMarketWitchOneWaySplineData NewData;
			Witch.SwingPointComp.ActivationRange = 900.0;
			Witch.SwingPointComp.AdditionalVisibleRange = 1200.0;
			Witch.bUseSwing = true;
			Witch.SetActorHiddenInGame(true);
			Witch.SwingPointComp.Disable(this);
			FinishSpawningActor(Witch);

			Witch.MakeNetworked(this, WitchesSpawned);
			WitchesSpawned++;

			if (bUseCustomCameras)
			{
				Witch.SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttachedEvent");
				Witch.SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetachedEvent");
			}
			NewData.Witch = Witch;
			NewData.Distance = DistanceAlong;
			NewData.SplineLength = SplineComp.SplineLength;
			NewData.SplineComp = SplineComp;
			NewData.InitiateWitchTransform();
			NewData.DropPlayerFromSwingBuffer = DropPlayerFromSwingBuffer;
			DataArray.Add(NewData);
			DistanceAlong += SpawnDistanceInterval;
		}
	}

	UFUNCTION(DevFunction)
	void ActivateWitches()
	{
		for (FMoonMarketWitchOneWaySplineData& Data : DataArray)
		{
			Data.Witch.RemoveActorDisable(this);
		}		
		SetActorTickEnabled(true);
	}

	UFUNCTION(DevFunction)
	void DeactivateWitches()
	{
		for (FMoonMarketWitchOneWaySplineData& Data : DataArray)
		{
			Data.Witch.AddActorDisable(this);
		}		
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnPlayerAttachedEvent(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if (Player.IsMio())
			MioCam.ActivateSwingCamera(Player, SwingPoint.Owner);
		else 
			ZoeCam.ActivateSwingCamera(Player, SwingPoint.Owner);
	}

	UFUNCTION()
	private void OnPlayerDetachedEvent(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if (Player.IsMio())
			MioCam.DeactivateSwingCamera(Player);
		else 
			ZoeCam.DeactivateSwingCamera(Player);
	}
};