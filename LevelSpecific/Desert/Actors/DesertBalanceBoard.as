UCLASS(Abstract)
class ADesertBalanceBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateRollComp;
	UPROPERTY(DefaultComponent, Attach = AxisRotateRollComp)
	UFauxPhysicsAxisRotateComponent AxisRotatePitchComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UDesertSandHeightSampleComponent Corner;
	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UDesertSandHeightSampleComponent Corner1;
	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UDesertSandHeightSampleComponent Corner2;
	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UDesertSandHeightSampleComponent Corner3;
	UPROPERTY(DefaultComponent, Attach = AxisRotatePitchComp)
	UDesertSandHeightSampleComponent Center;

	UPROPERTY(DefaultComponent)
	UDesertSandHeightComponent SandHeightComp;
	default SandHeightComp.LandscapeLevel = ESandSharkLandscapeLevel::Upper;

	UPROPERTY(EditAnywhere)
	ALandscape Landscape;

	UPROPERTY(EditAnywhere)
	bool bSnapToLandscape = true;
	
	UDesertSandHeightSampleComponent PreviousCorner = nullptr;
	float AngleForce=0;
	float Sin;

	float CurrentOffset = 0;
	float OffsetDistance = 100;

	UPROPERTY(EditAnywhere)
	bool bIsRotate = false;

	private TArray<UDesertSandHeightSampleComponent> Corners;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"ImpactPlayer");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"ImpactPlayerEnded");

		GetComponentsByClass(Corners);
	}

	UFUNCTION()
	private void ImpactPlayer(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 70, this);
	}

	UFUNCTION()
	private void ImpactPlayerEnded(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		auto CurrentCorner = GetSampleComponentFurthestSand();

		AxisRotatePitchComp.ApplyForce(CurrentCorner.WorldLocation,CurrentCorner.UpVector * (AngleForce)*-1);
		AxisRotateRollComp.ApplyForce(CurrentCorner.WorldLocation,CurrentCorner.UpVector * (AngleForce)*-1);

		if (CurrentCorner == PreviousCorner)
		{
			AngleForce = Math::FInterpTo(AngleForce,10,DeltaSeconds,0.1);
		}
		else
		{
			AngleForce = 0;
			PreviousCorner = CurrentCorner;
		}

		if(bIsRotate)
			AddActorLocalRotation(FRotator(0,2 * DeltaSeconds,0));
		
		 Sin += (DeltaSeconds*0.5);
		 if(Sin > PI)
		 	Sin = 0;

		 AxisRotatePitchComp.ApplyForce(CurrentCorner.WorldLocation, CurrentCorner.UpVector * FVector(0,0,Math::Sin(Sin)*2));
		 AxisRotateRollComp.ApplyForce(CurrentCorner.WorldLocation, CurrentCorner.UpVector * FVector(0,0,Math::Sin(Sin)*2));
	}

	private UDesertSandHeightSampleComponent GetSampleComponentFurthestSand() const
	{
		float FurthestDistance = -BIG_NUMBER;
		int FurthestIndex = -1;
		for(int i = 0; i < Corners.Num(); i++)
		{
			const float Distance = DistanceToLandscape(Corners[i].WorldLocation);
			if(Distance > FurthestDistance)
			{
				FurthestDistance = Distance;
				FurthestIndex = i;
			}
		}

		return Corners[FurthestIndex];
	}

	private float DistanceToLandscape(FVector Location) const
	{
		return Location.Z - Desert::GetLandscapeHeightByLevel(Location, ESandSharkLandscapeLevel::Upper);
	}

	UFUNCTION(BlueprintCallable)
	void StartRotate()
 	{
		bIsRotate = true;
	}
	UFUNCTION(BlueprintCallable)
	void StopRotate()
 	{
		bIsRotate = false;
	}
};