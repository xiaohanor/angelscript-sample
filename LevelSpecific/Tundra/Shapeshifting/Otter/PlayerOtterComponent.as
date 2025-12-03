event void FTundraOtterAttachToFloatingPoleEvent(ATundraFloatingPoleClimbActor FloatingPole);

UCLASS(Abstract)
class UTundraPlayerOtterComponent : UTundraPlayerShapeBaseComponent
{
	default ShapeType = ETundraShapeshiftShape::Small;

	UPROPERTY(Category = "Settings")
	TSubclassOf<ATundraPlayerOtterActor> OtterActorClass;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Settings")
	UTundraPlayerOtterSwimmingSettings SwimSettings;

	UPROPERTY(Category = "Settings")
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY(Category = "Settings")
	UPlayerJumpSettings JumpSettings;

	UPROPERTY(Category = "Settings")
	UTundraPlayerOtterSettings SettingsOverride;

	UPROPERTY(Category = "Settings|Floating Pole")
	UTundraPlayerOtterSwimmingSettings SwimSettingsInFloatingPoleCableInteract;

	UPROPERTY(Category = "Settings|Floating Pole")
	UTundraPlayerOtterSwimmingSettings SwimSettingsInFloatingPoleOverrideWhenZoeNotClimbing;

	UPROPERTY(Category = "Settings|Floating Pole")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsInFloatingPoleCableInteract;

	UPROPERTY(Category = "Settings")
	UNiagaraSystem SonarBlastEffect;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> SwimmingDashCameraShake;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect SwimmingDashForceFeedback;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> SonarBlastCameraShake;

	UPROPERTY(Category = "Settings|Force Feedback & Camera Shake")
	UForceFeedbackEffect SonarBlastForceFeedback;

	UPROPERTY()
	FTundraOtterAttachToFloatingPoleEvent OnFloatingPoleAttach;

	UPROPERTY()
	FTundraOtterAttachToFloatingPoleEvent OnFloatingPoleDetach;

	UTundraPlayerOtterSettings Settings;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	ATundraPlayerOtterActor OtterActor;

	ATundraFloatingPoleClimbActor CurrentFloatingPole;

	private TArray<FInstigator> ForceJumpOutOfInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(SettingsOverride != nullptr)
			Player.ApplyDefaultSettings(SettingsOverride);

		if(OtterActorClass != nullptr)
		{
			OtterActor = SpawnActor(OtterActorClass, bDeferredSpawn = true);
			OtterActor.Player = Player;
			FinishSpawningActor(OtterActor);
			OtterActor.MakeNetworked(this, n"_OtterActor");

			OtterActor.AttachToComponent(Player.Mesh);
			OtterActor.ActorRelativeTransform = FTransform::Identity;
			Player.Mesh.LinkMeshComponentToLocomotionRequests(OtterActor.Mesh);
			OtterActor.Mesh.SetOverrideRootMotionReceiverComponent(Player.RootComponent);
			OtterActor.AddActorDisable(ShapeshiftingComp);
			Outline::ApplyOutlineOnActor(OtterActor, Game::Zoe, Outline::GetZoeOutlineAsset(), this, EInstigatePriority::Level);

			UPlayerRenderingSettingsComponent::GetOrCreate(Player).AdditionalSubsurfaceMeshes.Add(OtterActor.Mesh);
		}

		Settings = UTundraPlayerOtterSettings::GetSettings(Player);

		TListedActors<ATundraFloatingPoleClimbBlockingVolume> FloatingPoleBlockingVolumes;
		for(ATundraFloatingPoleClimbBlockingVolume Volume : FloatingPoleBlockingVolumes)
		{
			OnFloatingPoleAttach.AddUFunction(Volume, n"OnAttachFloatingPole");
			OnFloatingPoleDetach.AddUFunction(Volume, n"OnDetachFloatingPole");
		}
	}

	AHazeCharacter GetShapeActor() const override
	{
		return OtterActor;
	}

	UHazeCharacterSkeletalMeshComponent GetShapeMesh() const override
	{
		return OtterActor.Mesh;
	}

	void GetMaterialTintColors(FLinearColor &PlayerColor, FLinearColor &ShapeColor) const override
	{
		PlayerColor = Settings.MorphPlayerTint;
		ShapeColor = Settings.MorphShapeTint;
	}

	float GetShapeGravityAmount() const override
	{
		return ShapeshiftingComp.OriginalPlayerGravityAmount;
	}

	float GetShapeTerminalVelocity() const override
	{
		return ShapeshiftingComp.OriginalPlayerTerminalVelocity;
	}

	FVector2D GetShapeCollisionSize() const override
	{
		return TundraShapeshiftingStatics::OtterCollisionSize;
	}

	void AddForceJumpOutOfInstigator(FInstigator Instigator)
	{
		ForceJumpOutOfInstigators.AddUnique(Instigator);
	}

	void RemoveForceJumpOutOfInstigator(FInstigator Instigator)
	{
		ForceJumpOutOfInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsJumpOutOfForced() const
	{
		return ForceJumpOutOfInstigators.Num() > 0;
	}
}