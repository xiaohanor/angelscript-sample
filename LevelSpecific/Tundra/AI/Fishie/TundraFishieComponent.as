enum ETundraFishiePatrolDirection
{
	Default, 
	Forward, 
	Backward
}

class UTundraFishieComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Spline")
	ASplineActor PatrolSpline;

	UPROPERTY(EditInstanceOnly, Category = "Spline")
	ETundraFishiePatrolDirection PatrolDirection;

	UPROPERTY(EditInstanceOnly, Category = "Spline")	
	bool bIsChaseFish = false;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> FishEatDeathEffect;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> ChasingCamShake;

	UTundraFishieSettings Settings;

	FSplinePosition LastPatrolPosition;
	float DefaultPatrolPosition = -1.0;

	FVector StartLoc;
	FVector Direction;
	FVector SideDir;
	FVector UpDir;
	FVector LastMoveLocation;	
	bool bIgnoreMovementCollision = false;

	bool bHasHuntingZones = false;
	TArray<AActor> ActiveHuntingZones;

	float LastChaseTime = -BIG_NUMBER;
	float DoneEatingTime = BIG_NUMBER;

	TInstigated<bool> bAgitated;
	default bAgitated.SetDefaultValue(false);
	FHazeAcceleratedFloat AccAgitation;
	UHazeCharacterSkeletalMeshComponent Mesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UTundraFishieSettings::GetSettings(Cast<AHazeActor>(Owner));	
		AccAgitation.SnapTo(1.0);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		for (int i = 0; i < Mesh.GetNumMaterials(); i++)
		{
			UMaterialInstanceDynamic MaterialInstance = Mesh.CreateDynamicMaterialInstance(i);
			Mesh.SetMaterial(i, MaterialInstance);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAgitated.Get())
			AccAgitation.AccelerateTo(Settings.AgitatedEmissiveStrength, Settings.AgitatedEmissiveDuration, DeltaTime);
		else 
			AccAgitation.AccelerateTo(1.0, Settings.CalmdownEmissiveDuration, DeltaTime);		 
		Mesh.SetScalarParameterValueOnMaterials(n"EmissiveStrength", AccAgitation.Value);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			// Ignore elliptical ends, draw as box
			FTransform Transform = Owner.ActorTransform;
			Transform.Location = Owner.ActorLocation;
			FVector Extent = FVector(Settings.ChaseRangeAhead + Settings.ChaseRangeBehind, 20.0, Settings.ChaseRangeAbove + Settings.ChaseRangeBelow) * 0.5;
			FVector Center = Transform.Location + Transform.Rotation.ForwardVector * (Settings.ChaseRangeAhead - Extent.X) + Transform.Rotation.UpVector * (Settings.ChaseRangeAhead - Extent.Z);
			Debug::DrawDebugBox(Center, Extent, Owner.ActorRotation, FLinearColor::Red, 5.0);
		}
#endif
	}

	bool IsNear(FVector Location, float Ahead, float Behind, float Above, float Below) const
	{
		FTransform Transform = Owner.ActorTransform;
		FVector LocalLoc = Transform.InverseTransformPositionNoScale(Location);
		if ((LocalLoc.X > Ahead) || (LocalLoc.X < -Behind) ||
			(LocalLoc.Z > Above) || (LocalLoc.Z < -Below))
			return false; // Outside of encapsulating rectangle

		float Height = (LocalLoc.Z > 0.0) ? Above : Below;
		if (LocalLoc.X > 0.0)
		{
			// Ahead, check if within ellipse quadrant 
			return (Math::Square(LocalLoc.X / Ahead) + Math::Square(LocalLoc.Z / Height) < 1.0);
		} 

		// Behind actor 
		if (Behind < Ahead)
		{
			// Check smaller ellipse quadrant to the rear
			return (Math::Square(LocalLoc.X / Behind) + Math::Square(LocalLoc.Z / Height) < 1.0);
		}

		// When Behind is greater than Ahead we assume that we want a rectangular segment along body 
		// stretching between 0 and (Behind - Ahead) units back along the direction.
		float BodyLength = (Behind - Ahead);
		if (LocalLoc.X < -BodyLength) 
		{
			// Check ellipse with Ahead halfwidth behind body
			return (Math::Square((LocalLoc.X + BodyLength) / Ahead) + Math::Square(LocalLoc.Z / Height) < 1.0);
		}

		// Within rectangular segment alongside body
		return true;
	}

	float GetPlaneHeight(FVector Location)
	{
		return UpDir.DotProduct(Location - StartLoc);		
	}

	void UpdateEating(UBasicAIAnimationComponent AnimComp)
	{
		// Fish should not stop eating animation until some while after behaviour is over
		if (Time::GameTimeSeconds < DoneEatingTime)
			return;

		// Done eating
		DoneEatingTime = BIG_NUMBER;
		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Follow, EBasicBehaviourPriority::Low, this);
	}

	bool CanHunt() const
	{
		if (!bHasHuntingZones)
			return true;
		if (ActiveHuntingZones.Num() > 0)
			return true;
		return false;
	}
}
