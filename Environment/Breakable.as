event void FOnBreakEvent(const FBreakData& BreakData);

struct FBreakData
{
	FVector WorldLocation;
	float Radius = 99999999;
	FVector Force = FVector(1000, 0, 0);
	float Scatter = 0.5;
}

struct FBreakableHitData
{
	UPROPERTY()
	FVector Force = FVector(0,0,0);

	UPROPERTY()
	float Scatter = 0.0;
}

enum EBreakableCollisionType
{
	None,
	Freeze,
	BounceOnce,
	Slide,
}

enum EBreakableCollisionAccuracy
{
	Low,
	High,
}

class UDataAssetBreakable : UDataAsset
{
    UPROPERTY(Category="All")
    UNiagaraSystem BreakParticle;

	UPROPERTY(Category = "Audio")
	UHazeAudioEvent BreakAudioEvent;

	UPROPERTY(Category = "Audio")
	FHazeAudioFireForgetEventParams AudioEventParams;

	UPROPERTY(Category = "Audio", DisplayName = "Break Sound Def")
	FSoundDefReference BreakSoundDefData;

	UPROPERTY(Category = "Audio")
	bool bSoundDefCanTick = false;

    UPROPERTY(Category="All", ToolTip="Mesh used for the effect, each geometry part should have a vertex color defining it's pivot relative to it's bounding box.")
    UStaticMesh ChunksMesh;

    UPROPERTY(Category="All", ToolTip="The intact mesh used before the breakable effect.")
    UStaticMesh Mesh;
	
    UPROPERTY(Category="Breakable")
    EBreakableCollisionType CollisionType = EBreakableCollisionType::BounceOnce;
    
	UPROPERTY(Category="Breakable")
	EBreakableCollisionAccuracy CollisionAccuracy = EBreakableCollisionAccuracy::Low;

    UPROPERTY(Category="Breakable")
    float RotationSpeedMin = 1.0;
	
    UPROPERTY(Category="Breakable")
    float RotationSpeedMax = 1.0;

    UPROPERTY(Category="Breakable")
    bool RotationRandom = false;

    UPROPERTY(Category="Breakable")
    float DragMin = 0.0;

    UPROPERTY(Category="Breakable")
    float DragMax = 2.0;

    UPROPERTY(Category="Breakable")
    float Bouncyness = 0.75;

    UPROPERTY(Category="Breakable")
    float SlideTimeMin = 0.5;

    UPROPERTY(Category="Breakable")
    float SlideTimeMax = 1.0;

	// Time after impact until the object starts to fade.
    UPROPERTY(Category="Breakable")
    float FadeDelay = 0.0;
}

UCLASS(hidecategories="Physics Rendering Activation Cooking Replication Input Actor HLOD Mobile AssetUserData StaticMesh")
class UBreakableComponent : UStaticMeshComponent
{
    UPROPERTY(EditAnywhere, Category="Breakable")
	UDataAssetBreakable Preset;
	
    UPROPERTY(EditAnywhere)
	UStaticMesh BeforeBreakMesh;

    UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

    UPROPERTY()
	FVector ForceDirection = FVector(1000, 0, 0);

	UPROPERTY(EditAnywhere, Interp)
	float Time = 0;

    UPROPERTY(EditAnywhere, Category="Breakable", meta=(UIMin=0, UIMax=1))
	float Scatter = 0.5;

    UPROPERTY(EditAnywhere, Category="Breakable")
	float ForceMin = 0.5;

    UPROPERTY(EditAnywhere, Category="Breakable")
	float ForceMax = 1;

    UPROPERTY()
	FVector BreakLocation;

    UPROPERTY(EditAnywhere, Category="Breakable")
	float BreakRadius = 9999999;

    UPROPERTY(EditAnywhere, Category="Breakable")
	FVector Gravity = FVector(0, 0, -980);
	
    UPROPERTY(EditAnywhere)
    UNiagaraSystem BreakParticle;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent BreakAudioEvent;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FHazeAudioFireForgetEventParams AudioEventParams;

	UPROPERTY(EditAnywhere, Category = "Audio", DisplayName = "Break Sound Def")
	FSoundDefReference BreakSoundDefData;

	UPROPERTY(EditAnywhere, Category = "Audio")
	bool bSoundDefCanTick = false;

    UPROPERTY(EditAnywhere)
	bool bAutoLoadFromPreset = false;

