UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AMoonMarketAmbientMovement : AHazePrefabActor
{
	default bAffectsNavigation = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent StaticMeshComponent; // dummy component, can't remove it or everything explodes.
	default StaticMeshComponent.bVisible = false;
	default StaticMeshComponent.bCanEverAffectNavigation = false;
	default StaticMeshComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = StaticMeshComponent)
	UMoonMarketBouncyBallFauxAxisRotatorResponseComponent BallResponseComp;

	UPROPERTY(DefaultComponent, Attach = BallResponseComp)
	UStaticMeshComponent ActualMesh;
	default ActualMesh.bBlockVisualsOnDisable = false;
	default ActualMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UMoonMarketAmbientMovementEditorComponent AmbientMovementEditorComponent;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;
	
    UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

    UPROPERTY(EditAnywhere)
	float TimeOffset = 0;
	
    UPROPERTY(EditAnywhere, Meta = (EditCondition = "false", EditConditionHides))
	float RandomValue = 0;
    
	UPROPERTY(EditAnywhere)
	bool bCollisionEnabled = true;

    UPROPERTY(EditAnywhere)
	ELightmapType LightmapType = ELightmapType::Default;

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

	float AmbientMovementInfluenceAlpha = 1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		StaticMeshComponent.StaticMesh = nullptr;
		ActualMesh.StaticMesh = Mesh;
		ActualMesh.CollisionProfileName = bCollisionEnabled ? n"BlockAllDynamic" : n"NoCollision";
		ActualMesh.LightmapType = LightmapType;

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
		ImpactCallbackComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnImpactByPlayer");
	}

	UFUNCTION()
	private void OnImpactByPlayer(AHazePlayerCharacter Player)
	{
		FVector PlayerVelocity = UPlayerMovementComponent::Get(Player).PreviousVelocity;
		FVector Impulse = PlayerVelocity * 2;
		BallResponseComp.ApplyImpulse(Player.ActorLocation, Impulse);
	}

	void MovementTick()
	{
		float Time = Time::PredictedGlobalCrumbTrailTime + TimeOffset;

		if(Math::Abs(BallResponseComp.Velocity) > 0.1)
		{
			AmbientMovementInfluenceAlpha = Math::FInterpTo(AmbientMovementInfluenceAlpha, 0, Time::GlobalWorldDeltaSeconds, .5);
		}
		else
		{
			AmbientMovementInfluenceAlpha = Math::FInterpTo(AmbientMovementInfluenceAlpha, 1, Time::GlobalWorldDeltaSeconds, .5);
		}

		StartLocation = BallResponseComp.WorldLocation;
		StartRotation = BallResponseComp.WorldRotation;
		
		ActualRotateAxis = RotateAxis;
		if(RotateLocalSpace)
			ActualRotateAxis = ActorTransform.TransformVectorNoScale(RotateAxis);
		

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

		FRotator TargetRotation = StartRotation.Compose(CurrentRotate).Compose(SwingRotation);
		FRotator NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, AmbientMovementInfluenceAlpha);

		ActualMesh.SetWorldTransform(
			FTransform(
				NewRotation,
				StartLocation + BobLocation + NoiseLocation,
				StaticMeshComponent.WorldScale * CurrentScale,
			)
		);
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		MovementTick();
    }
	
#if EDITOR
	void EditorTick()
	{
		if(DisableComp.bAutoDisable)
		{
			if(Editor::EditorViewLocation.Distance(ActorLocation) > DisableComp.AutoDisableRange)
			{
				// Emulate the auto disable range
				return;
			}
		}

		MovementTick();
	}
#endif
}

UCLASS()
class UMoonMarketAmbientMovementEditorComponent : USceneComponent
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
			Cast<AMoonMarketAmbientMovement>(Owner).EditorTick();
	}
#endif
};



