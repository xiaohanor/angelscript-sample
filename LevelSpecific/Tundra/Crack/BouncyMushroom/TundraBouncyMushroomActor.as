UCLASS(Abstract)
class ATundraBouncyMushroomActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.bBlockVisualsOnDisable = false;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TundraBouncyMushroomBounceCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float BounceStrengthSmallShape = 1200;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float SquishMultiplierSmallShape = 0.5;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float BounceStrengthHumanShape = 1200;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float SquishMultiplierHumanShape = 0.75;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float BounceStrengthBigShape = 2000;

	UPROPERTY(EditAnywhere, Category = "Bounce")
	const float SquishMultiplierBigShape = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	TPerPlayer<FHazePlaySlotAnimationParams> PlayerSmallBounceAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	TPerPlayer<FHazePlaySlotAnimationParams> PlayerHumanBounceAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	TPerPlayer<FHazePlaySlotAnimationParams> PlayerBigBounceAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	FRuntimeFloatCurve  HeightAnimationCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	FRuntimeFloatCurve WidthAnimationCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	UForceFeedbackEffect BounceForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Bounce")
	TSubclassOf<UCameraShakeBase> BounceCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Wobble")
	FRuntimeFloatCurve WobbleAnimationCurve;

	UPROPERTY(EditAnywhere, Category = "Wobble")
	float WobbleMinAnimationDuration = 0.8;

	UPROPERTY(EditAnywhere, Category = "Wobble")
	float WobbleMaxAnimationDuration = 1.3;

	UPROPERTY(EditAnywhere, Category = "Wobble")
	float WobbleMaxAngle = 10;

	UPROPERTY(EditAnywhere, Category = "Wobble")
	float WobbleMaxImpulse = 1000;

	FVector OriginalScale;
	float LastBounceGameTime = -1;
	float CurrentBounceMultiplier = 1;
	const float BounceAnimationDuration = 1.0;

	FQuat OriginalRotation;
	float LastWobbleGameTime = -1;
	FVector WobbleAxis;
	ETundraShapeshiftShape WobbleShapeShiftSize;
	float WobbleAmount = 0;
	float WobbleDuration = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CollisionMesh.StaticMesh = Mesh.StaticMesh;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorBlueprintCompiled()
	{
		CollisionMesh.StaticMesh = Mesh.StaticMesh;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		CollisionMesh.StaticMesh = Mesh.StaticMesh;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalScale = Mesh.WorldScale;
		OriginalRotation = Mesh.ComponentQuat;

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"Bounce");
		MovementImpactCallbackComp.OnWallImpactedByPlayer.AddUFunction(this, n"Wobble");
		MovementImpactCallbackComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"Wobble");
		GroundSlamResponseComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlammed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TimeSinceBounce = Time::GetGameTimeSince(LastBounceGameTime);
		const bool bBounceFinished = TimeSinceBounce > BounceAnimationDuration;
		if(bBounceFinished)
		{
			Mesh.SetWorldScale3D(OriginalScale);
		}
		else
		{
			float Width = WidthAnimationCurve.GetFloatValue(TimeSinceBounce);
			float Height = HeightAnimationCurve.GetFloatValue(TimeSinceBounce);

			Width = Math::Lerp(1, Width, CurrentBounceMultiplier);
			Height = Math::Lerp(1, Height, CurrentBounceMultiplier);

			Mesh.SetWorldScale3D(OriginalScale * FVector(Width, Width, Height));
		}

		const float TimeSinceWobble = Time::GetGameTimeSince(LastWobbleGameTime);
		const bool bWobbleFinished = TimeSinceWobble > WobbleDuration;
		if(bWobbleFinished)
		{
			Mesh.SetWorldRotation(OriginalRotation);
		}
		else
		{
			const float AngleAlpha = WobbleAnimationCurve.GetFloatValue(TimeSinceWobble / WobbleDuration);
			const float Angle = Math::Lerp(0, WobbleMaxAngle * WobbleAmount, AngleAlpha);
			const FQuat Delta = FQuat(WobbleAxis, Math::DegreesToRadians(Angle));
			const FQuat Rotation = FQuat::ApplyDelta(OriginalRotation, Delta);
			Mesh.SetWorldRotation(Rotation);
		}

		if(bBounceFinished && bWobbleFinished)
		{
			// We have finished playing the animations
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void Bounce(AHazePlayerCharacter Player)
	{
		auto BounceComp = UTundraMushroomPlayerBounceComponent::Get(Player);

		if(Time::FrameNumber - BounceComp.BounceFrame < 1)
			return;

		// Start ticking the bounce animation
		SetActorTickEnabled(true);

		LastBounceGameTime = Time::GameTimeSeconds;
		float BounceStrength = 0;

		UTundraPlayerShapeshiftingComponent TundraShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(TundraShapeShiftComp != nullptr)
		{
			if(TundraShapeShiftComp.CurrentShapeType == ETundraShapeshiftShape::Small)
			{
				BounceStrength = BounceStrengthSmallShape; 
				CurrentBounceMultiplier = SquishMultiplierSmallShape;
				UTundraBouncyMushroomEventHandler::Trigger_BounceSmallShape(Player, FTundraBouncyMushroomEventData(Player));
				UTundraBouncyMushroomEventHandler::Trigger_BounceSmallShape(this, FTundraBouncyMushroomEventData(Player));
				//TundraShapeShiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Small).PlaySlotAnimation(PlayerSmallBounceAnim[Player]);
			}
			else if(TundraShapeShiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			{
				BounceStrength = BounceStrengthBigShape;
				CurrentBounceMultiplier = SquishMultiplierBigShape;

				if(Player.IsZoe())
					BounceStrength *= 0.7;

				UTundraBouncyMushroomEventHandler::Trigger_BounceBigShape(Player, FTundraBouncyMushroomEventData(Player));
				UTundraBouncyMushroomEventHandler::Trigger_BounceBigShape(this, FTundraBouncyMushroomEventData(Player));
				//TundraShapeShiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Big).PlaySlotAnimation(PlayerBigBounceAnim[Player]);
			}
			else
			{
				Player.ResetMovement();
				BounceStrength = BounceStrengthHumanShape;
				CurrentBounceMultiplier = SquishMultiplierHumanShape;
				UTundraBouncyMushroomEventHandler::Trigger_BounceHumanShape(Player, FTundraBouncyMushroomEventData(Player));
				UTundraBouncyMushroomEventHandler::Trigger_BounceHumanShape(this, FTundraBouncyMushroomEventData(Player));
				//Player.PlaySlotAnimation(PlayerHumanBounceAnim[Player]);
			}
		}
		
		BounceComp.BounceFrame = Time::FrameNumber;

		Player.SetActorVerticalVelocity(FVector::ZeroVector);
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * BounceStrength);
		Player.PlayForceFeedback(BounceForceFeedback, false, false, this);
		//Player.PlayCameraShake(BounceCameraShake, this);
	}

	UFUNCTION()
	private void Wobble(AHazePlayerCharacter Player)
	{
		SetActorTickEnabled(true);

		// Don't wobble too often
		if(Time::GetGameTimeSince(LastWobbleGameTime) < WobbleMinAnimationDuration)
			return;

		LastWobbleGameTime = Time::GameTimeSeconds;
		FVector IntoMushroom = (ActorLocation - Player.ActorLocation).VectorPlaneProject(ActorUpVector).GetSafeNormal();
		WobbleAxis = ActorUpVector.CrossProduct(IntoMushroom).GetSafeNormal();

		FVector WobbleImpulse;
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if(MoveComp != nullptr)
		{
			WobbleImpulse = MoveComp.PreviousVelocity;
		}
		else
		{
			WobbleImpulse = Player.ActorVelocity;
		}

		auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(ShapeShiftComp != nullptr)
		{
			switch(ShapeShiftComp.ActiveShapeType)
			{
				case ETundraShapeshiftActiveShape::Small:
					WobbleImpulse *= 0.5;
					break;
				case ETundraShapeshiftActiveShape::Player:
					WobbleImpulse *= 1.0;
					break;
				case ETundraShapeshiftActiveShape::Big:
					WobbleImpulse *= 2.0;
					break;
			}
		}

		const float ImpulseIntoMushroom = WobbleImpulse.DotProduct(IntoMushroom);
		const float ImpulseUp = WobbleImpulse.DotProduct(ActorUpVector);

		const float Impulse = Math::Max(ImpulseIntoMushroom, ImpulseUp);

		WobbleAmount = Math::Saturate(Impulse / WobbleMaxImpulse);
		WobbleDuration = Math::Lerp(WobbleMinAnimationDuration, WobbleMaxAnimationDuration, WobbleAmount);
	}

	UFUNCTION()
	private void OnGroundSlammed(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType,
	                             FVector PlayerLocation)
	{
		Game::Mio.AddMovementImpulse(FVector::UpVector * 400);
	}
};

