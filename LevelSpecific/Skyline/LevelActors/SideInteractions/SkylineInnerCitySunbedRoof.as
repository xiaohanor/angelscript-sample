

UCLASS(Abstract)
class USkylineInnerCitySunbedRoofEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStarClosed()
	{
	}


};	
class ASkylineInnerCitySunbedRoof : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BedPivot;

	UPROPERTY(DefaultComponent, Attach = BedPivot)
	UStaticMeshComponent RoofMesh;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor Sunbed;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	bool bIsClosed = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TimeLike;

	UPROPERTY(EditAnywhere)
	APerchPointActor PerchPointActor;

	private bool bTriggeredLateBeginPlay = false;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	// to counter level streaming issues
	private void LateBeginPlay()
	{
		bTriggeredLateBeginPlay = true;
		TimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		TimeLike.BindFinished(this, n"OnTimeLikeFinished");
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleOnGroundImpact");
		RoofMesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", FVector::ZeroVector);
		Sunbed.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", FVector::ZeroVector);
		PerchPointActor.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandelOnPerched");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bTriggeredLateBeginPlay && Sunbed != nullptr)
			LateBeginPlay();
	}

	UFUNCTION()
	private void HandelOnPerched(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchPointActor.DisablePerchPoint(this);
	}

	UFUNCTION()
	private void OnTimeLikeFinished()
	{
		ActivateSunBed();
	}

	void ActivateSunBed()
	{
		BP_LightsOn();
		bIsClosed = true;
		RoofMesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", FVector(2.0, 1.3, 0));
		Sunbed.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", FVector(2.0, 1.3, 0));
	}

	UFUNCTION()
	private void OnTimeLikeUpdate(float CurrentValue)
	{
		BedPivot.RelativeRotation = FRotator(0.0,  0.0, CurrentValue * -45);
	}

	UFUNCTION()
	private void HandleOnGroundImpact(AHazePlayerCharacter Player)
	{
		if (!bIsClosed)
		{
			TimeLike.Play();
			PerchPointActor.DisablePerchPoint(this);
			USkylineInnerCitySunbedRoofEventHandler::Trigger_OnStarClosed(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_LightsOn()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_LightsOff()
	{
	}

	UFUNCTION(BlueprintCallable)
	void OpenSunBed()
	{
		if (bIsClosed)
		{
			TimeLike.Reverse();
			bIsClosed = false;
			BP_LightsOff();
		}
	}
}