#if EDITOR
class UMoonMarketReplaceAmbientMovementMenuExtension : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorGeneral";
	default ExtensionOrder = EScriptEditorMenuExtensionOrder::After;

	default SupportedClasses.Add(AAmbientMovement);

	UFUNCTION(BlueprintOverride)
	bool SupportsActor(AActor Actor) const
	{
		if(Cast<AAmbientMovement>(Actor) == nullptr)
			return false;

		return true;
	}

	/**
	 * Replaces a AmbientMovement with a MoonMarketAmbientMovement actor to allow for bouncy ball & fireworks response.
	 */
	UFUNCTION(CallInEditor, Meta = (EditorIcon = "Icons.ReplaceActor"))
	void ReplaceAmbientMovement()
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		TArray<AActor> NewActors;
		NewActors.Reserve(SelectedActors.Num());

		for(AActor SelectedActor : SelectedActors)
		{
			auto OriginalAmbientMovementActor = Cast<AAmbientMovement>(SelectedActor);
			
			auto MoonMarketAmbientMovementActor = SpawnActor(
				AMoonMarketAmbientMovement,
				SelectedActor.ActorLocation,
				SelectedActor.ActorRotation,
				n"MoonMarketAmbientMovementActor",
				true,
				SelectedActor.Level
			);

			MoonMarketAmbientMovementActor.Mesh = OriginalAmbientMovementActor.Mesh;
			MoonMarketAmbientMovementActor.TimeOffset = OriginalAmbientMovementActor.TimeOffset;
			MoonMarketAmbientMovementActor.bCollisionEnabled = OriginalAmbientMovementActor.bCollisionEnabled;
			MoonMarketAmbientMovementActor.LightmapType = OriginalAmbientMovementActor.LightmapType;

			//SWING
			MoonMarketAmbientMovementActor.SwingAxis = OriginalAmbientMovementActor.SwingAxis;
			MoonMarketAmbientMovementActor.SwingAngle = OriginalAmbientMovementActor.SwingAngle;
			MoonMarketAmbientMovementActor.SwingSpeed = OriginalAmbientMovementActor.SwingSpeed;
			MoonMarketAmbientMovementActor.bSwingNoise = OriginalAmbientMovementActor.bSwingNoise;
			MoonMarketAmbientMovementActor.SwingLocalSpace = OriginalAmbientMovementActor.SwingLocalSpace;

			//ROTATE
			MoonMarketAmbientMovementActor.RotateAxis = OriginalAmbientMovementActor.RotateAxis;
			MoonMarketAmbientMovementActor.RotateSpeed = OriginalAmbientMovementActor.RotateSpeed;
			MoonMarketAmbientMovementActor.RotateLocalSpace = OriginalAmbientMovementActor.RotateLocalSpace;

			//BOB
			MoonMarketAmbientMovementActor.BobAxis = OriginalAmbientMovementActor.BobAxis;
			MoonMarketAmbientMovementActor.BobDistance = OriginalAmbientMovementActor.BobDistance;
			MoonMarketAmbientMovementActor.BobSpeed = OriginalAmbientMovementActor.BobSpeed;
			MoonMarketAmbientMovementActor.BobLocalSpace = OriginalAmbientMovementActor.BobLocalSpace;

			//SCALE
			MoonMarketAmbientMovementActor.ScaleOffset = OriginalAmbientMovementActor.ScaleOffset;
			MoonMarketAmbientMovementActor.ScaleSpeed = OriginalAmbientMovementActor.ScaleSpeed;

			//NOISE
			MoonMarketAmbientMovementActor.NoiseDistanceForward = OriginalAmbientMovementActor.NoiseDistanceForward;
			MoonMarketAmbientMovementActor.NoiseDistanceRight = OriginalAmbientMovementActor.NoiseDistanceRight;
			MoonMarketAmbientMovementActor.NoiseDistanceUp = OriginalAmbientMovementActor.NoiseDistanceUp;
			MoonMarketAmbientMovementActor.NoiseSpeedForward = OriginalAmbientMovementActor.NoiseSpeedForward;
			MoonMarketAmbientMovementActor.NoiseSpeedRight = OriginalAmbientMovementActor.NoiseSpeedRight;
			MoonMarketAmbientMovementActor.NoiseSpeedUp = OriginalAmbientMovementActor.NoiseSpeedUp;
			MoonMarketAmbientMovementActor.bNoiseLocalSpace = OriginalAmbientMovementActor.bNoiseLocalSpace;


			MoonMarketAmbientMovementActor.ActualMesh.SetStaticMesh(OriginalAmbientMovementActor.ActualMesh.StaticMesh);

			for(int i = 0; i < OriginalAmbientMovementActor.ActualMesh.Materials.Num(); i++)
			{
				auto OriginalMaterial = OriginalAmbientMovementActor.ActualMesh.Materials[i];
				MoonMarketAmbientMovementActor.ActualMesh.SetMaterial(i, OriginalMaterial);
			}

			NewActors.Add(MoonMarketAmbientMovementActor);
			FinishSpawningActor(MoonMarketAmbientMovementActor);

			MoonMarketAmbientMovementActor.AttachToComponent(SelectedActor.RootComponent.AttachParent, SelectedActor.RootComponent.AttachSocketName);
			MoonMarketAmbientMovementActor.SetActorRelativeTransform(SelectedActor.ActorRelativeTransform);

			Editor::ReplaceAllActorReferences(SelectedActor, MoonMarketAmbientMovementActor);
			SelectedActor.DestroyActor();
		}

		if(!NewActors.IsEmpty())
			Editor::SelectActors(NewActors);
	}
};
#endif