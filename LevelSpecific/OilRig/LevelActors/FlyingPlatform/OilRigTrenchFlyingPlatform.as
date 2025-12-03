class AOilRigTrenchFlyingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Time = Time::GameTimeSeconds;
		float Roll = Math::DegreesToRadians(Math::Sin(Time * 1.2) * 0.5);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time * 0.9) * 0.3);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

		PlatformRoot.SetRelativeRotation(Rotation);

		float VertOffset = Math::Sin(Time * 0.75) * 30.0;
		PlatformRoot.SetRelativeLocation(FVector(0.0, 0.0, VertOffset));
	}
}