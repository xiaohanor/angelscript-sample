UCLASS(Abstract)
class ASanctuaryAntiGravityAffectedObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	float BreakVelocity = -4.0;

	UPROPERTY()
	bool bBreakable = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	float AntiGravityBobbingForce = 0.0;

	TInstigated<bool> bIsInsideAntiGravity;
	bool bWasInsideAntiGravity = false;
	float HeightAlpha = 1.0;

	float LastProgress = 0.0;
	FHazeAcceleratedFloat AccProgresss;
	FVector OGLocation;
	FQuat OGRotation;

	FVector FloatLocation;
	FQuat FloatRotation;

	float LastFrameVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGLocation = Mesh.WorldLocation;
		OGRotation = Mesh.WorldRotation.Quaternion();

		FloatLocation = OGLocation;
		FloatLocation.Z += 400.0;

		FloatRotation = FQuat(FVector::UpVector, Math::RandRange(-180.0, 180.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsInsideAntiGravity.Get())
		{
			if (!bWasInsideAntiGravity)
			{
				HeightAlpha = Math::RandRange(0.5, 1.5);
			}

			const float BobbAffection = Math::SinusoidalInOut(0.0, 0.05, AntiGravityBobbingForce);
			// Debug::DrawDebugString(Mesh.WorldLocation, "" + AntiGravityBobbingForce);
			AccProgresss.SpringTo(HeightAlpha + BobbAffection, 10.0, 0.5, DeltaSeconds);

			bWasInsideAntiGravity = true;
		}
		else
		{
			AccProgresss.ThrustTo(0.0, 9.8, DeltaSeconds, 980.0);
			bWasInsideAntiGravity = false;

			if(Math::IsNearlyEqual(AccProgresss.Value, 0.0))
			{
				if (LastFrameVelocity <= BreakVelocity)
					BP_Landed(LastFrameVelocity);
			}

			LastFrameVelocity = AccProgresss.Velocity;
		}
		
		if (!Math::IsNearlyEqual(LastProgress, AccProgresss.Value))
		{
			Mesh.SetWorldLocation(Math::Lerp(OGLocation, FloatLocation, AccProgresss.Value));
			Mesh.SetWorldRotation(FQuat::Slerp_NotNormalized(OGRotation, FloatRotation, AccProgresss.Value));
			LastProgress = AccProgresss.Value;
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Landed(float ImpactStrength){}
};