    //UPROPERTY(Category="All", ToolTip="Mesh used for the effect, each geometry part should have a vertex color defining it's pivot relative to it's bounding box.")
    //UStaticMesh ChunksMesh;
//
    //UPROPERTY(Category="All", ToolTip="The intact mesh used before the breakable effect.")
    //UStaticMesh Mesh;
	
    UPROPERTY(EditAnywhere, Category="Settings")
    EBreakableCollisionType CollisionType = EBreakableCollisionType::BounceOnce;
    
	UPROPERTY(EditAnywhere, Category="Settings")
	EBreakableCollisionAccuracy CollisionAccuracy = EBreakableCollisionAccuracy::Low;

    UPROPERTY(EditAnywhere, Category="Settings")
    float RotationSpeedMin = 1.0;
	
    UPROPERTY(EditAnywhere, Category="Settings")
    float RotationSpeedMax = 1.0;

    UPROPERTY(EditAnywhere, Category="Settings")
    bool RotationRandom = false;

    UPROPERTY(EditAnywhere, Category="Settings")
    float DragMin = 0.0;

    UPROPERTY(EditAnywhere, Category="Settings")
    float DragMax = 2.0;

    UPROPERTY(EditAnywhere, Category="Settings")
    float Bouncyness = 0.75;

    UPROPERTY(EditAnywhere, Category="Settings")
    float SlideTimeMin = 0.5;

    UPROPERTY(EditAnywhere, Category="Settings")
    float SlideTimeMax = 1.0;

	// Time after impact until the object starts to fade.
    UPROPERTY(EditAnywhere, Category="Settings")
    float FadeDelay = 0.0;

    UPROPERTY(EditAnywhere, Category="Settings")
	bool Preview = false;
	
    UPROPERTY(EditAnywhere, Category="Settings")
	bool PreviewFreeze = false;
	
    UPROPERTY(EditAnywhere, Category="Settings")
	float PreviewLoopTime = 4.0;

    UPROPERTY(EditAnywhere, Category="Settings")
	float MeshBoundsScale = 1.0;
	
	default bAffectDistanceFieldLighting = false;

    UPROPERTY()
	bool Broken = false;
	
    UPROPERTY()
	float CullDistanceMultiplier = 1.0;

	UPROPERTY(Category = "Breakable")
	bool DetachOnBreak = false;

	FOnBreakEvent OnBreak;

