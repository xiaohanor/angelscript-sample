UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AAmbientMovement : AHazePrefabActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent StaticMeshComponent; // dummy component, can't remove it or everything explodes.
	default StaticMeshComponent.bVisible = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ActualMesh;
	default ActualMesh.bBlockVisualsOnDisable = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UAmbientMovementEditorComponent AmbientMovementEditorComponent;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bActorIsVisualOnly = true;
	
    UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

    UPROPERTY(EditAnywhere)
	float TimeOffset = 0;
	
    UPROPERTY(EditAnywhere, Meta = (EditCondition = "false", EditConditionHides))
	float RandomValue = 0;
    
	UPROPERTY(EditAnywhere)
	bool bCollisionEnabled = true;

	UPROPERTY(EditAnywhere, AdvancedDisplay)
	bool bLerpBackAfterDisable = true;

    UPROPERTY(EditAnywhere)
	ELightmapType LightmapType = ELightmapType::Default;

    UPROPERTY(EditAnywhere)
	bool bHideOnDisable = false;

    UPROPERTY(EditAnywhere, Category = "Swing")
	FVector SwingAxis = FVector(1.0, 0.0, 0.0);
    UPROPERTY(EditAnywhere, Category = "Swing")
	float SwingAngle = 45;
    UPROPERTY(EditAnywhere, Category = "Swing")
	float SwingSpeed = 0;
    UPROPERTY(EditAnywhere, Category = "Swing")
	bool bSwingNoise = false;
    UPROPERTY(EditAnywhere, Category = "Swing")
	bool SwingLocalSpace = false;


    UPROPERTY(EditAnywhere, Category = "Rotate")
	FVector RotateAxis = FVector(0.0, 0.0, 1.0);
    UPROPERTY(EditAnywhere, Category = "Rotate")
	float RotateSpeed = 0;
    UPROPERTY(EditAnywhere, Category = "Rotate")
	bool RotateLocalSpace = false;


    UPROPERTY(EditAnywhere, Category = "Bob")
	FVector BobAxis = FVector(0.0, 0.0, 1.0);
    UPROPERTY(EditAnywhere, Category = "Bob")
	float BobDistance = 50;
    UPROPERTY(EditAnywhere, Category = "Bob")
	float BobSpeed = 0;
    UPROPERTY(EditAnywhere, Category = "Bob")
	bool BobLocalSpace = false;


    UPROPERTY(EditAnywhere, Category = "Scale")
	float ScaleOffset = 2.0;
    UPROPERTY(EditAnywhere, Category = "Scale")
	float ScaleSpeed = 0;


    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseDistanceForward = 0;
    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseDistanceRight = 0;
    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseDistanceUp = 0;

    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseSpeedForward = 0;
    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseSpeedRight = 0;
    UPROPERTY(EditAnywhere, Category = "Noise")
	float NoiseSpeedUp = 0;

    UPROPERTY(EditAnywhere, Category = "Noise")
	bool bNoiseLocalSpace = true;


    UPROPERTY()
	FRotator StartRotation;
    UPROPERTY()
	FVector StartLocation;
    UPROPERTY()
	FVector StartScale;
    UPROPERTY()
	FVector ActualRotateAxis = FVector::OneVector;

	access ReadOnly = private, *(readonly);

	// For tracking angle changes
	access:ReadOnly
	float CurrentSwingAngle = 0;

	private bool bIsLerpingBack = false;
	private FTransform LerpBackFromTransform;
	private float LerpBackTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		StaticMeshComponent.StaticMesh = nullptr;
		ActualMesh.StaticMesh = Mesh;
		ActualMesh.CollisionProfileName = bCollisionEnabled ? n"BlockAllDynamic" : n"NoCollision";
		ActualMesh.LightmapType = LightmapType;

		StaticMeshComponent.bBlockVisualsOnDisable = bHideOnDisable;
		ActualMesh.bBlockVisualsOnDisable = bHideOnDisable;

