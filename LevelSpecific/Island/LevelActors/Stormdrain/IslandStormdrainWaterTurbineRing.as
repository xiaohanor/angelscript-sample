enum EIslandStormdrainWaterTurbineType
{
	Thin,
	Thick,
	ThickRotated
}

class AIslandStormdrainWaterTurbineRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingRoot_CenterRotation;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	UStaticMeshComponent RingMesh;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine0;
	default MovingRoot_Turbine0.RelativeLocation = FVector(0, 0, -2000);
	default MovingRoot_Turbine0.RelativeRotation = FRotator(0,0,0);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine0)
	UStaticMeshComponent Turbine0;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine1;
	default MovingRoot_Turbine1.RelativeLocation = FVector(0, 1414, -1414);
	default MovingRoot_Turbine1.RelativeRotation = FRotator(0,0,-45);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine1)
	UStaticMeshComponent Turbine1;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine2;
	default MovingRoot_Turbine2.RelativeLocation = FVector(0, 2000, 0);
	default MovingRoot_Turbine2.RelativeRotation = FRotator(0,0,-90);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine2)
	UStaticMeshComponent Turbine2;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine3;
	default MovingRoot_Turbine3.RelativeLocation = FVector(0, 1414, 1414);
	default MovingRoot_Turbine3.RelativeRotation = FRotator(0,0,-135);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine3)
	UStaticMeshComponent Turbine3;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine4;
	default MovingRoot_Turbine4.RelativeLocation = FVector(0, 0, 2000);
	default MovingRoot_Turbine4.RelativeRotation = FRotator(0,0,180);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine4)
	UStaticMeshComponent Turbine4;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine5;
	default MovingRoot_Turbine5.RelativeLocation = FVector(0, -1414, 1414);
	default MovingRoot_Turbine5.RelativeRotation = FRotator(0,0,135);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine5)
	UStaticMeshComponent Turbine5;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine6;
	default MovingRoot_Turbine6.RelativeLocation = FVector(0, -2000, 0);
	default MovingRoot_Turbine6.RelativeRotation = FRotator(0,0,90);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine6)
	UStaticMeshComponent Turbine6;

	UPROPERTY(DefaultComponent, Attach = MovingRoot_CenterRotation)
	USceneComponent MovingRoot_Turbine7;
	default MovingRoot_Turbine7.RelativeLocation = FVector(0, -1414, -1414);
	default MovingRoot_Turbine7.RelativeRotation = FRotator(0,0,45);

	UPROPERTY(DefaultComponent, Attach = MovingRoot_Turbine7)
	UStaticMeshComponent Turbine7;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 24000;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;

	TArray<UStaticMeshComponent> TurbinesDir;
	TArray<UStaticMeshComponent> TurbinesOtherDir;

	UPROPERTY()
	UStaticMesh ThinMesh;

	UPROPERTY()
	UStaticMesh ThinMeshWithHoles;

	UPROPERTY()
	UStaticMesh ThinRing;

	UPROPERTY()
	UStaticMesh ThickMesh;

	UPROPERTY()
	UStaticMesh ThickRing;

	UPROPERTY()
	UStaticMesh ThickMeshWithHoles;

	UPROPERTY(EditAnywhere, EditFixedSize)
	TArray<bool> MeshWithHoles;
	default MeshWithHoles.SetNum(8);

	UPROPERTY(EditAnywhere, EditFixedSize)
	TArray<float> RotationOffsets;
	default RotationOffsets.SetNum(8);

	UPROPERTY()
	TArray<UStaticMeshComponent> Turbines;
	TArray<FVector> TurbineRelativeLocations;
	
	UPROPERTY(EditInstanceOnly)
	EIslandStormdrainWaterTurbineType Thickness;

	UPROPERTY(EditInstanceOnly)
	float RingSpeed = 5;

	UPROPERTY(EditInstanceOnly)
	float TurbineSpeed = 25;

	bool bAppliedDisableComp = false;

	UPROPERTY(EditAnywhere)
	FRotator TurbineStartRotation;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Turbines.Empty();
		Turbines.AddUnique(Turbine0);
		Turbines.AddUnique(Turbine1);
		Turbines.AddUnique(Turbine2);
		Turbines.AddUnique(Turbine3);
		Turbines.AddUnique(Turbine4);
		Turbines.AddUnique(Turbine5);
		Turbines.AddUnique(Turbine6);
		Turbines.AddUnique(Turbine7);

		switch(Thickness)
		{
			case EIslandStormdrainWaterTurbineType::Thin:
				for(int i = 0; i < 8; ++i)
				{
					if(MeshWithHoles[i] == true)
					{
						Turbines[i].SetStaticMesh(ThinMeshWithHoles);
					}
					else
					{
						Turbines[i].SetStaticMesh(ThinMesh);
					}
					Turbines[i].SetRelativeRotation(FRotator(0, 0, 0));
				}
				RingMesh.SetStaticMesh(ThinRing);
				break;

			case EIslandStormdrainWaterTurbineType::Thick:
				for(int i = 0; i<8; i++)
				{
					if(MeshWithHoles[i] == true)
					{
						Turbines[i].SetStaticMesh(ThickMeshWithHoles);
					}
					else
					{
						Turbines[i].SetStaticMesh(ThickMesh);
					}
					Turbines[i].SetRelativeRotation(FRotator(0, 0, 0));
				}
				RingMesh.SetStaticMesh(ThickRing);
				break;

			case EIslandStormdrainWaterTurbineType::ThickRotated:
				for(int i = 0; i<8; i++)
				{
					if(MeshWithHoles[i] == true)
					{
						Turbines[i].SetStaticMesh(ThickMeshWithHoles);
					}
					else
					{
						Turbines[i].SetStaticMesh(ThickMesh);
					}
					Turbines[i].SetRelativeRotation(FRotator(0, 90, 0));
				}
				RingMesh.SetStaticMesh(ThickRing);
				break;
		}

		TurbinesDir.Add(Turbine0);
		TurbinesOtherDir.Add(Turbine1);
		TurbinesDir.Add(Turbine2);
		TurbinesOtherDir.Add(Turbine3);
		TurbinesDir.Add(Turbine4);
		TurbinesOtherDir.Add(Turbine5);
		TurbinesDir.Add(Turbine6);
		TurbinesOtherDir.Add(Turbine7);

		TurbineStartRotation = FRotator(0, 0, Math::RandRange(0, 360));

		for(int i = 0; i<Turbines.Num(); i++)
		{
			if(TurbinesDir.FindIndex(Turbines[i]) != -1)
			{
				if(Thickness == EIslandStormdrainWaterTurbineType::ThickRotated)
				{
					Turbines[i].SetRelativeRotation(FRotator(0,90,RotationOffsets[i]+TurbineStartRotation.Roll));
				}
				else
				{
					Turbines[i].SetRelativeRotation(FRotator(0,0,RotationOffsets[i]+TurbineStartRotation.Roll));
				}
			}
			else
			{
				if(Thickness == EIslandStormdrainWaterTurbineType::ThickRotated)
				{
					Turbines[i].SetRelativeRotation(FRotator(0,90,360-TurbineStartRotation.Roll+RotationOffsets[i]));
				}
				else
				{
					Turbines[i].SetRelativeRotation(FRotator(0,0,360-TurbineStartRotation.Roll+RotationOffsets[i]));
				}
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Turbines.Empty();
		Turbines.AddUnique(Turbine0);
		Turbines.AddUnique(Turbine1);
		Turbines.AddUnique(Turbine2);
		Turbines.AddUnique(Turbine3);
		Turbines.AddUnique(Turbine4);
		Turbines.AddUnique(Turbine5);
		Turbines.AddUnique(Turbine6);
		Turbines.AddUnique(Turbine7);

		TurbinesDir.Empty();
		TurbinesOtherDir.Empty();
		TurbinesDir.Add(Turbine0);
		TurbinesOtherDir.Add(Turbine1);
		TurbinesDir.Add(Turbine2);
		TurbinesOtherDir.Add(Turbine3);
		TurbinesDir.Add(Turbine4);
		TurbinesOtherDir.Add(Turbine5);
		TurbinesDir.Add(Turbine6);
		TurbinesOtherDir.Add(Turbine7);


		// Link together all the turbine rings to disable at the same time
		if (!bAppliedDisableComp)
		{
			bAppliedDisableComp = true;
			for (auto TurbineRing : TListedActors<AIslandStormdrainWaterTurbineRing>())
			{
				if (TurbineRing != this)
					TurbineRing.bAppliedDisableComp = true;
				DisableComp.AutoDisableLinkedActors.Add(TurbineRing);
			}
			DisableComp.SetEnableAutoDisable(true);
		}

		for(int i = 0; i<Turbines.Num(); i++)
		{
			TurbineRelativeLocations.Add(Turbines[i].RelativeLocation);
			FTransform WorldTransform = Turbines[i].WorldTransform;
			Turbines[i].SetAbsolute(true, true, true);
			Turbines[i].SetWorldTransform(WorldTransform);
		}

		UpdateTurbineLocation();
	}

	void UpdateTurbineLocation()
	{
		MovingRoot_CenterRotation.SetRelativeRotation(FRotator(0, 0, 
			Math::Wrap(Time::PredictedGlobalCrumbTrailTime * RingSpeed, 0, 360)));

		float TurbineRoll = TurbineStartRotation.Roll + Time::PredictedGlobalCrumbTrailTime * TurbineSpeed;
		for(int i = 0; i<Turbines.Num(); i++)
		{
			float Offset = 0;

			if(!Math::IsNaN(RotationOffsets[i]))
			{
				Offset = RotationOffsets[i];
			}

			FRotator TurbineRotation;
			if(TurbinesDir.FindIndex(Turbines[i]) != -1)
			{
				if(Thickness == EIslandStormdrainWaterTurbineType::ThickRotated)
				{
					TurbineRotation = FRotator(0,90, TurbineRoll+Offset);
				}
				else
				{
					TurbineRotation = FRotator(0,0,TurbineRoll+Offset);
				}
			}
			else
			{
				if(Thickness == EIslandStormdrainWaterTurbineType::ThickRotated)
				{
					TurbineRotation = FRotator(0,90,360-TurbineRoll+Offset);
				}
				else
				{
					TurbineRotation = FRotator(0,0,360-TurbineRoll+Offset);
				}
			}

			FTransform AttachTransform = Turbines[i].AttachParent.WorldTransform;
			Turbines[i].SetWorldLocationAndRotation(
				AttachTransform.TransformPosition(TurbineRelativeLocations[i]),
				AttachTransform.TransformRotation(TurbineRotation)
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateTurbineLocation();
	}
}