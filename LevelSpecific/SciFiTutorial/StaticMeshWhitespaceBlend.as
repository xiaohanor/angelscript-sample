enum EAttachedObjectsStart
{
	AfterDelay,
	AfterBlend
}

UCLASS(Abstract, HideCategories = "Materials")
class AStaticMeshWhitespaceBlend : AStaticMeshActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UStaticMeshWhitespaceBlendComponent StaticMeshWhitespaceBlendComponent;
#endif
	//UPROPERTY(DefaultComponent)
	//UHazeLevelSequenceResponseComponent SequenceResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float BorderWidth = 20.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	EAttachedObjectsStart AttachedObjectsStart = EAttachedObjectsStart::AfterDelay;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float DelayTime = 0.5;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float BlendTime = 1.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	FVector BlendDirection = FVector(0, 0, 1);

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bWorldSpace = false;

	UPROPERTY(EditAnywhere, Category = "Blend")
	TArray<AStaticMeshWhitespaceBlend> ChildObjects;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInterface> OverrideMaterials;
	
	UPROPERTY(EditDefaultsOnly)
	TMap<UMaterialInterface, UMaterialInterface> WhitespaceMaterialReplaceMap;

	FVector BlendDirectionInternal;

	UPROPERTY(EditAnywhere)
	float TimeStart = 0;

	UPROPERTY(EditAnywhere)
	float TimeEnd = 0;

	UPROPERTY(EditAnywhere)
	float TimeCurrent = 0;

	UPROPERTY(EditAnywhere, Interp)
	bool bVisible;

	bool bLastVisible;

	UPROPERTY(EditAnywhere)
	bool bStartVisible = true;

	bool bTransistionedIn = true;

	float TimeLast = 0;

	UPROPERTY(EditAnywhere)
	float TransistionStart = MAX_flt;

	UPROPERTY(EditAnywhere)
	float BlendValue = 0;
	UPROPERTY(EditAnywhere)
	float Offset = 0;

	private UMaterialInterface FindReplacementMaterial(UMaterialInterface Original)
	{
		if (Original == nullptr)
			return Original;

		UMaterialInterface Replacement;
		UMaterialInstance Instance = Cast<UMaterialInstance>(Original);
		while (Instance != nullptr)
		{
			if (WhitespaceMaterialReplaceMap.Find(Instance, Replacement))
				return Replacement;
			Instance = Cast<UMaterialInstance>(Instance.Parent);
		}

		if (WhitespaceMaterialReplaceMap.Find(Original.BaseMaterial, Replacement))
			return Replacement;
		
		return nullptr;
	}

	void SetStartTimeRecursively(AStaticMeshWhitespaceBlend Actor)
	{
		if(Actor.AttachParentActor == nullptr || Cast<AStaticMeshWhitespaceBlend>(Actor.AttachParentActor) == nullptr)
		{
			Actor.TimeStart = 0;
		}
		else
		{
			AStaticMeshWhitespaceBlend Parent = Cast<AStaticMeshWhitespaceBlend>(Actor.AttachParentActor);
			Actor.TimeStart = Parent.TimeEnd;
		}

		if(Actor.AttachedObjectsStart == EAttachedObjectsStart::AfterDelay)
			Actor.TimeEnd = Actor.TimeStart + Actor.DelayTime;
		else
			Actor.TimeEnd = Actor.TimeStart + Actor.BlendTime;

		TArray<AActor> Actors;
		Actor.GetAttachedActors(Actors);
		for (int i = 0; i < Actors.Num(); i++)
		{
			AStaticMeshWhitespaceBlend Child = Cast<AStaticMeshWhitespaceBlend>(Actors[i]);
			if(Child == nullptr)
				continue;
			
			ChildObjects.Add(Child);

			SetStartTimeRecursively(Child);
		}
	}

	bool bBlendTimingsFixed = false;

	UFUNCTION()
	void FixBlendTimings()
	{
		ChildObjects.Empty();
		// if this has no parent, it's the root and should set the start/end times of all child objects.
		
		if(AttachParentActor == nullptr || Cast<AStaticMeshWhitespaceBlend>(AttachParentActor) == nullptr)
		{
			SetStartTimeRecursively(this);
		}

		//bVisible = true;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FixBlendTimings();
		Init();
		UpdateEffect(BlendValue, false);
	}
	
	void Init()
	{
		if(bWorldSpace)
			BlendDirectionInternal = BlendDirection;
		else
			BlendDirectionInternal = StaticMeshComponent.WorldTransform.TransformVector(BlendDirection);
		BlendDirectionInternal.Normalize();
		BlendDirectionInternal *= 0.8;

		bTransistionedIn = !bStartVisible;

		// rebase materials
		for (int i = 0; i < StaticMeshComponent.Materials.Num(); i++)
		{
			UMaterialInterface SourceMaterial = StaticMeshComponent.Materials[i];
			if(OverrideMaterials.Num() > i && OverrideMaterials[i] != nullptr)
			 	SourceMaterial = OverrideMaterials[i];

			UMaterialInterface NewBaseMaterial = FindReplacementMaterial(SourceMaterial);
			if (NewBaseMaterial == nullptr)
				continue;

			StaticMeshComponent.SetMaterial(i, Rendering::CreateRebasedDynamicMaterialInstance(SourceMaterial, NewBaseMaterial));
		}

		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Blend", bVisible ? 0 : 1);
		StaticMeshComponent.SetVectorParameterValueOnMaterials(n"Glitch_BlendDirection", BlendDirection);

		//float DownDistance = 1000;
		//FVector Origin;
		//FVector BoxExtent;
		//this.GetActorBounds(false, Origin, BoxExtent);
		//float PlayerRadius = BoxExtent.Size();
		//FVector Center = Origin - FVector(0, 0, DownDistance);
		//float Radius = (DownDistance - PlayerRadius) + (1.0 - (bVisible ? 0 : 1)) * PlayerRadius * 2.0;
		//StaticMeshComponent.SetVectorParameterValueOnMaterials(n"Glitch_Center", Center);
		//StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Radius", Radius);
		//StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_BorderWidth", -BorderWidth);
		
		//SequenceResponseComponent.OnSequenceUpdate.Clear();
		//SequenceResponseComponent.OnSequenceUpdate.AddUFunction(this, n"OnSequenceUpdate");
			
	}

	UFUNCTION()
	void OnSequenceUpdate(float CurrentTime)
	{
		TimeLast = TimeCurrent;
		TimeCurrent = CurrentTime;//ResponseData.CurrentTime;
		bool bScrubbedForwards = TimeCurrent > TimeLast;
		
		if(bVisible != bLastVisible)
		{
			bLastVisible = bVisible;
			if(bScrubbedForwards)
			{
				if(bVisible) // transistion in
				{
					TransistionStart = TimeCurrent;
					bTransistionedIn = true;
				}
				else // transistion out
				{
					TransistionStart = TimeCurrent;
					bTransistionedIn = false;
				}
			}
		}
		
		if(this.AttachParentActor == nullptr)
		{
			float Time = (TimeCurrent - TransistionStart);
			UpdateEffect(Time, bTransistionedIn);
			
			for (int i = 0; i < ChildObjects.Num(); i++)
			{
				if(ChildObjects[i] == nullptr)
					continue;
				ChildObjects[i].UpdateEffect(Time, bTransistionedIn);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();
	}
	
	ULevelSequenceDirector Director;

	void TickInEditor()
	{
	}

	bool bEffectUpdated;
	FVector UpdateLocation;
	bool bUpdateDirection;

	void UpdateEffect(float time, bool bBlendDirection)
	{
		float Blend = Math::Clamp((time - TimeStart) / BlendTime, 0.0, 1.0);
		if (BlendValue == Blend && bEffectUpdated && UpdateLocation.Equals(ActorLocation) && bUpdateDirection == bBlendDirection)
			return;	

		BlendValue = Blend;
		bEffectUpdated = true;
		UpdateLocation = ActorLocation;
		bUpdateDirection = bBlendDirection;

		if(!bBlendDirection)
			Blend = 1.0 - Blend;
		
 		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Blend", 1.0 - Blend);

		float DownDistance = 10000;
		FVector Origin;
		FVector BoxExtent;
		this.GetActorBounds(false, Origin, BoxExtent);
		float PlayerRadius = BoxExtent.Size() + BorderWidth * 5;
		FVector Center = Origin - (BlendDirection * -DownDistance);
		float Radius = (DownDistance - (PlayerRadius)) + ((1.0 - Blend) * (PlayerRadius) * 2.0);

		StaticMeshComponent.SetVectorParameterValueOnMaterials(n"Glitch_Center", Center);
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Radius", Radius);
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Offset", 0.90);
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_IsObjectBlend", 1.0f);
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_BorderWidth", BorderWidth * 30);
	}
	
#if EDITOR
	UFUNCTION(CallInEditor)
	void ConvertToHazeProp()
	{
		AHazeProp Prop = Cast<AHazeProp>(SpawnActor(AHazeProp, 
		GetActorLocation(), GetActorRotation(), FName(this.ActorNameOrLabel), false, this.Level));
		UHazePropComponent PropComp = Cast<UHazePropComponent>(Prop.GetComponent(UHazePropComponent));
		FHazePropSettings PropSettings = PropComp.Settings;

		PropSettings.StaticMesh = this.StaticMeshComponent.StaticMesh;

		Prop.OverrideSettings(PropSettings);
		Prop.SetActorScale3D(this.GetActorScale3D());
		Prop.SetActorRotation(this.GetActorRotation());
		Prop.AttachToActor(this.AttachParentActor, NAME_None, EAttachmentRule::KeepWorld);

		Prop.SetActorLabel(this.ActorNameOrLabel);

		this.DestroyActor(); 
	}
#endif

}

#if EDITOR
class UStaticMeshWhitespaceBlendComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto StaticMeshWhitespaceBlend = Cast<AStaticMeshWhitespaceBlend>(Owner);
		StaticMeshWhitespaceBlend.TickInEditor();
	}
};
#endif

