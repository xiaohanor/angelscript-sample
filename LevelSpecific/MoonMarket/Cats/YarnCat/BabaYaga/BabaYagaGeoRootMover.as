event void OnBabayagaStartStanding();

class ABabaYagaGeoRootMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bAbsoluteRotation = true;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditAnywhere)
	UMaterialInterface UnlitWindowMaterial;
		
	UPROPERTY(EditAnywhere)
	UMaterialInterface LitWindowMaterial;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<AStaticMeshActor> Windows;

	UPROPERTY(EditAnywhere)
	TArray<APointLight> PointLights;

	UPROPERTY(EditAnywhere)
	TArray<AHazeSphere> HazeSpheres;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	ABabaYagaLeg Leg;
	ABabaYagaLeg OtherLeg;

	OnBabayagaStartStanding OnStartStanding;
	OnBabayagaStartStanding OnStartStandingInstant;

	bool bIsLerping = false;
	float StartLerpTime;
	float LerpDuration = 1;

	float PointLightIntensity;
	float HazeSphereOpacity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Light : PointLights)
		{
			Light.AddActorDisable(this);
		}

		for(auto HazeSphere : HazeSpheres)
		{
			HazeSphere.AddActorDisable(this);
		}

		for(auto Window : Windows)
		{
			Window.StaticMeshComponent.SetMaterial(1, UnlitWindowMaterial);
		}

		PointLightIntensity = PointLights[0].PointLightComponent.Intensity;
		HazeSphereOpacity = HazeSpheres[0].HazeSphereComponent.Opacity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsLerping)
			return;

		float Alpha = Time::GetGameTimeSince(StartLerpTime);
		if(Alpha >= 1)
		{
			Alpha = 1;
			bIsLerping = false;
		}

		for(auto Light : PointLights)
		{
			Light.RemoveActorDisable(this);
			Light.LightComponent.SetIntensity(Alpha * PointLightIntensity);
		}

		for(auto HazeSphere : HazeSpheres)
		{
			HazeSphere.RemoveActorDisable(this);
			HazeSphere.HazeSphereComponent.SetOpacityValue(Alpha * HazeSphereOpacity);
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void WakeUpInstant()
	{
		LightUp();
		Leg.StandInstant();
		OtherLeg.StandInstant();
		
		OnStartStandingInstant.Broadcast();
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void LightUp()
	{
		bIsLerping = true;
		StartLerpTime = Time::GameTimeSeconds;

		for(auto Light : PointLights)
		{
			Light.RemoveActorDisable(this);
			Light.LightComponent.SetIntensity(0);
		}

		for(auto HazeSphere : HazeSpheres)
		{
			HazeSphere.RemoveActorDisable(this);
			HazeSphere.HazeSphereComponent.SetOpacityValue(0);
		}

		for(auto Window : Windows)
		{
			Window.StaticMeshComponent.SetMaterial(1, LitWindowMaterial);
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void RepopulateArrays()
	{
		Windows.Empty();
		PointLights.Empty();

		TArray<AActor> Children;
		GetAttachedActors(Children, true, true);

		for(auto Child : Children)
		{
			if(Child.ActorNameOrLabel.Find("Window") != -1)
			{
				Windows.Add(Cast<AStaticMeshActor>(Child));
			}
			else
			{
				APointLight Light = Cast<APointLight>(Child);
				if(Light != nullptr)
				{
					PointLights.Add(Light);
				}

				AHazeSphere HazeSphere = Cast<AHazeSphere>(Child);
				if(HazeSphere != nullptr)
				{
					HazeSpheres.Add(HazeSphere);
				}
			}
		}
	}
#endif
};