	// Helper function to hide & disable collision.
	void SetComponentEnabled(UPrimitiveComponent Component, bool bEnabled)
	{
		if(Component == nullptr)
			return;
		Component.SetVisibility(bEnabled);
		Component.SetCollisionEnabled(bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
	}
	
	FVector GetDefaultBreakLocation()
	{
		return BreakLocation;
	}
	
	float GetDefaultRadius()
	{
		return BreakRadius;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		Construct();
	}
#endif

	UFUNCTION(CallInEditor, Category = "Breakable")
	void LoadFromPreset()
	{
		BreakParticle			= 	Preset.BreakParticle					;
		BreakAudioEvent			= 	Preset.BreakAudioEvent				;
		AudioEventParams		= 	Preset.AudioEventParams				;
		BreakSoundDefData		= 	Preset.BreakSoundDefData				;
		bSoundDefCanTick		= 	Preset.bSoundDefCanTick				;
		BeforeBreakMesh 		= Preset.Mesh;
		Mesh 					= Preset.ChunksMesh;
		
		CollisionType 			= 	Preset.CollisionType 		;
		CollisionAccuracy 		= 	Preset.CollisionAccuracy 	;
		RotationSpeedMin 		=	Preset.RotationSpeedMin 	;	
		RotationSpeedMax		=	Preset.RotationSpeedMax		;
		RotationRandom 			=	Preset.RotationRandom 		;
		DragMin 				= 	Preset.DragMin 				;
		DragMax 				= 	Preset.DragMax 				;
		Bouncyness 				= 	Preset.Bouncyness 			;
		SlideTimeMin 			=	Preset.SlideTimeMin 		;
		SlideTimeMax 			=	Preset.SlideTimeMax 		;
		FadeDelay 				= 	Preset.FadeDelay 			;
	}
	
    void Construct()
	{
		if(bAutoLoadFromPreset)
		{
			if(Preset != nullptr)
			{
				LoadFromPreset();
			}
		}
		
		if(BeforeBreakMesh != nullptr)
			this.StaticMesh = BeforeBreakMesh;
		else
			this.StaticMesh = Mesh;

		this.SetBoundsScale(MeshBoundsScale);
		this.MarkRenderStateDirty();

		Init();

		if(Preview)
		{
			this.StaticMesh = Mesh;
			SetMaterialParameters(GetDefaultBreakLocation(), GetDefaultRadius(), ForceDirection, ForceMin, ForceMax, Scatter, false);
		}
		else
		{
			ResetMaterial();
		}
		
	}

	UFUNCTION(CallInEditor, Category = "Breakable")
    void ConstructionScript_Hack()
    {
#if EDITOR
		// Give artists direct feedback on changes made on data asset component(s)
		if (Preset != nullptr)
		{
			Preset.OnAssetChanged.Clear(); // Remove any previous delegates,
			Preset.OnAssetChanged.AddUFunction(this, n"OnComponentModifiedInEditor");
		}
#endif
		Construct();
    }
   	UFUNCTION(Category="Breakable", CallInEditor)
	void Reset()
	{
		Init();
	}
	


	void SetCullingDistance()
	{
		float dist = Editor::GetDefaultCullingDistance(this) * CullDistanceMultiplier;
		this.SetCullDistance(dist);
		SetCullDistance(dist);
	}
    
	void Init()
	{
		Broken = false;

		SetComponentEnabled(this, true);
		SetCullingDistance();
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Init();
		Preview = false;
		SetMaterialParameters(GetDefaultBreakLocation(), GetDefaultRadius(), ForceDirection, ForceMin, ForceMax, Scatter, false);
    }
	
	void ResetMaterial()
	{
		for(int i = 0; i < this.GetNumMaterials(); i++)
		{
			UMaterialInstanceDynamic CurrentMaterial = Cast<UMaterialInstanceDynamic>(this.GetMaterial(i));
			if(CurrentMaterial != nullptr)
			{
				this.SetMaterial(i, CurrentMaterial.Parent);
			}
		}
	}

	void SetMaterialParameters(FVector inWorldLocation, float inRadius, FVector inForce, float inForceMin, float inForceMax, float inScatter, bool setBreakTime)
	{
		ResetMaterial();
		
		for(int i = 0; i < this.GetNumMaterials(); i++)
		{
			UMaterialInstanceDynamic Material = this.CreateDynamicMaterialInstance(i);

			Material.SetScalarParameterValue(n"Breakable_Scatter", inScatter);
			Material.SetVectorParameterValue(n"Breakable_Force", FLinearColor(inForce));
			Material.SetScalarParameterValue(n"Breakable_ForceMin", inForceMin);
			Material.SetScalarParameterValue(n"Breakable_ForceMax", inForceMax);
			Material.SetScalarParameterValue(n"Breakable_CollisionType", int(CollisionType));
			Material.SetScalarParameterValue(n"Breakable_Preview", Preview ? PreviewLoopTime : 0);
			Material.SetScalarParameterValue(n"Breakable_PreviewFreeze", PreviewFreeze ? 1 : 0);
			Material.SetVectorParameterValue(n"Breakable_BreakLocation", FLinearColor(inWorldLocation));
			Material.SetVectorParameterValue(n"Breakable_Gravity", FLinearColor(Gravity));
			Material.SetScalarParameterValue(n"Breakable_Radius", inRadius);

			Material.SetScalarParameterValue(n"Breakable_DragMin", DragMin);
			Material.SetScalarParameterValue(n"Breakable_DragMax", DragMax);
			Material.SetScalarParameterValue(n"Breakable_RotationSpeedMin", RotationSpeedMin);
			Material.SetScalarParameterValue(n"Breakable_RotationSpeedMax", RotationSpeedMax);
			Material.SetScalarParameterValue(n"Breakable_RotationRandom", RotationRandom ? 1 : 0);
			Material.SetScalarParameterValue(n"Breakable_Bouncyness", Bouncyness);
			Material.SetScalarParameterValue(n"Breakable_SlideTimeMin", SlideTimeMin);
			Material.SetScalarParameterValue(n"Breakable_SlideTimeMax", SlideTimeMax);
			Material.SetScalarParameterValue(n"Breakable_CollisionAccuracy", int(CollisionAccuracy));
			Material.SetScalarParameterValue(n"Breakable_FadeDelay", FadeDelay);
			
			Material.SetScalarParameterValue(n"Breakable_InvBoundsScale", 1.0 / MeshBoundsScale);
			
			if(setBreakTime)
				Material.SetScalarParameterValue(n"Breakable_BreakTime", Time::GameTimeSeconds);

			if(Time > 0)
			{
				Material.SetScalarParameterValue(n"Breakable_Preview", -Time);
			}
		}
	}

	UFUNCTION()
	void BreakWithDefault()
	{
		BreakAt(GetDefaultBreakLocation(), GetDefaultRadius(), this.ForceDirection, this.Scatter);
	}
	UFUNCTION()
	void Break(FVector inForce = FVector(1000, 0, 0), float inScatter = 0.5)
	{
		BreakAt(GetDefaultBreakLocation(), GetDefaultRadius(), inForce, inScatter);
	}
	
	UFUNCTION()
	void BreakWithDefaultAt(FVector inWorldLocation, float inRadius = 99999999)
	{
		BreakAt(inWorldLocation, inRadius, this.ForceDirection, this.Scatter);
	}
	UFUNCTION()
	void BreakAt(FVector inWorldLocation, float inRadius = 99999999, FVector inForce = FVector(1000, 0, 0), float inScatter = 0.5)
	{
		if(Broken)
			return;

		Broken = true;
		
		this.StaticMesh = Mesh;
		
		TArray<AActor> AttachedActors;
		this.Owner.GetAttachedActors(AttachedActors);
		for (int i = 0; i < AttachedActors.Num(); i++)
		{
			AHazeNiagaraActor Effect = Cast<AHazeNiagaraActor>(AttachedActors[i]);
			if(Effect != nullptr)
			{
				Effect.NiagaraComponent0.Activate();
			}
		}
		
		if(BreakAudioEvent != nullptr)
		{		
			AudioEventParams.AttachComponent = this;
			AudioEventParams.Transform = GetWorldTransform();	
			AudioComponent::PostFireForget(BreakAudioEvent, AudioEventParams);		
		}

		if(BreakSoundDefData.SoundDef.IsValid())
		{	
			BreakSoundDefData.SpawnSoundDefOneshot(this, GetWorldTransform(), this, bCanTick = bSoundDefCanTick);			
		}

		if(BreakParticle != nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakParticle, GetWorldLocation(), GetWorldRotation());
		}
		
		FBreakData BreakData;
		BreakData.WorldLocation = inWorldLocation;
		BreakData.Radius = inRadius;
		BreakData.Force = inForce;
		BreakData.Scatter = inScatter;

		OnBreak.Broadcast(BreakData);			

		SetComponentEnabled(this, true);
		this.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		if(DetachOnBreak)
		{
			this.DetachFromParent(true);
		}

		SetMaterialParameters(inWorldLocation, inRadius, inForce, 1, 1, inScatter, true);
	}

	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time > 0)
		{
			SetMaterialParameters(GetDefaultBreakLocation(), GetDefaultRadius(), ForceDirection, ForceMin, ForceMax, Scatter, false);
		}
	}
}

