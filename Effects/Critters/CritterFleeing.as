struct FFleeingCritter
{
	UStaticMeshComponent MeshComp;

	float CurrentFleetime = 0;

	bool bFleeing = false;
	
	float WalkTime = 0;

	FVector FleeOffset;

	float Angle;
}

class ACritterFleeing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 4000.0;
	
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent FleeSpline;

	//UPROPERTY(DefaultComponent)
	//UHazeSplineComponent WalkSpline;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInterface> RandomMaterials;
	
	UPROPERTY(EditAnywhere)
	float FleeTriggerDistance = 500;

	UPROPERTY(EditAnywhere)
	float FleeSpeed = 10;

	UPROPERTY()
	bool bWalkAround = false;

	UPROPERTY()
	bool bAlignWithFleeSpline = false;

	UPROPERTY()
	bool bFleeSpeedIncreasesOverTime = true;

	UPROPERTY()
	float WalkAroundSpeed = 0.1;

	UPROPERTY(EditAnywhere)
	int CritterCount = 4.0f;

	UPROPERTY()
	bool bAnimateWhileFleeing = false;
	
	UPROPERTY()
	bool bAnimateBeforeFleeing = true;

	UPROPERTY()
	bool bBlendToPose2WhenFleeing = true;

	TArray<FFleeingCritter> Critters;

	UPROPERTY()
	float Scale = 0.5;

	UPROPERTY()
	float Radius = 250.0;


    UPROPERTY()
	TArray<UStaticMeshComponent> ConstructionScriptTempMeshes;

	UPROPERTY(EditAnywhere, Category="Audio")
	FSoundDefReference SoundDefRef;


    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(Mesh == nullptr)
			return;
		
		
		Critters = TArray<FFleeingCritter>();
		for (int i = 0; i < CritterCount; i++)
		{
			auto NewMesh = GetOrCreateComponent(UStaticMeshComponent, FName("Critter" + i));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			Critters.Add(FFleeingCritter());
			Critters[i].MeshComp = NewMesh;
			Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
			Critters[i].MeshComp.SetRelativeLocation(Math::GetRandomPointInCircle_XY() * Radius);
			Critters[i].MeshComp.SetRelativeRotation(FRotator(0, Math::RandRange(0,360), 0));
			
			if(RandomMaterials.Num() > 0)
			{
				int index = Math::RandRange(0, RandomMaterials.Num() - 1);
				auto RandomMaterial = RandomMaterials[index];
				Critters[i].MeshComp.SetMaterial(0, RandomMaterial);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Critters = TArray<FFleeingCritter>();
		for (int i = 0; i < CritterCount; i++)
		{
			
			auto NewMesh = GetOrCreateComponent(UStaticMeshComponent, FName("Critter" + i));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			Critters.Add(FFleeingCritter());
			Critters[i].MeshComp = NewMesh;
			Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
			Critters[i].MeshComp.SetRelativeLocation(Math::GetRandomPointInCircle_XY() * Radius);
			Critters[i].MeshComp.SetRelativeRotation(FRotator(0, Math::RandRange(0,360), 0));
			
			if(RandomMaterials.Num() > 0)
			{
				int index = Math::RandRange(0, RandomMaterials.Num() - 1);
				auto RandomMaterial = RandomMaterials[index];
				Critters[i].MeshComp.SetMaterial(0, RandomMaterial);
			}
		}

		if (SoundDefRef.IsValid())
		{
			SoundDefRef.SpawnSoundDefAttached(this);
		}
	}

	UFUNCTION(CallInEditor)
	void FleeAll()
	{
		for (int i = 0; i < CritterCount; i++)
		{
			Flee(i);
		}
	}

	void Flee(int i)
	{
		Critters[i].bFleeing = true;
		FVector StartFleeOffset = Critters[i].MeshComp.GetRelativeLocation();
		Critters[i].MeshComp.SetWorldTransform(FleeSpline.GetWorldTransformAtSplineDistance(0));
		Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
		FVector EndFleeOffset = Critters[i].MeshComp.GetRelativeLocation();
		Critters[i].FleeOffset = StartFleeOffset - EndFleeOffset;
		
		//if(bAnimateWhileFleeing)
		//	Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 80.0 * WalkAroundSpeed);
		//else
		//	Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0; i < CritterCount; i++)
		{
			if(Critters[i].MeshComp == nullptr)
				continue;

			if(!Critters[i].bFleeing)
			{
				for(AHazePlayerCharacter Player : Game::GetPlayers())
				{
					float dist = Critters[i].MeshComp.GetWorldLocation().Distance(Player.GetActorLocation());
					if(dist < FleeTriggerDistance)
					{
						Flee(i);
					}
				}
				
				//if(bWalkAround)
				//{
				//	Critters[i].WalkTime += DeltaTime * WalkAroundSpeed;
				//	Critters[i].WalkTime = Math::Frac(Critters[i].WalkTime);
				//	float WalkTime = Math::Frac(Critters[i].WalkTime + float(i) / float(CritterCount));
				//	Critters[i].MeshComp.SetWorldTransform(WalkSpline.GetWorldTransformAtSplineFraction(WalkTime));
				//	Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
				//}
//
				//Critters[i].Angle = Critters[i].MeshComp.GetWorldRotation().Yaw;
			}
			else
			{
				Critters[i].CurrentFleetime += DeltaTime * FleeSpeed;
				float FleeTimeSquared = Critters[i].CurrentFleetime;
				if(bFleeSpeedIncreasesOverTime)
				{
					FleeTimeSquared = Critters[i].CurrentFleetime * Critters[i].CurrentFleetime;
				}
				Critters[i].MeshComp.SetWorldTransform(FleeSpline.GetWorldTransformAtSplineDistance(FleeTimeSquared));
				Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));

				if(!bAlignWithFleeSpline)
					Critters[i].MeshComp.SetWorldRotation(FRotator(0, Critters[i].Angle, 0));

				Critters[i].MeshComp.AddRelativeLocation(Critters[i].FleeOffset);

				if(FleeTimeSquared > FleeSpline.GetSplineLength())
				{
					Critters[i].MeshComp.DestroyComponent(Critters[i].MeshComp);
				}

				//if(bBlendToPose2WhenFleeing)
				//{
				//	float Blend = Math::Clamp((Critters[i].CurrentFleetime / FleeSpeed) * 8.0, 0.0, 1.0);
				//	Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend2", Blend);
				//}
			}
		}
	}
}