#if EDITOR
class UStaticMeshWhitespaceBlendMenuExtension : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorViewOptions";
	default SupportedClasses.Add(AHazeProp);
	default SupportedClasses.Add(AStaticMeshActor);

	UFUNCTION(CallInEditor)
	void ConvertToWhitespaceBlend(AActor Prop)
	{
		UClass whitespaceBlendActor = Cast<UClass>(LoadObject(nullptr, "/Game/LevelSpecific/SciFiTutorial/BP_StaticMeshWhitespaceBlend.BP_StaticMeshWhitespaceBlend_C"));
		if(Cast<AHazeProp>(Prop) != nullptr)
		{
			Cast<AHazeProp>(Prop).Editor_ConvertToStaticMeshActor(whitespaceBlendActor);
		}
		else if(Cast<AStaticMeshActor>(Prop) != nullptr)
		{
			AStaticMeshActor OldProp = Cast<AStaticMeshActor>(Prop);
			AStaticMeshWhitespaceBlend NewProp = Cast<AStaticMeshWhitespaceBlend>(SpawnActor(whitespaceBlendActor));

			NewProp.SetActorLocation(OldProp.GetActorLocation());
			NewProp.SetActorRotation(OldProp.GetActorRotation());
			NewProp.SetActorScale3D(OldProp.GetActorScale3D());
			NewProp.StaticMeshComponent.SetStaticMesh(OldProp.StaticMeshComponent.StaticMesh);
			for (int i = 0; i < NewProp.StaticMeshComponent.Materials.Num(); i++)
			{
				NewProp.StaticMeshComponent.SetMaterial(i, OldProp.StaticMeshComponent.Materials[i]);
			}
			
			//NewProp.StaticMeshComponent.Materials = NewProp.StaticMeshComponent.Materials;

			OldProp.DestroyActor();
		}
	}
}
#endif