//UCLASS(Abstract, hideCategories="StartingAnimation Animation Mesh Physics Collision Activation Lighting Shape Navigation Clothing Replication Rendering Cooking Input Actor LOD AssetUserData")
UCLASS(Abstract)
class ABreakableActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UBreakableComponent BreakableComponent;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

    UPROPERTY(EditAnywhere)
	float EditorBillboardScale = 2.0;

    UPROPERTY(EditAnywhere, Category="Breakable", Meta = (MakeEditWidget))
	FVector BPForce = FVector(1000, 0, 0);

    UPROPERTY(EditAnywhere, Category="Breakable", Meta = (MakeEditWidget))
	FVector BPBreakLocation;

	UPROPERTY()
	FOnBreakEvent OnBreak;
	
	UFUNCTION(CallInEditor, Category = "Breakable")
	void LoadFromPreset()
	{
		BreakableComponent.LoadFromPreset();
	}
	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Billboard.SetWorldScale3D(FVector::OneVector*EditorBillboardScale);
		BreakableComponent.ForceDirection = GetActorTransform().TransformVector(BPForce);
		BreakableComponent.BreakLocation = GetActorTransform().TransformPosition(BPBreakLocation);
		//BreakableComponent.BreakRadius = BPBreakRadius;
		BreakableComponent.ConstructionScript_Hack();
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BreakableComponent.OnBreak.AddUFunction(this, n"OnBroken");
	}

	UFUNCTION()
	void OnBroken(const FBreakData& BreakData)
	{
		OnBreak.Broadcast(BreakData);
	}
}