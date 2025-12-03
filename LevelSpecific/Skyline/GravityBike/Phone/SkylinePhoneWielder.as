class ASkylinePhoneWielder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UHazeCameraComponent Camera;

	FHazeActionQueue FocusActionQueue;

	AHazeActor Phone;

	bool bBlendedIntoCamera = false;

	const float InitialAperture = 300;
	const float TargetAperture = 22;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FocusActionQueue.Initialize(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FocusActionQueue.Update(DeltaSeconds);

		if(bBlendedIntoCamera)
		{
			FCameraFocusSettings FocusSettings = Camera.FocusSettings;

			FocusSettings.FocusMethod = ECameraFocusMethod::Manual;
			FocusSettings.ManualFocusDistance = GetFocusDistanceToPhone();

			Camera.SetFocusSettings(FocusSettings);
		}

		Pivot.RelativeLocation = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 5.0) * 0.1
							   + FVector::RightVector * Math::Sin(Time::GameTimeSeconds * 7.0) * 0.3
							   + FVector::ForwardVector * Math::Sin(Time::GameTimeSeconds * 3.0) * 0.2;

		// FVector ToPhone = (Phone.ActorLocation -FVector::UpVector * 5 -Pivot.WorldLocation).GetSafeNormal();
		// SetActorRotation(FQuat::MakeFromXZ(ToPhone, AttachParentActor.ActorUpVector));
	}

	void StartFocusActionQueue(float CameraBlendTime)
	{
		FocusActionQueue.Empty();

		FocusActionQueue.Event(this, n"OnFocusBlendStarted");

		if(CameraBlendTime > 0)
		{
			FocusActionQueue.Idle(CameraBlendTime);
			FocusActionQueue.Duration(CameraBlendTime, this, n"BlendInFocus");
		}
		else
		{
			FocusActionQueue.Duration(KINDA_SMALL_NUMBER, this, n"BlendInFocus");
		}

		FocusActionQueue.Event(this, n"OnFocusBlendFinished");
	}

	UFUNCTION()
	void OnFocusBlendStarted()
	{
		bBlendedIntoCamera = false;

		FCameraFocusSettings FocusSettings = Camera.FocusSettings;
		FocusSettings.FocusMethod = ECameraFocusMethod::Disable;
		Camera.SetFocusSettings(FocusSettings);
	}

	UFUNCTION()
	void BlendInFocus(float Alpha)
	{
		FCameraFocusSettings FocusSettings = Camera.FocusSettings;

		FocusSettings.FocusMethod = ECameraFocusMethod::Manual;
		FocusSettings.ManualFocusDistance = GetFocusDistanceToPhone();

		Camera.SetFocusSettings(FocusSettings);

		const float Aperture = Math::Lerp(InitialAperture, TargetAperture, Alpha);
		Camera.SetCurrentAperture(Aperture);
	}

	UFUNCTION()
	private void OnFocusBlendFinished()
	{
		bBlendedIntoCamera = true;
	}

	float GetFocusDistanceToPhone() const
	{
		const FPlane PhonePlane = FPlane(Phone.ActorLocation, Camera.ForwardVector);

		const FVector Intersection = Math::RayPlaneIntersection(
			Camera.WorldLocation,
			Camera.ForwardVector,
			PhonePlane
		);

		return Camera.WorldLocation.Distance(Intersection);
	}
};