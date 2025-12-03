class ASkylineGravityBillboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComponent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider0;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider1;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider2;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider3;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider4;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider5;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider6;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider7;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider8;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider9;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider10;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collider11;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerTrigger;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
	#endif

	TArray<UStaticMeshComponent> Colliders;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh Mesh;

	UPROPERTY(EditDefaultsOnly)
	float AngleX = 0.5;
	UPROPERTY(EditDefaultsOnly)
	float AngleY = 1.0;
	UPROPERTY(EditDefaultsOnly)
	float Wavelength = 1000.0;
	UPROPERTY(EditDefaultsOnly)
	float Amplitude = 200.0;
	UPROPERTY(EditDefaultsOnly)
	float Offset = 0.0;

	UPROPERTY(EditDefaultsOnly)
	float MoveSpeed = 1.0;

	//UPROPERTY(EditDefaultsOnly)
	//float Width = 2000.0;

	UPROPERTY(EditDefaultsOnly)
	bool bShowCollision = false;
	
	// ray-box intersection function, used to decide the width of the boxes.
	// It's not 100% correct.. does unreal have lib functions for this?
	FVector2D RayBoxIntersect2D(FVector2D RayStart, FVector2D RayDirection, FVector2D BoxPosition, FVector2D BoxSize)
	{
		FVector2D BoxSizeHalf = BoxSize / 2;
		FVector2D p = RayStart - BoxPosition;

		if(RayDirection.X == 0)
		{
			float TopDistance 		= ( BoxSizeHalf.Y - p.Y) / RayDirection.Y;
			float BottomDistance 	= (-BoxSizeHalf.Y - p.Y) / RayDirection.Y;
			float maxy = Math::Max(BottomDistance, TopDistance);
			float miny = Math::Min(BottomDistance, TopDistance);
			return FVector2D(maxy, miny);
		}

		if(RayDirection.Y == 0)
		{
			float LeftDistance 		= (-BoxSizeHalf.X - p.X) / RayDirection.X;
			float RightDistance 	= ( BoxSizeHalf.X - p.X) / RayDirection.X;
			float maxx = Math::Max(LeftDistance, RightDistance);
			float minx = Math::Min(LeftDistance, RightDistance);
			return FVector2D(maxx, minx);
		}

		float LeftDistance 		= (-BoxSizeHalf.X - p.X) / RayDirection.X;
		float RightDistance 	= ( BoxSizeHalf.X - p.X) / RayDirection.X;
		float TopDistance 		= ( BoxSizeHalf.Y - p.Y) / RayDirection.Y;
		float BottomDistance 	= (-BoxSizeHalf.Y - p.Y) / RayDirection.Y;

		float maxx = Math::Max(LeftDistance, RightDistance);
		float minx = Math::Min(LeftDistance, RightDistance);
		float maxy = Math::Max(BottomDistance, TopDistance);
		float miny = Math::Min(BottomDistance, TopDistance);
		float ClosestDistance = Math::Max(minx, miny);
		float FurthestDistance = Math::Min(maxx, maxy);

		if (minx > maxy || miny > maxx)
		{
			return FVector2D(0, 0);
		}
		return FVector2D(ClosestDistance, FurthestDistance);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComponent.SetStaticMesh(Mesh);
		PlayerTrigger.SetBoxExtent(MeshComponent.GetBoundsExtent());
		
		Colliders.Empty();
		Colliders.Add(Collider0);
		Colliders.Add(Collider1);
		Colliders.Add(Collider2);
		Colliders.Add(Collider3);
		Colliders.Add(Collider4);
		Colliders.Add(Collider5);
		Colliders.Add(Collider6);
		Colliders.Add(Collider7);
		Colliders.Add(Collider8);
		Colliders.Add(Collider9);
		Colliders.Add(Collider10);
		Colliders.Add(Collider11);
		

		SetColliderTransforms(Offset);
		for (int i = 0; i < Colliders.Num(); i++)
		{
			Colliders[i].SetHiddenInGame(!bShowCollision);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Colliders.Empty();
		Colliders.Add(Collider0);
		Colliders.Add(Collider1);
		Colliders.Add(Collider2);
		Colliders.Add(Collider3);
		Colliders.Add(Collider4);
		Colliders.Add(Collider5);
		Colliders.Add(Collider6);
		Colliders.Add(Collider7);
		Colliders.Add(Collider8);
		Colliders.Add(Collider9);
		Colliders.Add(Collider10);
		Colliders.Add(Collider11);
		
		for (int i = 0; i < Colliders.Num(); i++)
		{
			Colliders[i].SetHiddenInGame(!bShowCollision);
			Colliders[i].SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		
		if (PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnter");
			PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerLeave");
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Time = MoveSpeed * Time::GameTimeSeconds + Offset;
		SetColliderTransforms(Time);
	}

	UFUNCTION()
	private void OnPlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		for (int i = 0; i < Colliders.Num(); i++)
		{
			Colliders[i].SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}
	}
	UFUNCTION()
    private void OnPlayerLeave(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
       		 				UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		for (int i = 0; i < Colliders.Num(); i++)
		{
			Colliders[i].SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}


	void SetColliderTransforms(float Time)
	{
		MeshComponent.SetScalarParameterValueOnMaterials(n"AngleX", AngleX);
		MeshComponent.SetScalarParameterValueOnMaterials(n"AngleY", AngleY);
		MeshComponent.SetScalarParameterValueOnMaterials(n"Wavelength", Wavelength);
		MeshComponent.SetScalarParameterValueOnMaterials(n"Amplitude", Amplitude);
		MeshComponent.SetScalarParameterValueOnMaterials(n"Offset", Time);
		
		for (int i = 0; i < Colliders.Num(); i++)
		{
			FVector Angle = FVector(AngleX, AngleY, 0.0);
			FVector Angle90 = FVector(-AngleY, AngleX, 0.0); // rotate 90 degrees
			Angle.Normalize();
			float correctedWavelength = Wavelength / (3.14152128 * 2.0);

			float XOffset = (i + 3) * Wavelength - Wavelength * (Math::IntegerDivisionTrunc(Colliders.Num(), 2) + 2);
			float LocalOffset = ((Time * correctedWavelength) % Wavelength) + XOffset + 200;

			FVector LocalLocation = -Angle * LocalOffset;

			FVector Min;
			FVector Max;
			MeshComponent.GetLocalBounds(Min, Max);
			FVector2D BoxPosition = (FVector2D(Max.X, Max.Y) + FVector2D(Min.X, Min.Y)) * 0.5;
			FVector2D BoxSize = FVector2D(Max.X, Max.Y) - FVector2D(Min.X, Min.Y);
			
			FVector2D Hit = RayBoxIntersect2D(
				FVector2D(LocalLocation.X, LocalLocation.Y), 
				FVector2D(Angle90.X, Angle90.Y), 
				BoxPosition, 
				BoxSize + FVector2D(Wavelength,Wavelength) * FVector2D(Math::Abs(Angle.X), Math::Abs(Angle.Y)));


			if(Hit.X == 0 && Hit.Y == 0)
			{
				// Error, ray missed, disable this collider
				Colliders[i].SetRelativeScale3D(FVector(1, 1, 1));
				Colliders[i].SetRelativeLocation(FVector(0, 0, 0));
				continue;
			}
			FVector Hit0 = LocalLocation + Angle90 * (Hit.X);
			FVector Hit1 = LocalLocation + Angle90 * (Hit.Y);
			//Debug::DrawDebugPoint(Hit0, 200);
			//Debug::DrawDebugPoint(Hit1, 200);
			LocalLocation = (Hit0 + Hit1)*0.5;
			float nWidth = Hit0.Distance(Hit1);
			
			FVector WorldLocation = ActorTransform.TransformPosition(LocalLocation);
			Colliders[i].SetWorldLocation(WorldLocation + GetActorUpVector() * Amplitude * 0.5);
			Colliders[i].SetRelativeRotation(FRotator::MakeFromYZ(Angle, FVector(0, 0, 1)));
			Colliders[i].SetRelativeScale3D(FVector(nWidth, Wavelength, Amplitude) * 0.01);

		}

	}
};