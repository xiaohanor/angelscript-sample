class ASanctuaryDarkPortalPullWindow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent StaticMeshComp;

	TArray<UDarkPortalTargetComponent> DarkPortalTargetComps;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	FHazeAcceleratedFloat ShakeBlendIn;

	UPROPERTY(EditAnywhere)
	float GrabTime = 1.0;
	float ThrowTime = 0.0;

	bool bIsThrownSent = false;
	bool bIsThrown = false;
	bool bIsGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(DarkPortalTargetComps);

		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ShakeBlendIn.AccelerateTo((DarkPortalResponseComp.IsGrabbed() ? 1.0 : 0.0), 1.0, DeltaSeconds);

		FVector ShakeLocation = FVector(
			Math::Sin(Time::GameTimeSeconds * 40.0) * 1.0,
			Math::Sin(Time::GameTimeSeconds * 50.0) * 0.5,
			Math::Sin(Time::GameTimeSeconds * 60.0) * 1.0
		);

		FRotator ShakeRotation = FRotator(
			Math::Sin(Time::GameTimeSeconds * 23.0) * 0.5,
			Math::Sin(Time::GameTimeSeconds * 34.0) * 0.3,
			Math::Sin(Time::GameTimeSeconds * 51.0) * 0.4
		);

		if (!bIsThrown)
			StaticMeshComp.SetRelativeLocationAndRotation(
				ShakeLocation * ShakeBlendIn.Value,
				ShakeRotation * ShakeBlendIn.Value
			);

		if (DarkPortalResponseComp.IsGrabbed())
		{
			if (Time::GameTimeSeconds > ThrowTime && !bIsThrownSent && HasControl())
			{
				bIsThrownSent = true;
				CrumbThrowWindow();
			}
		}
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (HasControl())
			CrumbGrabbed();
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (HasControl())
			CrumbReleased();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbThrowWindow()
	{
		bIsThrown = true;

		BP_ThrowWindow();

		for (auto DarkPortalTargetComp : DarkPortalTargetComps)
			DarkPortalTargetComp.Disable(this);

		StaticMeshComp.SetSimulatePhysics(true);
		StaticMeshComp.AddImpulse(ActorForwardVector * -100000.0);
		StaticMeshComp.AddImpulse(ActorUpVector * 100000.0);
		StaticMeshComp.AddImpulseAtLocation((FVector::ForwardVector * -60.0) + (FVector::UpVector * 20.0) + (ActorRightVector * 50.0), ActorUpVector * 100.0);
		
		USanctuaryDarkPortalPullWindowEventHandler::Trigger_OnWindowThrown(this);
		bIsGrabbed = false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbGrabbed()
	{
		ThrowTime = Time::GameTimeSeconds + GrabTime;
		BP_StartPulling();
		if (!bIsGrabbed)
			USanctuaryDarkPortalPullWindowEventHandler::Trigger_OnWindowGrabbed(this);
		bIsGrabbed = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReleased()
	{
		if (bIsGrabbed)
			USanctuaryDarkPortalPullWindowEventHandler::Trigger_OnWindowReleased(this);
		bIsGrabbed = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartPulling() { }

	UFUNCTION(BlueprintEvent)
	void BP_ThrowWindow() { }
};