#if EDITOR
class UTundraReplaceWithBouncyMushroomMenuExtension : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorGeneral";
	default ExtensionOrder = EScriptEditorMenuExtensionOrder::After;

	/**
	 * If we want to support more actors than AStaticMeshActor, add those here and in "GetStaticMeshComponent()"
	 */
	default SupportedClasses.Add(AStaticMeshActor);
	default SupportedClasses.Add(AInstancedFoliageActor);
	default SupportedClasses.Add(AHazeProp);

	UFUNCTION(BlueprintOverride)
	bool SupportsActor(AActor Actor) const
	{
		UStaticMesh StaticMesh = nullptr;
		TArray<FHazePropMaterialOverride> MaterialOverrides;
		GetStaticMeshAndMaterials(Actor, StaticMesh, MaterialOverrides);

		if(Cast<AInstancedFoliageActor>(Actor) != nullptr)
			return true;

		if(StaticMesh == nullptr)
			return false;

		if(!StaticMesh.Name.ToString().Contains("Mushroom"))
			return false;

		return true;
	}

	/**
	 * Replaces a StaticMeshActor with a TundraBouncyMushroomActor actor.
	 */
	UFUNCTION(CallInEditor, Meta = (EditorIcon = "Icons.ReplaceActor"))
	void ReplaceWithBouncyMushroom()
	{
		FString BlueprintPath = "/Game/LevelSpecific/Tundra/Crack/BouncyMushroom/BP_TundraBouncyMushroom.BP_TundraBouncyMushroom_C";
		TSubclassOf<ATundraBouncyMushroomActor> BouncyMushroomBlueprint = Cast<UClass>(LoadObject(nullptr, BlueprintPath));
		if(BouncyMushroomBlueprint == nullptr)
		{
			PrintError(f"Failed to load TundraBouncyMushRoomActor blueprint from path: {BlueprintPath}");
			return;
		}


		TArray<AActor> SelectedActors = Editor::SelectedActors;
		TArray<AActor> NewActors;
		NewActors.Reserve(SelectedActors.Num());


		for(AActor SelectedActor : SelectedActors)
		{
			if(Cast<AInstancedFoliageActor>(SelectedActor) != nullptr)
			{
				ReplaceInstancedFoliageMeshWithMushroom(Cast<AInstancedFoliageActor>(SelectedActor), BouncyMushroomBlueprint, NewActors);
				continue;
			}

			UStaticMesh StaticMesh = nullptr;
			TArray<FHazePropMaterialOverride> MaterialOverrides;
			GetStaticMeshAndMaterials(SelectedActor, StaticMesh, MaterialOverrides);

			if(!StaticMesh.Name.ToString().Contains("Mushroom"))
				continue;

			auto BouncyMushroom = Cast<ATundraBouncyMushroomActor>(SpawnActor(
				BouncyMushroomBlueprint,
				SelectedActor.ActorLocation,
				SelectedActor.ActorRotation,
				n"BP_TundraBouncyMushroom",
				true,
				SelectedActor.Level
			));

			NewActors.Add(BouncyMushroom);

			CopyStaticMesh(BouncyMushroom, StaticMesh, MaterialOverrides);

			FinishSpawningActor(BouncyMushroom);

			BouncyMushroom.AttachToComponent(SelectedActor.RootComponent.AttachParent, SelectedActor.RootComponent.AttachSocketName);
			BouncyMushroom.SetActorRelativeTransform(SelectedActor.ActorRelativeTransform);
			BouncyMushroom.SetFolderPath(SelectedActor.FolderPath);

			Editor::ReplaceAllActorReferences(SelectedActor, BouncyMushroom);
			SelectedActor.DestroyActor();
		}

		if(!NewActors.IsEmpty())
			Editor::SelectActors(NewActors);
	}

	void ReplaceInstancedFoliageMeshWithMushroom(AInstancedFoliageActor FoliageActor, TSubclassOf<AActor> MushroomBlueprint, TArray<AActor>& NewActors)
	{
		TArray<UFoliageInstancedStaticMeshComponent> Meshes;
		FoliageActor.GetComponentsByClass(UFoliageInstancedStaticMeshComponent, Meshes);

		for(int i = Meshes.Num()-1; i >= 0; i--)
		{
			const FString MeshName = Meshes[i].StaticMesh.Name.ToString();
			if(!MeshName.Contains("Mushroom_Gigant_Ground_01_A") && !MeshName.Contains("Mushroom_Gigant_Ground_01_B"))
				continue;

			UStaticMesh StaticMesh = nullptr;
			TArray<FHazePropMaterialOverride> MaterialOverrides;

			StaticMesh = Meshes[i].StaticMesh;
			for(int j = 0; j < Meshes[i].Materials.Num(); j++)
			{
				FHazePropMaterialOverride MaterialOverride;
				MaterialOverride.Material = Meshes[i].GetMaterial(j);
				MaterialOverride.MaterialSlotIndex = j;
				MaterialOverrides.Add(MaterialOverride);
			}

			for(int j = Meshes[i].GetInstanceCount()-1; j >= 0; j--)
			{
				FTransform InstanceTransform;
				Meshes[i].GetInstanceTransform(j, InstanceTransform, true);

				if(InstanceTransform.Scale3D.X < 0.1)
					continue;

				auto BouncyMushroom = Cast<ATundraBouncyMushroomActor>(SpawnActor(
					MushroomBlueprint,
					InstanceTransform.Location,
					InstanceTransform.Rotation.Rotator(),
					n"BP_TundraBouncyMushroom",
					true,
					FoliageActor.Level
				));

				CopyStaticMesh(BouncyMushroom, StaticMesh, MaterialOverrides);
				FinishSpawningActor(BouncyMushroom);
				BouncyMushroom.SetActorScale3D(InstanceTransform.Scale3D);
				NewActors.Add(BouncyMushroom);
				BouncyMushroom.SetFolderPath(FoliageActor.FolderPath);
				Meshes[i].RemoveInstance(j);
			}
		}
	}

	/**
	 * If we want to support more actors than AStaticMeshActor, add those here and in "SupportedClasses"
	 */
	void GetStaticMeshAndMaterials(AActor Actor, UStaticMesh&out OutStaticMesh, TArray<FHazePropMaterialOverride>& OutMaterials) const
	{
		AHazeProp HazeProp = Cast<AHazeProp>(Actor);
		if(HazeProp != nullptr)
		{
			OutStaticMesh = HazeProp.PropSettings.StaticMesh;
			OutMaterials = HazeProp.PropSettings.MaterialOverrides;
			return;
		}
		AStaticMeshActor StaticMeshActor = Cast<AStaticMeshActor>(Actor);
		if(StaticMeshActor != nullptr)
		{
			OutStaticMesh = StaticMeshActor.StaticMeshComponent.StaticMesh;
			for(int i = 0; i < OutStaticMesh.StaticMaterials.Num(); i++)
			{
				FHazePropMaterialOverride MaterialOverride;
				MaterialOverride.Material = OutStaticMesh.GetMaterial(i);
				MaterialOverride.MaterialSlotIndex = i;
				OutMaterials.Add(MaterialOverride);
			}
			return;
		}
	}

	void CopyStaticMesh(ATundraBouncyMushroomActor BouncyMushroom, UStaticMesh StaticMesh, TArray<FHazePropMaterialOverride> Materials) const
	{
		BouncyMushroom.Mesh.SetStaticMesh(StaticMesh);

		for(int i = 0; i < Materials.Num(); i++)
			BouncyMushroom.Mesh.SetMaterial(Materials[i].MaterialSlotIndex, Materials[i].Material);
	}
};
#endif