class UIslandPunchotronDecalComponent : UDecalComponent
{
	access DebugAccess = private, UIslandPunchotronDevTogglesCapability;

	private bool bIsFading = false;
	private float FadeTime;
	private float FadeTarget = 0.0;
	
	access:DebugAccess
	bool bIsDisabled = true;

	private float DefaultOpacity = 1.0;
	private FHazeAcceleratedFloat AccOpacity;
	private UMaterialInstanceDynamic MaterialInstance;

	private	bool bHasStartedLerp = false;
	private FHazeAcceleratedVector AccLocation;
	private FVector StartLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//CreateDynamicMaterialInstance();
		//UMaterialInterface Material = GetDecalMaterial();
		//MaterialInstance = Cast<UMaterialInstanceDynamic>(Material);
		//check(MaterialInstance != nullptr, "No material set on IslandPunchotronDecalComponent.");

		//DefaultOpacity = MaterialInstance.GetScalarParameterValue(n"Decal_Opacity");
	}

	void Hide()
	{
		SetHiddenInGame(true);
	}

	void Show()
	{
		if (bIsDisabled)
			return;
		SetHiddenInGame(false);
	}

	void FadeIn(float Time = 2.0)
	{
		if (!bIsFading)
		{
			bIsFading = true;
			AccOpacity.SnapTo(0.0);
		}
		FadeTime = Time;
		FadeTarget = DefaultOpacity;
		Show();
	}

	void FadeOut(float Time = 0.5)
	{
		bIsFading = true;
		FadeTime = Time;
		FadeTarget = 0.0;
	}

	void Reset()
	{
		bIsFading = false;
		bHasStartedLerp = false;
		AccOpacity.SnapTo(DefaultOpacity);
		//MaterialInstance.SetScalarParameterValue(n"Decal_Opacity", DefaultOpacity);
	}

	void LerpWorldLocationTo(FVector Target, float DeltaTime, float Time = 1.0)
	{
		if (!bHasStartedLerp)
		{
			bHasStartedLerp = true;
			StartLocation = Owner.ActorLocation + Owner.ActorForwardVector * 200;
			AccLocation.SnapTo(StartLocation);
		}
		
		AccLocation.AccelerateTo(Target, Time, DeltaTime);
		SetWorldLocation(AccLocation.Value);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsDisabled)
			return;

		if (!bIsFading)
			return;

		AccOpacity.AccelerateTo(FadeTarget, FadeTime, DeltaSeconds);
		//MaterialInstance.SetScalarParameterValue(n"Decal_Opacity", AccOpacity.Value);

		if (Math::Abs(AccOpacity.Value - FadeTarget) < SMALL_NUMBER)
		{
			bIsFading = false;
			if (FadeTarget == 0.0)
				Hide();
		}

	}
}