event void FOnBattlefieldBarrelGrindStart();
event void FOnBattlefieldBarrelGrindStop();

class ABattlefieldCannonBarrelGrindManager : AHazeActor
{
	UPROPERTY()
	FOnBattlefieldBarrelGrindStart OnBattlefieldBarrelGrindStart;

	UPROPERTY()
	FOnBattlefieldBarrelGrindStop OnBattlefieldBarrelGrindStop;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor	 Spline1;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor SplineCamera;

	TPerPlayer<bool> bHaveTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// auto GrindComp1 = UBattlefieldHoverboardGrindSplineComponent::Get(Spline1);

		// GrindComp1.OnPlayerStartedGrapplingToGrind.AddUFunction(this, n"OnPlayerStartedGrapplingToGrind");
		// GrindComp1.OnPlayerStoppedGrinding.AddUFunction(this, n"OnPlayerStoppedGrinding");
		// GrindComp1.OnPlayerStartedGrinding.AddUFunction(this, n"OnPlayerStartedGrinding");
	}
	
	UFUNCTION()
	private void OnPlayerStartedGrinding(UBattlefieldHoverboardGrindSplineComponent Comp, AHazePlayerCharacter Player)
	{
		if (bHaveTriggered[Player])
			return;

		bHaveTriggered[Player] = true;
		Player.ActivateCamera(SplineCamera, 1.5, this, EHazeCameraPriority::High);
	}

	UFUNCTION()
	private void OnPlayerStartedGrapplingToGrind(UBattlefieldHoverboardGrindSplineComponent Comp, AHazePlayerCharacter Player)
	{
		if (bHaveTriggered[Player])
			return;
		
		bHaveTriggered[Player] = true;
		Player.ActivateCamera(SplineCamera, 1.5, this, EHazeCameraPriority::High);
	}

	UFUNCTION()
	private void OnPlayerStoppedGrinding(UBattlefieldHoverboardGrindSplineComponent Comp, AHazePlayerCharacter Player)
	{
		bHaveTriggered[Player] = false;
		Player.DeactivateCameraByInstigator(this, 1.5);
	}
};