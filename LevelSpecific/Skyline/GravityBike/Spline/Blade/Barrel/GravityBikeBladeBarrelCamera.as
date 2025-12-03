/**
 * Super hacky camera actor to imitate what the camera did before, but just slightly less chaotic
 */
class AGravityBikeBladeBarrelCamera : AStaticCameraActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	UPROPERTY(EditInstanceOnly)
	AGravityBikeBladeBarrel Barrel;

	UPROPERTY(EditInstanceOnly)
	AActor FinalLookAtTarget;

	UPROPERTY(EditInstanceOnly)
	float MoveDuration = 6.0;

	UPROPERTY(EditInstanceOnly)
	FRuntimeFloatCurve FOVCurve;

	private float StartTime = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		const FVector Location =  Spline.Spline.GetWorldLocationAtSplineFraction(0);
		SetActorLocation(Location);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Duration = Time::GetGameTimeSince(StartTime);
		float Alpha = Math::Saturate(Duration / MoveDuration);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);
		FVector Location = Spline.Spline.GetWorldLocationAtSplineFraction(Alpha);

		FRotator Rotation = GetTargetRotation(Alpha, Location);
		Rotation = Math::RInterpTo(ActorRotation, Rotation, DeltaSeconds, GetRotateSpeed());
		SetActorLocationAndRotation(Location, Rotation);

		Camera.FieldOfView = FOVCurve.GetFloatValue(Alpha);
	}

	UFUNCTION(BlueprintCallable)
	void Activate(float BlendDuration = 3)
	{
		auto Player = Game::Mio;
		Player.ActivateCamera(this, BlendDuration, this);
		StartTime = Time::GameTimeSeconds;
		SetActorTickEnabled(true);

		SetActorRotation(GetTargetRotation(0, ActorLocation));
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate(float BlendDuration = 3)
	{
		auto Player = Game::Mio;
		Player.DeactivateCameraCustomBlend(this, GravityBikeBladeBarrelCameraBlend, BlendDuration);
		SetActorTickEnabled(false);
	}

	private FRotator GetTargetRotation(float Alpha, FVector Location) const
	{
		FVector LookAtTarget;
		if(Barrel.bIsDropping)
			LookAtTarget = Math::Lerp(Barrel.ActorLocation, FinalLookAtTarget.ActorLocation, 0.3);
		else
			LookAtTarget = Math::Lerp(Barrel.ActorLocation, FinalLookAtTarget.ActorLocation, Alpha);
		
		return FRotator::MakeFromX(LookAtTarget - Location);
	}

	float GetRotateSpeed() const
	{
		if(Barrel.bIsDropping)
			return 0.5;
		
		return 3;
	}
};