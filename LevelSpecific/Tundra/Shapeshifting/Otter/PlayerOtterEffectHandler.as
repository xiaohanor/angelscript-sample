struct FTundraPlayerOtterTransformParams
{
	UPROPERTY()
	float MorphTime;
}

struct FTundraPlayerOtterOnEnterLaunchSphereEffectParams
{
	UPROPERTY()
	ATundraPlayerOtterWaterLaunchSphere CurrentLaunchSphere;

	UPROPERTY()
	float DurationUntilLaunch;
}

struct FTundraPlayerOtterOnLaunchSphereLaunchEffectParams
{
	UPROPERTY()
	ATundraPlayerOtterWaterLaunchSphere CurrentLaunchSphere;

	UPROPERTY()
	float DurationToSurface;
}

struct FTundraPlayerOtterFootstepParams
{
	UPROPERTY()
	UHazeAudioEvent SurfaceEvent = nullptr;

	UPROPERTY()
	UHazeAudioEvent SurfaceAddEvent = nullptr;

	UPROPERTY()
	float SlopeTilt = 0.0;

	UPROPERTY()
	float Pitch = 0.0;
}

UCLASS(Abstract)
class UTundraPlayerOtterEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraPlayerOtterActor OtterActor;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtterActor = Cast<ATundraPlayerOtterActor>(Owner);
		Player = OtterActor.Player;
	}

    // Called when we transform into the otter
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedInto(FTundraPlayerOtterTransformParams Params) {}

 	// Called when we transform back into human form
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedOutOf(FTundraPlayerOtterTransformParams Params) {}

	// Called when the otter swims near a launch sphere (geyser)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterLaunchSphere(FTundraPlayerOtterOnEnterLaunchSphereEffectParams Params) {}

	// Called when launched by the launch sphere
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchSphereLaunch(FTundraPlayerOtterOnLaunchSphereLaunchEffectParams Params) {}

	// Called when performing underwater sonar blast
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnderwaterSonarBlast() {}

	// Called when otter grabs the cable to move around the floating pole
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterFloatingPoleCableInteract() {}

	// Called when otter lets go of the cable to move around the floating pole
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitFloatingPoleCableInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Plant(FTundraPlayerOtterFootstepParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Release(FTundraPlayerOtterFootstepParams Params) {}

	// Called when otter leaves the water surface and starts swimming underwater. Both when already swimming at the surface and when jumping into the surface
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakWaterSurface() {}
}