#if EDITOR
		RandomValue = Math::RandRange(0, 125);
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		RandomValue = Math::RandRange(0, 125);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (bLerpBackAfterDisable)
		{
			bIsLerpingBack = true;
			LerpBackFromTransform = ActualMesh.WorldTransform;
			LerpBackTimer = 0.0;
		}
	}

	void MovementTick(float DeltaTime)
	{
		StartLocation = ActorLocation;
		StartRotation = ActorRotation;
		
		ActualRotateAxis = RotateAxis;
		if(RotateLocalSpace)
			ActualRotateAxis = ActorTransform.TransformVectorNoScale(RotateAxis);
		
		float Time = Time::PredictedGlobalCrumbTrailTime + TimeOffset;

		FRotator SwingRotation;
		if(bSwingNoise)
		{
			CurrentSwingAngle = Math::PerlinNoise1D((Time+RandomValue) * SwingSpeed) * SwingAngle;
			SwingRotation = Math::RotatorFromAxisAndAngle((SwingLocalSpace ? GetActorTransform().TransformVector(SwingAxis) : SwingAxis), CurrentSwingAngle);
		}
		else
		{
			CurrentSwingAngle = Math::Sin(Time * SwingSpeed) * SwingAngle;
			SwingRotation = Math::RotatorFromAxisAndAngle((SwingLocalSpace ? GetActorTransform().TransformVector(SwingAxis) : SwingAxis), CurrentSwingAngle);
		}

		FRotator CurrentRotate = Math::RotatorFromAxisAndAngle(ActualRotateAxis, Time * RotateSpeed);
		
		FVector BobLocation = (BobLocalSpace ? GetActorTransform().TransformVector(BobAxis) : BobAxis) * Math::Sin(Time * BobSpeed) * BobDistance;
		
		FVector CurrentScale = FVector(Math::Lerp(1.0, ScaleOffset, Math::Cos(Time * ScaleSpeed + 3.14152128) * 0.5 + 0.5));
		
		FVector Right = FVector::RightVector;
		FVector Forward = FVector::ForwardVector;
		FVector Up = FVector::UpVector;
		if(bNoiseLocalSpace)
		{
			Right = GetActorRightVector();
			Forward = GetActorForwardVector();
			Up = GetActorUpVector();
		}

		FVector NoiseRight = Right * Math::PerlinNoise1D(Time * NoiseSpeedRight) * NoiseDistanceRight;
		FVector NoiseForward = Forward * Math::PerlinNoise1D(Time * NoiseSpeedForward + 100) * NoiseDistanceForward;
		FVector NoiseUp = Up * Math::PerlinNoise1D(Time * NoiseSpeedUp - 100) * NoiseDistanceUp;
		FVector NoiseLocation = NoiseRight + NoiseForward + NoiseUp;

		FTransform WantedTransform = FTransform(
			StartRotation.Compose(CurrentRotate).Compose(SwingRotation),
			StartLocation + BobLocation + NoiseLocation,
			StaticMeshComponent.WorldScale * CurrentScale,
		);

		if (bIsLerpingBack)
		{
			LerpBackTimer += DeltaTime;
			if (LerpBackTimer < 1.0)
			{
				FTransform BlendedTransform;
				BlendedTransform.Blend(
					LerpBackFromTransform,
					WantedTransform,
					Math::EaseIn(0, 1, LerpBackTimer, 2)
				);
				ActualMesh.SetWorldTransform(BlendedTransform);
			}
			else
			{
				bIsLerpingBack = false;
				ActualMesh.SetWorldTransform(WantedTransform);
			}
		}
		else
		{
			ActualMesh.SetWorldTransform(WantedTransform);
		}
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		MovementTick(DeltaTime);
    }
	
#if EDITOR
	void EditorTick(float DeltaTime)
	{
		if(DisableComp.bAutoDisable)
		{
			if(Editor::EditorViewLocation.Distance(ActorLocation) > DisableComp.AutoDisableRange)
			{
				// Emulate the auto disable range
				return;
			}
		}

		MovementTick(DeltaTime);
	}
#endif
}

UCLASS()
class UAmbientMovementEditorComponent : USceneComponent
{
	bool bInitialized = false;

	default bTickInEditor = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Disable ticking the component if it begins play, that means we're in a PIE world
		// so the actor's tick will take care of all the movement.
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Editor::IsPlaying())
			Cast<AAmbientMovement>(Owner).EditorTick(DeltaSeconds);
	}
#endif
};